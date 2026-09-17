cmake_minimum_required(VERSION 3.16)
project(sui-plugin-legacy VERSION 1.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(SAMP_SDK_DIR "${CMAKE_SOURCE_DIR}/lib/samp-plugin-sdk")

set(SOURCES
    src/main.cpp
    src/Core.cpp
    src/Natives.cpp
    ${SAMP_SDK_DIR}/amxplugin.cpp
    ${SAMP_SDK_DIR}/amxplugin2.cpp
)

if(WIN32)
    list(APPEND SOURCES src/sui-plugin-legacy.def)
    add_library(${PROJECT_NAME} SHARED ${SOURCES})

    # Static CRT (/MT) to avoid MSVCP/VCRUNTIME external dependencies on fresh SA-MP host
    set_property(TARGET ${PROJECT_NAME} PROPERTY
        MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

    target_compile_definitions(${PROJECT_NAME} PRIVATE
        HAVE_STDINT_H
        SUI_VERSION="${PROJECT_VERSION}"
    )

    set_target_properties(${PROJECT_NAME} PROPERTIES
        PREFIX ""
        SUFFIX ".dll"
        OUTPUT_NAME "sui-plugin-legacy"
    )
else()
    # Build 32-bit untuk legacy plugin SA-MP/open.mp pada Linux
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m32")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -m32")

    add_library(${PROJECT_NAME} SHARED ${SOURCES})

    target_compile_definitions(${PROJECT_NAME} PRIVATE
        LINUX
        HAVE_STDINT_H
        SUI_VERSION="${PROJECT_VERSION}"
    )

    set_target_properties(${PROJECT_NAME} PROPERTIES
        PREFIX ""
        SUFFIX ".so"
        OUTPUT_NAME "sui-plugin-legacy"
    )
endif()

target_include_directories(${PROJECT_NAME} PRIVATE
    src
    ${SAMP_SDK_DIR}
    ${SAMP_SDK_DIR}/amx
)