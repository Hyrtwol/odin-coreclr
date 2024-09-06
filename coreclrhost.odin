package coreclr

import		"base:intrinsics"
import		"core:dynlib"
import		"core:fmt"
import		"core:path/filepath"
import		"core:strings"

/*
Handle for the CoreCLR host.
*/
host_handle :: distinct rawptr

/*
Domain identifier for the CoreCLR host.
*/
domain_id   :: distinct u32

error :: enum i32 {
	ok,
	error,
	initialize_symbols,
	initialize_error,
	host_null,
	host_handle_null,
}

/*
https://github.com/dotnet/runtime/blob/main/src/coreclr/hosts/inc/coreclrhost.h
*/
core_clr_host :: struct {
	/*
	Initialize the CoreCLR. Creates and starts CoreCLR host and creates an app domain

	Parameters:
		exePath                 - Absolute path of the executable that invoked the ExecuteAssembly (the native host application)
		appDomainFriendlyName   - Friendly name of the app domain that will be created to execute the assembly
		propertyCount           - Number of properties (elements of the following two arguments)
		propertyKeys            - Keys of properties of the app domain
		propertyValues          - Values of properties of the app domain
		hostHandle              - Output parameter, handle of the created host
		domainId                - Output parameter, id of the created app domain

	Returns:
		HRESULT indicating status of the operation. S_OK if the assembly was successfully executed

	See:
		https://github.com/dotnet/runtime/blob/main/src/coreclr/hosts/inc/coreclrhost.h#L41
	*/
	coreclr_initialize:       proc "c" (
		exePath: cstring,
		appDomainFriendlyName: cstring,
		propertyCount: i32,
		propertyKeys: ^cstring,
		propertyValues: ^cstring,
		hostHandle: ^host_handle,
		domainId: ^domain_id,
	) -> error,
	/*
	Shutdown CoreCLR. It unloads the app domain and stops the CoreCLR host.

	Parameters:
		hostHandle              - Handle of the host
		domainId                - Id of the domain

	Returns:
		HRESULT indicating status of the operation. S_OK if the assembly was successfully executed

	See:
		https://github.com/dotnet/runtime/blob/main/src/coreclr/hosts/inc/coreclrhost.h#L78
	*/
	coreclr_shutdown:         proc "c" (
		hostHandle: host_handle,
		domainId: domain_id,
	) -> error,
	/*
	Shutdown CoreCLR. It unloads the app domain and stops the CoreCLR host.

	Parameters:
		hostHandle              - Handle of the host
		domainId                - Id of the domain
		latchedExitCode         - Latched exit code after domain unloaded

	Returns:
		HRESULT indicating status of the operation. S_OK if the assembly was successfully executed
	*/
	coreclr_shutdown_2:       proc "c" (
		hostHandle: host_handle,
		domainId: domain_id,
		latchedExitCode: ^i32,
	) -> error,
	/*
	Create a native callable function pointer for a managed method.

	Parameters:
		hostHandle              - Handle of the host
		domainId                - Id of the domain
		entryPointAssemblyName  - Name of the assembly which holds the custom entry point
		entryPointTypeName      - Name of the type which holds the custom entry point
		entryPointMethodName    - Name of the method which is the custom entry point
		delegate                - Output parameter, the function stores a native callable function pointer to the delegate at the specified address

	Returns:
		HRESULT indicating status of the operation. S_OK if the assembly was successfully executed
	*/
	coreclr_create_delegate:  proc "c" (
		hostHandle: host_handle,
		domainId: domain_id,
		entryPointAssemblyName: cstring,
		entryPointTypeName: cstring,
		entryPointMethodName: cstring,
		delegate: ^rawptr,
	) -> error,
	/*
	Execute a managed assembly with given arguments

	Parameters:
		hostHandle              - Handle of the host
		domainId                - Id of the domain
		argc                    - Number of arguments passed to the executed assembly
		argv                    - Array of arguments passed to the executed assembly
		managedAssemblyPath     - Path of the managed assembly to execute (or NULL if using a custom entrypoint).
		exitCode                - Exit code returned by the executed assembly

	Returns:
		HRESULT indicating status of the operation. S_OK if the assembly was successfully executed
	*/
	coreclr_execute_assembly: proc "c" (
		hostHandle: host_handle,
		domainId: domain_id,
		argc: i32,
		argv: ^cstring,
		managedAssemblyPath: cstring,
		exitCode: ^i32,
	) -> error,
	__handle:                 dynlib.Library,
}

event_type :: enum {
	create,
	load_library,
	unload_library,
	initialize,
	shutdown,
	destroy,
}

event_callback :: #type proc(ch: ^clr_host, type: event_type, hr: error)

clr_host :: struct {
	host:       ^core_clr_host,
	hostHandle: host_handle,
	domainId:   domain_id,
	event_cb:   event_callback,
}

@(private="file")
do_callback :: #force_inline proc(ch: ^clr_host, type: event_type, hr: error) -> error {
	if ch.event_cb != nil {ch.event_cb(ch, type, hr)}
	return hr
}

/*
Build a list of trusted platform assemblies
*/
build_tpa_list :: proc(path: string, allocator := context.allocator) -> (tpa: string, ok: bool) {
	pkg_path : string
	pkg_path, ok = filepath.abs(path, context.temp_allocator)
	if !ok {return}
	path_pattern := filepath.clean(fmt.tprintf("%s/*.dll", pkg_path), context.temp_allocator)
	matches, err := filepath.glob(path_pattern, context.temp_allocator)
	ok = err == .None
	if !ok {return}
	LIST_SEPARATOR := []byte{filepath.LIST_SEPARATOR}
	tpa = strings.join(matches, string(LIST_SEPARATOR), allocator)
	return
}

/*
Load CoreCLR runtime library.
windows: coreclr.dll
linux:   libcoreclr.so
darwin:  libcoreclr.dylib
*/
load_coreclr_library :: proc(ch: ^clr_host, coreclr_path: string) -> error {

	assert(ch.host == nil)
	assert(ch.hostHandle == nil)
	assert(ch.domainId == 0)

	do_callback(ch, .create, .ok)

	path: string = filepath.join({coreclr_path, LIBCORECLR}, context.temp_allocator)
	fmt.printf("path=%s\n", path)
	host := new(core_clr_host)
	count, ok := dynlib.initialize_symbols(host, path, /*TODO , "coreclr_"*/)
	if !ok {return do_callback(ch, .load_library, .initialize_symbols)}

	assert(count == 5)
	assert(host.__handle != nil)
	assert(host.coreclr_initialize != nil)
	assert(host.coreclr_shutdown != nil)
	assert(host.coreclr_shutdown_2 != nil)
	assert(host.coreclr_create_delegate != nil)
	assert(host.coreclr_execute_assembly != nil)

	ch.host = host
	ch.hostHandle = nil
	ch.domainId = 0
	return do_callback(ch, .load_library, .ok)
}

/*
Unload CoreCLR runtime library.
*/
unload_coreclr_library :: proc(ch: ^clr_host) -> error {
	if ch == nil {return .error}
	if ch.host == nil {return do_callback(ch, .unload_library, .host_null)}
	if ch.host.__handle == nil {return do_callback(ch, .unload_library, .host_handle_null)}

	library_handle := ch.host.__handle

	free(ch.host)
	ch.host = nil

	if library_handle != nil {
		if (!dynlib.unload_library(library_handle)) {
			return do_callback(ch, .unload_library, .error)
		}
	}
	return do_callback(ch, .unload_library, .ok)
}

/*
Initialize the CoreCLR. Creates and starts CoreCLR host and creates an app domain
*/
initialize :: proc(ch: ^clr_host, exePath: string, appDomainFriendlyName: string, tpa: string) -> error {
	if ch == nil {return .error}
	if ch.host == nil {return do_callback(ch, .initialize, .host_null)}
	if ch.host.__handle == nil {return do_callback(ch, .initialize, .host_handle_null)}

	propertyCount :: 1
	propertyKeys: [propertyCount]cstring = {"TRUSTED_PLATFORM_ASSEMBLIES"}
	propertyValues: [propertyCount]cstring = {cstring(raw_data(tpa))}

	hr := ch.host.coreclr_initialize(
		cstring(raw_data(exePath)), // App base path
		cstring(raw_data(appDomainFriendlyName)), // AppDomain friendly name
		propertyCount, // Property count
		(^cstring)(&propertyKeys[0]), // Property names
		(^cstring)(&propertyValues[0]), // Property values
		&ch.hostHandle, // Host handle
		&ch.domainId, // AppDomain ID
	)
	do_callback(ch, .initialize, hr)
	return hr
}

/*
Shutdown CoreCLR. It unloads the app domain and stops the CoreCLR host.
*/
shutdown :: proc(ch: ^clr_host) -> error {
	if ch == nil {return .error}
	if ch.host == nil {return do_callback(ch, .shutdown, .host_null)}
	if ch.host.__handle == nil {return do_callback(ch, .shutdown, .host_handle_null)}
	hr := ch.host.coreclr_shutdown(ch.hostHandle, ch.domainId)
	do_callback(ch, .shutdown, hr)
	if hr == .ok {
		ch.hostHandle = nil
		ch.domainId = 0
	}
	return hr
}

/*
Create a native callable function pointer for a managed method.
*/
create_delegate :: proc(
	clrhost: ^clr_host,
	entryPointAssemblyName: cstring,
	entryPointTypeName: cstring,
	entryPointMethodName: cstring,
	delegate: ^$T,
) -> error where intrinsics.type_is_proc(T) {
	delegate_ptr: rawptr
	hr := clrhost.host.coreclr_create_delegate(
		clrhost.hostHandle,
		clrhost.domainId,
		entryPointAssemblyName,
		entryPointTypeName,
		entryPointMethodName,
		&delegate_ptr,
	)
	if hr != .ok {
		delegate_ptr = nil
	}
	delegate^ = (T)(delegate_ptr)
	return hr
}

/*
Execute a managed assembly with given arguments
*/
coreclr_execute_assembly :: proc(
	clrhost: ^clr_host,
	argc: i32,
	argv: ^cstring,
	managedAssemblyPath: cstring,
	exit_code: ^i32,
) -> error {
	return clrhost.host.coreclr_execute_assembly(
		clrhost.hostHandle,
		clrhost.domainId,
		argc,
		argv,
		managedAssemblyPath,
		exit_code,
	)
}
