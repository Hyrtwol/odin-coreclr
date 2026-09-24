package coreclr_example_gateway

import clr "../.."
import "../../obug"
import "base:intrinsics"
import "core:fmt"
import "core:os"
import "core:strings"

// _ :: strings
coreclr_dir: string

c_appDomainFriendlyName: cstring = "SampleHost"

print_if_error :: proc(hr: clr.error, loc := #caller_location) {
	if hr != .ok {fmt.printfln("Error %v (0x%8X) @ %v", hr, u32(hr), loc)}
}

print_event_callback :: proc(ch: ^clr.clr_host, type: clr.event_type, hr: clr.error) {
	fmt.printfln("[%v] %v (%p,%p)", type, hr, ch.host, ch.hostHandle)
}

execute_clr_host :: proc(tpa: string) -> clr.error {
	host: clr.clr_host = {
		event_cb = print_event_callback,
	}
	ch: ^clr.clr_host = &host

	// Prepare the coreclr lib
	clr.load_coreclr_library(ch, coreclr_dir) or_return
	defer clr.unload_coreclr_library(ch)

	//c_appDomainFriendlyName := strings.clone_to_cstring("SampleHost", context.temp_allocator)
	fmt.println("c_appDomainFriendlyName:", c_appDomainFriendlyName)

	hr := ch.host.coreclr_initialize(
		nil, // App base path
		c_appDomainFriendlyName, // AppDomain friendly name
		0, // Property count
		nil, // Property names
		nil, // Property values
		&ch.hostHandle, // Host handle
		&ch.domainId, // AppDomain ID
	)
	fmt.println("coreclr_initialize", hr)
	if hr != .ok {
		return hr
	}

	defer clr.shutdown(&host)

	return .ok
}

run :: proc() -> (exit_code: int) {
	fmt.println(" -=< CoreCLR Host Demo >=- ")
	coreclr_dir = clr.get_coreclr_dir()
	fmt.println("coreclr_dir:", coreclr_dir)
	working_directory, err := os.get_working_directory(context.temp_allocator)
	if err != nil {fmt.panicf("get_working_directory: %v", err)}
	fmt.println("working_directory:", working_directory)
	tpa := clr.create_trusted_platform_assemblies(coreclr_dir, working_directory, allocator = context.temp_allocator)
	err = clr.write_tpa("tpa.log", tpa)
	if err != nil {fmt.panicf("write_tpa: %v", err)}
	result := execute_clr_host(tpa)
	fmt.println("Done.", result)
	exit_code = int(result)
	return
}

main :: proc() {
	when intrinsics.is_package_imported("obug") {
		os.exit(obug.tracked_run(run))
	} else {
		os.exit(run())
	}
}
