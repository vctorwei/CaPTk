# Macro to add, link, build, and install an application and it's cwl file
MACRO( CAPTK_ADD_EXECUTABLE APPLICATION SOURCESFILES DEPENDENT_LIBS )

  ADD_EXECUTABLE( 
    ${APPLICATION}
    ${SOURCESFILES}
  )
  
  TARGET_LINK_LIBRARIES( 
    ${APPLICATION}
    ${DEPENDENT_LIBS}
  )

  SET_TARGET_PROPERTIES( ${APPLICATION} PROPERTIES FOLDER "${CaPTk_CLIs_Folder}" )

  ADD_DEPENDENCIES( ${APPLICATION} ${LIBNAME_Applications} ${LIBNAME_FeatureExtractor} ${LIBNAME_CBICATK} )

  IF (APPLE) 
    # list (APPEND STANDALONE_APPS_LIST ${APPLICATION})
    INSTALL( 
      TARGETS ${APPLICATION}
      BUNDLE DESTINATION .
      RUNTIME DESTINATION ${EXE_NAME}.app/Contents/Resources/bin
      LIBRARY DESTINATION ${EXE_NAME}.app/Contents/Resources/lib
      CONFIGURATIONS "${CMAKE_CONFIGURATION_TYPES}"
      PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    ) 

  ELSE()
    INSTALL( 
      TARGETS ${APPLICATION}
      BUNDLE DESTINATION .
      RUNTIME DESTINATION bin
      LIBRARY DESTINATION lib
      CONFIGURATIONS "${CMAKE_CONFIGURATION_TYPES}"
      PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )

  ENDIF()

  # Add test for run tests
  ADD_TEST( NAME ${APPLICATION}_rt COMMAND ${APPLICATION} -rt )

  CWL_INSTALL(${APPLICATION})
  
ENDMACRO()

# Macro to generate and install a cwl file after target application is built
MACRO(CWL_INSTALL APPLICATION)

  # Post build cwl generation
  add_custom_command(TARGET ${APPLICATION}
    POST_BUILD
    COMMAND ${APPLICATION} -cwl
    COMMENT "Generating cwl for ${APPLICATION}..."
    VERBATIM
  )
  
  IF (APPLE) 
    # list (APPEND STANDALONE_APPS_LIST ${APPLICATION})
    INSTALL( 
      FILES ${PROJECT_BINARY_DIR}/${APPLICATION}.cwl
      DESTINATION ${EXE_NAME}.app/Contents/Resources/bin
    ) 
  
  ELSEIF(WIN32)
    INSTALL( 
      FILES ${PROJECT_BINARY_DIR}/$<CONFIGURATION>/${APPLICATION}.cwl
      DESTINATION bin
    )
  
  ELSE()
    INSTALL( 
      FILES ${PROJECT_BINARY_DIR}/${APPLICATION}.cwl
      DESTINATION bin
    )
  
  ENDIF()

ENDMACRO()

# macro to find all sub-directories
MACRO(SUBDIRLIST result curdir)
  FILE(GLOB children
    RELATIVE ${curdir} ${curdir}/*
    PATTERN "svn" EXCLUDE
  )
  SET(dirlist "")
  FOREACH(child ${children})
    IF(IS_DIRECTORY ${curdir}/${child})
      LIST(APPEND dirlist ${child})
    ENDIF()
  ENDFOREACH()
  SET(${result} ${dirlist})
ENDMACRO()

# a common version number is always maintained in CaPTk and all its applications
MACRO( CAPTK_ADD_PROJECT NEW_PROJECT_NAME NEW_PROJECT_VERSION )
  
  IF( "${PROJECT_VERSION}" STREQUAL "" )
    # this basically means that packaging will not be happening since the project is independent of CaPTk 
    PROJECT( ${NEW_PROJECT_NAME} )
    SET( PROJECT_VERSION "${NEW_PROJECT_VERSION}" )
    ADD_DEFINITIONS( -DPROJECT_VERSION="${PROJECT_VERSION}" )
    SET( CMAKE_CONFIGURATION_TYPES "Debug;Release" CACHE STRING "Default configuration types" FORCE )
  ELSE()
    PROJECT( ${NEW_PROJECT_NAME} )  
  ENDIF()  
  
ENDMACRO()

# macro to handle initial setup of projects (no library dependency management)
MACRO( CAPTK_INITIAL_SETUP )

FIND_PACKAGE( ITK REQUIRED )
INCLUDE( ${ITK_USE_FILE} )

SET(CMAKE_CXX_STANDARD 11)
SET(CMAKE_CXX_STANDARD_REQUIRED YES) 
SET_PROPERTY( GLOBAL PROPERTY USE_FOLDERS ON )

SET( CACHED_INCLUDE_DIRS
  ${CACHED_INCLUDE_DIRS}
  ${PROJECT_SOURCE_DIR}/src/
  ${PROJECT_SOURCE_DIR}/src/depends/
  CACHE STRING "All include directories" FORCE
)
#MESSAGE( STATUS "[DEBUG] CACHED_INCLUDE_DIRS@Macro: ${CACHED_INCLUDE_DIRS}" )

FILE( GLOB_RECURSE CURRENT_APPLICATION_DEPENDS "${PROJECT_SOURCE_DIR}/src/depends/*" )
FILE( GLOB CURRENT_APPLICATION_SOURCES "${PROJECT_SOURCE_DIR}/src/${PROJECT_NAME}*" )

SET( APPLICATION_SOURCES ${CURRENT_APPLICATION_DEPENDS} ${CURRENT_APPLICATION_SOURCES} CACHE STRING "All application sources and depends" FORCE )

# set the install path
IF( CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT )
  SET( CMAKE_INSTALL_PREFIX ${PROJECT_BINARY_DIR}/install )
ENDIF( )

#  set cmake up
IF(WIN32)
  SET(CMAKE_C_USE_RESPONSE_FILE_FOR_OBJECTS 1)
  SET(CMAKE_CXX_USE_RESPONSE_FILE_FOR_OBJECTS 1)
  SET(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES 1)
  SET(CMAKE_CXX_USE_RESPONSE_FILE_FOR_INCLUDES 1)
  SET(CMAKE_C_RESPONSE_FILE_LINK_FLAG "@")
  SET(CMAKE_CXX_RESPONSE_FILE_LINK_FLAG "@")
  SET(CMAKE_C_CREATE_STATIC_LIBRARY "<CMAKE_AR> rc <TARGET> <LINK_FLAGS> <OBJECTS>") 
  SET(CMAKE_CXX_CREATE_STATIC_LIBRARY "<CMAKE_AR> rc <TARGET> <LINK_FLAGS> <OBJECTS>") 
ENDIF()

IF(LINUX)
  SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
ENDIF()

# find openmp flags
IF(APPLE)
  SET(OPENMP_LIBRARIES "${CMAKE_C_COMPILER}/../../lib")
  SET(OPENMP_INCLUDES "${CMAKE_C_COMPILER}/../../include")
  
  MESSAGE ("${CMAKE_C_COMPILER}")
  
  SET(OpenMP_C "${CMAKE_C_COMPILER}")
  SET(OpenMP_C_FLAGS "-fopenmp=libomp -Wno-unused-command-line-argument")
  SET(OpenMP_C_LIB_NAMES "libomp" "libgomp" "libiomp5")
  SET(OpenMP_libomp_LIBRARY ${OpenMP_C_LIB_NAMES})
  SET(OpenMP_libgomp_LIBRARY ${OpenMP_C_LIB_NAMES})
  SET(OpenMP_libiomp5_LIBRARY ${OpenMP_C_LIB_NAMES})
  SET(OpenMP_CXX "${CMAKE_CXX_COMPILER}")
  SET(OpenMP_CXX_FLAGS "-fopenmp=libomp -Wno-unused-command-line-argument")
  SET(OpenMP_CXX_LIB_NAMES "libomp" "libgomp" "libiomp5")
  SET(OpenMP_libomp_LIBRARY ${OpenMP_CXX_LIB_NAMES})
  SET(OpenMP_libgomp_LIBRARY ${OpenMP_CXX_LIB_NAMES})
  SET(OpenMP_libiomp5_LIBRARY ${OpenMP_CXX_LIB_NAMES})
  
  INCLUDE_DIRECTORIES("${OPENMP_INCLUDES}")
  LINK_DIRECTORIES("${OPENMP_LIBRARIES}")

ELSE()

  FIND_PACKAGE(OpenMP REQUIRED)
  SET( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}" )
  SET( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}" )

ENDIF()
  
ENDMACRO()