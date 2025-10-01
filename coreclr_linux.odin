#+build linux
package coreclr

import "core:sys/linux"

LIBCORECLR :: "libcoreclr.so"
MAX_PATH :: 1024

get_coreclr_dir :: proc() -> string {
	panic("not implemented")
}
