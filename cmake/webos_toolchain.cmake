# webOS ARMv7 Toolchain File for Super Mario All-Stars Recomp
# Targets webOS 4.x+ Smart TVs (ARMv7a Cortex-A55 with NEON & VFPv4)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(WEBOS ON CACHE BOOL "webOS target" FORCE)

# 1. Locate Clang from Android NDK or standalone LLVM
if(NOT DEFINED NDK_PATH)
    if(DEFINED ENV{ANDROID_NDK_ROOT})
        set(NDK_PATH "$ENV{ANDROID_NDK_ROOT}")
    elseif(DEFINED ENV{NDK_PATH})
        set(NDK_PATH "$ENV{NDK_PATH}")
    else()
        message(FATAL_ERROR "Please set ANDROID_NDK_ROOT or NDK_PATH to your Android NDK directory (r27+)")
    endif()
endif()

file(TO_CMAKE_PATH "${NDK_PATH}" NDK_PATH)

if(CMAKE_HOST_WIN32)
    set(_EXE_EXT ".exe")
    set(_HOST_TAG "windows-x86_64")
elseif(CMAKE_HOST_APPLE)
    set(_EXE_EXT "")
    set(_HOST_TAG "darwin-x86_64")
else()
    set(_EXE_EXT "")
    set(_HOST_TAG "linux-x86_64")
endif()

set(CMAKE_C_COMPILER "${NDK_PATH}/toolchains/llvm/prebuilt/${_HOST_TAG}/bin/clang${_EXE_EXT}")
set(CMAKE_CXX_COMPILER "${NDK_PATH}/toolchains/llvm/prebuilt/${_HOST_TAG}/bin/clang++${_EXE_EXT}")

# 2. Locate webOS sysroot
if(NOT DEFINED WEBOS_SYSROOT)
    if(DEFINED ENV{WEBOS_SYSROOT})
        set(WEBOS_SYSROOT "$ENV{WEBOS_SYSROOT}")
    else()
        set(WEBOS_SYSROOT "${CMAKE_CURRENT_LIST_DIR}/../tools/sysroot")
    endif()
endif()

file(TO_CMAKE_PATH "${WEBOS_SYSROOT}" WEBOS_SYSROOT)
if(EXISTS "${WEBOS_SYSROOT}/sysroot")
    set(SYSROOT "${WEBOS_SYSROOT}/sysroot")
else()
    set(SYSROOT "${WEBOS_SYSROOT}")
endif()

file(GLOB _GCC_DIRS "${WEBOS_SYSROOT}/lib/gcc/arm-webos-linux-gnueabi/*")
if(_GCC_DIRS)
    list(GET _GCC_DIRS 0 GCC_LIB)
else()
    set(GCC_LIB "${SYSROOT}/usr/lib")
endif()

# 3. Compiler & Linker Flags (Tuned for Cortex-A55, ThinLTO, Hard Float, NEON)
set(CMAKE_C_FLAGS "--target=armv7a-linux-gnueabihf -mcpu=cortex-a55 -mfpu=neon-vfpv4 -mfloat-abi=hard --sysroot=\"${SYSROOT}\" -D__WEBOS__=1 -O3 -flto=thin -fno-strict-aliasing -fomit-frame-pointer" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS "--target=armv7a-linux-gnueabihf -mcpu=cortex-a55 -mfpu=neon-vfpv4 -mfloat-abi=hard --sysroot=\"${SYSROOT}\" -D__WEBOS__=1 -O3 -flto=thin -fno-strict-aliasing -fomit-frame-pointer" CACHE STRING "" FORCE)
set(CMAKE_EXE_LINKER_FLAGS "--target=armv7a-linux-gnueabihf --sysroot=\"${SYSROOT}\" -fuse-ld=lld -flto=thin -B\"${GCC_LIB}\" -L\"${GCC_LIB}\" -L\"${SYSROOT}/lib\" -L\"${SYSROOT}/usr/lib\" -Wl,-dynamic-linker,/lib/ld-linux.so.3 -Wl,-rpath,$ORIGIN/lib -Wl,-rpath,/media/developer/apps/usr/palm/applications/com.tanooki.smas/lib -lrt" CACHE STRING "" FORCE)

set(CMAKE_SYSROOT "${SYSROOT}")
set(CMAKE_FIND_ROOT_PATH "${SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
