# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "notification_master")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "notification_master_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "notification_master_plugin.cc"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# ── External library dependencies ───────────────────────────────────────────
# libnotify  — desktop notification display (notify-send equivalent, in-process)
# libsoup-3.0 — async HTTP client for the polling loop
#   Falls back to libsoup-2.4 on older distros (Ubuntu 20.04, etc.)
# json-glib-1.0 — JSON parsing for the polling response
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBNOTIFY  REQUIRED libnotify)
pkg_check_modules(JSON_GLIB  REQUIRED json-glib-1.0)

# Try libsoup 3 first; fall back to libsoup 2.4
pkg_check_modules(LIBSOUP3 libsoup-3.0)
if(LIBSOUP3_FOUND)
  set(LIBSOUP_INCLUDE_DIRS ${LIBSOUP3_INCLUDE_DIRS})
  set(LIBSOUP_LIBRARIES    ${LIBSOUP3_LIBRARIES})
  set(LIBSOUP_CFLAGS_OTHER ${LIBSOUP3_CFLAGS_OTHER})
  target_compile_definitions(${PLUGIN_NAME} PRIVATE SOUP_VERSION=3)
else()
  pkg_check_modules(LIBSOUP2 REQUIRED libsoup-2.4)
  set(LIBSOUP_INCLUDE_DIRS ${LIBSOUP2_INCLUDE_DIRS})
  set(LIBSOUP_LIBRARIES    ${LIBSOUP2_LIBRARIES})
  set(LIBSOUP_CFLAGS_OTHER ${LIBSOUP2_CFLAGS_OTHER})
  target_compile_definitions(${PLUGIN_NAME} PRIVATE SOUP_VERSION=2)
endif()

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_include_directories(${PLUGIN_NAME} PRIVATE
  ${LIBNOTIFY_INCLUDE_DIRS}
  ${LIBSOUP_INCLUDE_DIRS}
  ${JSON_GLIB_INCLUDE_DIRS})

target_compile_options(${PLUGIN_NAME} PRIVATE
  ${LIBNOTIFY_CFLAGS_OTHER}
  ${LIBSOUP_CFLAGS_OTHER}
  ${JSON_GLIB_CFLAGS_OTHER})

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${PLUGIN_NAME} PRIVATE
  ${LIBNOTIFY_LIBRARIES}
  ${LIBSOUP_LIBRARIES}
  ${JSON_GLIB_LIBRARIES})

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(notification_master_bundled_libraries
  ""
  PARENT_SCOPE
)

# === Background poller daemon ===
# A standalone executable that keeps polling + showing desktop notifications
# even after the main Flutter app is closed. Launched by the plugin via
# startBackgroundPollingService(). Uses libcurl for HTTP (simpler dependency
# for a standalone binary than libsoup).
find_package(CURL REQUIRED)

add_executable(notification_master_poller
  "nm_background_poller_linux.cpp"
)
target_include_directories(notification_master_poller PRIVATE
  ${LIBNOTIFY_INCLUDE_DIRS}
  ${JSON_GLIB_INCLUDE_DIRS}
  ${CURL_INCLUDE_DIRS}
)
target_compile_options(notification_master_poller PRIVATE
  ${LIBNOTIFY_CFLAGS_OTHER}
  ${JSON_GLIB_CFLAGS_OTHER}
)
target_link_libraries(notification_master_poller PRIVATE
  ${LIBNOTIFY_LIBRARIES}
  ${JSON_GLIB_LIBRARIES}
  ${CURL_LIBRARIES}
  pthread
)

# === Tests ===
# These unit tests can be run from a terminal after building the example.

# Only enable test builds when building the example (which sets this variable)
# so that plugin clients aren't building the tests.
if (${include_${PROJECT_NAME}_tests})
if(${CMAKE_VERSION} VERSION_LESS "3.11.0")
message("Unit tests require CMake 3.11.0 or later")
else()
set(TEST_RUNNER "${PROJECT_NAME}_test")
enable_testing()

# Add the Google Test dependency.
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
)
# Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
# Disable install commands for gtest so it doesn't end up in the bundle.
set(INSTALL_GTEST OFF CACHE BOOL "Disable installation of googletest" FORCE)

FetchContent_MakeAvailable(googletest)

# The plugin's exported API is not very useful for unit testing, so build the
# sources directly into the test binary rather than using the shared library.
add_executable(${TEST_RUNNER}
  test/notification_master_plugin_test.cc
  ${PLUGIN_SOURCES}
)
apply_standard_settings(${TEST_RUNNER})
target_include_directories(${TEST_RUNNER} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_include_directories(${TEST_RUNNER} PRIVATE
  ${LIBNOTIFY_INCLUDE_DIRS}
  ${LIBSOUP_INCLUDE_DIRS}
  ${JSON_GLIB_INCLUDE_DIRS})
target_link_libraries(${TEST_RUNNER} PRIVATE flutter)
target_link_libraries(${TEST_RUNNER} PRIVATE PkgConfig::GTK)
target_link_libraries(${TEST_RUNNER} PRIVATE
  ${LIBNOTIFY_LIBRARIES}
  ${LIBSOUP_LIBRARIES}
  ${JSON_GLIB_LIBRARIES})
target_link_libraries(${TEST_RUNNER} PRIVATE gtest_main gmock)

# Enable automatic test discovery.
include(GoogleTest)
gtest_discover_tests(${TEST_RUNNER})

endif()  # CMake version check
endif()  # include_${PROJECT_NAME}_tests
