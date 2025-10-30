package obug

import "core:terminal/ansi"
import "core:fmt"
import "core:mem"

Color :: enum {
	BLACK   = 0,
	RED     = 1,
	GREEN   = 2,
	YELLOW  = 3,
	BLUE    = 4,
	MAGENTA = 5,
	CYAN    = 6,
	WHITE   = 7,
	DEFAULT = 9,
}

NO_LEAKS_COLOR: [2]Color : {.BLUE, .WHITE}
LEAKS_COLOR: [2]Color : {.RED, .WHITE}
LEAK_COLOR: [2]Color : {.DEFAULT, .YELLOW}

reset_color :: proc() {
	fmt.print(ansi.CSI + ansi.RESET + ansi.SGR)
}

set_color :: proc(bf: [2]Color) {
	fmt.printf(ansi.CSI + "4%d;3%d" + ansi.SGR, bf[0], bf[1])
}

print_color :: proc(bf: [2]Color, args: ..any) {
	set_color(bf)
	fmt.print(args = args)
	reset_color()
}

printf_color :: proc(bf: [2]Color, format: string, args: ..any) {
	set_color(bf)
	fmt.printf(format, args = args)
	reset_color()
}

@(private = "file")
print_leaks :: proc(track: ^mem.Tracking_Allocator) -> int {
	errors := len(track.allocation_map) + len(track.bad_free_array)
	if errors > 0 {
		print_color(LEAKS_COLOR, " -= leaks detected =- ")
		fmt.println(" \U0001F4A6")

		for _, leak in track.allocation_map {
			printf_color(LEAK_COLOR, "%v leaked %m", leak.location, leak.size)
		}
		for bad_free in track.bad_free_array {
			printf_color(LEAK_COLOR, "%v allocation %p was freed badly", bad_free.location, bad_free.memory)
		}
	} else {
		print_color(NO_LEAKS_COLOR, " -= no leaks =- ")
		fmt.println(" \U0001F37B")
	}
	return errors
}

tracked_run :: proc(run: #type proc() -> int) -> int {
	print_color(NO_LEAKS_COLOR, " -= using tracking allocator =- ")
	fmt.println(" \U0001F50D")

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	exit_code := run()
	errors := print_leaks(&track)
	return exit_code == 0 ? errors : exit_code
}
