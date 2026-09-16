cmake_minimum_required(VERSION 3.16)
project(sui-plugin-legacy VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Build 32-bit untuk legacy plugin SA-MP/open.mp
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m32")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -m32")

set(SAMP_SDK_DIR "${CMAKE_SOURCE_DIR}/lib/samp-plugin-sdk")

set(SOURCES
    src/main.cpp
    src/Core.cpp
    src/Natives.cpp
    ${SAMP_SDK_DIR}/amxplugin.cpp
    ${SAMP_SDK_DIR}/amxplugin2.cpp
)

add_library(${PROJECT_NAME} SHARED ${SOURCES})

target_include_directories(${PROJECT_NAME} PRIVATE
    src
    ${SAMP_SDK_DIR}
    ${SAMP_SDK_DIR}/amx
)

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