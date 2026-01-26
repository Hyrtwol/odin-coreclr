package coreclr_example_gateway

// Types from gateway.cs

UnmanagedCallbackDelegate :: #type proc "c" (actionName: cstring, jsonArgs: cstring) -> bool

SizeOf :: struct {
	Int, Double, Float, Pointer: i32,
}

Gateway :: struct {
	AssemblyLocation:    #type proc "c" () -> cstring,
	SizeOfStuff:         #type proc "c" (sof: ^SizeOf),
	Plus:                #type proc "c" (x: f64, y: f64) -> f64,
	Sum:                 #type proc "c" (x: ^f64, n: i32) -> f64,
	ManagedDirectMethod: #type proc "c" (actionName: cstring, jsonArgs: cstring, unmanagedCallback: UnmanagedCallbackDelegate) -> cstring,
}
