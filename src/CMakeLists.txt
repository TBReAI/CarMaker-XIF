cmake_minimum_required(VERSION 3.10)

project(CarMaker-XIF)

add_subdirectory(XIF)

set(CM_VERSION 13.1.1)

set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS TRUE)

list(APPEND CMAKE_MODULE_PATH
    ${CMAKE_CURRENT_LIST_DIR}/cmake
)

find_package(CarMaker ${CM_VERSION} REQUIRED)

add_carmaker_executable(CarMaker-XIF 
    main.c
    #carmaker/app_tmp.c
    carmaker/CM_Main.c
    carmaker/CM_Vehicle.c
    carmaker/User.c
    carmaker/IO.c
    cmimg.c
)

target_include_directories(CarMaker-XIF PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}
    ${CMAKE_CURRENT_LIST_DIR}/XIF/include
)

target_link_libraries(CarMaker-XIF PRIVATE
    ${XIF_LIBS}
)

if (LINUX)
    set(OUTPUT_NAME "${CMAKE_BINARY_DIR}/CarMaker-XIF.linux64")
elseif (WIN32)
    set(OUTPUT_NAME "${CMAKE_BINARY_DIR}/CarMaker-XIF.win64.exe")
endif()


add_custom_command(TARGET CarMaker-XIF POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:CarMaker-XIF> ${OUTPUT_NAME}
    COMMENT "Copying CarMaker-XIF to ${OUTPUT_NAME}"
)

if(DEFINED XIF_LIBS)
    add_custom_command(TARGET CarMaker-XIF POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy ${XIF_DLL} ${CMAKE_BINARY_DIR}
        COMMENT "Copying ${XIF_DLL} to ${CMAKE_BINARY_DIR}"
    )
endif()