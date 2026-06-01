# webOS deps
set(DEP_PATH webOS)
add_executable(RetroEngine ${RETRO_FILES})
set(RETRO_SUBSYSTEM "SDL2" CACHE STRING "The subsystem to use")
if(NOT DEFINED ENV{STAGING_DIR})
    message(FATAL_ERROR
        "Can't find buildroot based toolchain. "
        "Please ensure STAGING_DIR is set correctly."
    )
endif()
set(STAGING_DIR $ENV{STAGING_DIR})

# Enable built-in source compilation
set(COMPILE_OGG ON)
set(COMPILE_THEORA ON)

# Optional compile flags for these libs
set(OGG_FLAGS "")
set(THEORA_FLAGS "")

set(CMAKE_C_COMPILER arm-webos-linux-gnueabi-gcc)
set(CMAKE_CXX_COMPILER arm-webos-linux-gnueabi-g++)
set(CMAKE_FIND_ROOT_PATH $ENV{STAGING_DIR})
set(CMAKE_SYSROOT $ENV{STAGING_DIR})
set_target_properties(RetroEngine PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)
if(RETRO_SUBSYSTEM STREQUAL "SDL2")
    set(SDL2_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/${DEP_PATH}/SDL2/include/SDL2")
    set(SDL2_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/${DEP_PATH}/SDL2/lib")
    target_include_directories(RetroEngine PRIVATE ${SDL2_INCLUDE_DIR})
    target_link_directories(RetroEngine PRIVATE ${SDL2_LIB_DIR})
    target_link_libraries(RetroEngine SDL2)
else()
    message(FATAL_ERROR "RETRO_SUBSYSTEM must be set to SDL2")
endif()

target_link_libraries(RetroEngine	
    ogg
    dl
    pthread
)
target_compile_definitions(RetroEngine PRIVATE ${SHARED_DEFINES} __webos__=ON)
set_target_properties(RetroEngine PROPERTIES
    BUILD_RPATH "\$ORIGIN/lib"
    INSTALL_RPATH "\$ORIGIN/lib"
)

if(WITH_RSDK AND NOT GAME_STATIC AND TARGET ${GAME_NAME})
    add_custom_command(TARGET RetroEngine POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:${GAME_NAME}>
            $<TARGET_FILE_DIR:RetroEngine>/Game.so
        VERBATIM
    )
endif()

add_custom_command(TARGET RetroEngine POST_BUILD
    COMMAND OUTPUT_FILE=$<TARGET_FILE_DIR:RetroEngine>/gamecontrollerdb.txt sh ${CMAKE_CURRENT_SOURCE_DIR}/webos/gen_gamecontrollerdb.sh
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/webos/icon.png $<TARGET_FILE_DIR:RetroEngine>
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/webos/splashplus.png $<TARGET_FILE_DIR:RetroEngine>/splash.png
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/webos/appinfoultimate.json $<TARGET_FILE_DIR:RetroEngine>/appinfo.json
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${STAGING_DIR}/usr/lib/libstdc++.so.6 $<TARGET_FILE_DIR:RetroEngine>/lib/libstdc++.so.6
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/dependencies/webOS/SDL2/lib/libSDL2-2.0.so.0 $<TARGET_FILE_DIR:RetroEngine>/lib/libSDL2-2.0.so.0
    COMMAND ares-package $<TARGET_FILE_DIR:RetroEngine> -o ${CMAKE_BINARY_DIR}
    COMMAND PATH=/bin:/usr/bin python3 ${CMAKE_CURRENT_SOURCE_DIR}/webos/gen_manifest.py -a $<TARGET_FILE_DIR:RetroEngine>/appinfo.json -p ${CMAKE_BINARY_DIR}/*.ipk -o ${CMAKE_BINARY_DIR}/webosbrew.manifest.json
)
set(PLATFORM webOS)
