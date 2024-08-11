package test_coreclr

import _c	"core:c"
import		"core:fmt"
import		"core:os"
import		"base:runtime"
import		"core:strings"
import		"core:testing"
import clr	".."

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect	:: testing.expect
	expectf	:: testing.expectf
	log		:: testing.log
} else {
	expect :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.println(message)
			return
		}
		fmt.println(" PASS")
	}
	expectf :: proc(t: ^testing.T, ok: bool, format: string, args: ..any, loc := #caller_location) {
		TEST_count += 1
		if !ok {
			TEST_fail += 1
			fmt.printf(format, ..args)
			return
		}
	}
	log :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc() {
	t := testing.T{}
	init_coreclr_lib(&t)
	initialize_coreclr_host(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

CORECLR_DIR :: "C:\\Program Files\\dotnet\\shared\\Microsoft.NETCore.App\\8.0.2"

//trusted_platform_assemblies: string = #load("trusted_platform_assemblies.txt") // todo implement a TPA scanner

unmanaged_callback_ptr :: #type proc "c" (actionName: cstring, jsonArgs: cstring) -> _c.bool

managed_direct_method_ptr :: #type proc "c" (
	actionName: cstring,
	jsonArgs: cstring,
	unmanagedCallback: unmanaged_callback_ptr,
) -> ^_c.char

create_trusted_platform_assemblies :: proc(paths: ..string) -> string {
	assemblies := make([dynamic]string, 0, 200)
	defer delete(assemblies)
	for path in paths {
		clr.asm_scan(&assemblies, path)
	}
	//write_tpa("tpa.log", assemblies[:])
	return strings.join(assemblies[:], clr.get_list_separator())
}

@(test)
init_coreclr_lib :: proc(t: ^testing.T) {
	hr: clr.error
	host: clr.clr_host
	hr = clr.load_coreclr_library(&host, CORECLR_DIR)
	expect(t, host.host != nil, "initialize_coreclr_library failure")
	fmt.printf("host=%v\n", host)

	hr = clr.unload_coreclr_library(&host)
	expectf(t, hr == .ok, "unload_coreclr_library %v", hr)
	fmt.printf("host=%v\n", host)
}

@(test)
initialize_coreclr_host :: proc(t: ^testing.T) {
	hr: clr.error
	host: clr.clr_host
	fmt.print("initialize_coreclr_host\n")
	hr = clr.load_coreclr_library(&host, CORECLR_DIR)
	expect(t, host.host != nil, "initialize_coreclr_library failure")
	//defer assert(clr.unload_coreclr_library(), "unload_coreclr_library")

	tpa := create_trusted_platform_assemblies(CORECLR_DIR, ".")

	fmt.print("initialize\n")
	hr = clr.initialize(&host, CORECLR_DIR, "SampleHost", tpa)
	expectf(t, hr == .ok, "initialize %v", hr)
	assert(hr == .ok, "initialize")

	fmt.printf("_hostHandle=%v _domainId=%v\n", host.hostHandle, host.domainId)

	fmt.print("shutdown\n")
	hr = clr.shutdown(&host)
	expectf(t, hr == .ok, "coreclr_shutdown %v", hr)
	assert(hr == .ok, "coreclr_shutdown")

	fmt.print("destroy\n")
	hr = clr.unload_coreclr_library(&host)
	expectf(t, hr == .ok, "unload_coreclr_library %v", hr)
	assert(hr == .ok, "unload_coreclr_library")
	fmt.print("done\n")
}

unmanaged_callback :: #type proc "c" (actionName: cstring, jsonArgs: cstring) -> _c.bool

do_unmanaged_callback :: proc "c" (actionName: cstring, jsonArgs: cstring) -> _c.bool {
	context = runtime.default_context()
	fmt.printf("Odin>> %s, %v", actionName, jsonArgs)
	return true
}

@(test)
coreclr_host_create_cb :: proc(t: ^testing.T) {
	hr: clr.error
	host: clr.clr_host
	hr = clr.load_coreclr_library(&host, CORECLR_DIR)
	expect(t, host.host != nil, "load_coreclr_library")
	assert(host.host != nil, "load_coreclr_library")
	//defer assert(clr.unload_coreclr_library(), "unload_coreclr_library")

	tpa := create_trusted_platform_assemblies(CORECLR_DIR, ".")

	fmt.print("initialize\n")
	hr = clr.initialize(&host, CORECLR_DIR, "SampleHost", tpa)
	expectf(t, hr == .ok, "initialize %v", hr)
	assert(hr == .ok, "initialize")
	fmt.printf("_hostHandle=%v _domainId=%v\n", host.hostHandle, host.domainId)

	delegate: unmanaged_callback
	hr = clr.create_delegate(&host, "gateway", "Gateway", "ManagedDirectMethod", &delegate)
	expectf(t, hr == .ok, "create_delegate %v", hr)
	fmt.printf("delegate %v\n", delegate)
	expectf(t, delegate != nil, "delegate %v", delegate)

	fmt.print("shutdown\n")
	hr = clr.shutdown(&host)
	expectf(t, hr == .ok, "coreclr_shutdown %v", hr)
	assert(hr == .ok, "coreclr_shutdown")
	fmt.print("destroy\n")
	hr = clr.unload_coreclr_library(&host)
	expectf(t, hr == .ok, "unload_coreclr_library %v", hr)
	assert(hr == .ok, "unload_coreclr_library")
	fmt.print("done\n")
}

@(test)
build_tpa :: proc(t: ^testing.T) {
	tpa, ok := clr.build_tpa_list(CORECLR_DIR)
	expect(t, ok, "build_tpa_list failure")
	fmt.printf("tpa=%s\n", tpa)
}
