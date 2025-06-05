# CarMaker CMake Template

This template folder is intended to be a drop-in solution for building CarMaker
extensions using the CMake build system, benefitting from cross compilation
capabilities and MSVC project generation.

## File Structure

- `FindCarMaker.cmake`:  
  Find CarMaker installation and define CarMaker libraries
- `IPG_Macro.cmake`:  
  Macros to build CarMaker executables and libraries, such as `add_carmaker_executable()` or `add_truckmaker_executable()`
- `toolchains`:  
  Toolchain files to pre-define or overwrite variables for e.g. compiler version or host and target systems. Use for cross-compiling or when your system's default compiler is incompatible with your project.
