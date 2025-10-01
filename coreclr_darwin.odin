#+build darwin
package coreclr

import "core:sys/darwin"

LIBCORECLR :: "libcoreclr.dylib"
MAX_PATH :: 1024

get_coreclr_dir :: proc() -> string {
	panic("not implemented")
}
