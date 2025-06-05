set(XENO TRUE CACHE STRING "True if compiling for Xeno" FORCE)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(potential_msys_roots
    # list all possible search paths for MSYS 2020
    "C:/msys-2020"
)

find_path(Msys_x64_bin
    NAMES "linux-gcc.exe" "linux-g++.exe"
    HINTS ${potential_msys_roots}
    PATH_SUFFIXES "x86_64-linux/bin"
)

set(CMAKE_C_COMPILER ${Msys_x64_bin}/linux-gcc.exe)
set(CMAKE_CXX_COMPILER ${Msys_x64_bin}/linux-g++.exe)

set(CMAKE_C_FLAGS -m64)
set(CMAKE_CXX_FLAGS -m64)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
