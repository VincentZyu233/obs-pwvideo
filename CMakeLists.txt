cmake_minimum_required(VERSION 3.28...3.30)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/finders")

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/bootstrap.cmake" NO_POLICY_SCOPE)

project(${_name} VERSION ${_version})

option(ENABLE_FRONTEND_API "Use obs-frontend-api for UI functionality" OFF)
option(ENABLE_QT "Use Qt functionality" OFF)

include(compilerconfig)
include(defaults)
include(helpers)
include(CheckCSourceCompiles)

add_library(${CMAKE_PROJECT_NAME} MODULE)

find_package(libobs REQUIRED)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::libobs)

# OBS 31/32 introduced explicit sync graphics APIs. OBS 30.2.3 does not have
# them, so detect the type at configure time and disable that path when absent.
set(OBS_PWVIDEO_EXPLICIT_SYNC "AUTO" CACHE STRING
    "Explicit sync support: AUTO, ON, or OFF")
set_property(CACHE OBS_PWVIDEO_EXPLICIT_SYNC PROPERTY STRINGS AUTO ON OFF)
get_target_property(_obs_include_dirs OBS::libobs INTERFACE_INCLUDE_DIRECTORIES)
set(CMAKE_REQUIRED_INCLUDES ${_obs_include_dirs})
check_c_source_compiles(
  "#include <obs.h>
   int main(void) {
     gs_sync_t *sync = (gs_sync_t *)0;
     (void)sync;
     return 0;
   }"
  OBS_HAS_EXPLICIT_SYNC)

if(OBS_PWVIDEO_EXPLICIT_SYNC STREQUAL "AUTO")
  set(_obs_explicit_sync_enabled ${OBS_HAS_EXPLICIT_SYNC})
elseif(OBS_PWVIDEO_EXPLICIT_SYNC STREQUAL "ON")
  if(NOT OBS_HAS_EXPLICIT_SYNC)
    message(FATAL_ERROR
      "OBS_PWVIDEO_EXPLICIT_SYNC=ON requires gs_sync_t from the installed libobs")
  endif()
  set(_obs_explicit_sync_enabled TRUE)
elseif(OBS_PWVIDEO_EXPLICIT_SYNC STREQUAL "OFF")
  set(_obs_explicit_sync_enabled FALSE)
else()
  message(FATAL_ERROR
    "OBS_PWVIDEO_EXPLICIT_SYNC must be AUTO, ON, or OFF (got '${OBS_PWVIDEO_EXPLICIT_SYNC}')")
endif()

if(_obs_explicit_sync_enabled)
  target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE HAVE_OBS_EXPLICIT_SYNC=1)
endif()

find_package(PipeWire 0.3.83 REQUIRED)
find_package(Libdrm REQUIRED)
get_target_property(libdrm_include_directories Libdrm::Libdrm INTERFACE_INCLUDE_DIRECTORIES)

if(ENABLE_FRONTEND_API)
  find_package(obs-frontend-api REQUIRED)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::obs-frontend-api)
endif()

if(ENABLE_QT)
  find_package(Qt6 COMPONENTS Widgets Core)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::Core Qt6::Widgets)
  target_compile_options(
    ${CMAKE_PROJECT_NAME}
    PRIVATE $<$<C_COMPILER_ID:Clang,AppleClang>:-Wno-quoted-include-in-framework-header -Wno-comma>
  )
  set_target_properties(
    ${CMAKE_PROJECT_NAME}
    PROPERTIES AUTOMOC ON AUTOUIC ON AUTORCC ON
  )
endif()

target_sources(
  ${CMAKE_PROJECT_NAME}
  PRIVATE src/plugin-main.c src/pipewire.c src/pipewire.h src/formats.c src/pw-filter.cpp src/formats.h
)
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${libdrm_include_directories})

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE PipeWire::PipeWire)

# Resolve EGL/GL symbols used by the PipeWire texture import path.
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE EGL GL)

set_target_properties_plugin(${CMAKE_PROJECT_NAME} PROPERTIES OUTPUT_NAME ${_name})
