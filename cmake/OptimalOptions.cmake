
# Detect if we're using Clang (including Apple Clang)
IF(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
	SET(CMAKE_COMPILER_IS_CLANG TRUE)
ENDIF()

# Set optimal options for Clang/LLVM (macOS and other platforms):
IF(CMAKE_COMPILER_IS_CLANG)
	# Enable modern C++ features
	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

	# Position-independent code for shared libraries
	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")

	# Fast math optimizations
	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffast-math")

	# Optimization level for release builds
	SET(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")

	# CPU-specific optimizations
	IF(NV_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
		# Apple Silicon / ARM64 - use native optimizations
		SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mcpu=apple-m1")
		ADD_DEFINITIONS(-D__ARM_NEON__=1)
	ELSEIF(NV_SYSTEM_PROCESSOR MATCHES "i.86|x86_64|amd64")
		# x86/x86_64 - use native optimizations
		SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
	ELSE()
		# Other architectures - use native optimizations
		SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
	ENDIF()

	# Link-time optimization for release builds
	SET(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -flto")

ENDIF()

# Set optimal options for GCC (non-Clang):
IF(CMAKE_COMPILER_IS_GNUCXX AND NOT CMAKE_COMPILER_IS_CLANG)
	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
ENDIF()

IF(MSVC)
	# Code generation flags.
#	SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /arch:SSE2 /fp:fast")
#	SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:SSE2 /fp:fast")

	# Optimization flags.
	SET(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS} /O2 /Ob2 /Oi /Ot /Oy /GL")
	SET(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS} /O2 /Ob2 /Oi /Ot /Oy /GL")
	SET(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /LTCG")
	SET(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /LTCG")
	SET(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${CMAKE_MODULE_LINKER_FLAGS_RELEASE} /LTCG")

	# Definitions.
	ADD_DEFINITIONS(-D__SSE2__ -D__SSE__ -D__MMX__)
ENDIF(MSVC)
