cmake_minimum_required(VERSION 3.14)
project(wifi_drop LANGUAGES CXX)

set(BINARY_NAME "WiFiDrop")

cmake_policy(SET CMP0079 NEW)

# Configure build options.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Configuration: Debug, Profile, Release"
      FORCE)
  endif()
endif()

# Application build configuration.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Configure Flutter Windows embedder libraries.
add_subdirectory(flutter)
add_subdirectory(runner)
