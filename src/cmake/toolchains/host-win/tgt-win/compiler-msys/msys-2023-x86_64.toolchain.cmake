set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(potential_msys_roots
    # list all possible search paths for MSYS 2023
    "C:/msys-2023"
)

find_path(Msys_x64_bin
    NAMES "gcc.exe" "g++.exe"
    HINTS ${potential_msys_roots}
    PATH_SUFFIXES "mingw/bin"
)

set(CMAKE_C_COMPILER ${Msys_x64_bin}/gcc.exe)
set(CMAKE_CXX_COMPILER ${Msys_x64_bin}/g++.exe)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
