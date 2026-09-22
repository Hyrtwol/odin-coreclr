/*
Core Common Language Runtime (CLR)

https://github.com/dotnet/runtime/blob/main/src/coreclr
*/
package coreclr

import "base:runtime"
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

get_list_separator :: proc() -> (separator: string, err: runtime.Allocator_Error) {
	return utf8.runes_to_string({os.Path_List_Separator}, context.temp_allocator)
}

asm_scan :: proc(assemblies: ^[dynamic]string, path: string, pattern: string = "*.dll") -> (err: Error) {
	pkg_path := os.get_absolute_path(path, context.temp_allocator) or_return
	path_pattern := os.join_path({pkg_path, pattern}, context.temp_allocator) or_return
	matches := os.glob(path_pattern, context.temp_allocator) or_return
	append_elems(assemblies, ..matches) or_return
	return
}

write_tpa :: proc(tpa_path: string, tpa: string) -> (err: Error) {
	path := os.get_absolute_path(tpa_path, context.temp_allocator) or_return
	fd := os.open(path, os.O_CREATE | os.O_WRONLY) or_return
	defer os.close(fd)
	sep := get_list_separator() or_return
	assemblies := strings.split(tpa, sep, context.temp_allocator) or_return
	for assembly in assemblies {
		os.write_string(fd, assembly) or_return
		os.write_string(fd, "\n") or_return
	}
	return
}

create_trusted_platform_assemblies :: proc(paths: ..string, allocator := context.allocator, loc := #caller_location) -> (tpa: string, err: Error) {
	assemblies := make([dynamic]string, 0, 200, context.temp_allocator) or_return
	for path in paths {
		asm_scan(&assemblies, path) or_return
	}
	return join_list(..assemblies[:], allocator = allocator, loc = loc)
}

join_list :: proc(assemblies: ..string, allocator := context.allocator, loc := #caller_location) -> (res: string, err: runtime.Allocator_Error) {
	list_separator := get_list_separator() or_return
	return strings.join(assemblies[:], list_separator, allocator, loc)
}
