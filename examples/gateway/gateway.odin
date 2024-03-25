package coreclr_example_gateway

// Types from gateway.cs

UnmanagedCallbackDelegate :: #type proc "c" (actionName: cstring, jsonArgs: cstring) -> bool

Gateway :: struct {
	Bootstrap:           #type proc "c" () -> cstring,
	Plus:                #type proc "c" (x: f64, y: f64) -> f64,
	Sum:                 #type proc "c" (x: ^f64, y: f64) -> f64,
	Sum2:                #type proc "c" (x: ^f64, y: f64) -> f64,
	ManagedDirectMethod: #type proc "c" (actionName: cstring, jsonArgs: cstring, unmanagedCallback: UnmanagedCallbackDelegate) -> cstring,
}
