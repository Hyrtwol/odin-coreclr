package coreclr_example_gateway

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:os"
import clr "../.."
import "../../obug"

coreclr_dir: string

print_if_error :: proc(hr: clr.error, loc := #caller_location) {
	if hr != .ok {fmt.printfln("Error %v (0x%8X) @ %v", hr, u32(hr), loc)}
}

event_callback :: proc(ch: ^clr.clr_host, type: clr.event_type, hr: clr.error) {
	fmt.printfln("[%v] %v (%p,%p)", type, hr, ch.host, ch.hostHandle)
}

create_gateway_delegates :: proc(host: ^clr.clr_host, gateway: ^Gateway) -> (res: clr.error) {
	an :: "gateway"
	tn :: "Gateway"
	print_if_error(clr.create_delegate(host, an, tn, "AssemblyLocation", &gateway.AssemblyLocation))
	print_if_error(clr.create_delegate(host, an, tn, "SizeOfStuff", &gateway.SizeOfStuff))
	print_if_error(clr.create_delegate(host, an, tn, "Plus", &gateway.Plus))
	print_if_error(clr.create_delegate(host, an, tn, "Sum", &gateway.Sum))
	print_if_error(clr.create_delegate(host, an, tn, "ManagedDirectMethod", &gateway.ManagedDirectMethod))
	return .ok
}

unmanaged_callback :: proc "c" (actionName: cstring, jsonArgs: cstring) -> bool {
	context = runtime.default_context()
	fmt.printfln("Odin>> %s, %v", actionName, jsonArgs)
	return true
}

call_csharp :: proc(gateway: ^Gateway) {

	fmt.println("AssemblyLocation:", gateway.AssemblyLocation())

	sof: SizeOf
	gateway.SizeOfStuff(&sof)
	fmt.println("SizeOfStuff:", sof)

	fmt.println("Plus:", gateway.Plus(1.3, 37))

	vals := [?]f64{1.0, 2.1, 3.2, 4.3}
	fmt.println("Sum:", gateway.Sum(&vals[0], len(vals)))

	fmt.println("ManagedDirectMethod")
	ok := gateway.ManagedDirectMethod("funky", "json doc", unmanaged_callback)
	fmt.printfln("Result: '%v'", ok)
}

execute_clr_host :: proc(tpa: string) -> clr.error {
	host: clr.clr_host = {
		event_cb = event_callback,
	}

	// Prepare the coreclr lib
	clr.load_coreclr_library(&host, coreclr_dir) or_return
	defer clr.unload_coreclr_library(&host)

	exePath, err := os.get_executable_path(context.temp_allocator)
	if err != nil {panic("get_executable_path")}
	fmt.println("exePath:", exePath)

	// Prepare the coreclr host
	clr.initialize(&host, exePath, "SampleHost", tpa) or_return
	defer clr.shutdown(&host)

	{
		// Prepare the delegates for calling C#
		gateway: Gateway = {}
		create_gateway_delegates(&host, &gateway) or_return

		call_csharp(&gateway)
	}

	return .ok
}

run :: proc() -> (exit_code: int) {
	fmt.println(" -=< CoreCLR Host Demo >=- ")
	coreclr_dir = clr.get_coreclr_dir()
	fmt.println("coreclr_dir:", coreclr_dir)
	working_directory, ok := os.get_working_directory(context.temp_allocator)
	if ok != nil {panic("get_working_directory")}
	fmt.println("working_directory:", working_directory)
	tpa := clr.create_trusted_platform_assemblies(coreclr_dir, working_directory, allocator = context.temp_allocator)
	clr.write_tpa("tpa.log", tpa)
	err := execute_clr_host(tpa)
	fmt.println("Done.", err)
	exit_code = int(err)
	return
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}
