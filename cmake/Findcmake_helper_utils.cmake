# cmake utils

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
    message(STATUS "validate: ARGUMENTS_UNPARSED_ARGUMENTS=${ARGUMENTS_UNPARSED_ARGUMENTS}")
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
    message(STATUS "ARGUMENTS_UNPARSED_ARGUMENTS=${ARGUMENTS_UNPARSED_ARGUMENTS}")
    message(STATUS "${ARGUMENTS_OUT_VAR}_FOUND_PROGRAM=${${ARGUMENTS_OUT_VAR}_FOUND_PROGRAM}")
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
    message(STATUS "validate: ARGUMENTS_UNPARSED_ARGUMENTS=${ARGUMENTS_UNPARSED_ARGUMENTS}")
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
    message(STATUS
      "found cppcheck config file: ${CPPCHECK_SUPRESSIONS}"
    )
  else()
    message(WARNING
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
              # if the ${ITEM} is non-empty, than append it
              $<$<BOOL:${collected_defines}>:-D$<JOIN:${collected_defines}, -D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, than append it
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
    message(STATUS
      "found valgrind config file: ${MEMORYCHECK_SUPRESSIONS}"
    )
  else()
    message(WARNING
      "unable to find valgrind config file: ${MEMORYCHECK_SUPRESSIONS}"
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
              # if the ${ITEM} is non-empty, than append it
              $<$<BOOL:${collected_defines}>:-extra-arg=-D$<JOIN:${collected_defines}, -extra-arg=-D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, than append it
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
              # if the ${ITEM} is non-empty, than append it
              #$<$<BOOL:${collected_defines}>:-D$<JOIN:${collected_defines}, -D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, than append it
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
              # if the ${ITEM} is non-empty, than append it
              $<$<BOOL:${collected_defines}>:-extra-arg=-D$<JOIN:${collected_defines}, -extra-arg=-D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, than append it
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
  )
  #
  # USAGE:
  # cmake -E time cmake --build . --target TARGET_NAME_run_iwyu
  if(ARGUMENTS_VERBOSE)
    message(STATUS "added new target: ${ARGUMENTS_TARGET_NAME}_run_iwyu")
  endif(ARGUMENTS_VERBOSE)
  add_custom_target(${ARGUMENTS_TARGET_NAME}_run_iwyu
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
      ${CMAKE_BINARY_DIR}/${ARGUMENTS_TARGET_NAME}_iwyu_report.xml
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
# cmake -E time cmake --build . --target TARGET_NAME_run_iwyu
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
          #
          #get_all_compile_definitions(collected_defines
          #  ${TARGET_NAME}
          #)
          ##
          #get_all_include_directories(collected_includes
          #  ${TARGET_NAME}
          #)
          ##
          #get_target_sources(TARGET_SOURCES
          #  ${TARGET_NAME}
          #)
          #
          #add_iwyu_target(
          #  TARGET_NAME ${TARGET_NAME}
          #  IWYU_FULL_CMD
          #    ${IWYU_RUNNABLE}
          #    # NOTE: generator expression, expands during build time
          #    # if the ${ITEM} is non-empty, than append it
          #    $<$<BOOL:${collected_defines}>:-D$<JOIN:${collected_defines}, -D>>
          #    # NOTE: generator expression, expands during build time
          #    # if the ${ITEM} is non-empty, than append it
          #    # To suppress compiler diagnostic messages
          #    # from third-party headers just use -isystem
          #    # instead of -I to include those headers.
          #    # $<$<BOOL:${collected_includes}>:-extra-arg=-isystem$<JOIN:${collected_includes}, -extra-arg=-isystem>>
          #    $<$<BOOL:${collected_includes}>:-I$<JOIN:${collected_includes}, -I>>
          #    #$<$<BOOL:${TARGET_SOURCES}>:--check_also=$<JOIN:${TARGET_SOURCES}, --check_also=>>
          #    ${TARGET_SOURCES}
          #  EXTRA_OPTIONS ${IWYU_OPTIONS}
          #)
          #if(CHECK_TARGETS_DEPEND)
          #  # run iwyu on each build of target
          #  add_dependencies(
          #    ${TARGET_NAME}
          #    ${TARGET_NAME}_run_iwyu
          #  )
          #endif(CHECK_TARGETS_DEPEND)

          #separate_arguments(IWYU_OPTIONS)

          set_property(TARGET ${TARGET_NAME}
            PROPERTY
              CXX_INCLUDE_WHAT_YOU_USE
                ${IWYU_RUNNABLE} ${IWYU_OPTIONS}
          )
        endforeach()
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
              # if the ${ITEM} is non-empty, than append it
              #$<$<BOOL:${collected_defines}>:-extra-arg=-D$<JOIN:${collected_defines}, -extra-arg=-D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, than append it
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
              # if the ${ITEM} is non-empty, than append it
              #$<$<BOOL:${collected_defines}>:-extra-arg=-D$<JOIN:${collected_defines}, -extra-arg=-D>>
              # NOTE: generator expression, expands during build time
              # if the ${ITEM} is non-empty, than append it
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

  set(CMAKE_C_COMPILER
    ${CLANG_PROGRAM}
    CACHE string
    "Clang C compiler" FORCE)

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

  set(CMAKE_CXX_COMPILER
    ${CLANGPP_PROGRAM}
    CACHE string
    "Clang C++ compiler" FORCE)

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
  find_program_helper(llvm-ld
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

  # Set linkers and other build tools.
  set(CMAKE_AR      "${LLVM_AR_PROGRAM}")
  set(CMAKE_LINKER  "${LLVM_LD_PROGRAM}")
  set(CMAKE_NM      "${LLVM_NM_PROGRAM}")
  set(CMAKE_OBJDUMP "${LLVM_OBJDUMP_PROGRAM}")
  set(CMAKE_RANLIB  "${LLVM_RANLIB_PROGRAM}")
endmacro(compile_with_llvm_tools)
