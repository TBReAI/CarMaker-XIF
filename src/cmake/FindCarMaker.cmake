cmake_minimum_required(VERSION 3.11)
# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.
#
#.rst:
# FindCarMaker
# -------
# Finds CarMaker libraries and includes, to build allow the easy building of
# custom, extended CarMaker artifacts.
#
# This file should be able to find any CarMaker inside IPG Karlsruhes network.

#### UNUSUAL BUILD ENVIRONMENTS ####
# If your IPG software installations are in an unusual spot, set the IPG_ROOT
# variable accordingly, and this script will attempt to find the correct
# sotfware/version from there.
###################################
#
# This will define the following variables::
#
#   CarMaker_FOUND    - True if the system has located CarMaker install.
#   CarMaker_VERSION  - The version of the CarMaker install found.
#
# The following legacy variables, which should be avoided and targets used instead.
#   CarMaker_INCLUDE_DIRS   - The CarMaker main include dir.
#   CarMaker_DEFINITIONS    - Defines needed to compile CarMaker.
#   CarMaker_LIBRARIES      - All the libraries CarMaker ships with.
#
# and the following imported targets::
#
#   CarMaker::Core              - The CarMaker Core libraries and headers.
#   CarMaker::Car               - Everything required to build an extended CarMaker, will
#                                      also pull in Core.
#   CarMaker::Mcycle            - Everything required to build an extended MotorcycleMaker, will
#                                      also pull in Core.
#   CarMaker::Truck             - Everything required to build an extended Truckmaker, will
#                                       also pull in Core.
#   CarMaker::Infofile          - Infofile library and headers only.
#   CarMaker::Apoclient         - Apo client library and headers only.
#   CarMaker::Roadbuilder       - Roadbuilder library and headers only.
#   CarMaker::MatlabSupport     - If Matlab was also found on this system,
#                                       everything needed to compile cm4sl
#
# This file supplies the following macros:
#   add_carmaker_executable(NAME SRCS):
#       Input:
#           NAME - The Name of the new target.
#           SRCS - A list of sources to compile into the executable.
#       Effect:
#           Creates a Cmake Target with all required settings to compile a CarMaker executable
#
#   add_truckmaker_executable(NAME SRCS):
#       Input:
#           NAME - The Name of the new target.
#           SRCS - A list of sources to compile into the executable.
#       Effect:
#           Creates a Cmake Target with all required settings to compile a Truckmaker executable
#
#   add_mcycle_executable(NAME SRCS):
#       Input:
#           NAME - The Name of the new target.
#           SRCS - A list of sources to compile into the executable.
#       Effect:
#           Creates a Cmake Target with all required settings to compile a MotorcycleMaker
#           execurable.
#
#   add_cm4sl_target(SRCS)
#       Input:
#           SRCS - A list of sources to compile into the executable.
#       Effect:
#           Create a Cmake target name libcarmaker4sl from the given sources. The fixed name is
#           required since Simulink looks it up. You can therefore ONLY HAVE ONE cm4sl target in a
#           cmake source tree.
#           Also note that this target copies the created simulink lib into its source folder. This
#           is also required for Simulink to find it.

## set apo client lib name depending on target platform
set(ipghome_env $ENV{IPGHOME})
if(ipghome_env)
    message(STATUS "Found IPGHOME env variable set as: ${ipghome_env}. Using it in search")
else()
    message(WARNING "IPGHOME env variable is unset.")
endif()


if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    # 64 bits
    set(IS_64BIT TRUE)
elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
    # 32 bits
    set(IS_64BIT FALSE)
endif()


if(UNIX)
    set(Arch "linux64")
    set(CarMaker_folder_arch "linux64")

    set(CarMaker_install_base_list
        "${ipghome_env}"
        "${IPG_ROOT}"
        "/opt/ipg"
        "/opt/IPG"
    )
endif()

if(WIN32)
    set(Arch "win64")
    set(CarMaker_folder_arch "win64")

    set(CarMaker_install_base_list
        "${ipghome_env}"
        "${IPG_ROOT}"
        "C:/IPG"
    )
endif()

set(CarMaker_lib_subfolder "lib")
set(CarMaker_zlib_lib "z-${Arch}")
set(CarMaker_apo-client_lib "apo-client-${Arch}")

if(XENO)
    set(Arch "xeno")
    if(CMAKE_HOST_WIN32)
        set(CarMaker_folder_arch "win64")
    endif()
    set(CarMaker_lib_subfolder "lib-${Arch}")
    set(CarMaker_zlib_lib "z-${Arch}")
    set(CarMaker_apo-client_lib "apo-client-linux64")
endif()

if(CarMaker_FIND_VERSION)
    message(STATUS "CarMaker version requested: ${CarMaker_FIND_VERSION}. Looking in common directories.")

    # version is specified, try lookup in common locations
    set(CARMAKER_INSTALL_DIR_rel carmaker/${CarMaker_folder_arch}-${CarMaker_FIND_VERSION})
    message(STATUS "Looking for include/CarMaker.h in the following dirs, sorted by priority: ${CarMaker_install_base_list}. Recursing into folders named ${CARMAKER_INSTALL_DIR_rel}.")
    find_path(CARMAKER_INSTALL_DIR
        NAMES "include/CarMaker.h"
        HINTS ${CarMaker_install_base_list}
        PATH_SUFFIXES "${CARMAKER_INSTALL_DIR_rel}"
    )
    message(STATUS "Found CarMaker in: ${CARMAKER_INSTALL_DIR}")
else()
    # no version specified, grab the folder from a cache variable and determine
    # version from that.
    message(WARNING "No CarMaker version to search specified. You will need to set CARMAKER_INSTALL_DIR manually.")
    if(NOT CARMAKER_INSTALL_DIR)
        set(CARMAKER_INSTALL_DIR "dir_NOTFOUND" CACHE PATH
        "The CarMaker folder where includes and libs are aquired from")

        message(FATAL_ERROR "Neither CarMaker version nor CMake cache variable CARMAKER_INSTALL_DIR set.\
        Can not find CarMaker install. Set CARMAKER_INSTALL_DIR to the required CarMaker install directory.\
        The folder is named <platform>-<version>")
    else()
        if(NOT EXISTS ${CARMAKER_INSTALL_DIR})
            message(FATAL_ERROR "Error finding CarMaker, folder given via cmake variable CARMAKER_INSTALL_DIR\
            \"${CARMAKER_INSTALL_DIR}\" does not exist.")
        endif() # CARMAKER_INSTALL_DIR is now set
    endif() # end special case to init the cached variable
endif() # after all this, CARMAKER_INSTALL_DIR should be set, as well as all version vars

if(EXISTS ${CARMAKER_INSTALL_DIR})
    string(REGEX MATCH "([0-9]+)\\.([0-9]+)\\.?([0-9]?)"
    cm_version_parsed ${CARMAKER_INSTALL_DIR})

    if(CMAKE_MATCH_COUNT LESS 2)
        message(AUTHOR_WARNING "Could not parse version of CM correctly!")
    endif()

    set(CarMaker_VERSION_MAJOR ${CMAKE_MATCH_1})
    set(CarMaker_VERSION_MINOR  ${CMAKE_MATCH_2})
    set(CarMaker_VERSION ${CarMaker_VERSION_MAJOR}.${CarMaker_VERSION_MINOR})
    math(EXPR CM_VERNUM "${CarMaker_VERSION_MAJOR} * 10000 + ${CarMaker_VERSION_MINOR} * 100")

    if(CMAKE_MATCH_COUNT EQUAL 3)
        set(CarMaker_VERSION_PATCH ${CMAKE_MATCH_3})
        set(CarMaker_VERSION ${CarMaker_VERSION_MAJOR}.${CarMaker_VERSION_MINOR}.${CarMaker_VERSION_PATCH})
        math(EXPR CM_VERNUM "${CM_VERNUM} + ${CarMaker_VERSION_PATCH}")
    endif() # end regex parsing

    message(STATUS "CM Version determined to be ${CarMaker_VERSION}")
    set(CarMaker_Include_DIR ${CARMAKER_INSTALL_DIR}/include)
    set(CarMaker_Library_DIR ${CARMAKER_INSTALL_DIR}/${CarMaker_lib_subfolder})

    if (XENO)
        list(APPEND CarMaker_Include_DIR
            ${CARMAKER_INSTALL_DIR}/include/cobalt
            ${CARMAKER_INSTALL_DIR}/include/alchemy
        )
    endif()

else()
    message(AUTHOR_WARNING "CARMAKER_INSTALL_DIR determined to be ${CARMAKER_INSTALL_DIR}, but folder does not exist.")
endif()

    message(STATUS "CarMaker_Library_DIR: ${CarMaker_Library_DIR}")
    message(STATUS "CarMaker_Include_DIR ${CarMaker_Include_DIR}")
    message(STATUS "CarMaker_VERSION: ${CarMaker_VERSION}")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(CarMaker
    FOUND_VAR CarMaker_FOUND
    REQUIRED_VARS
    CarMaker_Library_DIR
    CarMaker_Include_DIR
    VERSION_VAR CarMaker_VERSION
)

if(CarMaker_FOUND)

    if(${CMAKE_GENERATOR} MATCHES "Visual Studio" OR ${CMAKE_GENERATOR} MATCHES "NMake")

        list(APPEND cm_msvc_compatibility
            ${CarMaker_Library_DIR}/libcompat_${Arch}.a
            legacy_stdio_definitions
        )
    endif()

    if (${CarMaker_VERSION} VERSION_GREATER_EQUAL "11.0")
        set(CarMaker_uriparser_lib "uriparser")
    elseif (${CarMaker_VERSION} VERSION_GREATER_EQUAL "10.1")
        set(CarMaker_uriparser_lib "uriparser-${Arch}")
    endif()

    list(APPEND cm_core_libraries
        ${CarMaker_Library_DIR}/libipgdriver.a
        ${CarMaker_Library_DIR}/libipgroad.a
        ${CarMaker_Library_DIR}/libipgtire.a
        ${CarMaker_Library_DIR}/lib${CarMaker_zlib_lib}.a
        $<$<VERSION_GREATER_EQUAL:${CarMaker_VERSION},10.1>:${CarMaker_Library_DIR}/lib${CarMaker_uriparser_lib}.a>
    )

# append system-specific os libs
    if(UNIX)
        if (${CarMaker_VERSION} VERSION_GREATER_EQUAL "10.2.3")
            set(CarMaker_usb_lib usb-1.0)
        elseif (${CarMaker_VERSION} VERSION_GREATER_EQUAL "10.2")
            set(CarMaker_usb_lib ${CarMaker_Library_DIR}/libusb-loader.a)
        elseif (${CarMaker_VERSION} VERSION_GREATER_EQUAL "10.0")
            set(CarMaker_usb_lib usb)
            if (XENO)
                set(CarMaker_usb_lib ${CarMaker_Library_DIR}/libusb.so)
            endif()
        elseif (${CarMaker_VERSION} VERSION_GREATER_EQUAL "9.1.3")
            set(CarMaker_usb_lib ${CarMaker_Library_DIR}/libusb-loader.a)
        else()
            set(CarMaker_usb_lib usb)
            if (XENO)
                set(CarMaker_usb_lib ${CarMaker_Library_DIR}/libusb.so)
            endif()
        endif()
        list(APPEND cm_core_os_libraries
            pthread
            dl
            ${CarMaker_usb_lib}
            m
            rt
        )
        if(XENO)
            link_directories(${CarMaker_Library_DIR})
            list(APPEND cm_core_os_libraries
                alchemy
                copperplate
                cobalt
                $<$<VERSION_GREATER_EQUAL:${CarMaker_VERSION},10.1>:modechk>
            )
        endif()
    endif()


    if(WIN32)
        if (MSVC)
            list(APPEND cm_core_os_libraries
                ws2_32.lib
                winspool
            )
        else()
            list(APPEND cm_core_os_libraries
                -lws2_32
                -lpsapi
                -lwinspool
                $<$<VERSION_GREATER_EQUAL:${CarMaker_VERSION},13.0>:-lwinmm>
                $<$<VERSION_GREATER_EQUAL:${CarMaker_VERSION},13.0>:-lavrt>
            )
        endif()
    endif()

    list(APPEND cm_car_libraries
        ${CarMaker_Library_DIR}/libcar.a
    )

    list(APPEND cm_mcycle_libraries
        ${CarMaker_Library_DIR}/libmcycle.a
    )

    list(APPEND cm_truck_libraries
        ${CarMaker_Library_DIR}/libtruck.a
    )


    if(UNIX)
        list(APPEND cm_core_definitions
            LINUX
            LINUX64
            _GNU_SOURCE
            _FILE_OFFSET_BITS=64
            CM_NUMVER=${CM_VERNUM}
        )
    endif()
    if(XENO)
        list(APPEND cm_core_definitions
            XENO
            XENO64
            CM_HIL
            _REENTRANT
            __COBALT__
        )
    endif()
    if(WIN32)
        if(NOT MSVC)
            list(APPEND cm_core_definitions
                __USE_MINGW_ANSI_STDIO
                $<$<VERSION_GREATER_EQUAL:${CarMaker_VERSION},12.0>:UNICODE>
            )
        endif()
        list(APPEND cm_core_definitions
            WIN32
            $<$<BOOL:IS_64BIT>:WIN64>
            CM_NUMVER=${CM_VERNUM}
        )
    endif()

    # define cmake legacy variables
    set(CarMaker_INCLUDE_DIRS ${CarMaker_Include_DIR})
    set(CarMaker_LIBRARIES
        ${cm_msvc_compatibility}
        ${cm_core_os_libraries}
        ${cm_core_libraries}
        ${CarMaker_Library_DIR}/libcarmaker.a
        ${cm_car_libraries}
        ${cm_mcycle_libraries}
        ${cm_truck_libraries}
    )
    set(CarMaker_DEFINITIONS ${cm_core_definitions})

    if(NOT TARGET CarMaker::compat_arch)
        add_library(CarMaker::compat_arch STATIC IMPORTED)
        set_target_properties(CarMaker::compat_arch PROPERTIES
            IMPORTED_LOCATION ${CarMaker_Library_DIR}/libcompat_${Arch}.a
        )
    endif()

    if(NOT TARGET CarMaker::Core)
        add_library(CarMaker::Core STATIC IMPORTED GLOBAL)
        set_target_properties(CarMaker::Core PROPERTIES
            IMPORTED_LOCATION ${CarMaker_Library_DIR}/libcarmaker.a
            INTERFACE_INCLUDE_DIRECTORIES ${CarMaker_Include_DIR}
    )

    foreach(definition IN ITEMS ${cm_core_definitions})
        set_property(TARGET CarMaker::Core APPEND
            PROPERTY INTERFACE_COMPILE_DEFINITIONS ${definition})
    endforeach()

    target_link_libraries(CarMaker::Core
        INTERFACE
            ${cm_core_os_libraries}
            ${cm_core_libraries}
    )
    endif()

    if(NOT TARGET CarMaker::Car)
        add_library(CarMaker::Car STATIC IMPORTED GLOBAL)
        set_target_properties(CarMaker::Car PROPERTIES
            IMPORTED_LOCATION ${cm_car_libraries}
            INTERFACE_INCLUDE_DIRECTORIES ${CarMaker_Include_DIR}
    )
    target_link_libraries(CarMaker::Car
        INTERFACE
            CarMaker::Core
    )
    endif()

    if(NOT TARGET CarMaker::Mcycle)
        add_library(CarMaker::Mcycle STATIC IMPORTED GLOBAL)
        set_target_properties(CarMaker::Mcycle PROPERTIES
            IMPORTED_LOCATION ${cm_mcycle_libraries}
            INTERFACE_INCLUDE_DIRECTORIES ${CarMaker_Include_DIR}
    )
    target_link_libraries(CarMaker::Mcycle
        INTERFACE
            CarMaker::Core
    )
    endif()

    if(NOT TARGET CarMaker::Truck)
        add_library(CarMaker::Truck STATIC IMPORTED GLOBAL)
        set_target_properties(CarMaker::Truck PROPERTIES
            IMPORTED_LOCATION ${cm_truck_libraries}
            INTERFACE_INCLUDE_DIRECTORIES ${CarMaker_Include_DIR}
    )
    target_link_libraries(CarMaker::Truck
        INTERFACE
            CarMaker::Core
    )
    endif()

    if(NOT TARGET CarMaker::Infofile)
        add_library(CarMaker::Infofile STATIC IMPORTED GLOBAL)
        set_target_properties(CarMaker::Infofile PROPERTIES
            IMPORTED_LOCATION ${CarMaker_Library_DIR}/libinfofile.a
            INTERFACE_INCLUDE_DIRECTORIES ${CarMaker_Include_DIR}
    )
    target_link_libraries(CarMaker::Infofile
        INTERFACE
            $<$<C_COMPILER_ID:MSVC>:CarMaker::compat_arch>
            $<$<C_COMPILER_ID:MSVC>:legacy_stdio_definitions>
    )
    endif()

    if(NOT TARGET CarMaker::Apoclient)
        add_library(CarMaker::Apoclient STATIC IMPORTED GLOBAL)
        set_target_properties(CarMaker::Apoclient PROPERTIES
            IMPORTED_LOCATION ${CARMAKER_INSTALL_DIR}/lib/lib${CarMaker_apo-client_lib}.a
            INTERFACE_INCLUDE_DIRECTORIES ${CarMaker_Include_DIR}
    )
    target_link_libraries(CarMaker::Apoclient
        INTERFACE
            ${CarMaker_Library_DIR}/libcarmaker.a
            ${CarMaker_Library_DIR}/lib${CarMaker_zlib_lib}.a
            $<$<C_COMPILER_ID:MSVC>:CarMaker::compat_arch>
            $<$<C_COMPILER_ID:MSVC>:legacy_stdio_definitions>
            ${cm_core_os_libraries}
    )
    endif()

    if(NOT TARGET CarMaker::Roadbuilder)
        add_library(CarMaker::Roadbuilder STATIC IMPORTED GLOBAL)
        if (${CarMaker_VERSION} VERSION_LESS 11.0)
            set_target_properties(CarMaker::Roadbuilder PROPERTIES
                IMPORTED_LOCATION ${CarMaker_Library_DIR}/libipgroadbuilder.a
                INTERFACE_INCLUDE_DIRECTORIES ${CarMaker_Include_DIR}
            )
            target_link_libraries(CarMaker::Roadbuilder
                INTERFACE
                    ${CarMaker_Library_DIR}/libcarmaker.a
                    $<$<C_COMPILER_ID:MSVC>:CarMaker::compat_arch>
                    $<$<C_COMPILER_ID:MSVC>:legacy_stdio_definitions>
                    ${cm_core_os_libraries}
            )
        else()
            set_target_properties(CarMaker::Roadbuilder PROPERTIES
                IMPORTED_LOCATION ${CarMaker_Library_DIR}/libipgroad.a
                INTERFACE_INCLUDE_DIRECTORIES ${CarMaker_Include_DIR}
            )
            target_link_libraries(CarMaker::Roadbuilder
                INTERFACE
                    CarMaker::Infofile
                    ${CarMaker_Library_DIR}/libcarmaker.a
                    ${CarMaker_Library_DIR}/lib${CarMaker_zlib_lib}.a
                    $<$<C_COMPILER_ID:MSVC>:CarMaker::compat_arch>
                    $<$<C_COMPILER_ID:MSVC>:legacy_stdio_definitions>
                    ${cm_core_os_libraries}
            )
        endif()

    endif()

    if(NOT TARGET CarMaker::MatlabSupport)
        add_library(CarMaker::MatlabSupport STATIC IMPORTED GLOBAL)
        set(CM4SL_support_dir ${CARMAKER_INSTALL_DIR}/CM4SL/${Matlab_requested})
        set_target_properties(CarMaker::MatlabSupport PROPERTIES
            IMPORTED_LOCATION ${CM4SL_support_dir}/libsupp4sl-${Arch}.a
            INTERFACE_INCLUDE_DIRECTORIES ${CarMaker_Include_DIR}
        )

        list(APPEND cm4sl_core_libs
            ${CarMaker_Library_DIR}/libcar4sl.a
            ${CarMaker_Library_DIR}/libcarmaker4sl.a
            ${CarMaker_Library_DIR}/libipgdriver.a
            ${CarMaker_Library_DIR}/libipgroad.a
            ${CarMaker_Library_DIR}/libipgtire.a
            ${CarMaker_Library_DIR}/lib${CarMaker_zlib_lib}.a
            $<$<VERSION_GREATER_EQUAL:${CarMaker_VERSION},10.1>:${CarMaker_Library_DIR}/lib${CarMaker_uriparser_lib}.a>
        )

        set(Matlab_support_dir ${CARMAKER_INSTALL_DIR}/Matlab/${Matlab_requested})

        target_include_directories(CarMaker::MatlabSupport
            INTERFACE
                ${CarMaker_Include_DIR}
                ${CARMAKER_INSTALL_DIR}/Matlab/${Matlab_requested}
        )

        target_link_libraries(CarMaker::MatlabSupport
            INTERFACE
                ${cm4sl_core_libs}
                ${cm_core_os_libraries}
                ${Matlab_support_dir}/libmatsupp-${Arch}.a
        )

        if(WIN32)
            target_link_libraries(CarMaker::MatlabSupport
                INTERFACE
                    $<$<VERSION_GREATER_EQUAL:${CarMaker_VERSION},13.0>:${CM4SL_support_dir}/mingw64/libfixedpoint.lib>
                    ${CM4SL_support_dir}/mingw64/libmat.lib
                    ${CM4SL_support_dir}/mingw64/libmx.lib
                    ${CM4SL_support_dir}/mingw64/libmex.lib
                )
        endif()
        if(MINGW)
            target_link_libraries(CarMaker::MatlabSupport
                INTERFACE
                    ${CM4SL_support_dir}/mingw64/fixup.o
            )
        endif()
        if(UNIX)
            target_link_libraries(CarMaker::MatlabSupport
                INTERFACE
                    $<$<VERSION_GREATER_EQUAL:${CarMaker_VERSION},13.0>:-lfixedpoint>
                    ${Matlab_MAT_LIBRARY}
                    ${Matlab_MEX_LIBRARY}
                    ${Matlab_MX_LIBRARY}
        )
        endif()

        target_compile_definitions(CarMaker::MatlabSupport
            INTERFACE
                ${cm_core_definitions}
                CM4SL
        )

    endif()
    include(${CMAKE_CURRENT_LIST_DIR}/IPG_Macros.cmake)
endif()
