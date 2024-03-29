# cmake utils

# This macro lets you find executable programs on the host system
# Usefull for emscripten
macro(find_host_package)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER)
  find_package(${ARGN})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
endmacro(find_host_package)

# Useful cause some systems don`t allow easy package finding
macro(findPackageCrossPlatform)
  if(EMSCRIPTEN)
      find_host_package(${ARGN})
  elseif(ANDROID)
      find_host_package(${ARGN})
  elseif(CMAKE_HOST_WIN32)
      find_package(${ARGN})
  elseif(CMAKE_HOST_UNIX)
    find_package(${ARGN})
  else()
      message( STATUS
        "Unknown platform, using find_package" )
      find_package(${ARGN})
  endif()
endmacro(findPackageCrossPlatform)

# Get names of subdirectories in directory
macro(list_subdirectories result curdir)
  FILE(GLOB children RELATIVE ${curdir} ${curdir}/*)
  SET(dirlist "")
  foreach (child ${children})
    if (IS_DIRECTORY ${curdir}/${child} AND NOT ${child} STREQUAL "CMakeFiles")
      list(APPEND dirlist ${child})
    endif()
  endforeach ()
  set(${result} ${dirlist})
endmacro()

# Performs searching and adding of files to source list
# Appends source files to ${${PROJECT_NAME}_SRCS}
# Appends header files to ${${PROJECT_NAME}_HEADERS}
# Appends dir (argument) to ${${PROJECT_NAME}_DIRS}
# Appends extra_patterns (argument) to ${${PROJECT_NAME}_EXTRA}
# Example of extra_patterns: "cmake/*.cmake;cmake/*.imp"
macro(addFolder dir prefix extra_patterns)
  if (NOT EXISTS "${dir}")
    message(FATAL_ERROR "${dir} doesn`t exist!")
  endif()

  set(src_files "")
  set(header_files "")
  set(globType GLOB)
  if(${ARGC} GREATER 1 AND "${ARGV1}" STREQUAL "RECURSIVE")
      set(globType GLOB_RECURSE)
  endif()
  # Note: Certain IDEs will only display files that belong to a target, so add .h files too.
  file(${globType} src_files ABSOLUTE
      ${dir}/*.c
      ${dir}/*.cc
      ${dir}/*.cpp
      ${dir}/*.asm
      ${extra_patterns}
  )
  file(${globType} header_files ABSOLUTE
      ${dir}/*.h
      ${dir}/*.hpp
      ${extra_patterns}
  )
  file(${globType} extra_files ABSOLUTE
      ${extra_patterns}
  )
  LIST(APPEND ${prefix}_SRCS ${src_files})
  LIST(APPEND ${prefix}_HEADERS ${header_files})
  LIST(APPEND ${prefix}_EXTRA ${extra_files})
  LIST(APPEND ${prefix}_DIRS ${dir})
endmacro()

# Performs searching recursively and adding of files to source list
macro(addFolderRecursive dir prefix)
  addFolder("${dir}" "${prefix}" "" "RECURSIVE")
endmacro()

# add item at the beginning of the list
function(list_prepend var prefix)
  set(listVar "")
  list(APPEND listVar "${prefix}")
  list(APPEND listVar ${${var}})
  list(REMOVE_DUPLICATES listVar)
  set(${var} "${listVar}" PARENT_SCOPE)
endfunction(list_prepend)

# prefer ASCII for folder names
function(force_latin_paths)
  if(WIN32)
    set(force_latin_paths_separator
      ":")
  endif()

  set(force_latin_paths_path_regex
    "^([A-Za-z0-9${force_latin_paths_separator}._/-]+)$")

  if(NOT "${CMAKE_SOURCE_DIR}" MATCHES "${force_latin_paths_path_regex}" OR NOT "${CMAKE_BINARY_DIR}" MATCHES "${force_latin_paths_path_regex}")
      message(FATAL_ERROR
        "Ensure that the source and build paths contain only the following characters: alphanumeric, dash, underscore, slash, dot (and colon on Windows)")
  endif()
endfunction(force_latin_paths)

# out dirs must be not empty
function(validate_out_dirs)
  if (NOT CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY
      ${CMAKE_BINARY_DIR}/arc)
  endif()

  if (NOT CMAKE_LIBRARY_OUTPUT_DIRECTORY)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY
      ${CMAKE_BINARY_DIR}/bin/lib)
  endif()

  if (NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY
      ${CMAKE_BINARY_DIR}/bin)
  endif()
endfunction(validate_out_dirs)

# EXAMPLE:
# validate_out_source_build(FATAL_ERROR)
function(validate_out_source_build _MSG_TYPE)
  if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
    message(${_MSG_TYPE}
      "In-source builds not allowed. \
      Please make a new directory (called a build directory) \
      and run CMake from there.")
  endif()
endfunction(validate_out_source_build)

## ---------------------------- cppcheck -------------------------------- ##

# NOTE: global var.
# cppcheck is not compiler
# and can not define platform-specific defines
# We must do it manually
set(cppcheck_linux_defines
  # Compiler detection
  -D__GNUC__=100
  # Compiler detection
  -DCOMPILER_GCC=1
  -D__WCHAR_MAX__=0x7fffffff
  -D__GNUC_MINOR__=100
  -D__GNUC_PATCHLEVEL__=100
  -D__STDC__=1
  -D__i386__=1
  # Processor architecture detection
  -D__x86_64__=1
  -D__WORDSIZE=64
  # see https://fossies.org/linux/cppcheck/cfg/avr.cfg
  #"-D__CONCATenate(left, right)=left ## right"
  #"-D__CONCAT(left, right)=__CONCATenate(left, right)"
  #"-DUINT32_C(value)=__CONCAT(value, UL)"
  #"-DSB_IS(SB_FEATURE)=((defined SB_IS_##SB_FEATURE) && SB_IS_##SB_FEATURE)"
  -DSB_IS_ARCH_X64=1
  -DSB_IS_ARCH_X86=1
  -DSB_IS_ARCH_ARM=1
  -DSB_IS_32_BIT=1
  -DSB_HAS_1_CORE=1
  #-DSTARBOARD_CONFIGURATION_INCLUDE="starboard/linux/x64x11/configuration_public.h"
  #-DSTARBOARD_ATOMIC_INCLUDE="starboard/linux/x64x11/atomic_public.h"
  #-DSTARBOARD_THREAD_TYPES_INCLUDE="starboard/linux/x64x11/thread_types_public.h"
  -Dlinux=1
  -D__linux__=1
  # chromium/base support
  -DOS_POSIX=1
  # chromium/base support
  -DOS_LINUX=1
  -DULONG_MAX=18446744073709551615U
)

# EXAMPLE:
# find_program_helper("cppcheck-htmlreport"
#   PATHS
#     ${CONAN_BIN_DIRS}
#     ${CONAN_BIN_DIRS_LLVM_TOOLS}
#     # to use `cppcheck-htmlreport` from cmake subfolder
#     ${CMAKE_SOURCE_DIR}/cmake
#     ${CMAKE_CURRENT_SOURCE_DIR}/cmake
#   NO_SYSTEM_ENVIRONMENT_PATH
#   NO_CMAKE_SYSTEM_PATH
#   REQUIRED
#   OUT_VAR CPPCHECK_HTMLREPORT
#   VERBOSE TRUE
#   TEXT "not found"
# )
# NOTE: TEXT must be last argument
function(find_program_helper)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    CHECK_NOT_EMPTY # check: must be not empty
    REQUIRED
  )
  set(oneValueArgs
    VERBOSE
    OUT_VAR
  )
  set(multiValueArgs
    TEXT # text for displayed message
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})
  if(${ARGUMENTS_VERBOSE})
    message(STATUS
      "validate: ARGUMENTS_UNPARSED_ARGUMENTS=${ARGUMENTS_UNPARSED_ARGUMENTS}")
  endif(${ARGUMENTS_VERBOSE})

  # default
  set(TEXT
    "unable to find ${ARGUMENTS_UNPARSED_ARGUMENTS}"
  )
  if(ARGUMENTS_TEXT)
    set(TEXT
      ${ARGUMENTS_TEXT}
    )
  endif(ARGUMENTS_TEXT)

  if("${ARGUMENTS_UNPARSED_ARGUMENTS}" STREQUAL "")
    message(FATAL_ERROR "ARGUMENTS_UNPARSED_ARGUMENTS must be not empty")
  endif()

  # NOTE: cmake cached result of previous find_program,
  # so added `${ARGUMENTS_OUT_VAR}_` before FOUND_PROGRAM
  # to avoid storing result of find_program into cache
  find_program(${ARGUMENTS_OUT_VAR}_FOUND_PROGRAM ${ARGUMENTS_UNPARSED_ARGUMENTS})
  if(ARGUMENTS_REQUIRED AND NOT ${ARGUMENTS_OUT_VAR}_FOUND_PROGRAM)
    message(FATAL_ERROR ${TEXT})
  endif(ARGUMENTS_REQUIRED AND NOT ${ARGUMENTS_OUT_VAR}_FOUND_PROGRAM)
  if(${ARGUMENTS_VERBOSE})
    message(STATUS
      "ARGUMENTS_UNPARSED_ARGUMENTS=${ARGUMENTS_UNPARSED_ARGUMENTS}")
    message(STATUS
      "${ARGUMENTS_OUT_VAR}_FOUND_PROGRAM=${${ARGUMENTS_OUT_VAR}_FOUND_PROGRAM}")
  endif(${ARGUMENTS_VERBOSE})

  set(${ARGUMENTS_OUT_VAR} ${${ARGUMENTS_OUT_VAR}_FOUND_PROGRAM} PARENT_SCOPE)
endfunction(find_program_helper)

function(get_depends_properties RESULT_VARIABLE_NAME TARGET PROPERTIES)
  foreach(PROPERTY ${PROPERTIES})
    set(RESULT_${PROPERTY})
  endforeach()

  get_target_property(_TARGET_TYPE ${TARGET} TYPE)
  if(_TARGET_TYPE STREQUAL "INTERFACE_LIBRARY")
    get_target_property(INTERFACE_LINK_LIBRARIES ${TARGET} INTERFACE_LINK_LIBRARIES)
    if(INTERFACE_LINK_LIBRARIES)
      foreach(INTERFACE_LINK_LIBRARY ${INTERFACE_LINK_LIBRARIES})
        if(TARGET ${INTERFACE_LINK_LIBRARY})
          get_depends_properties(TMP ${INTERFACE_LINK_LIBRARY}
            "${PROPERTIES}")
          foreach(PROPERTY ${PROPERTIES})
            set(RESULT_${PROPERTY}
              ${RESULT_${PROPERTY}}
              ${TMP_${PROPERTY}}
            )
          endforeach()
        endif()
      endforeach()
    endif()
  else()
    get_target_property(LINK_LIBRARIES ${TARGET} LINK_LIBRARIES)
    if(LINK_LIBRARIES)
      foreach(LINK_LIBRARY ${LINK_LIBRARIES})
        if(TARGET ${LINK_LIBRARY})
          get_depends_properties(TMP ${LINK_LIBRARY}
            "${PROPERTIES}")
          foreach(PROPERTY ${PROPERTIES})
            set(RESULT_${PROPERTY}
              ${RESULT_${PROPERTY}}
              ${TMP_${PROPERTY}}
            )
          endforeach()
        endif()
      endforeach()
    endif()
  endif()

  foreach(PROPERTY ${PROPERTIES})
    get_target_property(TMP ${TARGET} ${PROPERTY})
    if(TMP)
      set(RESULT_${PROPERTY}
        ${RESULT_${PROPERTY}}
        ${TMP}
      )
    endif()
    set(${RESULT_VARIABLE_NAME}_${PROPERTY} ${RESULT_${PROPERTY}} PARENT_SCOPE)
  endforeach()
endfunction()

function(get_all_include_directories RESULT_VARIABLE_NAME TARGET)
  #get_depends_properties(RESULT ${TARGET}
  #  "INTERFACE_INCLUDE_DIRECTORIES;INTERFACE_SYSTEM_INCLUDE_DIRECTORIES;INCLUDE_DIRECTORIES;SYSTEM_INCLUDE_DIRECTORIES")
  get_depends_properties(RESULT ${TARGET}
    "INTERFACE_INCLUDE_DIRECTORIES;INTERFACE_SYSTEM_INCLUDE_DIRECTORIES")
  set(RESULT
    ${RESULT}
    ${RESULT_INTERFACE_INCLUDE_DIRECTORIES}
    ${RESULT_INTERFACE_SYSTEM_INCLUDE_DIRECTORIES}
    ${RESULT_INCLUDE_DIRECTORIES}
    ${RESULT_SYSTEM_INCLUDE_DIRECTORIES}
  )

  get_target_property(_TARGET_TYPE ${TARGET} TYPE)

  if(_TARGET_TYPE STREQUAL "INTERFACE_LIBRARY")
    get_target_property(INTERFACE_INCLUDE_DIRECTORIES ${TARGET} INTERFACE_INCLUDE_DIRECTORIES)
    if(INTERFACE_INCLUDE_DIRECTORIES)
      set(RESULT
        ${RESULT}
        ${INTERFACE_INCLUDE_DIRECTORIES}
      )
    endif()
  else()
    get_target_property(INCLUDE_DIRECTORIES ${TARGET} INCLUDE_DIRECTORIES)
    if(INCLUDE_DIRECTORIES)
      set(RESULT
        ${RESULT}
        ${INCLUDE_DIRECTORIES}
      )
    endif()
  endif()
  if(RESULT)
    list(REMOVE_DUPLICATES RESULT)
  endif()
  set(${RESULT_VARIABLE_NAME} ${RESULT} PARENT_SCOPE)
endfunction()

function(get_target_sources RESULT_VARIABLE_NAME TARGET)
  get_target_property(_TARGET_TYPE ${TARGET} TYPE)
  if(NOT _TARGET_TYPE STREQUAL "INTERFACE_LIBRARY")
    get_target_property(RESULT
      ${TARGET} SOURCES
    )
  endif()
  set(${RESULT_VARIABLE_NAME} ${RESULT} PARENT_SCOPE)
endfunction()

function(get_all_compile_definitions RESULT_VARIABLE_NAME TARGET)
  #get_depends_properties(RESULT ${TARGET}
  #  "INTERFACE_COMPILE_DEFINITIONS;COMPILE_DEFINITIONS")
  get_depends_properties(RESULT ${TARGET}
    "INTERFACE_COMPILE_DEFINITIONS")
  set(RESULT
    ${RESULT}
    ${RESULT_INTERFACE_COMPILE_DEFINITIONS}
    ${RESULT_COMPILE_DEFINITIONS}
  )
  get_target_property(COMPILE_DEFINITIONS ${TARGET} COMPILE_DEFINITIONS)
  if(COMPILE_DEFINITIONS)
    set(RESULT
      ${RESULT}
      ${COMPILE_DEFINITIONS}
    )
  endif()
  if(RESULT)
    list(REMOVE_DUPLICATES RESULT)
  endif()
  set(${RESULT_VARIABLE_NAME} ${RESULT} PARENT_SCOPE)
endfunction()

# prepends file path and line number to string
# EXAMPLE:
# FROM_HERE("invalid ...")
# message("${FROM_HERE}")
macro(FROM_HERE _MSG)
  set(FROM_HERE
    "${CMAKE_CURRENT_LIST_FILE}:${CMAKE_CURRENT_LIST_LINE}: ${_MSG}")
endmacro(FROM_HERE)

# EXAMPLE:
# message_if(ARGUMENTS_VERBOSE STATUS
#   "CPPCHECK_HTMLREPORT=${CPPCHECK_HTMLREPORT}"
# )
macro(message_if _CONDITION _MSG_TYPE _MSG)
  if(${_CONDITION})
    message(${_MSG_TYPE} "${_MSG}")
  endif(${_CONDITION})
endmacro(message_if)

# USAGE:
# validate(
#   ${MY_VAR}
#   TYPE FATAL_ERROR
#   CHECK_NOT_EMPTY
#   TEXT "${CMAKE_CURRENT_LIST_FILE}:${CMAKE_CURRENT_LIST_LINE}:"
#        "invalid MY_VAR"
#   VERBOSE TRUE
# )
# NOTE: TEXT must be after ${MY_VAR}
function(validate)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    CHECK_NOT_EMPTY # check: must be not empty
  )
  set(oneValueArgs
    TYPE # may be FATAL_ERROR, STATUS, etc.
    VERBOSE
  )
  set(multiValueArgs
    TEXT # text for displayed message
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})
  if(${ARGUMENTS_VERBOSE})
    message(STATUS
      "validate: ARGUMENTS_UNPARSED_ARGUMENTS=${ARGUMENTS_UNPARSED_ARGUMENTS}")
  endif(${ARGUMENTS_VERBOSE})

  # default
  set(TEXT
    "check failed: invalid ${ARGUMENTS_UNPARSED_ARGUMENTS}"
  )
  if(ARGUMENTS_TEXT)
    set(TEXT
      ${ARGUMENTS_TEXT}
    )
  endif(ARGUMENTS_TEXT)

  # default
  set(TYPE
    FATAL_ERROR
  )
  if(ARGUMENTS_TYPE)
    set(TYPE
      ${ARGUMENTS_TYPE}
    )
  endif(ARGUMENTS_TYPE)

  # check: must be not empty
  if(ARGUMENTS_CHECK_NOT_EMPTY)
    if("${ARGUMENTS_UNPARSED_ARGUMENTS}" STREQUAL "")
      message(${TYPE} ${TEXT})
    endif()
  else()
    message(FATAL_ERROR
      "you must provide at least one validation TYPE"
    )
  endif()
endfunction()

# EXAMPLE (joins defines by -D):
# get_all_compile_definitions(DEFINES_VARIABLE_NAME, TARGET_NAME)
# join_with_separator(DEFINES_VARIABLE_NAME, DEFINES_RESULT, "-D")
function(join_with_separator)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    PATH_MUST_EXIST
  )
  set(oneValueArgs
    START_SEPARATOR
    END_SEPARATOR
    RESULT_VARIABLE_NAME
  )
  set(multiValueArgs
    INPUT
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  foreach(ITEM ${ARGUMENTS_INPUT})
    set({ITEM_WITH_SEPARATOR
      ${ARGUMENTS_START_SEPARATOR}${ITEM}${ARGUMENTS_END_SEPARATOR}
    )
    set(RESULT
      ${RESULT}
      "${ITEM_WITH_SEPARATOR}"
    )
  endforeach()
  set(${ARGUMENTS_RESULT_VARIABLE_NAME} ${RESULT} PARENT_SCOPE)
endfunction()

## ---------------------------- cppcheck -------------------------------- ##

function(add_cppcheck_target)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    # empty
  )
  set(oneValueArgs
    TARGET_NAME
    HTML_REPORT
  )
  set(multiValueArgs
    CPPCHECK_FULL_CMD
    # adds options to default options
    EXTRA_OPTIONS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})

  FROM_HERE("invalid ARGUMENTS_TARGET_NAME")
  validate(CHECK_NOT_EMPTY
    ${ARGUMENTS_TARGET_NAME}
    TEXT "${FROM_HERE}"
  )
  #
  FROM_HERE("invalid ARGUMENTS_CPPCHECK_FULL_CMD")
  validate(CHECK_NOT_EMPTY
    ${ARGUMENTS_CPPCHECK_FULL_CMD}
    TEXT "${FROM_HERE}"
  )
  message_if(ARGUMENTS_VERBOSE STATUS
    "ARGUMENTS_CPPCHECK_FULL_CMD=${ARGUMENTS_CPPCHECK_FULL_CMD}"
  )
  #
  set(CPPCHECK_FULL_CMD
    ${ARGUMENTS_CPPCHECK_FULL_CMD}
    ${ARGUMENTS_EXTRA_OPTIONS}
  )
  if(NOT ${ARGUMENTS_HTML_REPORT} STREQUAL "")
    message_if(ARGUMENTS_VERBOSE STATUS
      "ARGUMENTS_HTML_REPORT=${ARGUMENTS_HTML_REPORT}"
    )
    #
    # NOTE: must be ending argument,
    # uses `2>` to re-route console output
    set(CPPCHECK_FULL_CMD
      ${CPPCHECK_FULL_CMD}
      --xml
      --xml-version=2
      2> ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_cppcheck_report.xml
    )
    set(HTMLREPORT_FULL_CMD
      ${ARGUMENTS_HTML_REPORT}
      --file=${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_cppcheck_report.xml
      --report-dir=${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report
      # directory with explored source
      --source-dir=
      --title=${ARGUMENTS_TARGET_NAME}
    )
  else() # ARGUMENTS_HTML_REPORT
    set(HTMLREPORT_FULL_CMD
      ${CMAKE_COMMAND}
      -E
      echo
      "html report disabled"
    )
  endif() # ARGUMENTS_HTML_REPORT
  if(ARGUMENTS_VERBOSE)
    message(STATUS "cppcheck: HTMLREPORT_FULL_CMD=${HTMLREPORT_FULL_CMD}")
  endif(ARGUMENTS_VERBOSE)
  #
  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_run_cppcheck
  message_if(ARGUMENTS_VERBOSE STATUS
    "ARGUMENTS_TARGET_NAME=${ARGUMENTS_TARGET_NAME}"
  )
  add_custom_target(${ARGUMENTS_TARGET_NAME}_run_cppcheck
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_cppcheck_report.xml
    # create report dir
    COMMAND
      ${CMAKE_COMMAND}
      -E
      make_directory
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report/index.html
    # print command that will be executed
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND
      "${CMAKE_COMMAND}"
      -E
      echo
      "executing command: ${CPPCHECK_FULL_CMD}"
    # Run cppcheck static analysis
    COMMAND
      "${CPPCHECK_FULL_CMD}"
    # print command that will be executed
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND
      "${CMAKE_COMMAND}"
      -E
      echo
      "executing command: ${HTMLREPORT_FULL_CMD}"
    # Generate html output
    COMMAND
      ${CMAKE_COMMAND}
      -E
      time
      "${HTMLREPORT_FULL_CMD}"
    VERBATIM
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND_EXPAND_LISTS
    #USES_TERMINAL
    # Set work directory for target
    WORKING_DIRECTORY
      ${CMAKE_BINARY_DIR}
    # Echo what is being done
    COMMENT "running cppcheck"
  )
endfunction(add_cppcheck_target)

# USAGE:
# cmake -E time cmake --build . --target TARGET_NAME_run_cppcheck
# EXAMPLE:
# cppcheck_enabler(
#   PATHS
#     # to use cppcheck_installer from conan
#     ${CONAN_BIN_DIRS}
#     ${CONAN_BIN_DIRS_LLVM_TOOLS}
#     # to use `cppcheck-htmlreport` from cmake subfolder
#     ${CMAKE_SOURCE_DIR}/cmake
#     ${CMAKE_CURRENT_SOURCE_DIR}/cmake
#   NO_SYSTEM_ENVIRONMENT_PATH
#   NO_CMAKE_SYSTEM_PATH
#   IS_ENABLED
#     ${ENABLE_CPPCHECK}
#   CHECK_TARGETS
#     ${LIB_NAME}
#   EXTRA_OPTIONS
#     --enable=all
#   HTML_REPORT TRUE
#   VERBOSE
# )
# @see https://github.com/cyyever/cmake/blob/master/static_code_analysis.cmake
# @see https://gitlab.cern.ch/Caribou/peary/blob/master/cmake/clang-cpp-checks.cmake
# @see https://github.com/doevelopper/cfs-third-parties/blob/master/src/main/resources/cmake/macros/CPPCheck.cmake
# @see https://habr.com/ru/post/210256/
# NOTE: cppcheck have bug: it does not report errors
# in file if it can not parse that file
# see https://sourceforge.net/p/cppcheck/discussion/general/thread/2a2e3ce6/
function(cppcheck_enabler)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    VERBOSE
    REQUIRED
    # will run check when target will be built
    CHECK_TARGETS_DEPEND
  )
  set(oneValueArgs
    IS_ENABLED
    HTML_REPORT
    STANDALONE_TARGET
  )
  set(multiValueArgs
    # completely changes options to provided options
    OVERRIDE_OPTIONS
    # adds options to default options
    EXTRA_OPTIONS
    # Will collect include dirs, defines and source files
    # from cmake targets
    # NOTE: Why not compile_commands.json?
    # - cmake can not generate that file on per-target basis
    # or into custom out dir
    # NOTE: Why not CMAKE_CXX_CPPCHECK?
    # - we want to run custom cppcheck target without
    # need to build whole poject per each check
    CHECK_TARGETS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})
  #
  # default options
  #
  # Set cppcheck supressions file.
  # This file must contain enough suppressions to result in no cppcheck warnings
  # see for example usage https://gitlab.kitware.com/vtk/vtk/blob/master/CMake/VTKcppcheckSuppressions.txt
  #
  # EXAMPLE FILE CONTENTS:
  #
  # // system libs
  # *:*/usr/include/*
  # *:/usr/local/*
  #
  # // Gives too many false positives.
  # unmatchedSuppression
  #
  # // False positives
  # syntaxError:*my_types.hpp
  # syntaxError:*my_conf.hpp
  set(CPPCHECK_SUPRESSIONS
    ${PROJECT_SOURCE_DIR}/cmake/cppcheck.cfg
  )
  # set supressions file only if it exists
  if(EXISTS "${CPPCHECK_SUPRESSIONS}")
    set(CPPCHECK_DEFAULT_SUPRESSIONS_ARG
      --suppressions-list=${CPPCHECK_SUPRESSIONS}
    )
    message_if(ARGUMENTS_VERBOSE STATUS
      "found cppcheck config file: ${CPPCHECK_SUPRESSIONS}"
    )
  else()
    message_if(ARGUMENTS_VERBOSE WARNING
      "unable to find cppcheck config file: ${CPPCHECK_SUPRESSIONS}"
    )
  endif()
  # Set message template
  set(CPPCHECK_TEMPLATE
    "[{file}:{line}] ({severity}) {message} ({id}) ({callstack})"
  )
  # Set cppcheck cache directory
  set(CPPCHECK_BUILD_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/cppcheck_cache
  )
  #
  set(CPPCHECK_OPTIONS
    #--enable=warning,performance,portability,information,missingInclude
    #--enable=all
    # more info in console
    --verbose
    # less info in console
    #--quiet
    # require well formed path for headers
    # NOTE: The normal code analysis is disabled by check-config.
    #--check-config
    # check all #ifdef
    #--force
    # see CMAKE_EXPORT_COMPILE_COMMANDS
    #--project=${CMAKE_BINARY_DIR}/compile_commands.json
    # Enable inline suppressions.
    # Use them by placing comments in the form:
    # // cppcheck-suppress memleak
    # before the line to suppress.
    --inline-suppr
    --platform=native
    --cppcheck-build-dir=${CPPCHECK_BUILD_DIR}
    --template="${CPPCHECK_TEMPLATE}"
    ${CPPCHECK_DEFAULT_SUPRESSIONS_ARG}
    --report-progress
    #--language=c++ #
    --library=std.cfg
    --library=posix.cfg
    --library=qt.cfg
    --library=boost.cfg
    #--error-exitcode=1
  )
  if(ARGUMENTS_OVERRIDE_OPTIONS)
    set(CPPCHECK_OPTIONS ${ARGUMENTS_OVERRIDE_OPTIONS})
  else()
    message_if(ARGUMENTS_VERBOSE STATUS
      "cppcheck: no OVERRIDE_OPTIONS provided"
    )
    # skip, use defaults
  endif()
  #
  list(APPEND CPPCHECK_OPTIONS ${ARGUMENTS_EXTRA_OPTIONS})
  message_if(ARGUMENTS_VERBOSE STATUS
    "ARGUMENTS_EXTRA_OPTIONS=${ARGUMENTS_EXTRA_OPTIONS}"
  )
  #
  if(${ARGUMENTS_IS_ENABLED})
    message_if(ARGUMENTS_VERBOSE STATUS
      "cppcheck enabled"
    )

    # to use `cppcheck` from conan
    list(APPEND CMAKE_PROGRAM_PATH ${CONAN_BIN_DIRS})

    # use cppcheck_installer from conan
    find_program_helper(cppcheck
      #PATHS
      #  ${CONAN_BIN_DIRS}
      #  ${CONAN_BIN_DIRS_LLVM_TOOLS}
      #NO_SYSTEM_ENVIRONMENT_PATH
      #NO_CMAKE_SYSTEM_PATH
      ${ARGUMENTS_UNPARSED_ARGUMENTS}
      REQUIRED
      OUT_VAR CPPCHECK_PROGRAM
      VERBOSE TRUE
    )

    message_if(ARGUMENTS_VERBOSE STATUS
      "ARGUMENTS_HTML_REPORT=${ARGUMENTS_HTML_REPORT}"
    )

    if(${ARGUMENTS_HTML_REPORT})
      list(APPEND CPPCHECK_OPTIONS
        --xml
        --xml-version=2
      )
    endif(${ARGUMENTS_HTML_REPORT})

    if(CPPCHECK_PROGRAM)
      # Create cppcheck cache directory
      file(MAKE_DIRECTORY ${CPPCHECK_BUILD_DIR})

      # Set cppcheck program + options.
      list(APPEND CPPCHECK_RUNNABLE
        ${CPPCHECK_PROGRAM}
      )

      message_if(ARGUMENTS_VERBOSE STATUS
        "CPPCHECK_RUNNABLE=${CPPCHECK_RUNNABLE}"
      )

      if(${ARGUMENTS_HTML_REPORT})
        # to use `cppcheck-htmlreport` from cmake subfolder
        list(APPEND CMAKE_PROGRAM_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
        list(APPEND CMAKE_PROGRAM_PATH ${CMAKE_SOURCE_DIR}/cmake)
        #
        find_program_helper("cppcheck-htmlreport"
          PATHS
            #${CONAN_BIN_DIRS}
            #${CONAN_BIN_DIRS_LLVM_TOOLS}
            ## to use `cppcheck-htmlreport` from cmake subfolder
            #${CMAKE_SOURCE_DIR}/cmake
            #${CMAKE_CURRENT_SOURCE_DIR}/cmake
            ${ARGUMENTS_UNPARSED_ARGUMENTS}
          NO_SYSTEM_ENVIRONMENT_PATH
          NO_CMAKE_SYSTEM_PATH
          REQUIRED
          OUT_VAR CPPCHECK_HTMLREPORT
          VERBOSE TRUE
        )
      else()
        set(CPPCHECK_HTMLREPORT "")
      endif(${ARGUMENTS_HTML_REPORT})

      if(ARGUMENTS_VERBOSE)
        message(STATUS "cppcheck: CPPCHECK_HTMLREPORT=${CPPCHECK_HTMLREPORT}")
      endif(ARGUMENTS_VERBOSE)

      # create separate target for cppcheck
      if(ARGUMENTS_STANDALONE_TARGET)
        add_cppcheck_target(
          TARGET_NAME ${ARGUMENTS_STANDALONE_TARGET}
          CPPCHECK_FULL_CMD
            ${CPPCHECK_RUNNABLE}
          HTML_REPORT ${CPPCHECK_HTMLREPORT}
          EXTRA_OPTIONS ${CPPCHECK_OPTIONS}
        )
      endif(ARGUMENTS_STANDALONE_TARGET)

      # collect headers and defines from existing target
      if(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "cppcheck: ARGUMENTS_CHECK_TARGETS=${ARGUMENTS_CHECK_TARGETS}")
        endif(ARGUMENTS_VERBOSE)
        foreach(TARGET_NAME ${ARGUMENTS_CHECK_TARGETS})
          if(ARGUMENTS_VERBOSE)
            message(STATUS "enabled cppcheck for target ${TARGET_NAME}")
          endif(ARGUMENTS_VERBOSE)
          #
          get_all_compile_definitions(collected_defines
            ${TARGET_NAME}
          )
          #
          get_all_include_directories(collected_includes
            ${TARGET_NAME}
          )
          #
          get_target_sources(TARGET_SOURCES
            ${TARGET_NAME}
          )
          #
          add_cppcheck_target(
            TARGET_NAME ${TARGET_NAME}
            CPPCHECK_FULL_CMD
              ${CPPCHECK_RUNNABLE}
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              $<$<BOOL:${collected_defines}>:-D$<JOIN:${collected_defines}, -D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              $<$<BOOL:${collected_includes}>:-I$<JOIN:${collected_includes}, -I>>
              ${TARGET_SOURCES}
            HTML_REPORT ${CPPCHECK_HTMLREPORT}
            EXTRA_OPTIONS ${CPPCHECK_OPTIONS}
          )
          if(CHECK_TARGETS_DEPEND)
            # run valgrind on each build of target
            add_dependencies(
              ${TARGET_NAME}
              ${TARGET_NAME}_run_cppcheck
            )
          endif(CHECK_TARGETS_DEPEND)
        endforeach()
      else(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "cppcheck: no CHECK_TARGETS provided")
        endif(ARGUMENTS_VERBOSE)
      endif(ARGUMENTS_CHECK_TARGETS)
    else(CPPCHECK_PROGRAM)
      message(WARNING "Program 'cppcheck' not found, unable to run 'cppcheck'.")
    endif(CPPCHECK_PROGRAM)
  else() # ARGUMENTS_IS_ENABLED
    if(ARGUMENTS_VERBOSE)
      message(STATUS "cppcheck disabled")
    endif(ARGUMENTS_VERBOSE)
  endif() # ARGUMENTS_IS_ENABLED
endfunction(cppcheck_enabler)

## ---------------------------- valgrind -------------------------------- ##

# see https://valgrind.org/docs/manual/QuickStart.html
function(add_valgrind_target)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    # empty
  )
  set(oneValueArgs
    TARGET_NAME
  )
  set(multiValueArgs
    MEMORYCHECK_FULL_CMD
    # adds options to default options
    EXTRA_OPTIONS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})

  FROM_HERE("invalid ARGUMENTS_TARGET_NAME")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_TARGET_NAME}
    TEXT "${FROM_HERE}"
  )
  #
  FROM_HERE("invalid ARGUMENTS_MEMORYCHECK_FULL_CMD")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_MEMORYCHECK_FULL_CMD}
    TEXT "${FROM_HERE}"
  )
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_MEMORYCHECK_FULL_CMD=${ARGUMENTS_MEMORYCHECK_FULL_CMD}")
  endif(ARGUMENTS_VERBOSE)
  #
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_HTML_REPORT=${ARGUMENTS_HTML_REPORT}")
  endif(ARGUMENTS_VERBOSE)
  #
  set(MEMORYCHECK_FULL_CMD
    ${ARGUMENTS_MEMORYCHECK_FULL_CMD}
    ${ARGUMENTS_EXTRA_OPTIONS}
  )
  #
  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_run_valgrind
  if(ARGUMENTS_VERBOSE)
    message(STATUS "added new target: ${ARGUMENTS_TARGET_NAME}_run_valgrind")
  endif(ARGUMENTS_VERBOSE)
  add_custom_target(${ARGUMENTS_TARGET_NAME}_run_valgrind
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_valgrind_report.xml
    # print command that will be executed
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND
      "${CMAKE_COMMAND}"
      -E
      echo
      "executing command: ${MEMORYCHECK_FULL_CMD}"
    # Run valgrind static analysis
    COMMAND
      "${MEMORYCHECK_FULL_CMD}"
    VERBATIM
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND_EXPAND_LISTS
    #USES_TERMINAL
    # Set work directory for target
    WORKING_DIRECTORY
      ${CMAKE_BINARY_DIR}
    # Echo what is being done
    COMMENT "running valgrind"
  )
endfunction(add_valgrind_target)

# USAGE:
# cmake -E time cmake --build . --target TARGET_NAME_run_valgrind
# EXAMPLE:
# valgrind_enabler(
#  IS_ENABLED
#    ${ENABLE_VALGRIND}
#  STANDALONE_TARGET
#    ${LIB_NAME}
#  EXTRA_OPTIONS
#    # see https://valgrind.org/docs/manual/manual-core.html
#    # When enabled, Valgrind will trace into sub-processes
#    # initiated via the exec system call.
#    # This is necessary for multi-process programs.
#    --trace-children=yes
#    # --leak-check=full:
#    # each individual leak will be shown in detail
#    --leak-check=full
#    # --show-leak-kinds=all:
#    # Show all of "definite, indirect, possible, reachable"
#    # leak kinds in the "full" report.
#    --show-leak-kinds=all
#    # --track-origins=yes:
#    # Favor useful output over speed.
#    # This tracks the origins of uninitialized values,
#    # which could be very useful for memory errors.
#    # Consider turning off if Valgrind is unacceptably slow.
#    # valgrind is good at spotting the use of uninitialized values
#    # use option --track-origins=yes to show where these originated from.
#    --track-origins=yes
#    # --verbose:
#    # Can tell you about unusual behavior of your program.
#    # Repeat for more verbosity.
#    --verbose
#    --show-reachable=yes
#    # When enabled, Valgrind stops reporting errors
#    # after 10,000,000 in total, or 1,000 different ones,
#    # have been seen.
#    --error-limit=yes
#    # is option is particularly useful with C++ programs,
#    # as it prints out the suppressions with mangled names,
#    # as required.
#    --gen-suppressions=all
#    # Write to a file.
#    # Useful when output exceeds terminal space.
#    --log-file=${CMAKE_CURRENT_BINARY_DIR}/${LIB_NAME}_valgrind_raw.log
#    # executable
#    $<TARGET_FILE:${LIB_NAME}>
#    # arguments of executable
#    --version
#   VERBOSE
# )
# @see https://habr.com/ru/post/210256/
function(valgrind_enabler)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    VERBOSE
    REQUIRED
  )
  set(oneValueArgs
    IS_ENABLED
    STANDALONE_TARGET
  )
  set(multiValueArgs
    # completely changes options to provided options
    OVERRIDE_OPTIONS
    # adds options to default options
    EXTRA_OPTIONS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})

  set(MEMORYCHECK_SUPRESSIONS
    ${PROJECT_SOURCE_DIR}/cmake/valgrind.cfg
  )

  # see https://valgrind.org/docs/manual/manual-core.html
  # see https://wiki.wxwidgets.org/Valgrind_Suppression_File_Howto
  # set supressions file only if it exists
  if(EXISTS "${MEMORYCHECK_SUPRESSIONS}")
    set(MEMORYCHECK_DEFAULT_SUPRESSIONS_ARG
      --suppressions=${MEMORYCHECK_SUPRESSIONS}
    )
    message_if(ARGUMENTS_VERBOSE STATUS
      "found valgrind config file: ${CPPCHECK_SUPRESSIONS}"
    )
  else()
    message_if(ARGUMENTS_VERBOSE WARNING
      "unable to find valgrind config file: ${CPPCHECK_SUPRESSIONS}"
    )
  endif()

  #
  # default options
  #
  set(MEMORYCHECK_OPTIONS
    ${MEMORYCHECK_DEFAULT_SUPRESSIONS_ARG}
  )

  if(ARGUMENTS_OVERRIDE_OPTIONS)
    set(MEMORYCHECK_OPTIONS ${ARGUMENTS_OVERRIDE_OPTIONS})
  else()
    if(ARGUMENTS_VERBOSE)
      message(STATUS "valgrind: no OVERRIDE_OPTIONS provided")
    endif(ARGUMENTS_VERBOSE)
    # skip, use defaults
  endif()
  #
  list(APPEND MEMORYCHECK_OPTIONS ${ARGUMENTS_EXTRA_OPTIONS})
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_EXTRA_OPTIONS=${ARGUMENTS_EXTRA_OPTIONS}")
  endif(ARGUMENTS_VERBOSE)
  #
  if(${ARGUMENTS_IS_ENABLED})
    message(STATUS "valgrind enabled")

    # to use `valgrind` from conan
    list(APPEND CMAKE_PROGRAM_PATH ${CONAN_BIN_DIRS})

    find_program_helper(valgrind
      #PATHS
      #  ${CONAN_BIN_DIRS}
      #  ${CONAN_BIN_DIRS_LLVM_TOOLS}
      #NO_SYSTEM_ENVIRONMENT_PATH
      #NO_CMAKE_SYSTEM_PATH
      ${ARGUMENTS_UNPARSED_ARGUMENTS}
      REQUIRED
      OUT_VAR CMAKE_MEMORYCHECK_COMMAND
      VERBOSE TRUE
    )

    if(CMAKE_MEMORYCHECK_COMMAND)
      # Set valgrind program + options.
      list(APPEND MEMORYCHECK_RUNNABLE
        ${CMAKE_MEMORYCHECK_COMMAND}
      )
      if(ARGUMENTS_VERBOSE)
        message(STATUS "MEMORYCHECK_RUNNABLE=${MEMORYCHECK_RUNNABLE}")
      endif(ARGUMENTS_VERBOSE)

      # create separate target for valgrind
      if(ARGUMENTS_STANDALONE_TARGET)
        add_valgrind_target(
          TARGET_NAME ${ARGUMENTS_STANDALONE_TARGET}
          MEMORYCHECK_FULL_CMD ${MEMORYCHECK_RUNNABLE}
          EXTRA_OPTIONS ${MEMORYCHECK_OPTIONS}
        )
      endif(ARGUMENTS_STANDALONE_TARGET)

    else(CMAKE_MEMORYCHECK_COMMAND)
      message(WARNING "Program 'valgrind' not found, unable to run 'valgrind'.")
    endif(CMAKE_MEMORYCHECK_COMMAND)
  else() # ARGUMENTS_IS_ENABLED
    if(ARGUMENTS_VERBOSE)
      message(STATUS "valgrind disabled")
    endif(ARGUMENTS_VERBOSE)
  endif() # ARGUMENTS_IS_ENABLED
endfunction(valgrind_enabler)

macro(check_valgrind_config)
  if(NOT CMAKE_BUILD_TYPE MATCHES "Debug" )
  message(FATAL_ERROR "valgrind require Debug build."
    " Current CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
  endif() # NOT CMAKE_BUILD_TYPE MATCHES "Debug"

  # If you have access to Linux on a common CPU type
  # or supported versions of OS X you can use valgrind
  if (NOT UNIX)
  message(FATAL_ERROR "Unsupported operating system."
  " Only Unix systems can use valgrind.")
  endif (NOT UNIX)

  # Set compiler flags
  set(CMAKE_C_FLAGS
    "${CMAKE_C_FLAGS} \
    -DVALGRIND=1 \
    -g -O0 \
    -fPIC \
    -fPIE \
    -fno-elide-constructors \
    -fno-optimize-sibling-calls \
    -fno-omit-frame-pointer \
    -fno-stack-protector")

    # Set compiler flags
    set(CMAKE_CXX_FLAGS
      "${CMAKE_CXX_FLAGS} \
      -DVALGRIND=1 \
      -g -O0 \
      -fPIC \
      -fPIE \
      -fno-elide-constructors \
      -fno-optimize-sibling-calls \
      -fno-omit-frame-pointer \
      -fno-stack-protector")
endmacro(check_valgrind_config)

## ---------------------------- clang_tidy -------------------------------- ##

function(add_clang_tidy_target)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    # empty
  )
  set(oneValueArgs
    TARGET_NAME
  )
  set(multiValueArgs
    CLANG_TIDY_FULL_CMD
    # adds options to default options
    EXTRA_OPTIONS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})

  FROM_HERE("invalid ARGUMENTS_TARGET_NAME")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_TARGET_NAME}
    TEXT "${FROM_HERE}"
  )

  #
  FROM_HERE("invalid ARGUMENTS_CLANG_TIDY_FULL_CMD")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_CLANG_TIDY_FULL_CMD}
    TEXT ${FROM_HERE}
  )
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_CLANG_TIDY_FULL_CMD=${ARGUMENTS_CLANG_TIDY_FULL_CMD}")
  endif(ARGUMENTS_VERBOSE)
  #
  set(CLANG_TIDY_FULL_CMD
    ${ARGUMENTS_CLANG_TIDY_FULL_CMD}
    ${ARGUMENTS_EXTRA_OPTIONS}
  )
  #
  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_run_clang_tidy
  if(ARGUMENTS_VERBOSE)
    message(STATUS "added new target: ${ARGUMENTS_TARGET_NAME}_run_clang_tidy")
  endif(ARGUMENTS_VERBOSE)
  add_custom_target(${ARGUMENTS_TARGET_NAME}_run_clang_tidy
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_clang_tidy_report.xml
    # create report dir
    COMMAND
      ${CMAKE_COMMAND}
      -E
      make_directory
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report/index.html
    # print command that will be executed
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND
      "${CMAKE_COMMAND}"
      -E
      echo
      "executing command: ${CLANG_TIDY_FULL_CMD}"
    # Run clang_tidy static analysis
    COMMAND
      "${CLANG_TIDY_FULL_CMD}"
    VERBATIM
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND_EXPAND_LISTS
    #USES_TERMINAL
    # Set work directory for target
    WORKING_DIRECTORY
      ${CMAKE_BINARY_DIR}
    # Echo what is being done
    COMMENT "running clang_tidy"
  )
endfunction(add_clang_tidy_target)

# USAGE:
# cmake -E time cmake --build . --target TARGET_NAME_run_clang_tidy
# EXAMPLE:
# clang_tidy_enabler(
#   PATHS
#     ${CONAN_BIN_DIRS}
#     ${CONAN_BIN_DIRS_LLVM_TOOLS}
#   NO_SYSTEM_ENVIRONMENT_PATH
#   NO_CMAKE_SYSTEM_PATH
#   IS_ENABLED
#     ${ENABLE_CLANG_TIDY}
#   CHECK_TARGETS
#     ${LIB_NAME}
#   EXTRA_OPTIONS
#    # see clang-tidy --list-checks -checks='*' | grep "modernize"
#    # see list of clang-tidy checks:
#    # https://clang.llvm.org/extra/clang-tidy/checks/list.html
#    -checks=*
#    -extra-arg=-std=c++17
#    -extra-arg=-Qunused-arguments
#    -extra-arg=-DBOOST_SYSTEM_NO_DEPRECATED
#    -extra-arg=-DBOOST_ERROR_CODE_HEADER_ONLY
#    -header-filter=${CMAKE_CURRENT_SOURCE_DIR}
#    -warnings-as-errors=cppcoreguidelines-avoid-goto
#   VERBOSE
# )
function(clang_tidy_enabler)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    VERBOSE
    REQUIRED
    # will run check when target will be built
    CHECK_TARGETS_DEPEND
  )
  set(oneValueArgs
    IS_ENABLED
    STANDALONE_TARGET
  )
  set(multiValueArgs
    # completely changes options to provided options
    OVERRIDE_OPTIONS
    # adds options to default options
    EXTRA_OPTIONS
    # Will collect include dirs, defines and source files
    # from cmake targets
    # NOTE: Why not compile_commands.json?
    # - cmake can not generate that file on per-target basis
    # or into custom out dir
    # NOTE: Why not CMAKE_CXX_CLANG_TIDY?
    # - we want to run custom clang_tidy target without
    # need to build whole poject per each check
    CHECK_TARGETS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})
  #
  # default options
  #
  # TODO
  #set(CLANG_TIDY_SUPRESSIONS
  #  ${PROJECT_SOURCE_DIR}/cmake/clang_tidy.cfg
  #)
  ## set supressions file only if it exists
  #if(EXISTS "${CLANG_TIDY_SUPRESSIONS}")
  #  set(CLANG_TIDY_DEFAULT_SUPRESSIONS_ARG
  #    --suppressions-list=${CLANG_TIDY_SUPRESSIONS}
  #  )
  #  message(STATUS
  #    "found clang_tidy config file: ${CLANG_TIDY_SUPRESSIONS}"
  #  )
  #else()
  #  message(WARNING
  #    "unable to find clang_tidy config file: ${CLANG_TIDY_SUPRESSIONS}"
  #  )
  #endif()
  # Set message template
  # TODO
  #set(CLANG_TIDY_TEMPLATE
  #  "[{file}:{line}] ({severity}) {message} ({id}) ({callstack})"
  #)
  # Set clang_tidy cache directory
  set(CLANG_TIDY_BUILD_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/clang_tidy_cache
  )
  #
  set(CLANG_TIDY_OPTIONS
    # more info in console
    #--verbose
  )
  if(ARGUMENTS_OVERRIDE_OPTIONS)
    set(CLANG_TIDY_OPTIONS ${ARGUMENTS_OVERRIDE_OPTIONS})
  else()
    if(ARGUMENTS_VERBOSE)
      message(STATUS "clang_tidy: no OVERRIDE_OPTIONS provided")
    endif(ARGUMENTS_VERBOSE)
    # skip, use defaults
  endif()
  #
  list(APPEND CLANG_TIDY_OPTIONS ${ARGUMENTS_EXTRA_OPTIONS})
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_EXTRA_OPTIONS=${ARGUMENTS_EXTRA_OPTIONS}")
  endif(ARGUMENTS_VERBOSE)
  #
  if(${ARGUMENTS_IS_ENABLED})
    message(STATUS "clang-tidy enabled")

    # to use `clang_tidy` from conan
    list(APPEND CMAKE_PROGRAM_PATH ${CONAN_BIN_DIRS})

    find_program_helper(clang-tidy
      #PATHS
      #  ${CONAN_BIN_DIRS}
      #  ${CONAN_BIN_DIRS_LLVM_TOOLS}
      #NO_SYSTEM_ENVIRONMENT_PATH
      #NO_CMAKE_SYSTEM_PATH
      ${ARGUMENTS_UNPARSED_ARGUMENTS}
      REQUIRED
      OUT_VAR CLANG_TIDY_PROGRAM
      VERBOSE TRUE
    )

    if(CLANG_TIDY_PROGRAM)
      # Create clang_tidy cache directory
      file(MAKE_DIRECTORY ${CLANG_TIDY_BUILD_DIR})

      # Set clang_tidy program + options.
      list(APPEND CLANG_TIDY_RUNNABLE
        ${CLANG_TIDY_PROGRAM}
      )
      if(ARGUMENTS_VERBOSE)
        message(STATUS "CLANG_TIDY_RUNNABLE=${CLANG_TIDY_RUNNABLE}")
      endif(ARGUMENTS_VERBOSE)

      # create separate target for clang_tidy
      if(ARGUMENTS_STANDALONE_TARGET)
        add_clang_tidy_target(
          TARGET_NAME ${ARGUMENTS_STANDALONE_TARGET}
          CLANG_TIDY_FULL_CMD
            ${CLANG_TIDY_RUNNABLE}
          EXTRA_OPTIONS ${CLANG_TIDY_OPTIONS}
        )
      endif(ARGUMENTS_STANDALONE_TARGET)

      # collect headers and defines from existing target
      if(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "clang_tidy: ARGUMENTS_CHECK_TARGETS=${ARGUMENTS_CHECK_TARGETS}")
        endif(ARGUMENTS_VERBOSE)
        foreach(TARGET_NAME ${ARGUMENTS_CHECK_TARGETS})
          if(ARGUMENTS_VERBOSE)
            message(STATUS "enabled clang_tidy for target ${TARGET_NAME}")
          endif(ARGUMENTS_VERBOSE)
          #
          get_all_compile_definitions(collected_defines
            ${TARGET_NAME}
          )
          #
          get_all_include_directories(collected_includes
            ${TARGET_NAME}
          )
          #
          get_target_sources(TARGET_SOURCES
            ${TARGET_NAME}
          )
          #
          add_clang_tidy_target(
            TARGET_NAME ${TARGET_NAME}
            CLANG_TIDY_FULL_CMD
              ${CLANG_TIDY_RUNNABLE}
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              $<$<BOOL:${collected_defines}>:-extra-arg=-D$<JOIN:${collected_defines}, -extra-arg=-D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              # To suppress compiler diagnostic messages
              # from third-party headers just use -isystem
              # instead of -I to include those headers.
              $<$<BOOL:${collected_includes}>:-extra-arg=-isystem$<JOIN:${collected_includes}, -extra-arg=-isystem>>
              ${TARGET_SOURCES}
            EXTRA_OPTIONS ${CLANG_TIDY_OPTIONS}
          )
          if(CHECK_TARGETS_DEPEND)
            # run clang-tidy on each build of target
            add_dependencies(
              ${TARGET_NAME}
              ${TARGET_NAME}_run_clang_tidy
            )
          endif(CHECK_TARGETS_DEPEND)
        endforeach()
      else(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "clang_tidy: no CHECK_TARGETS provided")
        endif(ARGUMENTS_VERBOSE)
      endif(ARGUMENTS_CHECK_TARGETS)
    else(CLANG_TIDY_PROGRAM)
      message(WARNING "Program 'clang_tidy' not found, unable to run 'clang_tidy'.")
    endif(CLANG_TIDY_PROGRAM)
  else() # ARGUMENTS_IS_ENABLED
    if(ARGUMENTS_VERBOSE)
      message(STATUS "clang_tidy disabled")
    endif(ARGUMENTS_VERBOSE)
  endif() # ARGUMENTS_IS_ENABLED
endfunction(clang_tidy_enabler)

## ---------------------------- cppclean -------------------------------- ##

function(add_cppclean_target)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    # empty
  )
  set(oneValueArgs
    TARGET_NAME
  )
  set(multiValueArgs
    CPPCLEAN_FULL_CMD
    # adds options to default options
    EXTRA_OPTIONS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})

  FROM_HERE("invalid ARGUMENTS_TARGET_NAME")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_TARGET_NAME}
    TEXT "${FROM_HERE}"
  )

  #
  FROM_HERE("invalid ARGUMENTS_CPPCLEAN_FULL_CMD")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_CPPCLEAN_FULL_CMD}
    TEXT ${FROM_HERE}
  )
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_CPPCLEAN_FULL_CMD=${ARGUMENTS_CPPCLEAN_FULL_CMD}")
  endif(ARGUMENTS_VERBOSE)
  #
  set(CPPCLEAN_FULL_CMD
    ${ARGUMENTS_CPPCLEAN_FULL_CMD}
    ${ARGUMENTS_EXTRA_OPTIONS}
  )
  #
  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_run_cppclean
  if(ARGUMENTS_VERBOSE)
    message(STATUS "added new target: ${ARGUMENTS_TARGET_NAME}_run_cppclean")
  endif(ARGUMENTS_VERBOSE)
  add_custom_target(${ARGUMENTS_TARGET_NAME}_run_cppclean
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_cppclean_report.xml
    # create report dir
    COMMAND
      ${CMAKE_COMMAND}
      -E
      make_directory
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report/index.html
    # print command that will be executed
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND
      "${CMAKE_COMMAND}"
      -E
      echo
      "executing command: ${CPPCLEAN_FULL_CMD}"
    # Run cppclean static analysis
    COMMAND
      "${CPPCLEAN_FULL_CMD}"
    VERBATIM
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND_EXPAND_LISTS
    #USES_TERMINAL
    # Set work directory for target
    WORKING_DIRECTORY
      ${CMAKE_BINARY_DIR}
    # Echo what is being done
    COMMENT "running cppclean"
  )
endfunction(add_cppclean_target)

# USAGE:
# cmake -E time cmake --build . --target TARGET_NAME_run_cppclean
# EXAMPLE:
# cppclean_enabler(
#   PATHS
#     ${CONAN_BIN_DIRS}
#     ${CONAN_BIN_DIRS_LLVM_TOOLS}
#   NO_SYSTEM_ENVIRONMENT_PATH
#   NO_CMAKE_SYSTEM_PATH
#   IS_ENABLED
#     ${ENABLE_CPPCLEAN}
#   CHECK_TARGETS
#     ${LIB_NAME}
#   EXTRA_OPTIONS
#    --include-path=allergies
#    allergies/allergies.h
#    allergies/allergies.cpp
#   VERBOSE
# )
function(cppclean_enabler)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    VERBOSE
    REQUIRED
    # will run check when target will be built
    CHECK_TARGETS_DEPEND
  )
  set(oneValueArgs
    IS_ENABLED
    STANDALONE_TARGET
  )
  set(multiValueArgs
    # completely changes options to provided options
    OVERRIDE_OPTIONS
    # adds options to default options
    EXTRA_OPTIONS
    # Will collect include dirs, defines and source files
    # from cmake targets
    # NOTE: Why not compile_commands.json?
    # - cmake can not generate that file on per-target basis
    # or into custom out dir
    # NOTE: Why not CMAKE_CXX_CPPCLEAN?
    # - we want to run custom cppclean target without
    # need to build whole poject per each check
    CHECK_TARGETS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})
  #
  # default options
  #
  # TODO
  #set(CPPCLEAN_SUPRESSIONS
  #  ${PROJECT_SOURCE_DIR}/cmake/cppclean.cfg
  #)
  ## set supressions file only if it exists
  #if(EXISTS "${CPPCLEAN_SUPRESSIONS}")
  #  set(CPPCLEAN_DEFAULT_SUPRESSIONS_ARG
  #    --suppressions-list=${CPPCLEAN_SUPRESSIONS}
  #  )
  #  message(STATUS
  #    "found cppclean config file: ${CPPCLEAN_SUPRESSIONS}"
  #  )
  #else()
  #  message(WARNING
  #    "unable to find cppclean config file: ${CPPCLEAN_SUPRESSIONS}"
  #  )
  #endif()
  # Set message template
  # TODO
  #set(CPPCLEAN_TEMPLATE
  #  "[{file}:{line}] ({severity}) {message} ({id}) ({callstack})"
  #)
  # Set cppclean cache directory
  set(CPPCLEAN_BUILD_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/cppclean_cache
  )
  #
  set(CPPCLEAN_OPTIONS
    # more info in console
    #--verbose
  )
  if(ARGUMENTS_OVERRIDE_OPTIONS)
    set(CPPCLEAN_OPTIONS ${ARGUMENTS_OVERRIDE_OPTIONS})
  else()
    if(ARGUMENTS_VERBOSE)
      message(STATUS "cppclean: no OVERRIDE_OPTIONS provided")
    endif(ARGUMENTS_VERBOSE)
    # skip, use defaults
  endif()
  #
  list(APPEND CPPCLEAN_OPTIONS ${ARGUMENTS_EXTRA_OPTIONS})
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_EXTRA_OPTIONS=${ARGUMENTS_EXTRA_OPTIONS}")
  endif(ARGUMENTS_VERBOSE)
  #
  if(${ARGUMENTS_IS_ENABLED})
    message(STATUS "cppclean enabled")

    # to use `cppclean` from conan
    list(APPEND CMAKE_PROGRAM_PATH ${CONAN_BIN_DIRS})

    find_program_helper(cppclean
      #PATHS
      #  ${CONAN_BIN_DIRS}
      #  ${CONAN_BIN_DIRS_LLVM_TOOLS}
      #NO_SYSTEM_ENVIRONMENT_PATH
      #NO_CMAKE_SYSTEM_PATH
      ${ARGUMENTS_UNPARSED_ARGUMENTS}
      REQUIRED
      OUT_VAR CPPCLEAN_PROGRAM
      VERBOSE TRUE
    )

    if(CPPCLEAN_PROGRAM)
      # Create cppclean cache directory
      file(MAKE_DIRECTORY ${CPPCLEAN_BUILD_DIR})

      # Set cppclean program + options.
      list(APPEND CPPCLEAN_RUNNABLE
        ${CPPCLEAN_PROGRAM}
      )
      if(ARGUMENTS_VERBOSE)
        message(STATUS "CPPCLEAN_RUNNABLE=${CPPCLEAN_RUNNABLE}")
      endif(ARGUMENTS_VERBOSE)

      # create separate target for cppclean
      if(ARGUMENTS_STANDALONE_TARGET)
        add_cppclean_target(
          TARGET_NAME ${ARGUMENTS_STANDALONE_TARGET}
          CPPCLEAN_FULL_CMD
            ${CPPCLEAN_RUNNABLE}
          EXTRA_OPTIONS ${CPPCLEAN_OPTIONS}
        )
      endif(ARGUMENTS_STANDALONE_TARGET)

      # collect headers and defines from existing target
      if(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "cppclean: ARGUMENTS_CHECK_TARGETS=${ARGUMENTS_CHECK_TARGETS}")
        endif(ARGUMENTS_VERBOSE)
        foreach(TARGET_NAME ${ARGUMENTS_CHECK_TARGETS})
          if(ARGUMENTS_VERBOSE)
            message(STATUS "enabled cppclean for target ${TARGET_NAME}")
          endif(ARGUMENTS_VERBOSE)
          #
          get_all_compile_definitions(collected_defines
            ${TARGET_NAME}
          )
          #
          get_all_include_directories(collected_includes
            ${TARGET_NAME}
          )
          #
          get_target_sources(TARGET_SOURCES
            ${TARGET_NAME}
          )
          #
          add_cppclean_target(
            TARGET_NAME ${TARGET_NAME}
            CPPCLEAN_FULL_CMD
              ${CPPCLEAN_RUNNABLE}
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              #$<$<BOOL:${collected_defines}>:-D$<JOIN:${collected_defines}, -D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              # To suppress compiler diagnostic messages
              # from third-party headers just use -isystem
              # instead of -I to include those headers.
              #$<$<BOOL:${collected_includes}>:--include-path-system $<JOIN:${collected_includes}, --include-path-system >>
              $<$<BOOL:${collected_includes}>:--include-path $<JOIN:${collected_includes}, --include-path >>
              ${TARGET_SOURCES}
            EXTRA_OPTIONS ${CPPCLEAN_OPTIONS}
          )
          if(CHECK_TARGETS_DEPEND)
            # run cppclean on each build of target
            add_dependencies(
              ${TARGET_NAME}
              ${TARGET_NAME}_run_cppclean
            )
          endif(CHECK_TARGETS_DEPEND)
        endforeach()
      else(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "cppclean: no CHECK_TARGETS provided")
        endif(ARGUMENTS_VERBOSE)
      endif(ARGUMENTS_CHECK_TARGETS)
    else(CPPCLEAN_PROGRAM)
      message(WARNING "Program 'cppclean' not found, unable to run 'cppclean'.")
    endif(CPPCLEAN_PROGRAM)
  else() # ARGUMENTS_IS_ENABLED
    if(ARGUMENTS_VERBOSE)
      message(STATUS "cppclean disabled")
    endif(ARGUMENTS_VERBOSE)
  endif() # ARGUMENTS_IS_ENABLED
endfunction(cppclean_enabler)

## ---------------------------- oclint -------------------------------- ##

function(add_oclint_target)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    # empty
  )
  set(oneValueArgs
    TARGET_NAME
  )
  set(multiValueArgs
    OCLINT_FULL_CMD
    # adds options to default options
    EXTRA_OPTIONS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})

  FROM_HERE("invalid ARGUMENTS_TARGET_NAME")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_TARGET_NAME}
    TEXT "${FROM_HERE}"
  )

  #
  FROM_HERE("invalid ARGUMENTS_OCLINT_FULL_CMD")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_OCLINT_FULL_CMD}
    TEXT ${FROM_HERE}
  )
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_OCLINT_FULL_CMD=${ARGUMENTS_OCLINT_FULL_CMD}")
  endif(ARGUMENTS_VERBOSE)
  #
  set(OCLINT_FULL_CMD
    ${ARGUMENTS_OCLINT_FULL_CMD}
    ${ARGUMENTS_EXTRA_OPTIONS}
  )
  #
  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_run_oclint
  if(ARGUMENTS_VERBOSE)
    message(STATUS "added new target: ${ARGUMENTS_TARGET_NAME}_run_oclint")
  endif(ARGUMENTS_VERBOSE)
  add_custom_target(${ARGUMENTS_TARGET_NAME}_run_oclint
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_oclint_report.xml
    # create report dir
    COMMAND
      ${CMAKE_COMMAND}
      -E
      make_directory
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report/index.html
    # print command that will be executed
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND
      "${CMAKE_COMMAND}"
      -E
      echo
      "executing command: ${OCLINT_FULL_CMD}"
    # Run oclint static analysis
    COMMAND
      "${OCLINT_FULL_CMD}"
    VERBATIM
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND_EXPAND_LISTS
    #USES_TERMINAL
    # Set work directory for target
    WORKING_DIRECTORY
      ${CMAKE_BINARY_DIR}
    # Echo what is being done
    COMMENT "running oclint"
  )
endfunction(add_oclint_target)

# USAGE:
# cmake -E time cmake --build . --target TARGET_NAME_run_oclint
# EXAMPLE:
# oclint_enabler(
#   PATHS
#     ${CONAN_BIN_DIRS}
#     ${CONAN_BIN_DIRS_LLVM_TOOLS}
#   NO_SYSTEM_ENVIRONMENT_PATH
#   NO_CMAKE_SYSTEM_PATH
#   IS_ENABLED
#     ${ENABLE_OCLINT}
#   CHECK_TARGETS
#     ${LIB_NAME}
#   EXTRA_OPTIONS
#     # OCLINT command-line manual
#     # https://oclint-docs.readthedocs.io/en/stable/manual/oclint.html
#     -extra-arg=-std=c++17
#     -extra-arg=-Qunused-arguments
#     # To suppress compiler diagnostic messages
#     # from third-party headers just use -isystem
#     # instead of -I to include those headers.
#     #-extra-arg=-nostdinc
#     #-extra-arg=-nostdinc++
#     -extra-arg=-DBOOST_SYSTEM_NO_DEPRECATED
#     -extra-arg=-DBOOST_ERROR_CODE_HEADER_ONLY
#     # Enable Clang Static Analyzer,
#     # and integrate results into OCLint report
#     -enable-clang-static-analyzer
#     # Compile every source, and analyze across global contexts
#     # (depends on number of source files,
#     # could results in high memory load)
#     # -enable-global-analysis
#     # Write output to <path>
#     -o=${CMAKE_CURRENT_BINARY_DIR}
#     # Build path is used to read a compile command database.
#     -p=${CMAKE_CURRENT_BINARY_DIR}
#     # Add directory to rule loading path
#     -R=${CMAKE_CURRENT_SOURCE_DIR}
#     # Disable the anonymous analytics
#     -no-analytics
#     #-rc=<parameter>=<value>       - Override the default behavior of rules
#     #-report-type=<name>           - Change output report type
#     #-rule=<rule name>             - Explicitly pick rules
# )
function(oclint_enabler)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    VERBOSE
    REQUIRED
    # will run check when target will be built
    CHECK_TARGETS_DEPEND
  )
  set(oneValueArgs
    IS_ENABLED
    STANDALONE_TARGET
  )
  set(multiValueArgs
    # completely changes options to provided options
    OVERRIDE_OPTIONS
    # adds options to default options
    EXTRA_OPTIONS
    # Will collect include dirs, defines and source files
    # from cmake targets
    # NOTE: Why not compile_commands.json?
    # - cmake can not generate that file on per-target basis
    # or into custom out dir
    # NOTE: Why not CMAKE_CXX_OCLINT?
    # - we want to run custom oclint target without
    # need to build whole poject per each check
    CHECK_TARGETS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})
  #
  # default options
  #
  # TODO
  #set(OCLINT_SUPRESSIONS
  #  ${PROJECT_SOURCE_DIR}/cmake/oclint.cfg
  #)
  ## set supressions file only if it exists
  #if(EXISTS "${OCLINT_SUPRESSIONS}")
  #  set(OCLINT_DEFAULT_SUPRESSIONS_ARG
  #    --suppressions-list=${OCLINT_SUPRESSIONS}
  #  )
  #  message(STATUS
  #    "found oclint config file: ${OCLINT_SUPRESSIONS}"
  #  )
  #else()
  #  message(WARNING
  #    "unable to find oclint config file: ${OCLINT_SUPRESSIONS}"
  #  )
  #endif()
  # Set message template
  # TODO
  #set(OcLINT_TEMPLATE
  #  "[{file}:{line}] ({severity}) {message} ({id}) ({callstack})"
  #)
  # Set oclint cache directory
  set(OCLINT_BUILD_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/oclint_cache
  )
  #
  set(OCLINT_OPTIONS
    # more info in console
    #--verbose
  )
  if(ARGUMENTS_OVERRIDE_OPTIONS)
    set(OCLINT_OPTIONS ${ARGUMENTS_OVERRIDE_OPTIONS})
  else()
    if(ARGUMENTS_VERBOSE)
      message(STATUS "oclint: no OVERRIDE_OPTIONS provided")
    endif(ARGUMENTS_VERBOSE)
    # skip, use defaults
  endif()
  #
  list(APPEND OCLINT_OPTIONS ${ARGUMENTS_EXTRA_OPTIONS})
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_EXTRA_OPTIONS=${ARGUMENTS_EXTRA_OPTIONS}")
  endif(ARGUMENTS_VERBOSE)
  #
  if(${ARGUMENTS_IS_ENABLED})
    message(STATUS "oclint enabled")

    # to use `oclint` from conan
    list(APPEND CMAKE_PROGRAM_PATH ${CONAN_BIN_DIRS})

    find_program_helper(oclint
      #PATHS
      #  ${CONAN_BIN_DIRS}
      #  ${CONAN_BIN_DIRS_LLVM_TOOLS}
      #NO_SYSTEM_ENVIRONMENT_PATH
      #NO_CMAKE_SYSTEM_PATH
      ${ARGUMENTS_UNPARSED_ARGUMENTS}
      REQUIRED
      OUT_VAR OCLINT_PROGRAM
      VERBOSE TRUE
    )

    if(OCLINT_PROGRAM)
      # Create oclint cache directory
      file(MAKE_DIRECTORY ${OCLINT_BUILD_DIR})

      # Set oclint program + options.
      list(APPEND OCLINT_RUNNABLE
        ${OCLINT_PROGRAM}
      )
      if(ARGUMENTS_VERBOSE)
        message(STATUS "OCLINT_RUNNABLE=${OCLINT_RUNNABLE}")
      endif(ARGUMENTS_VERBOSE)

      # create separate target for oclint
      if(ARGUMENTS_STANDALONE_TARGET)
        add_oclint_target(
          TARGET_NAME ${ARGUMENTS_STANDALONE_TARGET}
          OCLINT_FULL_CMD
            ${OCLINT_RUNNABLE}
          EXTRA_OPTIONS ${OCLINT_OPTIONS}
        )
      endif(ARGUMENTS_STANDALONE_TARGET)

      # collect headers and defines from existing target
      if(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "oclint: ARGUMENTS_CHECK_TARGETS=${ARGUMENTS_CHECK_TARGETS}")
        endif(ARGUMENTS_VERBOSE)
        foreach(TARGET_NAME ${ARGUMENTS_CHECK_TARGETS})
          if(ARGUMENTS_VERBOSE)
            message(STATUS "enabled oclint for target ${TARGET_NAME}")
          endif(ARGUMENTS_VERBOSE)
          #
          get_all_compile_definitions(collected_defines
            ${TARGET_NAME}
          )
          #
          get_all_include_directories(collected_includes
            ${TARGET_NAME}
          )
          #
          get_target_sources(TARGET_SOURCES
            ${TARGET_NAME}
          )
          #
          add_oclint_target(
            TARGET_NAME ${TARGET_NAME}
            OCLINT_FULL_CMD
              ${OCLINT_RUNNABLE}
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              $<$<BOOL:${collected_defines}>:-extra-arg=-D$<JOIN:${collected_defines}, -extra-arg=-D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              # To suppress compiler diagnostic messages
              # from third-party headers just use -isystem
              # instead of -I to include those headers.
              # $<$<BOOL:${collected_includes}>:-extra-arg=-isystem$<JOIN:${collected_includes}, -extra-arg=-isystem>>
              $<$<BOOL:${collected_includes}>:-extra-arg=-I$<JOIN:${collected_includes}, -extra-arg=-I>>
              ${TARGET_SOURCES}
            EXTRA_OPTIONS ${OCLINT_OPTIONS}
          )
          if(CHECK_TARGETS_DEPEND)
            # run oclint on each build of target
            add_dependencies(
              ${TARGET_NAME}
              ${TARGET_NAME}_run_oclint
            )
          endif(CHECK_TARGETS_DEPEND)
        endforeach()
      else(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "oclint: no CHECK_TARGETS provided")
        endif(ARGUMENTS_VERBOSE)
      endif(ARGUMENTS_CHECK_TARGETS)
    else(OCLINT_PROGRAM)
      message(WARNING "Program 'oclint' not found, unable to run 'oclint'.")
    endif(OCLINT_PROGRAM)
  else() # ARGUMENTS_IS_ENABLED
    if(ARGUMENTS_VERBOSE)
      message(STATUS "oclint disabled")
    endif(ARGUMENTS_VERBOSE)
  endif() # ARGUMENTS_IS_ENABLED
endfunction(oclint_enabler)

## ---------------------------- iwyu -------------------------------- ##

# IWYU detects superfluous includes and when the include can be replaced with a forward declaration.
# It can be obtained using "apt-get install iwyu" or from "github.com/include-what-you-use".
# make sure it can find Clang built-in headers (stdarg.h and friends.)
# see https://stackoverflow.com/a/30951493/10904212
function(add_iwyu_target)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    # empty
  )
  set(oneValueArgs
    TARGET_NAME
    POSTFIX
  )
  set(multiValueArgs
    IWYU_FULL_CMD
    # adds options to default options
    EXTRA_OPTIONS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})

  FROM_HERE("invalid ARGUMENTS_TARGET_NAME")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_TARGET_NAME}
    TEXT "${FROM_HERE}"
  )

  #
  FROM_HERE("invalid ARGUMENTS_IWYU_FULL_CMD")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_IWYU_FULL_CMD}
    TEXT ${FROM_HERE}
  )
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_IWYU_FULL_CMD=${ARGUMENTS_IWYU_FULL_CMD}")
  endif(ARGUMENTS_VERBOSE)
  #
  set(IWYU_FULL_CMD
    ${ARGUMENTS_IWYU_FULL_CMD}
    ${ARGUMENTS_EXTRA_OPTIONS}
    # NOTE: `|| true` will allow IWYU
    # to scan all source files even if one of them failed with error
    # see https://stackoverflow.com/a/50027621
    # Note: iwyu outputs to stderr and always returns a failure status code
    # since it generates no output.
    # see https://github.com/include-what-you-use/include-what-you-use/issues/440
    ";||;true"
  )
  #
  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_run_iwyu_${ARGUMENTS_POSTFIX}
  if(ARGUMENTS_VERBOSE)
    message(STATUS "added new target: ${ARGUMENTS_TARGET_NAME}_run_iwyu_${ARGUMENTS_POSTFIX}")
  endif(ARGUMENTS_VERBOSE)
  add_custom_target(${ARGUMENTS_TARGET_NAME}_run_iwyu_${ARGUMENTS_POSTFIX}
    # remove old report
    #COMMAND
    #  # Remove the file(s).
    #  # If any of the listed files already do not exist,
    #  # the command returns a non-zero exit code,
    #  # but no message is logged.
    #  # The -f option changes the behavior to return a zero exit code
    #  # (i.e. success) in such situations instead.
    #  ${CMAKE_COMMAND}
    #  -E
    #  remove
    #  -f
    #  ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_iwyu_report.xml
    ## create report dir
    #COMMAND
    #  ${CMAKE_COMMAND}
    #  -E
    #  make_directory
    #  ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report
    # remove old report
    #COMMAND
    #  # Remove the file(s).
    #  # If any of the listed files already do not exist,
    #  # the command returns a non-zero exit code,
    #  # but no message is logged.
    #  # The -f option changes the behavior to return a zero exit code
    #  # (i.e. success) in such situations instead.
    #  ${CMAKE_COMMAND}
    #  -E
    #  remove
    #  -f
    #  ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report/index.html
    # print command that will be executed
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND
      "${CMAKE_COMMAND}"
      -E
      echo
      "executing command: ${IWYU_FULL_CMD}"
    # Run iwyu static analysis
    COMMAND
      "${IWYU_FULL_CMD}"
    VERBATIM
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND_EXPAND_LISTS
    #USES_TERMINAL
    # Set work directory for target
    WORKING_DIRECTORY
      ${CMAKE_BINARY_DIR}
    # Echo what is being done
    COMMENT "running iwyu"
  )
endfunction(add_iwyu_target)

# USAGE:
# cmake -E time cmake --build . --target TARGET_NAME_run_iwyu_${ARGUMENTS_POSTFIX}
# EXAMPLE:
# iwyu_enabler(
#   PATHS
#     ${CONAN_BIN_DIRS}
#     ${CONAN_BIN_DIRS_LLVM_TOOLS}
#   NO_SYSTEM_ENVIRONMENT_PATH
#   NO_CMAKE_SYSTEM_PATH
#   IS_ENABLED
#     ${ENABLE_IWYU}
#   CHECK_TARGETS
#     ${LIB_NAME}
#   EXTRA_OPTIONS
#     # TODO
# )
function(iwyu_enabler)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    VERBOSE
    REQUIRED
    # will run check when target will be built
    CHECK_TARGETS_DEPEND
  )
  set(oneValueArgs
    IS_ENABLED
    STANDALONE_TARGET
  )
  set(multiValueArgs
    # completely changes options to provided options
    OVERRIDE_OPTIONS
    # adds options to default options
    EXTRA_OPTIONS
    # Will use set CXX_INCLUDE_WHAT_YOU_USE property
    # for all provided targets
    CHECK_TARGETS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})
  #
  # default options
  #
  # TODO
  #set(IWYU_SUPRESSIONS
  #  ${PROJECT_SOURCE_DIR}/cmake/iwyu.cfg
  #)
  ## set supressions file only if it exists
  #if(EXISTS "${IWYU_SUPRESSIONS}")
  #  set(IWYU_DEFAULT_SUPRESSIONS_ARG
  #    --suppressions-list=${IWYU_SUPRESSIONS}
  #  )
  #  message(STATUS
  #    "found iwyu config file: ${IWYU_SUPRESSIONS}"
  #  )
  #else()
  #  message(WARNING
  #    "unable to find iwyu config file: ${IWYU_SUPRESSIONS}"
  #  )
  #endif()
  # Set iwyu cache directory
  set(IWYU_BUILD_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/iwyu_cache
  )
  #
  set(IWYU_OPTIONS
    # more info in console
    #--verbose
  )
  if(ARGUMENTS_OVERRIDE_OPTIONS)
    set(IWYU_OPTIONS ${ARGUMENTS_OVERRIDE_OPTIONS})
  else()
    if(ARGUMENTS_VERBOSE)
      message(STATUS "iwyu: no OVERRIDE_OPTIONS provided")
    endif(ARGUMENTS_VERBOSE)
    # skip, use defaults
  endif()
  #
  list(APPEND IWYU_OPTIONS ${ARGUMENTS_EXTRA_OPTIONS})
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_EXTRA_OPTIONS=${ARGUMENTS_EXTRA_OPTIONS}")
  endif(ARGUMENTS_VERBOSE)
  #
  if(${ARGUMENTS_IS_ENABLED})
    message(STATUS "iwyu enabled")

    # to use `iwyu` from conan
    list(APPEND CMAKE_PROGRAM_PATH ${CONAN_BIN_DIRS})

    find_program_helper(include-what-you-use
      #PATHS
      #  ${CONAN_BIN_DIRS}
      #  ${CONAN_BIN_DIRS_LLVM_TOOLS}
      #NO_SYSTEM_ENVIRONMENT_PATH
      #NO_CMAKE_SYSTEM_PATH
      ${ARGUMENTS_UNPARSED_ARGUMENTS}
      REQUIRED
      OUT_VAR IWYU_PROGRAM
      VERBOSE TRUE
    )

    if(IWYU_PROGRAM)
      # Create iwyu cache directory
      file(MAKE_DIRECTORY ${IWYU_BUILD_DIR})

      # Set iwyu program + options.
      list(APPEND IWYU_RUNNABLE
        ${IWYU_PROGRAM}
      )
      if(ARGUMENTS_VERBOSE)
        message(STATUS "IWYU_RUNNABLE=${IWYU_RUNNABLE}")
      endif(ARGUMENTS_VERBOSE)

      # create separate target for iwyu
      if(ARGUMENTS_STANDALONE_TARGET)
        add_iwyu_target(
          TARGET_NAME ${ARGUMENTS_STANDALONE_TARGET}
          IWYU_FULL_CMD
            ${IWYU_RUNNABLE}
          EXTRA_OPTIONS ${IWYU_OPTIONS}
        )
      endif(ARGUMENTS_STANDALONE_TARGET)

      # collect headers and defines from existing target
      if(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "iwyu: ARGUMENTS_CHECK_TARGETS=${ARGUMENTS_CHECK_TARGETS}")
        endif(ARGUMENTS_VERBOSE)
        foreach(TARGET_NAME ${ARGUMENTS_CHECK_TARGETS})
          if(ARGUMENTS_VERBOSE)
            message(STATUS "enabled iwyu for target ${TARGET_NAME}")
          endif(ARGUMENTS_VERBOSE)

          get_all_compile_definitions(collected_defines
            ${TARGET_NAME}
          )

          get_all_include_directories(collected_includes
            ${TARGET_NAME}
          )

          get_target_sources(TARGET_SOURCES
            ${TARGET_NAME}
          )

          add_custom_target(${TARGET_NAME}_run_iwyu)

          # loop index
          set(_loop_counter "0")
          # loop over source files
          foreach(FILE_NAME ${TARGET_SOURCES})
            # increment variable (loop index)
            MATH(EXPR _loop_counter "${_loop_counter}+1")

            add_iwyu_target(
              TARGET_NAME ${TARGET_NAME}
              POSTFIX ${_loop_counter}
              IWYU_FULL_CMD
                ${IWYU_RUNNABLE}
                ${IWYU_OPTIONS}
                # NOTE: generator expression, expands during build time
                # if the ${ITEM} is non-empty, then append it
                $<$<BOOL:${collected_defines}>:-D$<JOIN:${collected_defines}, -D>>
                # NOTE: generator expression, expands during build time
                # if the ${ITEM} is non-empty, then append it
                # To suppress compiler diagnostic messages
                # from third-party headers just use -isystem
                # instead of -I to include those headers.
                # $<$<BOOL:${collected_includes}>:-extra-arg=-isystem$<JOIN:${collected_includes}, -extra-arg=-isystem>>
                $<$<BOOL:${collected_includes}>:-isystem$<JOIN:${collected_includes}, -isystem>>
                #$<$<BOOL:${TARGET_SOURCES}>:--check_also=$<JOIN:${TARGET_SOURCES}, --check_also=>>
                # pass each file individually to fix
                # `error: unable to handle compilation, expected exactly one compiler job`
                ${FILE_NAME}
              EXTRA_OPTIONS ${IWYU_OPTIONS}
            )

            # run iwyu on each build of target
            add_dependencies(
              ${TARGET_NAME}_run_iwyu
              ${TARGET_NAME}_run_iwyu_${_loop_counter}
            )
          endforeach() # TARGET_SOURCES

          if(CHECK_TARGETS_DEPEND)
            # run iwyu on each build of target
            add_dependencies(
              ${TARGET_NAME}
              ${TARGET_NAME}_run_iwyu
            )
          endif(CHECK_TARGETS_DEPEND)

          separate_arguments(IWYU_OPTIONS)

          # NOTE: CXX_INCLUDE_WHAT_YOU_USE broken
          # see https://gitlab.kitware.com/cmake/cmake/-/issues/19706
          #set_property(TARGET ${TARGET_NAME}
          #  PROPERTY
          #    CXX_INCLUDE_WHAT_YOU_USE
          #      ${IWYU_RUNNABLE} ${IWYU_OPTIONS}
          #)
        endforeach() # ARGUMENTS_CHECK_TARGETS
      else(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "iwyu: no CHECK_TARGETS provided")
        endif(ARGUMENTS_VERBOSE)
      endif(ARGUMENTS_CHECK_TARGETS)
    else(IWYU_PROGRAM)
      message(WARNING "Program 'iwyu' not found, unable to run 'iwyu'.")
    endif(IWYU_PROGRAM)
  else() # ARGUMENTS_IS_ENABLED
    if(ARGUMENTS_VERBOSE)
      message(STATUS "iwyu disabled")
    endif(ARGUMENTS_VERBOSE)
  endif() # ARGUMENTS_IS_ENABLED
endfunction(iwyu_enabler)

## ---------------------------- clang-format -------------------------------- ##

function(add_clang_format_target)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    # empty
  )
  set(oneValueArgs
    TARGET_NAME
  )
  set(multiValueArgs
    CLANG_FORMAT_FULL_CMD
    # adds options to default options
    EXTRA_OPTIONS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})

  FROM_HERE("invalid ARGUMENTS_TARGET_NAME")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_TARGET_NAME}
    TEXT "${FROM_HERE}"
  )

  #
  FROM_HERE("invalid ARGUMENTS_CLANG_FORMAT_FULL_CMD")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_CLANG_FORMAT_FULL_CMD}
    TEXT ${FROM_HERE}
  )
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_CLANG_FORMAT_FULL_CMD=${ARGUMENTS_CLANG_FORMAT_FULL_CMD}")
  endif(ARGUMENTS_VERBOSE)
  #
  set(CLANG_FORMAT_FULL_CMD
    ${ARGUMENTS_CLANG_FORMAT_FULL_CMD}
    ${ARGUMENTS_EXTRA_OPTIONS}
  )
  #
  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_run_clang_format
  if(ARGUMENTS_VERBOSE)
    message(STATUS "added new target: ${ARGUMENTS_TARGET_NAME}_run_clang_format")
  endif(ARGUMENTS_VERBOSE)
  add_custom_target(${ARGUMENTS_TARGET_NAME}_run_clang_format
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_clang_format_report.xml
    # create report dir
    COMMAND
      ${CMAKE_COMMAND}
      -E
      make_directory
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report/index.html
    # print command that will be executed
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND
      "${CMAKE_COMMAND}"
      -E
      echo
      "executing command: ${CLANG_FORMAT_FULL_CMD}"
    # Run clang_format static analysis
    COMMAND
      "${CLANG_FORMAT_FULL_CMD}"
    VERBATIM
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND_EXPAND_LISTS
    #USES_TERMINAL
    # Set work directory for target
    WORKING_DIRECTORY
      ${CMAKE_BINARY_DIR}
    # Echo what is being done
    COMMENT "running clang_format"
  )
endfunction(add_clang_format_target)

# USAGE:
# cmake -E time cmake --build . --target TARGET_NAME_run_clang_format
# EXAMPLE:
# clang_format_enabler(
#   PATHS
#     ${CONAN_BIN_DIRS}
#     ${CONAN_BIN_DIRS_LLVM_TOOLS}
#   NO_SYSTEM_ENVIRONMENT_PATH
#   NO_CMAKE_SYSTEM_PATH
#   IS_ENABLED
#     ${ENABLE_CLANG_FORMAT}
#   CHECK_TARGETS
#     ${LIB_NAME}
#   EXTRA_OPTIONS
#    # ...
#   VERBOSE
# )
function(clang_format_enabler)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    VERBOSE
    REQUIRED
    # will run check when target will be built
    CHECK_TARGETS_DEPEND
  )
  set(oneValueArgs
    IS_ENABLED
    STANDALONE_TARGET
  )
  set(multiValueArgs
    # completely changes options to provided options
    OVERRIDE_OPTIONS
    # adds options to default options
    EXTRA_OPTIONS
    # Will collect include dirs, defines and source files
    # from cmake targets
    # NOTE: Why not compile_commands.json?
    # - cmake can not generate that file on per-target basis
    # or into custom out dir
    # NOTE: Why not CMAKE_CXX_CLANG_FORMAT?
    # - we want to run custom clang_format target without
    # need to build whole poject per each check
    CHECK_TARGETS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})
  #
  # default options
  #
  # TODO
  #set(CLANG_FORMAT_SUPRESSIONS
  #  ${PROJECT_SOURCE_DIR}/cmake/clang_format.cfg
  #)
  ## set supressions file only if it exists
  #if(EXISTS "${CLANG_FORMAT_SUPRESSIONS}")
  #  set(CLANG_FORMAT_DEFAULT_SUPRESSIONS_ARG
  #    --suppressions-list=${CLANG_FORMAT_SUPRESSIONS}
  #  )
  #  message(STATUS
  #    "found clang_format config file: ${CLANG_FORMAT_SUPRESSIONS}"
  #  )
  #else()
  #  message(WARNING
  #    "unable to find clang_format config file: ${CLANG_FORMAT_SUPRESSIONS}"
  #  )
  #endif()
  # Set message template
  # TODO
  #set(CLANG_FORMAT_TEMPLATE
  #  "[{file}:{line}] ({severity}) {message} ({id}) ({callstack})"
  #)
  # Set clang_format cache directory
  set(CLANG_FORMAT_BUILD_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/clang_format_cache
  )
  #
  set(CLANG_FORMAT_OPTIONS
    # more info in console
    #--verbose
  )
  if(ARGUMENTS_OVERRIDE_OPTIONS)
    set(CLANG_FORMAT_OPTIONS ${ARGUMENTS_OVERRIDE_OPTIONS})
  else()
    if(ARGUMENTS_VERBOSE)
      message(STATUS "clang_format: no OVERRIDE_OPTIONS provided")
    endif(ARGUMENTS_VERBOSE)
    # skip, use defaults
  endif()
  #
  list(APPEND CLANG_FORMAT_OPTIONS ${ARGUMENTS_EXTRA_OPTIONS})
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_EXTRA_OPTIONS=${ARGUMENTS_EXTRA_OPTIONS}")
  endif(ARGUMENTS_VERBOSE)
  #
  if(${ARGUMENTS_IS_ENABLED})
    message(STATUS "clang-format enabled")

    # to use `clang_format` from conan
    list(APPEND CMAKE_PROGRAM_PATH ${CONAN_BIN_DIRS})

    find_program_helper(clang-format
      #PATHS
      #  ${CONAN_BIN_DIRS}
      #  ${CONAN_BIN_DIRS_LLVM_TOOLS}
      #NO_SYSTEM_ENVIRONMENT_PATH
      #NO_CMAKE_SYSTEM_PATH
      ${ARGUMENTS_UNPARSED_ARGUMENTS}
      REQUIRED
      OUT_VAR CLANG_FORMAT_PROGRAM
      VERBOSE TRUE
    )

    if(CLANG_FORMAT_PROGRAM)
      # Create clang_format cache directory
      file(MAKE_DIRECTORY ${CLANG_FORMAT_BUILD_DIR})

      # Set clang_format program + options.
      list(APPEND CLANG_FORMAT_RUNNABLE
        ${CLANG_FORMAT_PROGRAM}
      )
      if(ARGUMENTS_VERBOSE)
        message(STATUS "CLANG_FORMAT_RUNNABLE=${CLANG_FORMAT_RUNNABLE}")
      endif(ARGUMENTS_VERBOSE)

      # create separate target for clang_format
      if(ARGUMENTS_STANDALONE_TARGET)
        add_clang_format_target(
          TARGET_NAME ${ARGUMENTS_STANDALONE_TARGET}
          CLANG_FORMAT_FULL_CMD
            ${CLANG_FORMAT_RUNNABLE}
          EXTRA_OPTIONS ${CLANG_FORMAT_OPTIONS}
        )
      endif(ARGUMENTS_STANDALONE_TARGET)

      # collect headers and defines from existing target
      if(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "clang_format: ARGUMENTS_CHECK_TARGETS=${ARGUMENTS_CHECK_TARGETS}")
        endif(ARGUMENTS_VERBOSE)
        foreach(TARGET_NAME ${ARGUMENTS_CHECK_TARGETS})
          if(ARGUMENTS_VERBOSE)
            message(STATUS "enabled clang_format for target ${TARGET_NAME}")
          endif(ARGUMENTS_VERBOSE)
          #
          get_all_compile_definitions(collected_defines
            ${TARGET_NAME}
          )
          #
          get_all_include_directories(collected_includes
            ${TARGET_NAME}
          )
          #
          get_target_sources(TARGET_SOURCES
            ${TARGET_NAME}
          )
          #
          add_clang_format_target(
            TARGET_NAME ${TARGET_NAME}
            CLANG_FORMAT_FULL_CMD
              ${CLANG_FORMAT_RUNNABLE}
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              #$<$<BOOL:${collected_defines}>:-extra-arg=-D$<JOIN:${collected_defines}, -extra-arg=-D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              # To suppress compiler diagnostic messages
              # from third-party headers just use -isystem
              # instead of -I to include those headers.
              #$<$<BOOL:${collected_includes}>:-extra-arg=-isystem$<JOIN:${collected_includes}, -extra-arg=-isystem>>
              ${TARGET_SOURCES}
            EXTRA_OPTIONS ${CLANG_FORMAT_OPTIONS}
          )
          if(CHECK_TARGETS_DEPEND)
            # run clang-format on each build of target
            add_dependencies(
              ${TARGET_NAME}
              ${TARGET_NAME}_run_clang_format
            )
          endif(CHECK_TARGETS_DEPEND)
        endforeach()
      else(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "clang_format: no CHECK_TARGETS provided")
        endif(ARGUMENTS_VERBOSE)
      endif(ARGUMENTS_CHECK_TARGETS)
    else(CLANG_FORMAT_PROGRAM)
      message(WARNING "Program 'clang_format' not found, unable to run 'clang_format'.")
    endif(CLANG_FORMAT_PROGRAM)
  else() # ARGUMENTS_IS_ENABLED
    if(ARGUMENTS_VERBOSE)
      message(STATUS "clang_format disabled")
    endif(ARGUMENTS_VERBOSE)
  endif() # ARGUMENTS_IS_ENABLED
endfunction(clang_format_enabler)

## ---------------------------- uncrustify -------------------------------- ##

function(add_uncrustify_target)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    # empty
  )
  set(oneValueArgs
    TARGET_NAME
  )
  set(multiValueArgs
    UNCRUSTIFY_FULL_CMD
    # adds options to default options
    EXTRA_OPTIONS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})

  FROM_HERE("invalid ARGUMENTS_TARGET_NAME")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_TARGET_NAME}
    TEXT "${FROM_HERE}"
  )

  #
  FROM_HERE("invalid ARGUMENTS_UNCRUSTIFY_FULL_CMD")
  validate(CHECK_NOT_EMPTY ${ARGUMENTS_UNCRUSTIFY_FULL_CMD}
    TEXT ${FROM_HERE}
  )
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_UNCRUSTIFY_FULL_CMD=${ARGUMENTS_UNCRUSTIFY_FULL_CMD}")
  endif(ARGUMENTS_VERBOSE)
  #
  set(UNCRUSTIFY_FULL_CMD
    ${ARGUMENTS_UNCRUSTIFY_FULL_CMD}
    ${ARGUMENTS_EXTRA_OPTIONS}
  )
  #
  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_run_uncrustify
  if(ARGUMENTS_VERBOSE)
    message(STATUS "added new target: ${ARGUMENTS_TARGET_NAME}_run_uncrustify")
  endif(ARGUMENTS_VERBOSE)
  add_custom_target(${ARGUMENTS_TARGET_NAME}_run_uncrustify
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_uncrustify_report.xml
    # create report dir
    COMMAND
      ${CMAKE_COMMAND}
      -E
      make_directory
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report
    # remove old report
    COMMAND
      # Remove the file(s).
      # If any of the listed files already do not exist,
      # the command returns a non-zero exit code,
      # but no message is logged.
      # The -f option changes the behavior to return a zero exit code
      # (i.e. success) in such situations instead.
      ${CMAKE_COMMAND}
      -E
      remove
      -f
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_report/index.html
    # print command that will be executed
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND
      "${CMAKE_COMMAND}"
      -E
      echo
      "executing command: ${UNCRUSTIFY_FULL_CMD}"
    # Run uncrustify static analysis
    COMMAND
      "${UNCRUSTIFY_FULL_CMD}"
    VERBATIM
    # NOTE: uses COMMAND_EXPAND_LISTS
    # to support generator expressions
    # see https://cmake.org/cmake/help/v3.13/command/add_custom_target.html
    COMMAND_EXPAND_LISTS
    #USES_TERMINAL
    # Set work directory for target
    WORKING_DIRECTORY
      ${CMAKE_BINARY_DIR}
    # Echo what is being done
    COMMENT "running uncrustify"
  )
endfunction(add_uncrustify_target)

# USAGE:
# cmake -E time cmake --build . --target TARGET_NAME_run_uncrustify
# EXAMPLE:
# uncrustify_enabler(
#   PATHS
#     ${CONAN_BIN_DIRS}
#     ${CONAN_BIN_DIRS_LLVM_TOOLS}
#   NO_SYSTEM_ENVIRONMENT_PATH
#   NO_CMAKE_SYSTEM_PATH
#   IS_ENABLED
#     ${ENABLE_UNCRUSTIFY}
#   CHECK_TARGETS
#     ${LIB_NAME}
#   EXTRA_OPTIONS
#    # ...
#   VERBOSE
# )
function(uncrustify_enabler)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    VERBOSE
    REQUIRED
    # will run check when target will be built
    CHECK_TARGETS_DEPEND
  )
  set(oneValueArgs
    IS_ENABLED
    STANDALONE_TARGET
  )
  set(multiValueArgs
    # completely changes options to provided options
    OVERRIDE_OPTIONS
    # adds options to default options
    EXTRA_OPTIONS
    # Will collect include dirs, defines and source files
    # from cmake targets
    # NOTE: Why not compile_commands.json?
    # - cmake can not generate that file on per-target basis
    # or into custom out dir
    # NOTE: Why not CMAKE_CXX_UNCRUSTIFY?
    # - we want to run custom uncrustify target without
    # need to build whole poject per each check
    CHECK_TARGETS
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})
  #
  # default options
  #
  # TODO
  #set(UNCRUSTIFY_SUPRESSIONS
  #  ${PROJECT_SOURCE_DIR}/cmake/uncrustify.cfg
  #)
  ## set supressions file only if it exists
  #if(EXISTS "${UNCRUSTIFY_SUPRESSIONS}")
  #  set(UNCRUSTIFY_DEFAULT_SUPRESSIONS_ARG
  #    --suppressions-list=${UNCRUSTIFY_SUPRESSIONS}
  #  )
  #  message(STATUS
  #    "found uncrustify config file: ${UNCRUSTIFY_SUPRESSIONS}"
  #  )
  #else()
  #  message(WARNING
  #    "unable to find uncrustify config file: ${UNCRUSTIFY_SUPRESSIONS}"
  #  )
  #endif()
  # Set message template
  # TODO
  #set(UNCRUSTIFY_TEMPLATE
  #  "[{file}:{line}] ({severity}) {message} ({id}) ({callstack})"
  #)
  # Set uncrustify cache directory
  set(UNCRUSTIFY_BUILD_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/uncrustify_cache
  )
  #
  set(UNCRUSTIFY_OPTIONS
    # more info in console
    #--verbose
  )
  if(ARGUMENTS_OVERRIDE_OPTIONS)
    set(UNCRUSTIFY_OPTIONS ${ARGUMENTS_OVERRIDE_OPTIONS})
  else()
    if(ARGUMENTS_VERBOSE)
      message(STATUS "uncrustify: no OVERRIDE_OPTIONS provided")
    endif(ARGUMENTS_VERBOSE)
    # skip, use defaults
  endif()
  #
  list(APPEND UNCRUSTIFY_OPTIONS ${ARGUMENTS_EXTRA_OPTIONS})
  if(ARGUMENTS_VERBOSE)
    message(STATUS "ARGUMENTS_EXTRA_OPTIONS=${ARGUMENTS_EXTRA_OPTIONS}")
  endif(ARGUMENTS_VERBOSE)
  #
  if(${ARGUMENTS_IS_ENABLED})
    message(STATUS "uncrustify enabled")

    # to use `uncrustify` from conan
    list(APPEND CMAKE_PROGRAM_PATH ${CONAN_BIN_DIRS})

    find_program_helper(uncrustify
      #PATHS
      #  ${CONAN_BIN_DIRS}
      #  ${CONAN_BIN_DIRS_LLVM_TOOLS}
      #NO_SYSTEM_ENVIRONMENT_PATH
      #NO_CMAKE_SYSTEM_PATH
      ${ARGUMENTS_UNPARSED_ARGUMENTS}
      REQUIRED
      OUT_VAR UNCRUSTIFY_PROGRAM
      VERBOSE TRUE
    )

    if(UNCRUSTIFY_PROGRAM)
      # Create uncrustify cache directory
      file(MAKE_DIRECTORY ${UNCRUSTIFY_BUILD_DIR})

      # Set uncrustify program + options.
      list(APPEND UNCRUSTIFY_RUNNABLE
        ${UNCRUSTIFY_PROGRAM}
      )
      if(ARGUMENTS_VERBOSE)
        message(STATUS "UNCRUSTIFY_RUNNABLE=${UNCRUSTIFY_RUNNABLE}")
      endif(ARGUMENTS_VERBOSE)

      # create separate target for uncrustify
      if(ARGUMENTS_STANDALONE_TARGET)
        add_uncrustify_target(
          TARGET_NAME ${ARGUMENTS_STANDALONE_TARGET}
          UNCRUSTIFY_FULL_CMD
            ${UNCRUSTIFY_RUNNABLE}
          EXTRA_OPTIONS ${UNCRUSTIFY_OPTIONS}
        )
      endif(ARGUMENTS_STANDALONE_TARGET)

      # collect headers and defines from existing target
      if(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "uncrustify: ARGUMENTS_CHECK_TARGETS=${ARGUMENTS_CHECK_TARGETS}")
        endif(ARGUMENTS_VERBOSE)
        foreach(TARGET_NAME ${ARGUMENTS_CHECK_TARGETS})
          if(ARGUMENTS_VERBOSE)
            message(STATUS "enabled uncrustify for target ${TARGET_NAME}")
          endif(ARGUMENTS_VERBOSE)
          #
          get_all_compile_definitions(collected_defines
            ${TARGET_NAME}
          )
          #
          get_all_include_directories(collected_includes
            ${TARGET_NAME}
          )
          #
          get_target_sources(TARGET_SOURCES
            ${TARGET_NAME}
          )
          #
          add_uncrustify_target(
            TARGET_NAME ${TARGET_NAME}
            UNCRUSTIFY_FULL_CMD
              ${UNCRUSTIFY_RUNNABLE}
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              #$<$<BOOL:${collected_defines}>:-extra-arg=-D$<JOIN:${collected_defines}, -extra-arg=-D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, then append it
              # To suppress compiler diagnostic messages
              # from third-party headers just use -isystem
              # instead of -I to include those headers.
              #$<$<BOOL:${collected_includes}>:-extra-arg=-isystem$<JOIN:${collected_includes}, -extra-arg=-isystem>>
              ${TARGET_SOURCES}
            EXTRA_OPTIONS ${UNCRUSTIFY_OPTIONS}
          )
          if(CHECK_TARGETS_DEPEND)
            # run uncrustify on each build of target
            add_dependencies(
              ${TARGET_NAME}
              ${TARGET_NAME}_run_uncrustify
            )
          endif(CHECK_TARGETS_DEPEND)
        endforeach()
      else(ARGUMENTS_CHECK_TARGETS)
        if(ARGUMENTS_VERBOSE)
          message(STATUS "uncrustify: no CHECK_TARGETS provided")
        endif(ARGUMENTS_VERBOSE)
      endif(ARGUMENTS_CHECK_TARGETS)
    else(UNCRUSTIFY_PROGRAM)
      message(WARNING "Program 'uncrustify' not found, unable to run 'uncrustify'.")
    endif(UNCRUSTIFY_PROGRAM)
  else() # ARGUMENTS_IS_ENABLED
    if(ARGUMENTS_VERBOSE)
      message(STATUS "uncrustify disabled")
    endif(ARGUMENTS_VERBOSE)
  endif() # ARGUMENTS_IS_ENABLED
endfunction(uncrustify_enabler)

## ---------------------------- llvm_tools -------------------------------- ##

macro(compile_with_llvm_tools)
  message(STATUS
    "Using clang 10 from conan")

  # use llvm_tools from conan
  find_program_helper(clang
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    ${ARGUMENTS_UNPARSED_ARGUMENTS}
    REQUIRED
    OUT_VAR CLANG_PROGRAM
    VERBOSE TRUE
  )

  # we can NOT change CMAKE_C_COMPILER dynamically
  # (it will corrupt cmake cache), but we can check CC env. var
  if(NOT "${CMAKE_C_COMPILER}" STREQUAL "${CLANG_PROGRAM}")
    message(WARNING "CMAKE_C_COMPILER=${CMAKE_C_COMPILER} does not match ${CLANG_PROGRAM}. Run command:")
    message(FATAL_ERROR "export CC=${CLANG_PROGRAM}")
  endif()

  # use llvm_tools from conan
  find_program_helper(clang++
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    ${ARGUMENTS_UNPARSED_ARGUMENTS}
    REQUIRED
    OUT_VAR CLANGPP_PROGRAM
    VERBOSE TRUE
  )

  # we can NOT change CMAKE_CXX_COMPILER dynamically
  # (it will corrupt cmake cache), but we can check CXX env. var
  if(NOT "${CMAKE_CXX_COMPILER}" STREQUAL "${CLANGPP_PROGRAM}")
    message(WARNING "CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} does not match ${CLANGPP_PROGRAM}. Run command:")
    message(FATAL_ERROR "export CXX=${CLANGPP_PROGRAM}")
  endif()

  if(NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    message(FATAL_ERROR "CMAKE_CXX_COMPILER_ID=${CMAKE_CXX_COMPILER_ID} does not match Clang. Run command:")
  endif()

  # use llvm_tools from conan
  find_program_helper(llvm-ar
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    ${ARGUMENTS_UNPARSED_ARGUMENTS}
    REQUIRED
    OUT_VAR LLVM_AR_PROGRAM
    VERBOSE TRUE
  )

  # use llvm_tools from conan
  find_program_helper(
    # llvm-ld replaced by llvm-ld
    ld.lld
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    ${ARGUMENTS_UNPARSED_ARGUMENTS}
    REQUIRED
    OUT_VAR LLVM_LD_PROGRAM
    VERBOSE TRUE
  )

  # use llvm_tools from conan
  find_program_helper(llvm-nm
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    ${ARGUMENTS_UNPARSED_ARGUMENTS}
    REQUIRED
    OUT_VAR LLVM_NM_PROGRAM
    VERBOSE TRUE
  )

  # use llvm_tools from conan
  find_program_helper(llvm-objdump
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    ${ARGUMENTS_UNPARSED_ARGUMENTS}
    REQUIRED
    OUT_VAR LLVM_OBJDUMP_PROGRAM
    VERBOSE TRUE
  )

  # use llvm_tools from conan
  find_program_helper(llvm-ranlib
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    ${ARGUMENTS_UNPARSED_ARGUMENTS}
    REQUIRED
    OUT_VAR LLVM_RANLIB_PROGRAM
    VERBOSE TRUE
  )

  # use llvm_tools from conan
  find_program_helper(llvm-as
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    ${ARGUMENTS_UNPARSED_ARGUMENTS}
    REQUIRED
    OUT_VAR LLVM_ASM_PROGRAM
    VERBOSE TRUE
  )

  # use llvm_tools from conan
  find_program_helper(llvm-rc # TODO: llvm-rc-rc or llvm-rc?
    PATHS
      #${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
    ${ARGUMENTS_UNPARSED_ARGUMENTS}
    REQUIRED
    OUT_VAR LLVM_RC_PROGRAM
    VERBOSE TRUE
  )

  # Set linkers and other build tools.
  # NOTE: use UNINSTRUMENTED llvm-ar, llvml-symbolizer, etc.
  # Related documentation
  # https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_COMPILER.html
  # https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_FLAGS_INIT.html
  # https://cmake.org/cmake/help/latest/variable/CMAKE_LINKER.html
  # https://cmake.org/cmake/help/latest/variable/CMAKE_AR.html
  # https://cmake.org/cmake/help/latest/variable/CMAKE_RANLIB.html
  if(NOT CMAKE_AR)
    set(CMAKE_AR "${LLVM_AR_PROGRAM}")
  endif(NOT CMAKE_AR)
  #
  if(NOT CMAKE_LINKER)
    set(CMAKE_LINKER "${LLVM_LD_PROGRAM}")
  endif(NOT CMAKE_LINKER)
  #
  if(NOT CMAKE_NM)
    set(CMAKE_NM "${LLVM_NM_PROGRAM}")
  endif(NOT CMAKE_NM)
  #
  if(NOT CMAKE_OBJDUMP)
    set(CMAKE_OBJDUMP "${LLVM_OBJDUMP_PROGRAM}")
  endif(NOT CMAKE_OBJDUMP)
  #
  if(NOT CMAKE_RANLIB)
    set(CMAKE_RANLIB "${LLVM_RANLIB_PROGRAM}")
  endif(NOT CMAKE_RANLIB)
  #
  if(NOT CMAKE_ASM_COMPILER)
    set(CMAKE_ASM_COMPILER "${LLVM_ASM_PROGRAM}")
  endif(NOT CMAKE_ASM_COMPILER)
  #
  if(NOT CMAKE_RC_COMPILER)
    set(CMAKE_RC_COMPILER "${LLVM_RC_PROGRAM}")
  endif(NOT CMAKE_RC_COMPILER)

  # use llvm_tools from conan
  find_library(CLANG_LIBCPP
    NAMES
      c++
    PATHS
      ${CONAN_LIB_DIRS_LLVM_TOOLS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
  )
  if(NOT CLANG_LIBCPP)
    message(FATAL_ERROR
      "Unable to find libc++")
  endif(NOT CLANG_LIBCPP)
  get_filename_component(CLANG_LIBCPP_DIR
    ${CLANG_LIBCPP}
    DIRECTORY)
  message(STATUS
    "CLANG_LIBCPP_DIR=${CLANG_LIBCPP_DIR}")
  if(NOT IS_ABSOLUTE ${CLANG_LIBCPP_DIR})
    message(FATAL_ERROR
      "Path to libc++ must be absolute")
  endif(NOT IS_ABSOLUTE ${CLANG_LIBCPP_DIR})

  # use llvm_tools from conan
  find_library(CLANG_LIBCPPABI
    NAMES
    c++abi
    PATHS
      ${CONAN_LIB_DIRS_LLVM_TOOLS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    NO_SYSTEM_ENVIRONMENT_PATH
    NO_CMAKE_SYSTEM_PATH
  )
  if(NOT CLANG_LIBCPPABI)
    message(FATAL_ERROR
      "Unable to find libc++abi")
  endif(NOT CLANG_LIBCPPABI)
  get_filename_component(CLANG_LIBCPPABI_DIR
    ${CLANG_LIBCPPABI}
    DIRECTORY)
  message(STATUS
    "CLANG_LIBCPPABI_DIR=${CLANG_LIBCPPABI_DIR}")
  if(NOT IS_ABSOLUTE ${CLANG_LIBCPPABI_DIR})
    message(FATAL_ERROR
      "Path to libc++abi must be absolute")
  endif(NOT IS_ABSOLUTE ${CLANG_LIBCPPABI_DIR})

  find_path(
    LIBCXX_LIBCXXABI_INCLUDE_FILE cxxabi.h
    PATHS
      ${CONAN_LLVM_TOOLS_ROOT}/include/c++/v1
      ${CONAN_INCLUDE_DIRS_LLVM_TOOLS}
    NO_DEFAULT_PATH
    NO_CMAKE_FIND_ROOT_PATH
  )
  if(NOT LIBCXX_LIBCXXABI_INCLUDE_FILE)
    message(FATAL_ERROR
      "Unable to find cxxabi.h")
  endif(NOT LIBCXX_LIBCXXABI_INCLUDE_FILE)
  get_filename_component(LIBCXX_LIBCXXABI_INCLUDE_FILE_DIR
    ${LIBCXX_LIBCXXABI_INCLUDE_FILE}
    DIRECTORY)
  message(STATUS
    "LIBCXX_LIBCXXABI_INCLUDE_FILE_DIR=${LIBCXX_LIBCXXABI_INCLUDE_FILE_DIR}")
  if(NOT IS_ABSOLUTE ${LIBCXX_LIBCXXABI_INCLUDE_FILE_DIR})
    message(FATAL_ERROR
      "Path to cxxabi.h must be absolute")
  endif(NOT IS_ABSOLUTE ${LIBCXX_LIBCXXABI_INCLUDE_FILE_DIR})
  if("${CONAN_LLVM_TOOLS_ROOT}" STREQUAL "")
    message(FATAL_ERROR
      "CONAN_LLVM_TOOLS_ROOT not found")
  endif()

  # libcxx which we will use with specific version of clang
  SET(LIBCXX_INC_PATH
    ${CONAN_LLVM_TOOLS_ROOT}/include/c++/v1)

  SET(LIBCXX_LIB_PATH
    ${CONAN_LLVM_TOOLS_ROOT}/lib)

  # Remove -stdlib flags
  string(REPLACE "-stdlib=libstdc++" ""
    CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  string(REPLACE "-static-libstdc++" ""
    CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  string(REPLACE "-stdlib=libstdc++" ""
    CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
  string(REPLACE "-static-libstdc++" ""
    CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")

  set(CMAKE_REQUIRED_FLAGS
    "${CMAKE_REQUIRED_FLAGS} -stdlib=libc++")

  set(CMAKE_CXX_FLAGS "\
    -D__CLANG__ \
    -nostdinc++ \
    -Wno-unused-command-line-argument \
    -Wno-error=unused-command-line-argument \
    -stdlib=libc++ \
    -isystem ${LIBCXX_INC_PATH} \
    -isystem ${CONAN_LLVM_TOOLS_ROOT}/include \
    -isystem ${CONAN_LLVM_TOOLS_ROOT}/lib/clang/10.0.1/include \
    ${CMAKE_CXX_FLAGS}")

  set(CMAKE_EXE_LINKER_FLAGS "\
    -lc++ -lc++abi -lunwind \
    -Wl,-rpath,${LIBCXX_LIB_PATH} \
    -stdlib=libc++ \
    ${CMAKE_EXE_LINKER_FLAGS}")

  set(CMAKE_SHARED_LINKER_FLAGS "\
    -lc++ -lc++abi -lunwind \
    -Wl,-rpath,${LIBCXX_LIB_PATH} \
    -stdlib=libc++ \
    ${CMAKE_SHARED_LINKER_FLAGS}")

  link_directories(${LIBCXX_LIB_PATH})

  include(CheckCXXSourceCompiles)

  # Check if initializer lists are supported.
  check_cxx_source_compiles("
#include <iostream>
#ifdef __GLIBCXX__
  #error \"Using libstdc++\"
#else
  #warning \"Using libc++\"
#endif
int main(int argc, char* argv[])
{
return 0;
}
" SUPPORTS_LIBCPP)
  if (NOT SUPPORTS_LIBCPP)
    message(FATAL_ERROR "Unable to compile test program using libc++")
  endif ()

endmacro(compile_with_llvm_tools)

################################################################################
# ccache enables faster builds
################################################################################

# see https://www.virag.si/2015/07/use-ccache-with-cmake-for-faster-compilation/
# TODO: Xcode support https://stackoverflow.com/a/36515503
# TODO: CMAKE_XCODE_ATTRIBUTE_CC https://crascit.com/2016/04/09/using-ccache-with-cmake/
macro(add_ccache)
  find_program_helper(ccache
    PATHS
      ${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    #NO_SYSTEM_ENVIRONMENT_PATH
    #NO_CMAKE_SYSTEM_PATH
    #${ARGUMENTS_UNPARSED_ARGUMENTS}
    #REQUIRED
    OUT_VAR CCACHE_PROGRAM
    VERBOSE TRUE
  )
  #
  if(CCACHE_PROGRAM)
    set_property(GLOBAL PROPERTY
      RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
    set_property(GLOBAL PROPERTY
      RULE_LAUNCH_LINK "${CCACHE_PROGRAM}")
    message(STATUS "Using CCACHE. To see if ccache is really working, you can use ccache -s command, which will display ccache statistics.")
    message(STATUS "CCACHE: On second and all subsequent compilations the “cache hit” values should increase and thus show that ccache is working.")
  else()
    message(WARNING "CCACHE not found, see https://askubuntu.com/a/470636 (also note /usr/sbin/update-ccache-symlinks).")
  endif()
endmacro()

function(target_ccache_summary TARGET)
  find_program_helper(ccache
    PATHS
      ${CONAN_BIN_DIRS}
      ${CONAN_BIN_DIRS_LLVM_TOOLS}
    #NO_SYSTEM_ENVIRONMENT_PATH
    #NO_CMAKE_SYSTEM_PATH
    #${ARGUMENTS_UNPARSED_ARGUMENTS}
    #REQUIRED
    OUT_VAR CCACHE_PROGRAM
    VERBOSE TRUE
  )
  #
  if(CCACHE_PROGRAM)
    message("cmake summary: add_custom_target: ccache -s")
    # NOTE: clean old build dirs to get fresh ccache summary
    add_custom_target(ccache_stats ALL
      COMMAND ${CCACHE_PROGRAM} -s
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "!!!!!!!!!!!!!!!!!!!! getting ccache stats !!!!!!!!!!!!!!!!!!!!!!!!!!"
      DEPENDS ${TARGET}
    )
  endif()
endfunction()

################################################################################
# Gold linker.
################################################################################

# see https://cristianadam.eu/20170709/speeding-up-cmake/
# TODO: use with gold: "--threads", "--thread-count COUNT", "--preread-archive-symbols"
# NOTE: gold not threaded by default, configure with "--enable-threads"
# NOTE: lld threaded by default, may be faster then gold
macro(add_gold_linker)
  if("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
    execute_process(
      COMMAND
        ${CMAKE_C_COMPILER}
        -fuse-ld=gold -Wl,--version
        OUTPUT_VARIABLE stdout
        ERROR_QUIET)
    if("${stdout}" MATCHES "GNU gold")
      set(CMAKE_C_FLAGS
        "${CMAKE_C_FLAGS} \
        -fuse-ld=gold")
      set(CMAKE_CXX_FLAGS
        "${CMAKE_CXX_FLAGS} \
        -fuse-ld=gold")
      set(CMAKE_LD_FLAGS
        "${CMAKE_LD_FLAGS} \
        -fuse-ld=gold -Wl,--disable-new-dtags")
      set(CMAKE_EXE_LINKER_FLAGS
        "${CMAKE_EXE_LINKER_FLAGS} \
        -fuse-ld=gold -Wl,--disable-new-dtags")
      set(CMAKE_STATIC_LINKER_FLAGS
        "${CMAKE_STATIC_LINKER_FLAGS} \
        -fuse-ld=gold -Wl,--disable-new-dtags")
      set(CMAKE_SHARED_LINKER_FLAGS
        "${CMAKE_SHARED_LINKER_FLAGS} \
        -fuse-ld=gold -Wl,--disable-new-dtags")
      message(STATUS
        "Using GNU gold linker.")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
      # Clang is using the LLVM Linker instead of the LLVM gold plugin. This is
      # because the LLVM linker is faster. Linker and plugin:
      # The LLVM-Linker     : https://lld.llvm.org/
      # The LLVM gold plugin: https://llvm.org/docs/GoldPlugin.html
      # TODO: -flto: This flag will also cause clang to look for the gold plugin in the lib directory under its prefix and pass the -plugin option to ld.
      set(CMAKE_EXE_LINKER_FLAGS
        "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=lld")
      set(CMAKE_SHARED_LINKER_FLAGS
        "${CMAKE_SHARED_LINKER_FLAGS} -fuse-ld=lld")
      message(STATUS
        "Using Clang lld instead of gold linker
        because the LLVM linker is faster.")
    else()
      message(WARNING
        "GNU gold linker isn't available, using the default system linker.")
      message(WARNING
        "To install gold linker: sudo apt-get install binutils-gold")
    endif()
  else()
    message(WARNING
      "GNU gold linker disabled.")
  endif()
endmacro()

################################################################################
# warning level
################################################################################

# Helper script to set warnings
# Usage :
#  target_set_warnings(target
#    [ENABLE [ALL] [list of warning names]]
#    [DISABLE [ALL/Annoying] [list of warning names]]
#    [AS_ERROR ALL]
#  )
#
# Example 1:
# # Helper that can set default warning flags for you
# target_set_warnings(${LIB_NAME}
#   ENABLE ALL
#   AS_ERROR ALL
#   DISABLE Annoying)
#
# Example 2:
# # Helper that can set default warning flags for you
# target_set_warnings(${LIB_NAME}
#   ENABLE ALL
#   AS_ERROR ALL
#   DISABLE Annoying)
#
# Example 3:
# # Treat third-party library fmtlib as a system include as to ignore the warnings
# target_set_warnings(fmt DISABLE ALL)
#
#  ENABLE
#    * ALL: means all the warnings possible to enable through a one parameter switch.
#      Note that for some compilers, this does not mean every single warning will be enabled (GCC for instance).
#    * Any other name: enable the warning with the given name
#
#  DISABLE
#    * ALL: will override any other settings and this target INTERFACE includes will be considered as system includes by targets linking it.
#    * Annoying: Warnings that the author thinks should only be used as static analysis tools not in production. On MSVC, also sets _CRT_SECURE_NO_WARNINGS.
#    * Any other name: disable the warning with the given name
#
#  AS_ERROR
#    * ALL: is the only option available as not all compilers let us set specific warnings as error from command line (MSVC).
#
function(target_set_warnings)
  #
  if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    set(WMSVC TRUE)
    # Means the warning will be available at all levels that do emit warnings
    set(WARNING_ENABLE_PREFIX "/w1")
    set(WARNING_DISABLE_PREFIX "/wd")
  elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(WGCC TRUE)
    set(WARNING_ENABLE_PREFIX "-W")
    set(WARNING_DISABLE_PREFIX "-Wno-")
  elseif ("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
    set(WCLANG TRUE)
    set(WARNING_ENABLE_PREFIX "-W")
    set(WARNING_DISABLE_PREFIX "-Wno-")
  endif()
  #
  set(multiValueArgs
    ENABLE
    DISABLE
    AS_ERROR)
  cmake_parse_arguments(ARGUMENTS "" "" "${multiValueArgs}" ${ARGN})
  #
  # ALL: means all the warnings possible to enable through a one parameter switch.
  list(FIND ARGUMENTS_ENABLE "ALL" enable_all)
  #
  # ALL: will override any other settings and this target INTERFACE includes will be considered as system includes by targets linking it.
  list(FIND ARGUMENTS_DISABLE "ALL" disable_all)
  #
  # ALL: is the only option available as not all compilers let us set specific warnings as error from command line (MSVC).
  list(FIND ARGUMENTS_AS_ERROR "ALL" as_error_all)
  #
  if(NOT ${enable_all} EQUAL -1) # enable all warnings
    if(WMSVC)
      # Not all the warnings, but WAll is unusable when using libraries
      # Unless you'd like to support MSVC in the code with pragmas, this is probably the best option
      # NOTE: explicitly select the "C++ Core Check Lifetime Rules" (or "Microsoft All Rules") in order to enable the lifetime checks.
      # see https://devblogs.microsoft.com/cppblog/c-core-guidelines-checker-in-visual-studio-2017/
      # see https://www.modernescpp.com/index.php/c-core-guidelines-lifetime-safety
      list(APPEND WarningFlags
        "/W4"
        )
    elseif(WGCC)
      # see https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
      list(APPEND WarningFlags
        -Wall
        -Wextra
        -Wpedantic
        -Wdeprecated-register
        -Wnon-virtual-dtor
        # disable warning: designated initializers are a C99 feature
        -Wno-c99-extensions
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wduplicated-cond
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wduplicated-branches
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wlogical-op
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wrestrict
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wnull-dereference
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wold-style-cast
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wuseless-cast
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wjump-misses-init
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wdouble-promotion
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wshadow
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wformat=2)
    elseif(WCLANG)
      list(APPEND WarningFlags
        # see https://pspdfkit.com/blog/2020/the-cpp-lifetime-profile/
        # TODO: only special branch of Clang currently https://github.com/mgehre/llvm-project
        #-Wlifetime
        # see http://clang.llvm.org/docs/ThreadSafetyAnalysis.html
        # see https://github.com/isocpp/CppCoreGuidelines/blob/master/docs/Lifetime.pdf
        -Wthread-safety-analysis
        -Wall
        -Weverything
        -Wpedantic
        -Wdeprecated-register
        -Wnon-virtual-dtor
        # disable warning: designated initializers are a C99 feature
        -Wno-c99-extensions
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wduplicated-cond
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wduplicated-branches
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wlogical-op
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wrestrict
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wnull-dereference
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wold-style-cast
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wuseless-cast
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wjump-misses-init
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wdouble-promotion
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wshadow
        # see https://kristerw.blogspot.com/2017/09/useful-gcc-warning-options-not-enabled.html
        -Wformat=2
        # Negative requirements are an experimental feature
        # which will produce many warnings in existing code
        -Wno-thread-safety-negative
        )
    endif()
  elseif(NOT ${disable_all} EQUAL -1) # disable all warnings
    # Treat includes as if coming from system to suppress warnings
    # see https://stackoverflow.com/a/52136398
    set(SystemIncludes TRUE)
    if(WMSVC)
      list(APPEND WarningFlags
        "/w"
        "/W0")
    elseif(WGCC OR WCLANG)
      list(APPEND WarningFlags
        "-w")
    endif()
  endif()
  #
  list(FIND ARGUMENTS_DISABLE "Annoying" disable_annoying)
  if(NOT ${disable_annoying} EQUAL -1) # disable annoying warnings
    if(WMSVC)
      # bounds-checked functions require to set __STDC_WANT_LIB_EXT1__ which we usually don't need/want
      list(APPEND WarningDefinitions
        -D_CRT_SECURE_NO_WARNINGS)
      # disable C4514 C4710 C4711... Those are useless to add most of the time
      #list(APPEND WarningFlags "/wd4514" "/wd4710" "/wd4711")
      #list(APPEND WarningFlags "/wd4365") #signed/unsigned mismatch
      #list(APPEND WarningFlags "/wd4668") # is not defined as a preprocessor macro, replacing with '0' for
    elseif(WGCC OR WCLANG)
      list(APPEND WarningFlags
        -Wno-switch-enum)
      if(WCLANG)
        list(APPEND WarningFlags
          -Wno-global-constructors
          -Wno-exit-time-destructors
          -Wno-documentation
          -Wno-documentation-unknown-command
          -Wno-unknown-warning-option
          -Wno-padded
          -Wno-undef
          -Wno-reserved-id-macro
          -Wno-inconsistent-missing-destructor-override
          -fcomment-block-commands=test,retval)
        if(NOT CMAKE_CXX_STANDARD EQUAL 98)
          list(APPEND WarningFlags
            -Wno-c++98-compat
            -Wno-c++98-compat-pedantic)
        endif()
        if ("${CMAKE_CXX_SIMULATE_ID}" STREQUAL "MSVC")
          # clang-cl has some VCC flags by default that it will not recognize...
          list(APPEND WarningFlags
            -Wno-unused-command-line-argument
            -Wno-error=unused-command-line-argument)
        endif()
      endif(WCLANG)
    endif()
  endif()
  #
  if(NOT ${as_error_all} EQUAL -1) # error on warnings
    if(WMSVC)
      list(APPEND WarningFlags "/WX")
    elseif(WGCC OR WCLANG)
      list(APPEND WarningFlags "-Werror")
    endif()
  endif()
  #
  if(ARGUMENTS_ENABLE)
    # `ALL` is invalid warning name
    list(REMOVE_ITEM ARGUMENTS_ENABLE ALL)
    # Any other name: enable the warning with the given name
    foreach(warning-name IN LISTS ARGUMENTS_ENABLE)
      list(APPEND WarningFlags "${WARNING_ENABLE_PREFIX}${warning-name}")
    endforeach()
  endif()
  #
  if(ARGUMENTS_DISABLE)
    # `ALL` is invalid warning name
    list(REMOVE_ITEM ARGUMENTS_DISABLE ALL Annoying)
    # Any other name: disable the warning with the given name
    foreach(warning-name IN LISTS ARGUMENTS_DISABLE)
      list(APPEND WarningFlags "${WARNING_DISABLE_PREFIX}${warning-name}")
    endforeach()
  endif()
  #
  # ARGUMENTS_UNPARSED_ARGUMENTS holds target names
  foreach(target IN LISTS ARGUMENTS_UNPARSED_ARGUMENTS)
    if(WarningFlags)
      target_compile_options(${target} PRIVATE ${WarningFlags})
    endif()
    if(WarningDefinitions)
      target_compile_definitions(${target} PRIVATE ${WarningDefinitions})
    endif()
    if(SystemIncludes)
      # declare imported targets as system to suppress warnings
      # see https://stackoverflow.com/a/52136398
      set_target_properties(${target} PROPERTIES
          INTERFACE_SYSTEM_INCLUDE_DIRECTORIES $<TARGET_PROPERTY:${target},INTERFACE_INCLUDE_DIRECTORIES>)
    endif()
  endforeach()
endfunction(target_set_warnings)

################################################################################
# Link Time Optimization
################################################################################
#
# Usage :
#
# Variable : ENABLE_LTO | Enable or disable LTO support for this build
#
# find_lto(lang)
# - lang is C or CXX (the language to test LTO for)
# - call it after project() so that the compiler is already detected
#
# This will check for LTO support and create a target_enable_lto(target [debug,optimized,general]) macro.
# The 2nd parameter has the same meaning as in target_link_libraries, and is used to enable LTO only for those build configurations
# 'debug' is by default the Debug configuration, and 'optimized' all the other configurations
#
# if ENABLE_LTO is set to false, an empty macro will be generated
#
# Then to enable LTO for your target use
#
#       target_enable_lto(mytarget general)
#
# It is however recommended to use it only for non debug builds the following way :
#
#       target_enable_lto(mytarget optimized)
#
# Note : For CMake versions < 3.9, target_link_library is used in it's non plain version.
#        You will need to specify PUBLIC/PRIVATE/INTERFACE to all your other target_link_library calls for the target
#
# WARNING for cmake versions older then 3.9 :
# This module will override CMAKE_AR CMAKE_RANLIB and CMAKE_NM by the gcc versions if found when building with gcc
#

macro(find_lto lang)
  if(LTO_${lang}_CHECKED)

    #LTO support was added for clang/gcc in 3.9
    if(${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION} VERSION_LESS 3.9)
        cmake_policy(SET CMP0054 NEW)
    message(STATUS "Checking for LTO Compatibility")
        # Since GCC 4.9 we need to use gcc-ar / gcc-ranlib / gcc-nm
        if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
            if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND NOT CMAKE_GCC_AR OR NOT CMAKE_GCC_RANLIB OR NOT CMAKE_GCC_NM)
                find_program(CMAKE_GCC_AR NAMES
                  "${_CMAKE_TOOLCHAIN_PREFIX}gcc-ar"
                  "${_CMAKE_TOOLCHAIN_PREFIX}gcc-ar-${_version}"
                  DOC "gcc provided wrapper for ar which adds the --plugin option"
                )
                find_program(CMAKE_GCC_RANLIB NAMES
                  "${_CMAKE_TOOLCHAIN_PREFIX}gcc-ranlib"
                  "${_CMAKE_TOOLCHAIN_PREFIX}gcc-ranlib-${_version}"
                  DOC "gcc provided wrapper for ranlib which adds the --plugin option"
                )
                # Not needed, but at least stay coherent
                find_program(CMAKE_GCC_NM NAMES
                  "${_CMAKE_TOOLCHAIN_PREFIX}gcc-nm"
                  "${_CMAKE_TOOLCHAIN_PREFIX}gcc-nm-${_version}"
                  DOC "gcc provided wrapper for nm which adds the --plugin option"
                )
                mark_as_advanced(CMAKE_GCC_AR CMAKE_GCC_RANLIB CMAKE_GCC_NM)
                set(CMAKE_LTO_AR ${CMAKE_GCC_AR})
                set(CMAKE_LTO_RANLIB ${CMAKE_GCC_RANLIB})
                set(CMAKE_LTO_NM ${CMAKE_GCC_NM})
            endif()
            if("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
                set(CMAKE_LTO_AR ${CMAKE_AR})
                set(CMAKE_LTO_RANLIB ${CMAKE_RANLIB})
                set(CMAKE_LTO_NM ${CMAKE_NM})
            endif()

            if(CMAKE_LTO_AR AND CMAKE_LTO_RANLIB)
              set(__lto_flags -flto)

              if(NOT CMAKE_${lang}_COMPILER_VERSION VERSION_LESS 4.7)
                list(APPEND __lto_flags -fno-fat-lto-objects)
              endif()

              if(NOT DEFINED CMAKE_${lang}_PASSED_LTO_TEST)
                set(__output_dir "${CMAKE_PLATFORM_INFO_DIR}/LtoTest1${lang}")
                file(MAKE_DIRECTORY "${__output_dir}")
                set(__output_base "${__output_dir}/lto-test-${lang}")

                execute_process(
                  COMMAND ${CMAKE_COMMAND} -E echo "void foo() {}"
                  COMMAND ${CMAKE_${lang}_COMPILER} ${__lto_flags} -c -xc -
                    -o "${__output_base}.o"
                  RESULT_VARIABLE __result
                  ERROR_QUIET
                  OUTPUT_QUIET
                )

                if("${__result}" STREQUAL "0")
                  execute_process(
                    COMMAND ${CMAKE_LTO_AR} cr "${__output_base}.a" "${__output_base}.o"
                    RESULT_VARIABLE __result
                    ERROR_QUIET
                    OUTPUT_QUIET
                  )
                endif()

                if("${__result}" STREQUAL "0")
                  execute_process(
                    COMMAND ${CMAKE_LTO_RANLIB} "${__output_base}.a"
                    RESULT_VARIABLE __result
                    ERROR_QUIET
                    OUTPUT_QUIET
                  )
                endif()

                if("${__result}" STREQUAL "0")
                  execute_process(
                    COMMAND ${CMAKE_COMMAND} -E echo "void foo(); int main() {foo();}"
                    COMMAND ${CMAKE_${lang}_COMPILER} ${__lto_flags} -xc -
                      -x none "${__output_base}.a" -o "${__output_base}"
                    RESULT_VARIABLE __result
                    ERROR_QUIET
                    OUTPUT_QUIET
                  )
                endif()

                if("${__result}" STREQUAL "0")
                  set(__lto_found TRUE)
                endif()

                set(CMAKE_${lang}_PASSED_LTO_TEST
                  ${__lto_found} CACHE INTERNAL
                  "If the compiler passed a simple LTO test compile")
              endif()
              if(CMAKE_${lang}_PASSED_LTO_TEST)
                message(STATUS "Checking for LTO Compatibility - works")
                set(LTO_${lang}_SUPPORT TRUE CACHE BOOL "Do we have LTO support ?")
                set(LTO_COMPILE_FLAGS -flto CACHE STRING "Link Time Optimization compile flags")
                set(LTO_LINK_FLAGS -flto CACHE STRING "Link Time Optimization link flags")
              else()
                message(STATUS "Checking for LTO Compatibility - not working")
              endif()

            endif()
          elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
              message(STATUS "Checking for LTO Compatibility - works (assumed for clang)")
              set(LTO_${lang}_SUPPORT TRUE CACHE BOOL "Do we have LTO support ?")
              set(LTO_COMPILE_FLAGS -flto CACHE STRING "Link Time Optimization compile flags")
              set(LTO_LINK_FLAGS -flto CACHE STRING "Link Time Optimization link flags")
          elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
              message(STATUS "Checking for LTO Compatibility - works")
              set(LTO_${lang}_SUPPORT TRUE CACHE BOOL "Do we have LTO support ?")
              set(LTO_COMPILE_FLAGS /GL CACHE STRING "Link Time Optimization compile flags")
              set(LTO_LINK_FLAGS -LTCG:INCREMENTAL CACHE STRING "Link Time Optimization link flags")
          else()
              message(STATUS "Checking for LTO Compatibility - compiler not handled by module")
          endif()
          mark_as_advanced(LTO_${lang}_SUPPORT LTO_COMPILE_FLAGS LTO_LINK_FLAGS)


          set(LTO_${lang}_CHECKED TRUE CACHE INTERNAL "" )

          if(CMAKE_GCC_AR AND CMAKE_GCC_RANLIB AND CMAKE_GCC_NM)
              # THIS IS HACKY BUT THERE IS NO OTHER SOLUTION ATM
              set(CMAKE_AR ${CMAKE_GCC_AR} CACHE FILEPATH "Forcing gcc-ar instead of ar" FORCE)
              set(CMAKE_NM ${CMAKE_GCC_NM} CACHE FILEPATH "Forcing gcc-nm instead of nm" FORCE)
              set(CMAKE_RANLIB ${CMAKE_GCC_RANLIB} CACHE FILEPATH "Forcing gcc-ranlib instead of ranlib" FORCE)
          endif()
    endif(${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION} VERSION_LESS 3.9)
  endif(NOT LTO_${lang}_CHECKED)

  #Special case for cmake older then 3.9, using a library for gcc/clang, but could setup the flags directly.
  #Taking advantage of the [debug,optimized] parameter of target_link_libraries
  if(${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION} VERSION_LESS 3.9)
    if(LTO_${lang}_SUPPORT)
        if(NOT TARGET __enable_lto_tgt)
            add_library(__enable_lto_tgt INTERFACE)
        endif()
        target_compile_options(__enable_lto_tgt INTERFACE ${LTO_COMPILE_FLAGS})
        #this might not work for all platforms... in which case we'll have to set the link flags on the target directly
        target_link_libraries(__enable_lto_tgt INTERFACE ${LTO_LINK_FLAGS} )
        macro(target_enable_lto _target _build_configuration)
            if(${_build_configuration} STREQUAL "optimized" OR ${_build_configuration} STREQUAL "debug" )
                target_link_libraries(${_target} PRIVATE ${_build_configuration} __enable_lto_tgt)
            else()
                target_link_libraries(${_target} PRIVATE __enable_lto_tgt)
            endif()
        endmacro()
    else()
        #In old cmake versions, we can set INTERPROCEDURAL_OPTIMIZATION even if not supported by the compiler
        #So if we didn't detect it, let cmake give it a try
        set(__IPO_SUPPORTED TRUE)
    endif()
  else()
      cmake_policy(SET CMP0069 NEW)
      include(CheckIPOSupported)
      # Optional IPO. Do not use IPO if it's not supported by compiler.
      check_ipo_supported(RESULT __IPO_SUPPORTED OUTPUT output)
      if(NOT __IPO_SUPPORTED)
        message(STATUS "IPO is not supported or broken.")
      else()
        message(STATUS "IPO is supported !")
      endif()
  endif()
  if(__IPO_SUPPORTED)
    macro(target_enable_lto _target _build_configuration)
        if(NOT ${_build_configuration} STREQUAL "debug" )
            #enable for all configurations
            set_target_properties(${_target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)
        endif()
        if(${_build_configuration} STREQUAL "optimized" )
            #blacklist debug configurations
            set(__enable_debug_lto FALSE)
        else()
            #enable only for debug configurations
            set(__enable_debug_lto TRUE)
        endif()
        get_property(DEBUG_CONFIGURATIONS GLOBAL PROPERTY DEBUG_CONFIGURATIONS)
        if(NOT DEBUG_CONFIGURATIONS)
            set(DEBUG_CONFIGURATIONS DEBUG) # This is what is done by CMAKE internally... since DEBUG_CONFIGURATIONS is empty by default
        endif()
        foreach(config IN LISTS DEBUG_CONFIGURATIONS)
            set_target_properties(${_target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION_${config} ${__enable_debug_lto})
        endforeach()
    endmacro()
  endif()

  if(NOT COMMAND target_enable_lto)
      macro(target_enable_lto _target _build_configuration)
      endmacro()
  endif()
endmacro()

################################################################################
# Coverage.
################################################################################

function(report_uninstalled PROGRAM)
  message(FATAL_ERROR "Failed to process coverage option. Program '${PROGRAM}' has not been installed.")
endfunction()

# TODO: genhtml
# https://github.com/blockspacer/CXCMake/blob/28da209d6c48997711908501ff8c33c79cd467e5/cmake/core/codecov/CXCMake_CodeCoverage.cmake
# https://github.com/luk036/physdes/blob/846f70f74d5f1ebb774d8b1895fcae6b88660bbb/cmake/CodeCoverage.cmake
# https://github.com/luk036/physdes/blob/846f70f74d5f1ebb774d8b1895fcae6b88660bbb/cmake/Coverage.cmake
function(add_coverage)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  set(options
    REQUIRED
  )
  set(oneValueArgs
    VERBOSE
    COVERAGE_DIR
  )
  set(multiValueArgs
    # skip
  )
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(args_unparsed ${ARGUMENTS_UNPARSED_ARGUMENTS})
  if(${ARGUMENTS_VERBOSE})
    message(STATUS
      "validate: ARGUMENTS_UNPARSED_ARGUMENTS=${ARGUMENTS_UNPARSED_ARGUMENTS}")
  endif(${ARGUMENTS_VERBOSE})

  # Set coverage report directory
  # default
  set(COVERAGE_DIR
    ${CMAKE_CURRENT_BINARY_DIR}/coverage
  )
  if(ARGUMENTS_COVERAGE_DIR)
    set(COVERAGE_DIR
      ${ARGUMENTS_COVERAGE_DIR}
    )
  endif(ARGUMENTS_COVERAGE_DIR)

  # Set source directories
  # set(SOURCE_SRC_DIR ${CMAKE_CURRENT_BINARY_DIR}/src)

  file(MAKE_DIRECTORY ${COVERAGE_DIR})

  # GNU compilers use gcov for coverage.
  if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_GNUCC)
    # Check that gcovr is installed.
    find_program_helper(gcovr
      PATHS
        ${CONAN_BIN_DIRS}
        ${CONAN_BIN_DIRS_LLVM_TOOLS}
      #NO_SYSTEM_ENVIRONMENT_PATH
      #NO_CMAKE_SYSTEM_PATH
      #${ARGUMENTS_UNPARSED_ARGUMENTS}
      REQUIRED
      OUT_VAR GCOVR
      VERBOSE TRUE
    )

    # cgov documentation: https://gcc.gnu.org/onlinedocs/gcc/Gcov.html
    # gcovr documentation: http://gcovr.com/guide.html
    if(GCOVR)
      set(CMAKE_CXX_OUTPUT_EXTENSION_REPLACE ON)

      set(CMAKE_C_FLAGS
        "${CMAKE_C_FLAGS} \
        -g -O0 --coverage")

      set(CMAKE_CXX_FLAGS
        "${CMAKE_CXX_FLAGS} \
        -g -O0 --coverage")

      set(CMAKE_EXE_LINKER_FLAGS
        "${CMAKE_EXE_LINKER_FLAGS} \
        -g -O0 --coverage")

      set(CMAKE_STATIC_LINKER_FLAGS
        "${CMAKE_STATIC_LINKER_FLAGS} \
        -g -O0 --coverage")

      set(CMAKE_SHARED_LINKER_FLAGS
        "${CMAKE_SHARED_LINKER_FLAGS} \
        -g -O0 --coverage")

      # TODO: custom --exclude-directories
      add_custom_target(coverage_${PROJECT_NAME}
        gcovr
          --root=${CMAKE_CURRENT_SOURCE_DIR}
          .
          --exclude-directories={test|doc|bench}
          --html
          --html-details
          --output=${COVERAGE_DIR}/index.html
          --object-directory=${CMAKE_CURRENT_BINARY_DIR}/impl
          --delete
          --print-summary
          --exclude-unreachable-branches
      )

      add_dependencies(coverage coverage_${PROJECT_NAME})
    else(GCOVR)
      report_uninstalled("gcovr")
    endif(GCOVR)

  # LLVM compilers use llvm-cov for coverage.
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # Check that llvm-cov is installed.
    find_program_helper(llvm-cov
      PATHS
        ${CONAN_BIN_DIRS}
        ${CONAN_BIN_DIRS_LLVM_TOOLS}
      #NO_SYSTEM_ENVIRONMENT_PATH
      #NO_CMAKE_SYSTEM_PATH
      #${ARGUMENTS_UNPARSED_ARGUMENTS}
      REQUIRED
      OUT_VAR LLVM_COV
      VERBOSE TRUE
    )

    # llvm-cov documentation: https://llvm.org/docs/CommandGuide/llvm-cov.html
    # llvm coverage documentation : https://clang.llvm.org/docs/SourceBasedCodeCoverage.html
    if(LLVM_COV)
      # Set profile output file name and directory.
      set(ENV{LLVM_PROFILE_FILE}
        ${COVERAGE_DIR}/coverage.profraw)

      # llvm-profdata merge -sparse coverage.profraw -o coverage.profdata
      # llvm-cov show ./foo -instr-profile=coverage.profdata -format=html -output-dir=${COVERAGE_DIR}

      set(CMAKE_C_FLAGS
        "${CMAKE_C_FLAGS} \
        -fprofile-instr-generate -fcoverage-mapping")

      set(CMAKE_CXX_FLAGS
        "${CMAKE_CXX_FLAGS} \
        -fprofile-instr-generate -fcoverage-mapping")

      set(CMAKE_LD_FLAGS
        "${CMAKE_LD_FLAGS} \
        -fprofile-instr-generate -fcoverage-mapping")

      set(CMAKE_EXE_LINKER_FLAGS
        "${CMAKE_EXE_LINKER_FLAGS} \
        -fprofile-instr-generate -fcoverage-mapping")

      set(CMAKE_STATIC_LINKER_FLAGS
        "${CMAKE_EXE_LINKER_FLAGS} \
        -fprofile-instr-generate -fcoverage-mapping")

      set(CMAKE_SHARED_LINKER_FLAGS
        "${CMAKE_SHARED_LINKER_FLAGS} \
        -fprofile-instr-generate -fcoverage-mapping")
    else(LLVM_COV)
      report_uninstalled("llvm-cov")
    endif(LLVM_COV)
  endif()
endfunction(add_coverage)

################################################################################
# Doxygen.
# TODO: create conan package https://github.com/mosra/m.css.git
################################################################################

# cached path to this file, forces refresh on each use
unset(CXCMAKE_DOC_LIST_DIR CACHE)
set(CXCMAKE_DOC_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}"
  CACHE STRING "(autogenerated) path to cmake file")

macro(enable_doxygen_generator Doxyfile_mcss_path)
  if(NOT DOXYGEN_FOUND)
    message(FATAL_ERROR "Doxygen not found, unable to generate documentation")
  endif()

  if(NOT EXISTS "${m_css_executable}")
    message(FATAL_ERROR "NOT FOUND: ${m_css_executable}")
  endif(NOT EXISTS "${m_css_executable}")

  # Add a hint to help Cmake to find the correct python version:
  # (see https://cmake.org/cmake/help/v3.0/module/FindPythonInterp.html)
  set(Python_ADDITIONAL_VERSIONS 3)
  # You can set -DPYTHON_EXECUTABLE=/usr/bin/python3
  find_package(PythonInterp 3 REQUIRED)
  if(NOT PYTHONINTERP_FOUND)
    message(FATAL_ERROR "Python 3 not found, unable to generate documentation")
  endif()

  # create dirs
  add_custom_command(
    OUTPUT ${DOXY_NO_THEME_OUTPUT_DIR}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${DOXY_NO_THEME_OUTPUT_DIR}
    COMMENT "Creating documentation directory for ${CMAKE_PROJECT_NAME}"
  )

  # configure Doxyfile.in
  add_custom_command(
    OUTPUT ${doxy_file} # this line links the command to below add_custom_target
    COMMAND ${CMAKE_COMMAND}
            -D "DOXY_TEMPLATE=${doxy_template}"
            -D "DOXY_DOC_DEST_DIR=${DOXY_DOC_DEST_DIR}"
            -D "DOXY_PROJECT_NAME=${DOXY_PROJECT_NAME}"
            -D "DOXY_PROJECT_VER=${DOXY_PROJECT_VER}"
            -D "DOXY_DOC_INPUT_ROOT_DIRS=${DOXY_DOC_INPUT_ROOT_DIRS}"
            -D "DOXY_DOC_EXCLUDE_PATTERNS_DIRS=${DOXY_DOC_EXCLUDE_PATTERNS_DIRS}"
            -D "DOXY_DOC_COMMON_IMG_PATH=${DOXY_DOC_COMMON_IMG_PATH}"
            -D "DOXY_FILE=${doxy_file}"
            -D "DOXY_ROOT_DIR=${DOXY_ROOT_DIR}"
            -D "DOXY_STRIP_FROM_PATH=${DOXY_ROOT_DIR}"
            -D "DOXY_OUTPUT_DIR=${DOXY_NO_THEME_OUTPUT_DIR}"
            -P ${CXCMAKE_DOC_LIST_DIR}/configure_doxygen.cmake
    DEPENDS ${DOXY_NO_THEME_OUTPUT_DIR}
    COMMENT "Generating Doxyfile for ${CMAKE_PROJECT_NAME}"
  )

  # copy DOXYMCSS_SRC to DOXYMCSS_DST
  add_custom_command(
    OUTPUT ${doxy_mcss_file}
    COMMAND ${CMAKE_COMMAND}
            -D "DOXYMCSS_SRC=${Doxyfile_mcss_path}"
            -D "DOXYMCSS_DST=${DOXY_MCSS_OUTPUT_DIR}"
            -P ${CXCMAKE_DOC_LIST_DIR}/create_doxy_mcss.cmake
    COMMENT "Generating Doxyfile-mcss for ${CMAKE_PROJECT_NAME}"
  )

  # build docs with mcss theme
  add_custom_command(
    OUTPUT ${DOXY_MCSS_OUTPUT_DIR}/html
    COMMAND ${PYTHON_EXECUTABLE} ${m_css_executable} --debug ${doxy_mcss_file}
    WORKING_DIRECTORY ${DOXY_ROOT_DIR}
    DEPENDS ${doxy_file} ${doxy_mcss_file}
    COMMENT "Creating documentation for ${CMAKE_PROJECT_NAME}"
  )

  # build docs in standard theme
  add_custom_target(doxyDoc_notheme
    COMMAND ${DOXYGEN_EXECUTABLE} "${DOXY_NO_THEME_OUTPUT_DIR}/Doxyfile"
    WORKING_DIRECTORY ${CMAKE_HOME_DIRECTORY}
    DEPENDS ${doxy_file} ${doxy_mcss_file}
    COMMENT "Building user's documentation into doxyDoc build dir..."
  )

  # build both mcss and standard theme
  add_custom_target(doxyDoc ALL
    DEPENDS
    ${DOXY_NO_THEME_OUTPUT_DIR}
    ${DOXY_MCSS_OUTPUT_DIR}
    ${doxy_file}
    ${doxy_mcss_file}
    ${DOXY_MCSS_OUTPUT_DIR}/html
    # doxyDoc_notheme
  )

  install(DIRECTORY ${DOXY_NO_THEME_OUTPUT_DIR}
    DESTINATION share/doc
    COMPONENT docs
    # OPTIONAL here means `do not raise an error if target file/dir not found`
    OPTIONAL)
endmacro(enable_doxygen_generator)

################################################################################
# GDB
################################################################################

# Helper macro for creating convenient targets
find_program(GDB_PATH gdb)

# Adds -run and -dbg targets
macro(addRunAndDebugTargets TARGET)
  add_custom_target(${TARGET}-run
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    USES_TERMINAL
    DEPENDS ${TARGET}
    COMMAND ./${TARGET})

  # convenience run gdb target
  if(GDB_PATH)
    add_custom_target(${TARGET}-gdb
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
      USES_TERMINAL
      DEPENDS ${TARGET}
      COMMAND ${GDB_PATH} ./${TARGET})
  endif()
endmacro()

################################################################################
# Uninstall (using install_manifest.txt)
################################################################################

# cached path to this file, forces refresh on each use
unset(CXCMAKE_UNINSTALL_LIST_DIR CACHE)
set(CXCMAKE_UNINSTALL_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}"
  CACHE STRING "(autogenerated) path to cmake file")

# see https://gitlab.kitware.com/cmake/community/wikis/FAQ#can-i-do-make-uninstall-with-cmake
macro(addinstallManifest)
  configure_file(
    "${CXCMAKE_UNINSTALL_LIST_DIR}/Uninstall.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/Uninstall.cmake"
    IMMEDIATE @ONLY)
  add_custom_target(uninstall
    COMMAND
      ${CMAKE_COMMAND}
      -P ${CMAKE_CURRENT_BINARY_DIR}/Uninstall.cmake)
endmacro()

# `configure_file_if_changed` able to detect configuration changes
# (changes in used cmake defines) or missing files
# i.e. it will not re-generate files if configuration not changed.
#
# MOTIVATION: `configure_file` will NOT re-generate file if used cmake defines
# changed. It able to detect changes only in input file before preprocessing.
# Use `configure_file_if_changed` as drop-in replacement for `configure_file`.
#
# It uses configure_file(... @ONLY), so make sure you declared
# all required CMake defines i.e. `@USE_ALLOCATOR_SHIM_FLAG@` in input file
# will expand to 1 in output file only if you declared in CMake
# `set(USE_ALLOCATOR_SHIM_FLAG "1")`.
#
# Function
#   configure_file_if_changed(INPUT <...> OUTPUT <...> TMP_FILE <...>)
#
function(configure_file_if_changed)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  #set(options ) # empty
  set(oneValueArgs INPUT OUTPUT TMP_FILE )
  set(multiValueArgs ) # empty
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(INPUT ${ARGUMENTS_INPUT})
  #
  set(OUTPUT ${ARGUMENTS_OUTPUT})
  #
  set(TMP_FILE ${ARGUMENTS_TMP_FILE})
  #
  set(UNPARSED_ARGUMENTS ${ARGUMENTS_UNPARSED_ARGUMENTS})
  #
  set(INTERNAL_NEED_TO_UPDATE_FILE FALSE)
  if(NOT EXISTS "${OUTPUT}")
    message(STATUS "Unable to find required file: ${OUTPUT}")
    message(STATUS "File will be re-generated: ${OUTPUT}")
    set(INTERNAL_NEED_TO_UPDATE_FILE TRUE)
  else()
    # remove old tmp file
    execute_process(
      COMMAND
        ${CMAKE_COMMAND} -E remove
          ${TMP_FILE}
      OUTPUT_QUIET
    )

    configure_file(${INPUT}
      ${TMP_FILE} @ONLY)

    # compare tmp file with the real file
    execute_process(
      COMMAND
        ${CMAKE_COMMAND} -E compare_files
          ${TMP_FILE}
          ${OUTPUT}
      RESULT_VARIABLE
        INTERNAL_NEED_TO_UPDATE_FILE
      OUTPUT_QUIET
    )
  endif()

  # update the real file if necessary
  if(INTERNAL_NEED_TO_UPDATE_FILE)
    # remove old file
    execute_process(
      COMMAND
        ${CMAKE_COMMAND} -E remove
          ${OUTPUT}
      OUTPUT_QUIET
    )

    # generate new file
    configure_file(${INPUT}
      ${OUTPUT} @ONLY)
    message(STATUS "File was re-generated: ${OUTPUT}")
  else()
    message(STATUS "Skipped file generation: ${OUTPUT}")
    if(NOT EXISTS "${OUTPUT}")
      message(FATAL_ERROR "Unable to find required file: ${OUTPUT}")
    endif()
  endif(INTERNAL_NEED_TO_UPDATE_FILE)

  # file generation may fail due to OS or drive issues (not enough disk space, etc.)
  if(NOT EXISTS "${OUTPUT}")
    message(WARNING "Something went wrong. Unable to find generated file: ${OUTPUT}")
  endif()

  set_source_files_properties(${OUTPUT}
    PROPERTIES GENERATED TRUE)
endfunction()

# Filter values through regex
function(filter_regex)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  #set(options ) # empty
  set(oneValueArgs OUTPUT_VAR IS_INCLUDE_REGEX REGEX)
  set(multiValueArgs INPUT_ITEMS)
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(INPUT_ITEMS)
  list(APPEND INPUT_ITEMS ${ARGUMENTS_INPUT_ITEMS})
  #
  set(OUTPUT_VAR ${ARGUMENTS_OUTPUT_VAR})
  #
  set(IS_INCLUDE_REGEX ${ARGUMENTS_IS_INCLUDE_REGEX})
  #
  set(REGEX ${ARGUMENTS_REGEX})
  #
  set(result_list)
  foreach(element ${INPUT_ITEMS})
    string(REGEX MATCH ${REGEX} has_match ${element})
    if(has_match)
      if(IS_INCLUDE_REGEX)
        list(APPEND result_list ${element})
      endif()
    else()
      if(NOT IS_INCLUDE_REGEX)
        list(APPEND result_list ${element})
      endif()
    endif()
  endforeach()

  # put result in parent scope variable
  set(${OUTPUT_VAR} ${result_list} PARENT_SCOPE)
endfunction()

# USAGE
#
# set(MY_SOURCES "1" "2" "3"  "4")
# remove_from_list(
#   CHECK_EXISTS TRUE
#   INPUT ${MY_SOURCES}
#   OUTPUT MY_SOURCES
#   ITEMS "1"
#         "3")
# message(STATUS "MY_SOURCES=${MY_SOURCES}")
# # Will print MY_SOURCES=2;4
#
function(remove_from_list)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  #set(options ) # empty
  set(oneValueArgs OUTPUT CHECK_EXISTS)
  set(multiValueArgs ITEMS INPUT)
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(result_input ${ARGUMENTS_INPUT})
  foreach(element ${ARGUMENTS_ITEMS})
    if(ARGUMENTS_CHECK_EXISTS)
      if (NOT "${element}" IN_LIST result_input)
        message(FATAL_ERROR "Unable to remove not-existing element ${element} from list ${result_input} to create ${ARGUMENTS_OUTPUT}")
      endif()
    endif(ARGUMENTS_CHECK_EXISTS)
    list(REMOVE_ITEM result_input ${element})
    if ("${element}" IN_LIST result_input)
      message(FATAL_ERROR "Unable to remove multiple occurrences of element ${element} from list ${result_input} to create ${ARGUMENTS_OUTPUT}")
    endif()
  endforeach()
  set(${ARGUMENTS_OUTPUT} ${result_input} PARENT_SCOPE)
endfunction()

# USAGE
#
# sanitize_lib(LIB_NAME ${PROJECT_NAME}
#   MSAN ${ENABLE_MSAN}
#   TSAN ${ENABLE_TSAN}
#   ASAN ${ENABLE_ASAN}
#   UBSAN ${ENABLE_UBSAN}
# )
function(sanitize_lib)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  #set(options ) # empty
  set(oneValueArgs LIB_NAME MSAN TSAN ASAN UBSAN) 
  # set(multiValueArgs ) # empty
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(LIB_NAME ${ARGUMENTS_LIB_NAME})
  #
  if(${ARGUMENTS_MSAN})
    message(STATUS "enabling MSAN on ${LIB_NAME}")
    add_msan_static_link(${LIB_NAME})
    add_msan_definitions(${LIB_NAME})
    add_msan_flags()
  else()
    message(STATUS
      "Disabled MSAN on ${LIB_NAME}")
  endif()

  if(${ARGUMENTS_TSAN})
    message(STATUS "enabling TSAN on ${LIB_NAME}")
    add_tsan_static_link(${LIB_NAME})
    add_tsan_definitions(${LIB_NAME})
    add_tsan_flags()
  else()
    message(STATUS
      "Disabled TSAN on ${LIB_NAME}")
  endif()

  if(${ARGUMENTS_ASAN})
    message(STATUS "enabling ASAN on ${LIB_NAME}")
    add_asan_static_link(${LIB_NAME})
    add_asan_definitions(${LIB_NAME})
    add_asan_flags()
  else()
    message(STATUS
      "Disabled ASAN on ${LIB_NAME}")
  endif()

  if(${ARGUMENTS_UBSAN})
    message(STATUS "enabling UBSAN on ${LIB_NAME}")
    add_ubsan_static_link(${LIB_NAME})
    add_ubsan_definitions(${LIB_NAME})
    add_ubsan_flags()
  else()
    message(STATUS
      "Disabled UBSAN on ${LIB_NAME}")
  endif()
endfunction(sanitize_lib)

macro(set_tests_default_compile_options target)
  target_compile_options(${target} PRIVATE
      $<$<CXX_COMPILER_ID:MSVC>:
      /W3 # Set warning level
      #/WX # Treats all compiler warnings as errors.
      >
      $<$<CXX_COMPILER_ID:GNU>:
      -Wformat=2
      -Wall
      -W
  ##              "$<$<CONFIG:RELEASE>:-Werror>" # Treats all compiler warnings as errors.
      -Wpedantic
      #-fsanitize-address-use-after-scope # https://clang.llvm.org/docs/AddressSanitizer.html
      #-fsanitize=pointer-compare # https://kristerw.blogspot.com/2018/06/useful-gcc-address-sanitizer-checks-not.html
      -fno-omit-frame-pointer # https://github.com/google/sanitizers/wiki/AddressSanitizer#using-addresssanitizer
      >
      $<$<CXX_COMPILER_ID:Clang>:
      -Wformat=2
      -Wall
      -W
  ##              "$<$<CONFIG:RELEASE>:-Werror>" # Treats all compiler warnings as errors.
      -Wpedantic
      -Wdeprecated-register
      #-fsanitize-address-use-after-scope # https://clang.llvm.org/docs/AddressSanitizer.html
      #-fsanitize=pointer-compare # https://kristerw.blogspot.com/2018/06/useful-gcc-address-sanitizer-checks-not.html
      -fno-omit-frame-pointer # https://github.com/google/sanitizers/wiki/AddressSanitizer#using-addresssanitizer
      >
  )

  # @see https://github.com/eranpeer/FakeIt
  target_compile_options( ${target} PRIVATE
    # If you don't use /ZI, you will have exceptions mocking destructors (which includes unique_ptr and other smart pointers).
    $<$<CXX_COMPILER_ID:MSVC>:/ZI>
    # On GCC, optimization flag O2 and O3 are not supported. You must compile the test project with -O1 or -O0.
    $<$<CXX_COMPILER_ID:GNU>:-O0>
    $<$<CXX_COMPILER_ID:Clang>:-O0> )

  target_compile_options(${target} PUBLIC
    -Wno-c++11-narrowing
    -Wno-c++98-compat
    -Wno-reserved-id-macro
    -Wno-macro-redefined
    -Wno-implicit-function-declaration
    -Wno-c++11-narrowing
    -Wno-builtin-macro-redefined
    #  format string is not a string literal
    -Wno-format-nonliteral
    -fno-exceptions # disabling exceptions
    # definition of implicit copy assignment operator
    # for 'Location' is deprecated because it has a user-declared copy constructor
    -Wno-deprecated-copy
    # trace_event.h: warning: unused function template 'AddMetadataEvent'
    -Wno-unused-template
    # warning: empty expression statement has no effect; remove unnecessary ';'
    # to silence this warning [-Wextra-semi-stmt]
    # TRACE_EVENT0
    -Wno-extra-semi-stmt
    -Wno-unused-parameter
    -Wno-unused-variable
    -Wno-old-style-cast
    # frame.h: warning: definition of implicit copy constructor for 'Frame'
    # is deprecated because it has a user-declared destructor
    -Wno-deprecated-copy-dtor
    # fixes base/logging.h:406:65: warning: token pasting of ',' and __VA_ARGS__ is a GNU extension [-Wgnu-zero-variadic-macro-arguments]
    -Wno-gnu-zero-variadic-macro-arguments
    -Wno-missing-field-initializers
    -Wno-implicit-int-float-conversion
    -Wno-gnu-statement-expression
  )
endmacro()

# USAGE
#
# set( TEST_ARGS
#   "--gtest_repeat=1"
#   "--gtest_shuffle")
#
# set(single_unittest_target run_test_${test_name})
#
# set( source_list
#   "main_gtest.cc"
#   "my_tests.cc"
#   "util_one.cc"
#   "util_two.cc")
#
# add_test_executable_and_targets("${test_name}" "${single_unittest_target}" "${source_list}" "${TEST_ARGS}")
#
macro(add_test_executable_and_targets test_name single_unittest_target source_list TEST_ARGS)
  add_executable(${test_name} ${source_list})

  add_test(
    NAME ${test_name}
    COMMAND ${test_name} ${TEST_ARGS})

  add_single_unittest_target(
    ADD_TARGET ${single_unittest_target}
    TEST_NAME ${test_name}
  )
endmacro()

# Creates target that can be used to run single unittest using
# cmake -E time cmake --build . --target ${ADD_TARGET}
#
# By default `ctest` runs all unittests,
# so we have to use regex `-R '^${TEST_NAME}'`.
#
# ARGUMENTS
#
# ADD_TARGET - target that will be created to run single unittest using regex
# TEST_NAME - target created by `add_test(...)`
# CTEST_ARGS - overrides default ctest options.
#
# NOTE: Takes into consideration environment varariable CTEST_ARGS
#
# CTEST_ARGS="--repeat-until-fail 9;--force-new-ctest-process;--verbose;--output-on-failure;--parallel 9;--timeout 600" \
#   cmake -E time \
#     conan build .. --build-folder=. \
#       > .test_log
#
# USAGE
#
# set(GTEST_TEST_ARGS
#   "--gtest_repeat=1"
#   "--gtest_shuffle")
#
# add_test(
#   NAME ${target}
#   COMMAND ${target} ${GTEST_TEST_ARGS})
#
# add_single_unittest_target(
#   ADD_TARGET run_test_${target}
#   TEST_NAME ${target}
# )
#
function(add_single_unittest_target)
  # see https://cliutils.gitlab.io/modern-cmake/chapters/basics/functions.html
  #set(options ) # empty
  set(oneValueArgs TEST_NAME ADD_TARGET CTEST_ARGS)
  #set(multiValueArgs ) # empty
  #
  cmake_parse_arguments(
    ARGUMENTS # prefix of output variables
    "${options}" # list of names of the boolean arguments (only defined ones will be true)
    "${oneValueArgs}" # list of names of mono-valued arguments
    "${multiValueArgs}" # list of names of multi-valued arguments (output variables are lists)
    ${ARGN} # arguments of the function to parse, here we take the all original ones
  )
  #
  set(ADD_TARGET ${ARGUMENTS_ADD_TARGET})
  #
  set(TEST_NAME ${ARGUMENTS_TEST_NAME})
  #
  if(NOT "${ARGUMENTS_CTEST_ARGS}" STREQUAL "")
    set(CTEST_ARGS ${ARGUMENTS_CTEST_ARGS})
  elseif(NOT "$ENV{CTEST_ARGS}" STREQUAL "")
    set(CTEST_ARGS $ENV{CTEST_ARGS})
  else()
    # default CTest options
    set(CTEST_ARGS
      # Require each test to run <n> times without failing in order to pass.
      --repeat-until-fail 1
      --force-new-ctest-process
      --verbose
      --output-on-failure
      --config $<CONFIG>
      --parallel ${NUM_PROCESSORS}
      --timeout 600
    )
  endif()
  #
  # Load addional modules
  include(ProcessorCount)
  ProcessorCount(NUM_PROCESSORS)
  set(NUM_PROCESSORS ${NUM_PROCESSORS} CACHE STRING "Processor count")
  set(TARGET_CTEST_COMMAND
    ${CMAKE_CTEST_COMMAND}
      -R '^${TEST_NAME}'
      ${CTEST_ARGS}
  )
  add_custom_target(${ADD_TARGET}
      COMMAND ${CMAKE_COMMAND} -E echo ----------------------------------
      COMMAND ${TARGET_CTEST_COMMAND}
      COMMAND ${CMAKE_COMMAND} -E echo ----------------------------------
      COMMENT "Running ${TARGET_CTEST_COMMAND}"
      DEPENDS ${TEST_NAME}
  )
endfunction(add_single_unittest_target)
