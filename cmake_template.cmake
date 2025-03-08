cmake_minimum_required(VERSION 3.10)
project(::PROJECT_NAME::)
set(CMAKE_C_STANDARD 11)

# 设置安装目录
set(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/::INSTALL_DIR::" CACHE PATH "Install path prefix" FORCE)

# 设置全局输出目录
# 使用 CACHE 确保子项目也会继承这些设置
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "Global runtime output directory")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "Global library output directory")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib" CACHE PATH "Global archive output directory")

# 确保子项目也使用相同的输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" CACHE PATH "Global debug runtime output directory")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}" CACHE PATH "Global debug library output directory")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}" CACHE PATH "Global debug archive output directory")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" CACHE PATH "Global release runtime output directory")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}" CACHE PATH "Global release library output directory")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}" CACHE PATH "Global release archive output directory")

# 设置子项目的输出目录
set(BUILD_TESTING FALSE CACHE BOOL "" FORCE) # for hashlink

set(WITH_VM FALSE CACHE BOOL "Skip building hl executable" FORCE)

# 覆盖 HashLink 的安装路径
set(CMAKE_INSTALL_BINDIR "." CACHE PATH "Installation directory for executables" FORCE)
set(CMAKE_INSTALL_LIBDIR "." CACHE PATH "Installation directory for libraries" FORCE)
set(CMAKE_INSTALL_INCLUDEDIR "." CACHE PATH "Installation directory for header files" FORCE)

# 强制设置 HashLink 的输出目录
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_INIT "${CMAKE_BINARY_DIR}/bin")
set(HDLL_DESTINATION "${CMAKE_BINARY_DIR}/bin" CACHE STRING "HDLL installation directory")


# import hashlink
add_subdirectory(
    ::HASHLINK_SOURCE_DIR::
    ::HASHLINK_LIBRARY_DIR::
)

# SDL2
add_subdirectory(
    ::SDL_SOURCE_DIR::
    ::SDL_LIBRARY_DIR::
)


# your project
include_directories(.)
set(SOURCES
    ::ENTRY_POINT::
)

set(::PROJECT_NAME::_LINK_LIBRARIES
    libhl
    sdl.hdll
    fmt.hdll
    ui.hdll
    uv.hdll
    SDL2main
)

add_executable(::PROJECT_NAME:: ${SOURCES})
add_library(::PROJECT_NAME::_lib SHARED ${SOURCES})
target_link_libraries(::PROJECT_NAME:: PRIVATE 
    ${::PROJECT_NAME::_LINK_LIBRARIES}
)
target_link_libraries(::PROJECT_NAME::_lib PRIVATE 
    ${::PROJECT_NAME::_LINK_LIBRARIES}
)

# 设置 RUNPATH 而不是 RPATH
# $ORIGIN 表示可执行文件所在目录
# $ORIGIN/../lib 表示可执行文件上级目录的 lib 子目录
set_target_properties(::PROJECT_NAME:: PROPERTIES
    BUILD_WITH_INSTALL_RPATH TRUE
    SKIP_BUILD_RPATH FALSE
    INSTALL_RPATH "$ORIGIN;$ORIGIN/../lib"
    INSTALL_RPATH_USE_LINK_PATH TRUE
)

set_target_properties(::PROJECT_NAME::_lib PROPERTIES
    BUILD_WITH_INSTALL_RPATH TRUE
    SKIP_BUILD_RPATH FALSE
    INSTALL_RPATH "$ORIGIN;$ORIGIN/../lib"
    INSTALL_RPATH_USE_LINK_PATH TRUE
)

# 安装规则
install(
    TARGETS ${PROJECT_NAME} ${PROJECT_NAME}_lib
    RUNTIME DESTINATION .
    LIBRARY DESTINATION .
    ARCHIVE DESTINATION .
)

# 复制 HDLL 文件
install(
    DIRECTORY ${CMAKE_BINARY_DIR}/bin/
    DESTINATION .
    FILES_MATCHING PATTERN "*.hdll"
)


# for debug reason, list all targets
function(print_all_targets)
    # get all_subdirectories recursively
    set(all_dirs ${CMAKE_CURRENT_SOURCE_DIR})
    get_directory_property(initial_subdirs SUBDIRECTORIES)
    list(APPEND all_dirs ${initial_subdirs})
    
    set(dir_groups)

    while(NOT "${all_dirs}" STREQUAL "")
        list(GET all_dirs 0 current_dir)
        list(REMOVE_AT all_dirs 0)


        get_directory_property(targets DIRECTORY "${current_dir}" BUILDSYSTEM_TARGETS)
        
        get_directory_property(subdirs DIRECTORY "${current_dir}" SUBDIRECTORIES)
        list(APPEND all_dirs ${subdirs})

        foreach(target ${targets})
            if(TARGET "${target}")
                get_target_property(src_dir "${target}" SOURCE_DIR)
                get_target_property(type "${target}" TYPE)

                # filter out utility targets
                if("${type}" STREQUAL "UTILITY")
                    continue()
                endif()

                if(src_dir)
                    get_filename_component(src_dir "${src_dir}" ABSOLUTE)
                else()
                    set(src_dir "[GENERATED]")
                endif()

                # convert string /home/user/work/mygames/libs/hashlink
                # to
                # string _home_user_work_mygames_libs_hashlink
                string(REPLACE "/" "_" dir_key "${src_dir}")
                
                if(NOT DEFINED dir_${dir_key}_targets)
                    set(dir_${dir_key}_path "${src_dir}")
                    set(dir_${dir_key}_targets)
                    list(APPEND dir_groups "${dir_key}")
                endif()
                
                list(FIND dir_${dir_key}_targets "${target} (${type})" found)
                if(found EQUAL -1)
                    list(APPEND dir_${dir_key}_targets "${target} (${type})")
                endif()
            endif()
        endforeach()
    endwhile()

    message(STATUS "\n🌐 Target Groups:")
    foreach(dir_key IN LISTS dir_groups)
        set(dir_path "${dir_${dir_key}_path}")
        set(target_list "${dir_${dir_key}_targets}")
        
        list(REMOVE_DUPLICATES target_list)
        
        message(STATUS "📁 ${dir_path}")
        foreach(target IN LISTS target_list)
            message("  ➜ ${target}")
        endforeach()
        message("")  
    endforeach()
endfunction()

# call at end,make ensure all add_subdirectory done.
print_all_targets()