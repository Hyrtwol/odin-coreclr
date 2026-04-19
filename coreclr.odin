/*
Core Common Language Runtime (CLR)

https://github.com/dotnet/runtime/blob/main/src/coreclr
*/
package coreclr

import _c "core:c"
import "core:os"
import "core:strings"
import "core:unicode/utf8"

char_t :: _c.wchar_t
size_t :: _c.size_t
int32_t :: _c.int32_t
int64_t :: _c.int64_t

/*
Odin utils
*/

get_list_separator :: proc() -> string {
	return utf8.runes_to_string({os.Path_List_Separator}, context.temp_allocator)
}

asm_scan :: proc(totmatches: ^[dynamic]string, path: string, pattern: string = "*.dll") {
	pkg_path, erra := os.get_absolute_path(path, context.temp_allocator)
	if erra != os.General_Error.None {return}

	path_pattern, errj := os.join_path({pkg_path, pattern}, context.temp_allocator)
	if errj != .None {return}

	matches, errg := os.glob(path_pattern, context.temp_allocator)
	if errg != os.General_Error.None {return}
	append_elems(totmatches, ..matches)
}

write_tpa :: proc(tpa_path: string, tpa: string) {
	path, erra := os.get_absolute_path(tpa_path, context.temp_allocator)
	if erra != os.ERROR_NONE {return}
	fd, err := os.open(path, os.O_CREATE | os.O_WRONLY)
	if err != os.ERROR_NONE {return}
	defer os.close(fd)

	sep := get_list_separator()
	assemblies, err2 := strings.split(tpa, sep, context.temp_allocator)
	if err2 == .None {
		for assembly in assemblies {
			os.write_string(fd, assembly)
			os.write_string(fd, "\n")
		}
	}
}

create_trusted_platform_assemblies :: proc(paths: ..string, allocator := context.allocator, loc := #caller_location) -> string {
	assemblies := make([dynamic]string, 0, 200, context.temp_allocator)
	for path in paths {
		asm_scan(&assemblies, path)
	}
	return join_list(..assemblies[:], allocator = allocator, loc = loc)
}

join_list :: proc(assemblies: ..string, allocator := context.allocator, loc := #caller_location) -> string {
	return strings.join(assemblies[:], get_list_separator(), allocator, loc)
}
