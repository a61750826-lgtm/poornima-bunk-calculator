cmake_minimum_required(VERSION 3.10)
project(poornima_bunk_core CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(include)

add_executable(bunk_core src/main.cpp)
add_library(poornima_core SHARED src/main.cpp)

set_target_properties(poornima_core PROPERTIES
    OUTPUT_NAME "poornima_core"
)
