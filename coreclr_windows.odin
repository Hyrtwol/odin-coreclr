#+build windows
package coreclr

import win32 "core:sys/windows"

import "core:path/filepath"

LIBCORECLR :: "coreclr.dll"
MAX_PATH :: win32.MAX_PATH

CORECLR_DIR :: "C:\\Program Files\\dotnet\\shared\\Microsoft.NETCore.App\\9.0.8"

get_coreclr_dir :: proc() -> string {
	matches := filepath.glob("C:\\Program Files\\dotnet\\shared\\Microsoft.NETCore.App\\*", context.temp_allocator) or_else panic("filepath.glob")
	//coreclr_dir = clr.CORECLR_DIR
	return matches[len(matches)-1]
}
