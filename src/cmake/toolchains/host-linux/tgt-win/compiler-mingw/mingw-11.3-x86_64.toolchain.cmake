set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(mingw64-root /opt/gcc-mingw-11.3)
set(tools ${mingw64-root}/bin/x86_64-w64-mingw32)

# cross compilers to use for C, C++ and Fortran
set(CMAKE_C_COMPILER ${tools}-gcc)
set(CMAKE_CXX_COMPILER ${tools}-g++)
set(CMAKE_Fortran_COMPILER ${tools}-gfortran)
set(CMAKE_RC_COMPILER ${tools}-windres)

# modify default behavior of FIND_XXX() commands
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
