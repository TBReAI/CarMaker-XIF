set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(gcc-root /opt/gcc-5.4)
set(tools ${gcc-root}/bin)

set(CMAKE_C_COMPILER ${tools}/gcc-5.4)
set(CMAKE_CXX_COMPILER ${tools}/g++-5.4)

set(CMAKE_C_FLAGS -m64)
set(CMAKE_CXX_FLAGS -m64)
