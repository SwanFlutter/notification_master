# Helper invoked from example/windows/CMakeLists.txt at install time to copy
# the background poller daemon next to the app executable.
#
# The daemon is built by the plugin under
#   <example build>/windows/x64/plugins/notification_master/<CONFIG>/
# (CMAKE_BINARY_DIR here is that windows/x64 directory). We copy it into the
# app's bundle dir so it can be launched (and keep polling/showing toasts) even
# after the app is closed.
#
# A running instance would lock the destination (Permission denied), so stop
# any running copy first. Errors from taskkill (no process) are swallowed via
# cmd /c "... || exit /b 0" so they never fail the install step.

set(_poller_dir "${CMAKE_BINARY_DIR}/plugins/notification_master")
# Use the same configuration that is being installed (BUILD_TYPE is set by
# cmake_install.cmake as Debug/Release/Profile).
if(NOT DEFINED BUILD_TYPE OR BUILD_TYPE STREQUAL "")
  set(_cfg "Release")
else()
  set(_cfg "${BUILD_TYPE}")
endif()

set(_found "${_poller_dir}/${_cfg}/notification_master_poller.exe")
if(NOT EXISTS "${_found}")
  # Fall back to any configuration that was built.
  set(_found "")
  foreach(_c Debug Release Profile)
    if(EXISTS "${_poller_dir}/${_c}/notification_master_poller.exe")
      set(_found "${_poller_dir}/${_c}/notification_master_poller.exe")
      break()
    endif()
  endforeach()
endif()

# install(SCRIPT) runs in its own scope, so INSTALL_BUNDLE_LIB_DIR and
# CMAKE_INSTALL_PREFIX are not reliably resolved. The app bundle dir is simply
# <binary>/runner/<cfg>/, which is where the other DLLs are installed.
set(_dest "${CMAKE_BINARY_DIR}/runner/${_cfg}")

if(_found)
  message(STATUS "[NM] _found=${_found}")
  message(STATUS "[NM] _dest=${_dest}")
  # Stop a running daemon so the destination file isn't locked. Swallow errors.
  execute_process(COMMAND cmd /c "taskkill /F /IM notification_master_poller.exe 2>nul || exit /b 0"
                  COMMAND_ERROR_IS_FATAL NONE)
  file(COPY "${_found}" DESTINATION "${_dest}")
  message(STATUS "[NM] Copied notification_master_poller.exe next to app")
else()
  message(WARNING "[NM] notification_master_poller.exe not found under ${_poller_dir}; background polling daemon will not be available")
endif()
