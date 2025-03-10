cmake_minimum_required(VERSION 3.10)
project(::PROJECT_NAME::)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 11)

# install path
set(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/::INSTALL_DIR::" CACHE PATH "Install path prefix" FORCE)

# 设置全局输出目录
# 使用 CACHE 确保子项目也会继承这些设置
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "Global runtime output directory")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin" CACHE PATH "Global library output directory")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib" CACHE PATH "Global archive output directory")

# # 确保子项目也使用相同的输出目录
# set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" CACHE PATH "Global debug runtime output directory")
# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}" CACHE PATH "Global debug library output directory")
# set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}" CACHE PATH "Global debug archive output directory")

# set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" CACHE PATH "Global release runtime output directory")
# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}" CACHE PATH "Global release library output directory")
# set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}" CACHE PATH "Global release archive output directory")

# for hashlink and SDL, disable build test
set(BUILD_TESTING FALSE CACHE BOOL "" FORCE) 
set(SDL_TEST FALSE CACHE BOOL "" FORCE) 

# for hashlink, disable build vm
set(WITH_VM FALSE CACHE BOOL "Skip building hl executable" FORCE)

# TODO 不要通过参数获取，而应该找出android构建时，是否设置了独特的参数以区分是否是android
set(IS_ANDROID ::IS_ANDROID::)

# whatever is linux or android,build shared library
set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries" FORCE)

# RPATH 
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set(CMAKE_INSTALL_RPATH "$ORIGIN")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

set(CMAKE_SKIP_RPATH FALSE)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# when make install. [.] means ${CMAKE_INSTALL_PREFIX}.
set(CMAKE_INSTALL_BINDIR "." CACHE PATH "Installation directory for executables" FORCE)
set(CMAKE_INSTALL_LIBDIR "." CACHE PATH "Installation directory for libraries" FORCE)
set(CMAKE_INSTALL_INCLUDEDIR "." CACHE PATH "Installation directory for header files" FORCE)

# TODO 编译过程中，文件放到了  ./haxe/build/hashlink/bin/heaps.hdll ？
# 当前AI生成的这两行不管设置还是没设置，都是这个路径，那似乎就没有存在的必要了
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

if(IS_ANDROID)
    # Android,create static library.then can link in android main CMakeLists.txt
    add_library(::PROJECT_NAME:: STATIC ${SOURCES})
    
    # 设置库的属性
    set_target_properties(::PROJECT_NAME:: PROPERTIES
        POSITION_INDEPENDENT_CODE ON
    )
    
    # 安装规则
    install(
        TARGETS ${PROJECT_NAME}
        ARCHIVE DESTINATION .
    )
else()
    # non-Android - create executable and shared library
    # executable for test.
    # TODO do we need shared library?
    add_executable(::PROJECT_NAME:: ${SOURCES})
    add_library(::PROJECT_NAME::_lib SHARED ${SOURCES})
    
    target_link_libraries(::PROJECT_NAME:: PRIVATE 
        ${::PROJECT_NAME::_LINK_LIBRARIES}
    )
    target_link_libraries(::PROJECT_NAME::_lib PRIVATE 
        ${::PROJECT_NAME::_LINK_LIBRARIES}
    )
    
    set_target_properties(::PROJECT_NAME:: PROPERTIES
        BUILD_WITH_INSTALL_RPATH TRUE
        SKIP_BUILD_RPATH FALSE
        INSTALL_RPATH "$ORIGIN"
        INSTALL_RPATH_USE_LINK_PATH TRUE
        BUILD_RPATH "$ORIGIN"
    )
    
    set_target_properties(::PROJECT_NAME::_lib PROPERTIES
        BUILD_WITH_INSTALL_RPATH TRUE
        SKIP_BUILD_RPATH FALSE
        INSTALL_RPATH "$ORIGIN"
        INSTALL_RPATH_USE_LINK_PATH TRUE
        BUILD_RPATH "$ORIGIN"
        SOVERSION 1
    )
    
    install(
        TARGETS ${PROJECT_NAME} ${PROJECT_NAME}_lib
        RUNTIME DESTINATION .
        LIBRARY DESTINATION .
        ARCHIVE DESTINATION .
    )
endif()

# 似乎没什么用
# install(
#     DIRECTORY ${CMAKE_BINARY_DIR}/bin/
#     DESTINATION .
#     FILES_MATCHING PATTERN "*.hdll"
# )


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