# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#.rst:
# FindRTMaker
# -------

# Finds RTMaker libraries and includes, to build allow the easy building of
# custom, extended RTMaker artifacts.
#
# This file should be able to find any RTMaker inside IPG Karlsruhes network.
#
#### UNUSUAL BUILD ENVIRONMENTS ####
# If your IPG software installations are in an unusual spot, set the IPG_ROOT
# variable accordingly, and this script will attempt to find the correct
# sotfware/version from there.
###################################
#
# This will define the following variables::
#
#   RTMaker_FOUND    - True if the system has the Foo library
#   RTMaker_VERSION  - The version of the Foo library which was found
#
# The following legacy variables, which should be avoided and targets used instead.
#   RTMaker_INCLUDE_DIRS   - The CarMaker main include dir.
#   RTMaker_DEFINITIONS    - Defines needed to compile CarMaker.
#   RTMaker_LIBRARIES      - All the libraries CarMaker ships with.
#
# and the following imported targets::
#
#   RTMaker::Core               - The RTMaker libraries and headers
#   RTMaker::Infofile           - Infofile library and headers only.
#   RTMaker::Apoclient          - Apo client library and headers only.
#   RTMaker::Roadbuilder        - Roadbuilder library and headers only.
#
# This file supplies the following macros:
#   add_xeno_executable(NAME SRCS):
#       Input:
#           NAME - The Name of the new target.
#           SRCS - A list of sources to compile into the executable.
#       Effect:
#           Creates a Cmake Target with all required settings to compile a
#               RTMaker executable

## set apo client lib name depending on target platform
if(UNIX)
    set(RTMaker_apo-client_lib "apo-client-linux")
    set(RTMaker_zlib_lib "z-linux")
    set(RTMaker_lib_subfolder "lib")
endif()
if(WIN32)
    set(RTMaker_apo-client_lib "apo-client-win32")
    set(RTMaker_zlib_lib "z-win32")
    set(RTMaker_folder_arch "win32-xeno")
    set(RTMaker_lib_subfolder "lib")
endif()
if(CMAKE_CL_64)
    set(RTMaker_apo-client_lib "apo-client-win64")
    set(RTMaker_zlib_lib "z-win64")
    set(RTMaker_lib_subfolder "lib64")
endif()

if(CMAKE_HOST_WIN32)
    set(RTMaker_install_base_list
        "${RTMaker_install_DIR}" 
        "${IPG_ROOT}/rtmaker" 
        "C:/IPG/rtmaker"
    )
    set(RTMaker_folder_arch "win32-xeno")
    set(RTMaker_CreateCarMakerAppInfo_CMD bin/CreateCarMakerAppInfo.exe CACHE FILEPATH "Binary \
    program that is run inside RTMaker install folder to generate some files to compile CarMaker templates")
endif()
if(CMAKE_HOST_UNIX)
    set(RTMaker_install_base_list "${RTMaker_install_DIR}" "${IPG_ROOT}/rtmaker" "/opt/ipg/rtmaker")
    set(RTMaker_folder_arch "linux-xeno")
    set(RTMaker_CreateCarMakerAppInfo_CMD bin/CreateCarMakerAppInfo CACHE FILEPATH "Binary \
    program that is run inside RTMaker install folder to generate some files to compile CarMaker templates")
endif()
if(RTMaker_FIND_VERSION)
    # version is specified, try lookup in ipg network locations
    set(RTMaker_install_DIR_rel ${RTMaker_folder_arch}-${RTMaker_FIND_VERSION})
    find_path(RTMaker_include_folder
        NAMES "RTMaker.h"
        HINTS ${RTMaker_install_base_list}
        PATH_SUFFIXES "${RTMaker_install_DIR_rel}/include"
    )
    get_filename_component(RTMaker_install_DIRtemp ${RTMaker_include_folder} DIRECTORY)
    unset(RTMaker_include_folder CACHE)
    set(RTMaker_install_DIR ${RTMaker_install_DIRtemp} CACHE PATH
    "The RTMaker folder where includes and libs are aquired from")
    if(NOT EXISTS ${RTMaker_install_DIRtemp})
        # if not in ipg network, ask user to specify which carmaker he wants.
        message(FATAL_ERROR "Did not find RTMaker ${RTMaker_FIND_VERSION}.\
        Set either cache variable RTMaker_install_DIR to a carmaker install folder with the name\
        ${RTMaker_folder_arch}-${RTMaker_FIND_VERSION}. \
        Or set IPG_ROOT to the root folder of IPG program installations, \
        e.g. C:/IPG")

        if(NOT IPG_ROOT)
            set(IPG_ROOT "IPG_ROOT_NOTFOUND" CACHE PATH "Path to IPG install root")
        endif()
    endif()
else()
    # no version specified, grab the folder from a cache variable and determine
    # version from that.
    if(NOT RTMaker_install_DIR)
        set(RTMaker_install_DIR "dir_NOTFOUND" CACHE PATH
        "The RTMaker folder where includes and libs are aquired from")

        message(FATAL_ERROR "Neither RTMaker version nor CMake cache variable RTMaker_install_DIR set.\
        Can not find RTMaker install. Set RTMaker_install_DIR to the required RTMaker install directory.\
        The folder is named <platform>-<version>")
    else()
        if(NOT EXISTS ${RTMaker_install_DIR})
            message(FATAL_ERROR "Error finding RTMaker, folder given via cmake variable RTMaker_install_DIR\
            \"${RTMaker_install_DIR}\" does not exist.")
        endif() # RTMaker_install_DIR is now set
    endif() # end special case to init the cached variable
endif() # after all this, RTMaker_install_DIR should be set, as well as all version vars

string(REGEX MATCH "([0-9]+)\\.([0-9]+)\\.?([0-9]?)"
    cm_version_parsed ${RTMaker_install_DIR})

if(CMAKE_MATCH_COUNT LESS 2)
    message(AUTHOR_WARNING "Could not parse version of CM correctly!")
endif()

set(RTMaker_VERSION_MAJOR ${CMAKE_MATCH_1})
set(RTMaker_VERSION_MINOR  ${CMAKE_MATCH_2})
set(CarMaker_VERSION ${CarMaker_VERSION_MAJOR}.${CarMaker_VERSION_MINOR})
math(EXPR CM_VERNUM "${RTMaker_VERSION_MAJOR} * 10000 + ${RTMaker_VERSION_MINOR} * 100")

if(CMAKE_MATCH_COUNT EQUAL 3)
    set(RTMaker_VERSION_PATCH ${CMAKE_MATCH_3})
    set(CarMaker_VERSION ${CarMaker_VERSION_MAJOR}.${CarMaker_VERSION_MINOR}.${CarMaker_VERSION_PATCH})
    math(EXPR CM_VERNUM "${CM_VERNUM} + ${RTMaker_VERSION_PATCH}")
endif() # end regex parsing

file(TO_NATIVE_PATH ${RTMaker_install_DIR} RTMaker_install_DIR)

set(RTMaker_Include_DIR ${RTMaker_install_DIR}/include)
set(RTMaker_Library_DIR ${RTMaker_install_DIR}/${RTMaker_lib_subfolder})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(RTMaker
    FOUND_VAR RTMaker_FOUND
    REQUIRED_VARS
      RTMaker_Library_DIR
      RTMaker_Include_DIR
    VERSION_VAR RTMaker_VERSION
)

# if(${RTMaker_FIND_VERSION} VERSION_GREATER ${RTMaker_VERSION})
#     message(
# endif()


if(RTMaker_FOUND)
    list(APPEND rt_core_libraries
        native
        xenomai
        rtdm
    )

# append system-specific os libs
    if(UNIX)
        list(APPEND rt_core_os_libraries
            pthread
            dl
            usb
            m
            rt
            ${RTMaker_Library_DIR}/lib${RTMaker_zlib_lib}.a
        )
    endif()
    if(UNIX)
        list(APPEND rt_core_definitions
            -DRTMAKER
            -DLINUX
            -D_GNU_SOURCE
            -D_FILE_OFFSET_BITS=64
            -DRTM_NUMVER=${CM_VERNUM}
        )
    endif()

    # define cmake legacy variables
    set(RTMaker_INCLUDE_DIRS ${RTMaker_Include_DIR})
    set(RTMaker_LIBRARIES
        ${RTMaker_Library_DIR}/librtmaker.a
        ${rt_core_libraries}
        ${rt_core_os_libraries}
    )
    set(RTMaker_DEFINITIONS ${rt_core_definitions})

    if(NOT TARGET RTMaker::Core)
        add_library(RTMaker::Core STATIC IMPORTED GLOBAL)
        set_target_properties(RTMaker::Core PROPERTIES
            IMPORTED_LOCATION ${RTMaker_Library_DIR}/librtmaker.a
            INTERFACE_INCLUDE_DIRECTORIES ${RTMaker_Include_DIR}
    )

    target_link_libraries(RTMaker::Core
        INTERFACE
            ${rt_core_libraries}
            ${rt_core_os_libraries}
    )

    target_compile_definitions(RTMaker::Core
        INTERFACE
            ${rt_core_definitions}
    )
    endif()

    if(NOT TARGET RTMaker::Infofile)
        add_library(RTMaker::Infofile STATIC IMPORTED GLOBAL)
        set_target_properties(RTMaker::Infofile PROPERTIES
            IMPORTED_LOCATION ${RTMaker_Library_DIR}/libinfofile.a
            INTERFACE_INCLUDE_DIRECTORIES ${RTMaker_Include_DIR}
        )
    endif()

    if(NOT TARGET RTMaker::Apoclient)
        add_library(RTMaker::Apoclient STATIC IMPORTED GLOBAL)
        set_target_properties(RTMaker::Apoclient PROPERTIES
            IMPORTED_LOCATION ${RTMaker_Library_DIR}/lib${RTMaker_apo-client_lib}.a
            INTERFACE_INCLUDE_DIRECTORIES ${RTMaker_Include_DIR}
        )
    endif()

    if(NOT TARGET RTMaker::Roadbuilder)
        add_library(RTMaker::Roadbuilder STATIC IMPORTED GLOBAL)
        set_target_properties(RTMaker::Roadbuilder PROPERTIES
            IMPORTED_LOCATION ${RTMaker_Library_DIR}/libroadbuilder.a
            INTERFACE_INCLUDE_DIRECTORIES ${RTMaker_Include_DIR}
        )
    endif()

    include(${CMAKE_CURRENT_LIST_DIR}/IPG_RTMacros.cmake)

endif()
