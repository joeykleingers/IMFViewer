

if( "${IMFViewer_EXTRA_PLUGINS}" STREQUAL "")
 set(IMFViewer_EXTRA_PLUGINS "" CACHE STRING "")
else()
  set(IMFViewer_EXTRA_PLUGINS ${IMFViewer_EXTRA_PLUGINS} CACHE STRING "")
endif()


# --------------------------------------------------------------------
# This function optionally compiles a named plugin when compiling IMFViewer
# This function will add in an Option "IMFViewer_BUILD_PLUGIN_${NAME} which
# the programmer can use to enable/disable the compiling of specific plugins
# Arguments:
# PLUGIN_NAME The name of the Plugin
# PLUGIN_SOURCE_DIR The source directory for the plugin
function(IMFViewer_COMPILE_PLUGIN)
    set(options)
    set(oneValueArgs PLUGIN_NAME PLUGIN_SOURCE_DIR)
    cmake_parse_arguments(PLUG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
    set_property(GLOBAL PROPERTY PluginNumFilters "-1")

    option(IMFViewer_BUILD_PLUGIN_${PLUG_PLUGIN_NAME} "Build the ${PLUG_PLUGIN_NAME}" ON)
    
    if(IMFViewer_BUILD_PLUGIN_${PLUG_PLUGIN_NAME})
        add_subdirectory(${PLUG_PLUGIN_SOURCE_DIR} ${PROJECT_BINARY_DIR}/Plugins/${PLUG_PLUGIN_NAME})
        get_property(PluginNumFilters GLOBAL PROPERTY PluginNumFilters)
        set_property(GLOBAL PROPERTY ${PLUG_PLUGIN_NAME}_NumFilters ${PluginNumFilters})

        if(${PluginNumFilters} GREATER -1)
          # get_property(IMFViewerDocRoot GLOBAL PROPERTY IMFViewerDocRoot)
          # add_custom_target(${PLUG_PLUGIN_NAME}_DOC_FOLDER_COPY ALL
          #   COMMAND ${CMAKE_COMMAND} -E copy_directory "${PLUG_PLUGIN_SOURCE_DIR}/Documentation/${PLUG_PLUGIN_NAME}Filters/"
          #   "${IMFViewerDocRoot}/ReferenceManual/Plugins/${PLUG_PLUGIN_NAME}/"
          #   COMMENT "${PLUG_PLUGIN_NAME}: Copying Documentation to build directory")
          # set_target_properties(${PLUG_PLUGIN_NAME}_DOC_FOLDER_COPY PROPERTIES FOLDER ZZ_COPY_FILES)

          message(STATUS "${PLUG_PLUGIN_NAME} [ENABLED] ${PluginNumFilters} Filters")
          #- Now set up the dependency between the main application and each of the plugins so that
          #- things like Visual Studio are forced to rebuild the plugins when launching
          #- the IMFViewer application
          if(IMFViewer_BUILD_PLUGIN_${PLUG_PLUGIN_NAME} AND TARGET IMFViewer AND TARGET ${PLUG_PLUGIN_NAME})
            add_dependencies(IMFViewer ${PLUG_PLUGIN_NAME})
          endif()
        else()
          set(IMFViewer_BUILD_PLUGIN_${PLUG_PLUGIN_NAME} "OFF" CACHE BOOL "Build the ${PLUG_PLUGIN_NAME}" FORCE)
          message(STATUS "${PLUG_PLUGIN_NAME} [DISABLED]: Use -DIMFViewer_BUILD_PLUGIN_${PLUG_PLUGIN_NAME}=ON to Enable Plugin")
        endif()

    else()
        message(STATUS "${PLUG_PLUGIN_NAME} [DISABLED]: Use -DIMFViewer_BUILD_PLUGIN_${PLUG_PLUGIN_NAME}=ON to Enable Plugin")
    endif()
endfunction()

# --------------------------------------------------------------------
#
#
#
#
function(IMFViewer_ADD_PLUGINS)
    set(options)
    set(multiValueArgs PLUGIN_NAMES)
    cmake_parse_arguments(PLUG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
    get_filename_component(IMFViewer_PARENT_DIR  ${PROJECT_SOURCE_DIR}/Source DIRECTORY)
    #message(STATUS "IMFViewer_PARENT_DIR: ${IMFViewer_PARENT_DIR}")

    #-- Attempt to look in our local source directory for the plugin. Anywhere else
    # and the user will have to put the entire path into CMake manually.
    foreach(d3dPlugin ${PLUG_PLUGIN_NAMES})

      # message(STATUS "Evaluating Plugin: ${d3dPlugin}...")

      if(DEFINED ${d3dPlugin}_SOURCE_DIR AND "${${d3dPlugin}_SOURCE_DIR}" STREQUAL "")
        set(pluginSearchDir ${PROJECT_CODE_DIR}/Plugins/${d3dPlugin})
        set(${d3dPlugin}_SOURCE_DIR ${pluginSearchDir} CACHE PATH "")
      endif()


      if(NOT DEFINED ${d3dPlugin}_SOURCE_DIR)
          set(pluginSearchDir ${PROJECT_CODE_DIR}/Plugins/${d3dPlugin})
          if(EXISTS ${pluginSearchDir})
            set(${d3dPlugin}_SOURCE_DIR ${pluginSearchDir} CACHE PATH "")
            message(STATUS "Plugin: Defining ${d3dPlugin}_SOURCE_DIR to ${${d3dPlugin}_SOURCE_DIR}")
          else()

            set(pluginSearchDir ${PROJECT_SOURCE_DIR}/Source/ExternalProjects/Plugins/${d3dPlugin})
            if(EXISTS ${pluginSearchDir})
                set(${d3dPlugin}_SOURCE_DIR ${pluginSearchDir} CACHE PATH "")
                message(STATUS "Plugin: Defining ${d3dPlugin}_SOURCE_DIR to ${${d3dPlugin}_SOURCE_DIR}")
            endif()
            set(pluginSearchDir ${IMFViewer_PARENT_DIR}/IMFViewer_Plugins/${d3dPlugin})
            if(EXISTS ${pluginSearchDir})
                set(${d3dPlugin}_SOURCE_DIR ${pluginSearchDir} CACHE PATH "")
                message(STATUS "Plugin: Defining ${d3dPlugin}_SOURCE_DIR to ${${d3dPlugin}_SOURCE_DIR}")
            endif()
          endif()
      endif()

      # Mark these variables as advanced
      mark_as_advanced(${d3dPlugin}_SOURCE_DIR)


    # Now that we have defined where the user's plugin directory is at we
    # need to make sure it have a CMakeLists.txt file in it
      if(EXISTS ${${d3dPlugin}_SOURCE_DIR}/CMakeLists.txt)
        set(${d3dPlugin}_IMPORT_FILE ${d3dPlugin}_SOURCE_DIR/CMakeLists.txt)
      endif()


    # By this point we should have everything defined and ready to go...
      if(DEFINED ${d3dPlugin}_SOURCE_DIR AND DEFINED ${d3dPlugin}_IMPORT_FILE)
          #message(STATUS "Plugin: Adding Plugin ${${d3dPlugin}_SOURCE_DIR}")
          IMFViewer_COMPILE_PLUGIN(PLUGIN_NAME ${d3dPlugin}
                                 PLUGIN_SOURCE_DIR ${${d3dPlugin}_SOURCE_DIR})
      else()
          set(${d3dPlugin}_SOURCE_DIR ${pluginSearchDir} CACHE PATH "" FORCE)
          message(FATAL_ERROR "Plugin: The directory for plugin ${d3dPlugin} was not found. Use -D${d3dPlugin}_SOURCE_DIR=/Path/To/PluginDir")
      endif()

    endforeach()

endfunction()

set(PluginNumFilters 0)
set_property(GLOBAL PROPERTY PluginNumFilters ${PluginNumFilters})

#-----------------
# These are the core plugins that need to be built
set(IMFViewer_BASE_PLUGINS
  ITKImageProcessing
)

get_filename_component(IMFViewer_PARENT_DIR  ${PROJECT_SOURCE_DIR}/Source DIRECTORY)
set(IMFViewer_ALL_PLUGINS ${IMFViewer_BASE_PLUGINS} ${IMFViewer_EXTRA_PLUGINS} )

message(STATUS "*******************************************************")
message(STATUS "* Base Plugins                                        *")
message(STATUS "*******************************************************")
IMFViewer_ADD_PLUGINS(PLUGIN_NAMES ${IMFViewer_BASE_PLUGINS})


message(STATUS "*******************************************************")
message(STATUS "* Extra External Plugins                              *")
message(STATUS "*******************************************************")
IMFViewer_ADD_PLUGINS(PLUGIN_NAMES ${IMFViewer_EXTRA_PLUGINS})

