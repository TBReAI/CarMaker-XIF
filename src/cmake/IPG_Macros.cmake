set(this_file_loc ${CMAKE_CURRENT_LIST_DIR})

###################################
#  add_carmaker_executable macro  #
###################################

if(CMAKE_HOST_WIN32 AND UNIX AND NOT XENO)
    message(FATAL_ERROR "I didn't expect you to cross-compile from win to \
    linux, this is currently not possible.")
endif()

if(CMAKE_HOST_UNIX)
    find_path(CARMAKER_INSTALL_DIR_NATIVE
        NAMES "include/CarMaker.h"
        HINTS
            "${ipghome_env}"
            "${IPG_ROOT}"
            "/opt/ipg"
            "/opt/IPG"
        PATH_SUFFIXES "carmaker/linux64-${CarMaker_VERSION}"
    )
endif()

find_program (CARMAKER_APPINFO_CMD
    NAMES CreateCarMakerAppInfo CreateCarMakerAppInfo.exe
    PATHS
        # use native path, when cross-compiling
        ${CARMAKER_INSTALL_DIR_NATIVE}/bin
        # otherwise use normal install path
        ${CARMAKER_INSTALL_DIR}/bin
    DOC "Binary program that is run inside CarMaker install folder to \
    generate some files to compile CarMaker templates"
    NO_DEFAULT_PATH
)

find_program (CARMAKER_PLUG_UTIL
    NAMES cmplugutil cmplugutil.exe
    PATHS
        # use native path, when cross-compiling
        ${CARMAKER_INSTALL_DIR_NATIVE}/bin
        # otherwise use normal install path
        ${CARMAKER_INSTALL_DIR}/bin
    DOC "Binary program that is run inside CarMaker install folder to \
    generate some files to compile CarMaker templates"
    NO_DEFAULT_PATH
)

macro(add_carmaker_executable NAME)
add_executable(${NAME} app_tmp_car.c ${ARGN})
if(CMAKE_HOST_WIN32 AND NOT XENO)
    if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        message(FATAL_ERROR "Can not currently cross-compile a linux executable from windows. \
        Only compilation of xeno executables is allowed.")
    endif()
endif()

target_link_libraries(${NAME}
    PRIVATE
    $<$<C_COMPILER_ID:MSVC>:CarMaker::compat_arch>
    $<$<C_COMPILER_ID:MSVC>:legacy_stdio_definitions>
    CarMaker::Car
)

if(XENO)
    target_include_directories(${NAME}
        PUBLIC
            ${CARMAKER_INSTALL_DIR}/include/cobalt
            ${CARMAKER_INSTALL_DIR}/include/alchemy
    )
    target_compile_options(${NAME}
        PRIVATE
            -fasynchronous-unwind-tables
    )
    set_target_properties(${NAME}
        PROPERTIES
            LINK_FLAGS "-Wl,--allow-shlib-undefined"
    )
endif()

add_custom_command(OUTPUT app_tmp_car.c
    COMMAND ${CARMAKER_APPINFO_CMD}
        =av "${NAME}"
        =sv "${CarMaker_VERSION}"
        =arch "${Arch}"
        =c "Created using cmake"
        =cf "Flags auto determined"
        =libs ${cm_core_libraries} ${cm_car_libraries} > app_tmp_car.c
        DEPENDS ${ARGN}
)

if(${BUILD_DEBUG_WITH_ASAN})
    target_compile_options(${NAME}
        PUBLIC
        $<$<CONFIG:DEBUG>:-fsanitize=address>
        $<$<CONFIG:DEBUG>:-fno-omit-frame-pointer>
        $<$<CONFIG:DEBUG>:-static-libasan>
    )

    set_target_properties(${NAME}
        PROPERTIES
            LINK_FLAGS_DEBUG "-fsanitize=address -fno-omit-frame-pointer -static-libasan"
    )
endif()

set_target_properties(${NAME}
    PROPERTIES
        C_STANDARD 99
        OUTPUT_NAME "${NAME}.${Arch}"
)

if(UNIX)
    target_compile_options(${NAME}
        PRIVATE
        $<$<CONFIG:Debug>:-Wall -Wextra -Wshadow -Wno-deprecated-declarations -Wno-unused-parameter>)
endif()
endmacro()

###################################
#  add_truckmaker_executable macro  #
###################################
macro(add_truckmaker_executable NAME)
add_executable(${NAME} app_tmp_truck.c ${ARGN})
if(CMAKE_HOST_WIN32 AND NOT XENO)
    if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        message(FATAL_ERROR "Can not currently cross-compile a linux executable from windows. \
        Only compilation of xeno executables is allowed.")
    endif()
endif()

target_link_libraries(${NAME}
    PRIVATE
    $<$<C_COMPILER_ID:MSVC>:CarMaker::compat_arch>
    $<$<C_COMPILER_ID:MSVC>:legacy_stdio_definitions>
    CarMaker::Truck
)

if(XENO)
    target_include_directories(${NAME}
        PUBLIC
            ${CARMAKER_INSTALL_DIR}/include/cobalt
            ${CARMAKER_INSTALL_DIR}/include/alchemy
    )
    target_compile_options(${NAME}
        PRIVATE
            -fasynchronous-unwind-tables
    )
    set_target_properties(${NAME}
        PROPERTIES
            LINK_FLAGS "-Wl,--allow-shlib-undefined"
    )
endif()

add_custom_command(
    OUTPUT app_tmp_truck.c
    COMMAND ${CARMAKER_APPINFO_CMD}
        =av "${NAME}"
        =sv "${CarMaker_VERSION}"
        =arch "${Arch}"
        =c "Created using cmake"
        =cf "Flags auto determined"
        =libs ${cm_core_libraries} ${cm_truc_libraries} > app_tmp_truck.c
    DEPENDS ${ARGN}

)

if(${BUILD_DEBUG_WITH_ASAN})
    target_compile_options(${NAME}
        PUBLIC
        $<$<CONFIG:DEBUG>:-fsanitize=address>
        $<$<CONFIG:DEBUG>:-fno-omit-frame-pointer>
        $<$<CONFIG:DEBUG>:-static-libasan>
    )

    set_target_properties(${NAME}
        PROPERTIES
            LINK_FLAGS_DEBUG "-fsanitize=address -fno-omit-frame-pointer -static-libasan"
    )
endif()

set_target_properties(${NAME}
    PROPERTIES
        C_STANDARD 99
        OUTPUT_NAME "${NAME}.${Arch}"
)

if(UNIX)
    target_compile_options(${NAME}
        PRIVATE
        $<$<CONFIG:Debug>:-Wall -Wextra -Wshadow -Wno-deprecated-declarations -Wno-unused-parameter>)
endif()
endmacro()

###################################
#  add_mcycle_executable macro  #
###################################
macro(add_mcycle_executable NAME)
add_executable(${NAME} app_tmp_mcycle.c ${ARGN})
if(CMAKE_HOST_WIN32 AND NOT XENO)
    if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        message(FATAL_ERROR "Can not currently cross-compile a linux executable from windows. \
        Only compilation of xeno executables is allowed.")
    endif()
endif()

target_link_libraries(${NAME}
    PRIVATE
    $<$<C_COMPILER_ID:MSVC>:CarMaker::compat_arch>
    $<$<C_COMPILER_ID:MSVC>:legacy_stdio_definitions>
    CarMaker::Mcycle
)

if(XENO)
    target_include_directories(${NAME}
        PUBLIC
            ${CARMAKER_INSTALL_DIR}/include/cobalt
            ${CARMAKER_INSTALL_DIR}/include/alchemy
    )
    target_compile_options(${NAME}
        PRIVATE
            -fasynchronous-unwind-tables
    )
    set_target_properties(${NAME}
        PROPERTIES
            LINK_FLAGS "-Wl,--allow-shlib-undefined"
    )
endif()

add_custom_command(
    OUTPUT app_tmp_mcycle.c
    COMMAND ${CARMAKER_APPINFO_CMD}
        =av "${NAME}"
        =sv "${CarMaker_VERSION}"
        =arch "${Arch}"
        =c "Created using cmake"
        =cf "Flags auto determined"
        =libs ${cm_core_libraries} ${cm_mcycle_libraries} > app_tmp_mcycle.c
    DEPENDS ${ARGN}

)

if(${BUILD_DEBUG_WITH_ASAN})
    target_compile_options(${NAME}
        PUBLIC
        $<$<CONFIG:DEBUG>:-fsanitize=address>
        $<$<CONFIG:DEBUG>:-fno-omit-frame-pointer>
        $<$<CONFIG:DEBUG>:-static-libasan>
    )
endif()

set_target_properties(${NAME}
    PROPERTIES
        C_STANDARD 99
        OUTPUT_NAME "${NAME}.${Arch}"
)

if(UNIX)
    target_compile_options(${NAME}
        PRIVATE
        $<$<CONFIG:Debug>:-Wall -Wextra -Wshadow -Wno-deprecated-declarations -Wno-unused-parameter>)
endif()
endmacro()

macro(add_cm4sl_target)
set(NAME libcarmaker4sl)

add_library(${NAME} SHARED
    app_tmp_ml.c ${ARGN}
)

target_link_libraries(${NAME}
    PUBLIC
        $<$<C_COMPILER_ID:GNU>:-Wl,-Bsymbolic,--allow-shlib-undefined>
        "-u CarMaker4SL_CMLib"
        $<$<C_COMPILER_ID:MSVC>:-INCREMENTAL:NO>
        $<$<C_COMPILER_ID:MSVC>:CarMaker::compat_arch>
        $<$<C_COMPILER_ID:MSVC>:legacy_stdio_definitions>
        CarMaker::MatlabSupport
)

target_compile_definitions(${NAME}
    PUBLIC
        MATLAB_MEX_FILE
)

set_target_properties(${NAME}
    PROPERTIES
        PREFIX ""
        OUTPUT_NAME "libcarmaker4sl"
        SUFFIX .${Matlab_MEX_EXTENSION}
)

# the following re-generates app_tmp_truck.c if and only if the target NAME changes.

add_custom_command(
    OUTPUT app_tmp_ml.c
    COMMAND ${CARMAKER_APPINFO_CMD}
        =av "${NAME}"
        =sv "${CarMaker_VERSION}"
        =arch "${Arch}"
        =c "Created using cmake"
        =cf "Flags auto determined"
        =libs ${cm4sl_core_libs} > app_tmp_ml.c
    DEPENDS ${ARGN}
)

## copy the cm4sl lib into its source folder, since simulink looks for it there..
add_custom_target(Place_cm4sl_in_src_dir ALL
    COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:${NAME}> ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS ${NAME}
)
endmacro()

macro(build_hil_1006_executable NAME ADDITIONAL_INCLUDES ADDITIONAL_DEFINITIONS ADDITIONAL_LIBS)
    set(DS1006_exec_name ${NAME})
    set(DS1006_additional_libs ${ADDITIONAL_LIBS})
    set(DS1006_additional_defines ${ADDITIONAL_DEFINITIONS})
    set(DS1006_additional_includes ${ADDITIONAL_INCLUDES})
    set(DS1006_BINARY_DIR ${CMAKE_BINARY_DIR}/ds1006/${NAME})
    set(CMPU ${CARMAKER_PLUG_UTIL})
    set(CREATE_INFO_CMD ${CARMAKER_APPINFO_CMD})

    add_custom_command(OUTPUT ${DS1006_BINARY_DIR}/Version.h
        COMMAND ${CMAKE_COMMAND}
        -D LIB_VERSION=${LIB_VERSION}
        -D CarMaker_VERSION=${CarMaker_VERSION}
        -D Arch=ds1006
        -D FROM_FILE=${CMAKE_CURRENT_SOURCE_DIR}/Version.h.in
        -D TO_FILE=${DS1006_BINARY_DIR}/Version.h
        -P ${this_file_loc}/Generate_Version_h.cmake
        VERBATIM
    )

    foreach(source ${ARGN})
        set(processed_name ${DS1006_BINARY_DIR}/${source})
        list(APPEND processed_sources
            ${processed_name}
        )
        add_custom_command(
            OUTPUT ${processed_name}
            COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_LIST_DIR}/${source} ${processed_name}
            DEPENDS ${source}
        )
    endforeach()

    string(REPLACE ".c" ".o" M_OBJS_rel "${ARGN}")
    string(REPLACE ";" " " M_OBJS "${M_OBJS_rel}")
    configure_file(${this_file_loc}/ds1006/Makefile_exe.in ${DS1006_BINARY_DIR}/Makefile)

    add_custom_target(${NAME}.ds1006 ALL
        COMMAND make-ds1006 > make-ds1006.log
        DEPENDS ${processed_sources} ${ADDITIONAL_LIBS} ${DS1006_BINARY_DIR}/Makefile
        BYPRODUCTS ${DS1006_BINARY_DIR}/${NAME}.x86 ${DS1006_BINARY_DIR}/${NAME}.map
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/ds1006/${NAME}
        SOURCES ${processed_sources}
    )

    set_property(TARGET ${NAME}.ds1006
        PROPERTY
            BINARY_DIR ${DS1006_BINARY_DIR}
    )

    foreach(rel_obj ${M_OBJS_rel})
            list(APPEND built_objects
                ${DS1006_BINARY_DIR}/${rel_obj}
            )
    endforeach()

    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/
        PROPERTY
            ADDITIONAL_MAKE_CLEAN_FILES ${DS1006_BINARY_DIR}/${NAME}.x86 ${DS1006_BINARY_DIR}/${NAME}.x86g ${DS1006_BINARY_DIR}/${NAME}.map ${built_objects}
    )
endmacro()

macro(build_hil_1006_static_library NAME ADDITIONAL_INCLUDES ADDITIONAL_DEFINITIONS ADDITIONAL_LIBS)
    set(DS1006_lib_name lib${NAME}.a)
    set(DS1006_additional_libs ${ADDITIONAL_LIBS})
    set(DS1006_additional_defines ${ADDITIONAL_DEFINITIONS})
    set(DS1006_additional_includes ${ADDITIONAL_INCLUDES})
    set(DS1006_BINARY_DIR ${CMAKE_BINARY_DIR}/ds1006/${NAME})
    set(CMPU ${CARMAKER_PLUG_UTIL})
    set(CREATE_INFO_CMD ${CARMAKER_APPINFO_CMD})

    foreach(source ${ARGN})
        set(processed_name ${DS1006_BINARY_DIR}/${source})
    list(APPEND processed_sources
        ${processed_name}
    )
    add_custom_command(
        OUTPUT ${processed_name}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_LIST_DIR}/${source} ${processed_name}
        DEPENDS ${source}
    )
    endforeach()

    string(REPLACE ".c" ".o" M_OBJS_rel "${ARGN}")
    string(REPLACE ";" " " M_OBJS "${M_OBJS_rel}")
    configure_file(${this_file_loc}/ds1006/Makefile_lib.in ${DS1006_BINARY_DIR}/Makefile)

    add_custom_target(${NAME}.ds1006 ALL
        COMMAND make-ds1006 > make-ds1006.log
        DEPENDS ${processed_sources} ${DS1006_BINARY_DIR}/Makefile
        BYPRODUCTS ${DS1006_BINARY_DIR}/${NAME}.a
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/ds1006/${NAME}
        SOURCES ${processed_sources}
    )

    set_property(TARGET ${NAME}.ds1006
        PROPERTY
            BINARY_DIR ${DS1006_BINARY_DIR}
    )

    foreach(rel_obj ${M_OBJS_rel})
            list(APPEND built_objects
                ${DS1006_BINARY_DIR}/${rel_obj}
            )
    endforeach()
    list(APPEND built_objects
        ${DS1006_BINARY_DIR}/app_tmp.o
    )

    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/
        PROPERTY
            ADDITIONAL_MAKE_CLEAN_FILES ${DS1006_BINARY_DIR}/${NAME}.a ${built_objects}
    )
endmacro()

macro(add_carmaker_library NAME INFO)
add_library(${NAME} ${INFO} Version.h ${ARGN})


if(CMAKE_HOST_WIN32 AND NOT XENO)
    if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
        message(FATAL_ERROR "Can not currently cross-compile a linux executable from windows. \
        Only compilation of xeno executables is allowed.")
    endif()
endif()

target_link_libraries(${NAME}
    INTERFACE
        $<$<C_COMPILER_ID:MSVC>:CarMaker::compat_arch>
        $<$<C_COMPILER_ID:MSVC>:legacy_stdio_definitions>
        CarMaker::Car
)

set (LIB_CFLAGS "")
if(CMAKE_BUILD_TYPE)
    string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_UPPER)
    string(APPEND LIB_CFLAGS ${CMAKE_C_FLAGS_${CMAKE_BUILD_TYPE_UPPER}})
endif()

if (${INFO} STREQUAL "SHARED")
    string(APPEND LIB_CFLAGS " -fPIC")
endif()

foreach(item ${CarMaker_DEFINITIONS})
    string(APPEND LIB_CFLAGS " -D${item}")
endforeach()

foreach(item ${CarMaker_INCLUDE_DIRS})
    string(APPEND LIB_CFLAGS " -I${item}")
endforeach()

add_custom_command(OUTPUT Version.h
    COMMAND ${CMAKE_COMMAND}
    -D LIB_VERSION=${LIB_VERSION}
    -D LIB_CM_VERSION=${CarMaker_VERSION}
    -D LIB_ARCH=${Arch}
    -D LIB_CFLAGS=${LIB_CFLAGS}
    -D TO_FILE=${CMAKE_CURRENT_SOURCE_DIR}/Version.h
    -P ${this_file_loc}/Generate_Version_h.cmake
    VERBATIM
)

target_include_directories(${NAME}
    PUBLIC
        ${CARMAKER_INSTALL_DIR}/include
        $<$<BOOL:XENO>:${CARMAKER_INSTALL_DIR}/include/cobalt>
        $<$<BOOL:XENO>:${CARMAKER_INSTALL_DIR}/include/alchemy>
)

target_compile_options(${NAME}
    PRIVATE
        $<$<BOOL:XENO>:-fasynchronous-unwind-tables>
)
endmacro()

macro(add_target_zip_folder INPUT OUTPUT)
add_custom_target(zip_folder
    DEPENDS "${INPUT}"
    COMMAND ${CMAKE_COMMAND} -E tar "cfv" "${OUTPUT}" --format=zip .
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${INPUT}"
    WORKING_DIRECTORY "${INPUT}"
    COMMENT "Zip and clean up folder"
    VERBATIM)
endmacro()
