package test_coreclr

import _c	"core:c"
import		"core:fmt"
import		"base:runtime"
import		"core:testing"
import clr	".."

expect	:: testing.expect
expectf	:: testing.expectf
expect_value	:: testing.expect_value

unmanaged_callback_ptr :: #type proc "c" (actionName: cstring, jsonArgs: cstring) -> _c.bool

managed_direct_method_ptr :: #type proc "c" (
	actionName: cstring,
	jsonArgs: cstring,
	unmanagedCallback: unmanaged_callback_ptr,
) -> ^_c.char

@(test)
init_coreclr_lib :: proc(t: ^testing.T) {
	coreclr_dir := clr.get_coreclr_dir()
	hr: clr.error
	host: clr.clr_host
	hr = clr.load_coreclr_library(&host, coreclr_dir)
	expect(t, host.host != nil, "initialize_coreclr_library failure")
	//fmt.printf("host=%v\n", host)

	hr = clr.unload_coreclr_library(&host)
	expectf(t, hr == .ok, "unload_coreclr_library %v", hr)
	//fmt.printf("host=%v\n", host)
}

@(test)
build_tpa :: proc(t: ^testing.T) {
	coreclr_dir := clr.get_coreclr_dir()
	tpa, ok := clr.build_tpa_list(coreclr_dir, context.temp_allocator)
	expect(t, ok, "build_tpa_list failure")
	// fmt.printf("tpa=%s\n", tpa)
	expect(t, len(tpa) > 1000, fmt.tprintf("len(tpa) = %d", len(tpa)))
}

@(test)
initialize_coreclr_host :: proc(t: ^testing.T) {
	coreclr_dir := clr.get_coreclr_dir()
	hr: clr.error
	host: clr.clr_host

	hr = clr.load_coreclr_library(&host, coreclr_dir)
	expect(t, host.host != nil, "initialize_coreclr_library failure")

	tpa := clr.create_trusted_platform_assemblies(coreclr_dir, ".", allocator = context.temp_allocator)

	hr = clr.initialize(&host, coreclr_dir, "SampleHost", tpa)
	expectf(t, hr == .ok, "initialize %v", hr)
	assert(hr == .ok, "initialize")

	hr = clr.shutdown(&host)
	expectf(t, hr == .ok, "coreclr_shutdown %v %x", hr, u32(hr))
	assert(hr == .ok, "coreclr_shutdown :(")

	hr = clr.unload_coreclr_library(&host)
	expectf(t, hr == .ok, "unload_coreclr_library %v", hr)
	assert(hr == .ok, "unload_coreclr_library")
}

unmanaged_callback :: #type proc "c" (actionName: cstring, jsonArgs: cstring) -> _c.bool

do_unmanaged_callback :: proc "c" (actionName: cstring, jsonArgs: cstring) -> _c.bool {
	context = runtime.default_context()
	fmt.printf("Odin>> %s, %v", actionName, jsonArgs)
	return true
}

//not working when runng as a test //
@(test)
coreclr_host_create_cb :: proc(t: ^testing.T) {
	coreclr_dir := clr.get_coreclr_dir()
	hr: clr.error
	host: clr.clr_host
	hr = clr.load_coreclr_library(&host, coreclr_dir)
	expect(t, host.host != nil, "load_coreclr_library")
	assert(host.host != nil, "load_coreclr_library")
	//defer assert(clr.unload_coreclr_library(), "unload_coreclr_library")

	tpa := clr.create_trusted_platform_assemblies(coreclr_dir, ".", allocator = context.temp_allocator)

	//fmt.print("initialize\n")
	hr = clr.initialize(&host, coreclr_dir, "SampleHost", tpa)
	expectf(t, hr == .ok, "initialize %v", hr)
	assert(hr == .ok, "initialize")
	//fmt.printf("_hostHandle=%v _domainId=%v\n", host.hostHandle, host.domainId)

	delegate: unmanaged_callback
	hr = clr.create_delegate(&host, "gateway", "Gateway", "ManagedDirectMethod", &delegate)
	expectf(t, hr == .ok, "create_delegate %v", hr)
	//fmt.printf("delegate %v\n", delegate)
	expectf(t, delegate != nil, "delegate %v", delegate)

	//fmt.print("shutdown\n")
	hr = clr.shutdown(&host)
	expectf(t, hr == .ok, "coreclr_shutdown %v %x", hr, u32(hr))
	assert(hr == .ok, "coreclr_shutdown")
	//fmt.print("destroy\n")
	hr = clr.unload_coreclr_library(&host)
	expectf(t, hr == .ok, "unload_coreclr_library %v", hr)
	assert(hr == .ok, "unload_coreclr_library")
	//fmt.print("done\n")
}
