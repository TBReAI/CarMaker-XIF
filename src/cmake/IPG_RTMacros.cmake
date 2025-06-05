###################################
#  add_carmaker_executable macro  #
###################################
link_directories(${RTMaker_Library_DIR})
macro(add_xeno_executable NAME)

if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    message(FATAL_ERROR "Can not cross-compile a xeno executable for target platform windows, since that does not make sense.")
endif()
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "i686")
    message(FATAL_ERROR "Can not cross-compile a xeno executable for target processor i686, since xeno is 32bit only.")
endif()

add_executable(${NAME} app_tmp_rt.c ${ARGN})

set_target_properties(${NAME}
    PROPERTIES
        COMPILE_FLAGS "-m32"
        LINK_FLAGS "-m32"
)

target_link_libraries(${NAME}
    PRIVATE
    RTMaker::Core
)

add_custom_command(
    OUTPUT app_tmp_rt.c
    COMMAND ${RTMaker_install_DIR}/${RTMaker_CreateCarMakerAppInfo_CMD}
        =av '${NAME}'
        =sv '${CarMaker_VERSION}'
        =arch 'xeno'
        =c 'Created using cmake'
        =cf 'Flags auto determined'
        =libs ${RTMaker_Library_DIR}/librtmaker.a ${rt_core_libraries} > app_tmp_rt.c
    DEPENDS ${ARGN}

)
endmacro()
