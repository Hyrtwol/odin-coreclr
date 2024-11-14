package test_coreclr

import "core:fmt"
import "core:os"
import "core:testing"
import "core:mem"

when ODIN_TEST {
	_ :: fmt
	_ :: os
	_ :: testing
	_ :: mem
} else {
	run :: proc() -> int{
		fmt.println("tracking allocator")
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		context.allocator = mem.tracking_allocator(&track)

		t := testing.T{}

		init_coreclr_lib(&t)
		build_tpa(&t)
		initialize_coreclr_host(&t)
		coreclr_host_create_cb(&t)

		fmt.printfln("errors: %d", t.error_count)

		for _, leak in track.allocation_map {
			fmt.printf("%v leaked %m\n", leak.location, leak.size)
		}
		for bad_free in track.bad_free_array {
			fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
		}
		return t.error_count
	}

	main :: proc() {
		exit_code := run()
		os.exit(exit_code)
	}
}
