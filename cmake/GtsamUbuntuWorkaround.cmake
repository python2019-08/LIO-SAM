# Ubuntu 24.04's libgtsam-dev 4.2.0 exports CppUnitLite but omits its
# archive. CMake validates even unused imported targets, preventing GTSAM
# consumers from configuring. Keep the installed package untouched and
# remove only that unused archive check from a private copy of its config.
set(_gtsam_system_config "/usr/lib/cmake/GTSAM")
set(_gtsam_private_config "${CMAKE_CURRENT_BINARY_DIR}/gtsam-config")
if((NOT GTSAM_DIR OR GTSAM_DIR STREQUAL _gtsam_system_config OR
    GTSAM_DIR STREQUAL _gtsam_private_config) AND
   EXISTS "${_gtsam_system_config}/GTSAMConfig.cmake" AND
   NOT EXISTS "/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/libCppUnitLite.a")
  file(GLOB _gtsam_config_files "${_gtsam_system_config}/*.cmake")
  file(MAKE_DIRECTORY "${_gtsam_private_config}")
  # The package also names the METIS development symlink without depending
  # on libmetis-dev. Its installed runtime library has the same ABI.
  if(NOT EXISTS "/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/libmetis.so")
    find_library(_gtsam_metis_library NAMES metis libmetis.so.5 REQUIRED)
  endif()
  foreach(_gtsam_config_file IN LISTS _gtsam_config_files)
    file(READ "${_gtsam_config_file}" _gtsam_config_text)
    # Preserve the real installation paths after relocating the config.
    string(REPLACE "\${_IMPORT_PREFIX}/" "/usr/"
      _gtsam_config_text "${_gtsam_config_text}")
    string(REPLACE "\${OUR_CMAKE_DIR}/../../../include" "/usr/include"
      _gtsam_config_text "${_gtsam_config_text}")
    if(_gtsam_metis_library)
      string(REPLACE "/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/libmetis.so\""
        "${_gtsam_metis_library}\"" _gtsam_config_text "${_gtsam_config_text}")
    endif()
    string(REGEX REPLACE
      "list\\(APPEND _cmake_import_check_files_for_CppUnitLite [^\n]*\\)"
      "" _gtsam_config_text "${_gtsam_config_text}")
    get_filename_component(_gtsam_config_name "${_gtsam_config_file}" NAME)
    file(WRITE "${_gtsam_private_config}/${_gtsam_config_name}"
      "${_gtsam_config_text}")
  endforeach()
  set(GTSAM_DIR "${_gtsam_private_config}")
  message(STATUS "Using Ubuntu GTSAM config workaround for missing unused CppUnitLite archive")
endif()
