package coreclr

hostfxr_delegate_type :: enum {
	hdt_com_activation,
	hdt_load_in_memory_assembly,
	hdt_winrt_activation,
	hdt_com_register,
	hdt_com_unregister,
	hdt_load_assembly_and_get_function_pointer,
	hdt_get_function_pointer,
	hdt_load_assembly,
	hdt_load_assembly_bytes,
}

hostfxr_main_fn :: #type proc(argc: int, argv: ^cstring) -> int32_t

hostfxr_main_startupinfo_fn :: #type proc(
	argc: int,
	argv: ^cstring,
	host_path: cstring,
	dotnet_root: cstring,
	app_path: cstring,
) -> int32_t

hostfxr_main_bundle_startupinfo_fn :: #type proc(
	argc: int,
	argv: ^cstring,
	host_path: cstring,
	dotnet_root: cstring,
	app_path: cstring,
	bundle_header_offset: int64_t,
) -> int32_t

hostfxr_error_writer_fn :: #type proc(message: cstring)

//
// Sets a callback which is to be used to write errors to.
//
// Parameters:
//     error_writer
//         A callback function which will be invoked every time an error is to be reported.
//         Or nullptr to unregister previously registered callback and return to the default behavior.
// Return value:
//     The previously registered callback (which is now unregistered), or nullptr if no previous callback
//     was registered
//
// The error writer is registered per-thread, so the registration is thread-local. On each thread
// only one callback can be registered. Subsequent registrations overwrite the previous ones.
//
// By default no callback is registered in which case the errors are written to stderr.
//
// Each call to the error writer is sort of like writing a single line (the EOL character is omitted).
// Multiple calls to the error writer may occur for one failure.
//
// If the hostfxr invokes functions in hostpolicy as part of its operation, the error writer
// will be propagated to hostpolicy for the duration of the call. This means that errors from
// both hostfxr and hostpolicy will be reporter through the same error writer.
//
hostfxr_set_error_writer_fn :: #type proc(error_writer: hostfxr_error_writer_fn) -> hostfxr_error_writer_fn

hostfxr_handle :: distinct rawptr

hostfxr_initialize_parameters :: struct {
	size:        size_t,
	host_path:   cstring,
	dotnet_root: cstring,
}

//
// Initializes the hosting components for a dotnet command line running an application
//
// Parameters:
//    argc
//      Number of argv arguments
//    argv
//      Command-line arguments for running an application (as if through the dotnet executable).
//      Only command-line arguments which are accepted by runtime installation are supported, SDK/CLI commands are not supported.
//      For example 'app.dll app_argument_1 app_argument_2`.
//    parameters
//      Optional. Additional parameters for initialization
//    host_context_handle
//      On success, this will be populated with an opaque value representing the initialized host context
//
// Return value:
//    Success          - Hosting components were successfully initialized
//    HostInvalidState - Hosting components are already initialized
//
// This function parses the specified command-line arguments to determine the application to run. It will
// then find the corresponding .runtimeconfig.json and .deps.json with which to resolve frameworks and
// dependencies and prepare everything needed to load the runtime.
//
// This function only supports arguments for running an application. It does not support SDK commands.
//
// This function does not load the runtime.
//
hostfxr_initialize_for_dotnet_command_line_fn :: #type proc(
	argc: int,
	argv: ^cstring,
	parameters: ^hostfxr_initialize_parameters,
	host_context_handle: ^hostfxr_handle,
) -> int32_t

//
// Initializes the hosting components using a .runtimeconfig.json file
//
// Parameters:
//    runtime_config_path
//      Path to the .runtimeconfig.json file
//    parameters
//      Optional. Additional parameters for initialization
//    host_context_handle
//      On success, this will be populated with an opaque value representing the initialized host context
//
// Return value:
//    Success                            - Hosting components were successfully initialized
//    Success_HostAlreadyInitialized     - Config is compatible with already initialized hosting components
//    Success_DifferentRuntimeProperties - Config has runtime properties that differ from already initialized hosting components
//    CoreHostIncompatibleConfig         - Config is incompatible with already initialized hosting components
//
// This function will process the .runtimeconfig.json to resolve frameworks and prepare everything needed
// to load the runtime. It will only process the .deps.json from frameworks (not any app/component that
// may be next to the .runtimeconfig.json).
//
// This function does not load the runtime.
//
// If called when the runtime has already been loaded, this function will check if the specified runtime
// config is compatible with the existing runtime.
//
// Both Success_HostAlreadyInitialized and Success_DifferentRuntimeProperties codes are considered successful
// initializations. In the case of Success_DifferentRuntimeProperties, it is left to the consumer to verify that
// the difference in properties is acceptable.
//
hostfxr_initialize_for_runtime_config_fn :: #type proc(
	runtime_config_path: cstring,
	parameters: ^hostfxr_initialize_parameters,
	host_context_handle: ^hostfxr_handle,
) -> int32_t

//
// Gets the runtime property value for an initialized host context
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//     name
//       Runtime property name
//     value
//       Out parameter. Pointer to a buffer with the property value.
//
// Return value:
//     The error code result.
//
// The buffer pointed to by value is owned by the host context. The lifetime of the buffer is only
// guaranteed until any of the below occur:
//   - a 'run' method is called for the host context
//   - properties are changed via hostfxr_set_runtime_property_value
//   - the host context is closed via 'hostfxr_close'
//
// If host_context_handle is nullptr and an active host context exists, this function will get the
// property value for the active host context.
//
hostfxr_get_runtime_property_value_fn :: #type proc(
	host_context_handle: hostfxr_handle,
	name: cstring,
	value: ^cstring,
) -> int32_t

//
// Sets the value of a runtime property for an initialized host context
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//     name
//       Runtime property name
//     value
//       Value to set
//
// Return value:
//     The error code result.
//
// Setting properties is only supported for the first host context, before the runtime has been loaded.
//
// If the property already exists in the host context, it will be overwritten. If value is nullptr, the
// property will be removed.
//
hostfxr_set_runtime_property_value_fn :: #type proc(
	host_context_handle: hostfxr_handle,
	name: cstring,
	value: cstring,
) -> int32_t

//
// Gets all the runtime properties for an initialized host context
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//     count
//       [in] Size of the keys and values buffers
//       [out] Number of properties returned (size of keys/values buffers used). If the input value is too
//             small or keys/values is nullptr, this is populated with the number of available properties
//     keys
//       Array of pointers to buffers with runtime property keys
//     values
//       Array of pointers to buffers with runtime property values
//
// Return value:
//     The error code result.
//
// The buffers pointed to by keys and values are owned by the host context. The lifetime of the buffers is only
// guaranteed until any of the below occur:
//   - a 'run' method is called for the host context
//   - properties are changed via hostfxr_set_runtime_property_value
//   - the host context is closed via 'hostfxr_close'
//
// If host_context_handle is nullptr and an active host context exists, this function will get the
// properties for the active host context.
//
hostfxr_get_runtime_properties_fn :: #type proc(
	host_context_handle: hostfxr_handle,
	count: ^size_t,
	keys: ^cstring,
	values: ^cstring,
) -> int32_t

//
// Load CoreCLR and run the application for an initialized host context
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//
// Return value:
//     If the app was successfully run, the exit code of the application. Otherwise, the error code result.
//
// The host_context_handle must have been initialized using hostfxr_initialize_for_dotnet_command_line.
//
// This function will not return until the managed application exits.
//
hostfxr_run_app_fn :: #type proc(host_context_handle: hostfxr_handle) -> int32_t

//
// Gets a typed delegate from the currently loaded CoreCLR or from a newly created one.
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//     type
//       Type of runtime delegate requested
//     delegate
//       An out parameter that will be assigned the delegate.
//
// Return value:
//     The error code result.
//
// If the host_context_handle was initialized using hostfxr_initialize_for_runtime_config,
// then all delegate types are supported.
// If the host_context_handle was initialized using hostfxr_initialize_for_dotnet_command_line,
// then only the following delegate types are currently supported:
//     hdt_load_assembly_and_get_function_pointer
//     hdt_get_function_pointer
//
hostfxr_get_runtime_delegate_fn :: #type proc(
	host_context_handle: hostfxr_handle,
	type: hostfxr_delegate_type,
	delegate: ^rawptr,
) -> int32_t

//
// Closes an initialized host context
//
// Parameters:
//     host_context_handle
//       Handle to the initialized host context
//
// Return value:
//     The error code result.
//
hostfxr_close_fn :: #type proc(host_context_handle: hostfxr_handle) -> int32_t

hostfxr_dotnet_environment_sdk_info :: struct {
	size:    size_t,
	version: cstring,
	path:    cstring,
}

hostfxr_get_dotnet_environment_info_result_fn :: #type proc(
	info: ^hostfxr_dotnet_environment_info,
	result_context: rawptr
) -> int32_t

hostfxr_dotnet_environment_framework_info :: struct {
	size:    size_t,
	name:    cstring,
	version: cstring,
	path:    cstring,
}

hostfxr_dotnet_environment_info :: struct {
	size:                size_t,
	hostfxr_version:     cstring,
	hostfxr_commit_hash: cstring,
	sdk_count:           size_t,
	sdks:                ^hostfxr_dotnet_environment_sdk_info,
	framework_count:     size_t,
	frameworks:          ^hostfxr_dotnet_environment_framework_info,
}

//
// Returns available SDKs and frameworks.
//
// Resolves the existing SDKs and frameworks from a dotnet root directory (if
// any), or the global default location. If multi-level lookup is enabled and
// the dotnet root location is different than the global location, the SDKs and
// frameworks will be enumerated from both locations.
//
// The SDKs are sorted in ascending order by version, multi-level lookup
// locations are put before private ones.
//
// The frameworks are sorted in ascending order by name followed by version,
// multi-level lookup locations are put before private ones.
//
// Parameters:
//    dotnet_root
//      The path to a directory containing a dotnet executable.
//
//    reserved
//      Reserved for future parameters.
//
//    result
//      Callback invoke to return the list of SDKs and frameworks.
//      Structs and their elements are valid for the duration of the call.
//
//    result_context
//      Additional context passed to the result callback.
//
// Return value:
//   0 on success, otherwise failure.
//
// String encoding:
//   Windows     - UTF-16 (pal::char_t is 2 byte wchar_t)
//   Unix        - UTF-8  (pal::char_t is 1 byte char)
//
hostfxr_get_dotnet_environment_info_fn :: #type proc(
	dotnet_root: cstring,
	reserved: rawptr,
	result: hostfxr_get_dotnet_environment_info_result_fn,
	result_context: rawptr
) -> int32_t
