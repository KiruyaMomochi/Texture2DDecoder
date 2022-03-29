cmake_minimum_required(VERSION 3.13)

project(Texture2DDecoderNative)
set(CMAKE_CXX_STANDARD 17)

add_compile_definitions(_T2D_DLL)

# https://cmake.org/cmake/help/latest/guide/tutorial/Selecting%20Static%20or%20Shared%20Libraries.html
option(BUILD_SHARED_LIBS "Build using shared libraries" ON)
option(BUILD_FRAMEWORK "Build as framework" OFF)
set(CMAKE_INSTALL_FRAMEWORKDIR "framework" CACHE PATH "Install Frameworks directory")

add_library(Texture2DDecoderNative
            astc.cpp
            atc.cpp
            bcn.cpp
            crunch.cpp
            dllmain.cpp
            etc.cpp
            pvrtc.cpp
            unitycrunch.cpp)

set_target_properties(Texture2DDecoderNative PROPERTIES
    # "current version" in semantic format in Mach-O binary file
    VERSION 1.0.0
    # "compatibility version" in semantic format in Mach-O binary file
    SOVERSION 1.0.0
)

set_target_properties(Texture2DDecoderNative PROPERTIES
    FRAMEWORK ${BUILD_FRAMEWORK}
    FRAMEWORK_VERSION C
    MACOSX_FRAMEWORK_IDENTIFIER com.kyaru.texture2DDecoderNative
    # PUBLIC_HEADER dynamicFramework.h
    # XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
)
            
# Important: If compiling with gcc, be sure strict aliasing is disabled: -fno-strict-aliasing
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set_target_properties(Texture2DDecoderNative PROPERTIES COMPILE_FLAGS "${COMPILE_FLAGS} -fno-strict-aliasing")
endif()

target_include_directories(Texture2DDecoderNative PRIVATE ${PROJECT_SOURCE_DIR})
install(TARGETS Texture2DDecoderNative 
    DESTINATION ${CMAKE_INSTALL_LIBDIR} 
    FRAMEWORK DESTINATION ${CMAKE_INSTALL_FRAMEWORKDIR}
)
