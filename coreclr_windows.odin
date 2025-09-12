#+build windows
package coreclr

import win32 "core:sys/windows"

LIBCORECLR :: "coreclr.dll"
MAX_PATH :: win32.MAX_PATH

CORECLR_DIR :: "C:\\Program Files\\dotnet\\shared\\Microsoft.NETCore.App\\9.0.8"
