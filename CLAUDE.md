# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NVIDIA Texture Tools (nvtt) version 2.0.8 - A C++ library for DXT/BC texture compression with optional CUDA hardware acceleration. The library supports all DirectX 10 texture formats and provides both CPU and GPU compression paths.

## Build System

This project uses **CMake** as its primary build system with a convenience configure script for Unix-like systems.

### Building the Project

**Unix/Linux/macOS:**
```bash
./configure [--debug|--release] [--prefix=/path]
make
sudo make install
```

The configure script creates a build directory and generates Unix Makefiles. Options:
- `--debug` - Configure debug build (default)
- `--release` - Configure release build
- `--prefix=path` - Set installation prefix (default: /usr/local)

**Windows:**
Use Visual Studio solution file: `project/vc8/nvtt.sln`

**CMake Direct Usage:**
```bash
mkdir build && cd build
cmake .. -DNVTT_SHARED=1 -DCMAKE_BUILD_TYPE=Release
make
```

### Build Options

- `NVTT_SHARED=1` - Build shared libraries instead of static
- `NVCORE_SHARED`, `NVMATH_SHARED`, `NVIMAGE_SHARED` - Individual library shared/static control
- CUDA support is automatically detected when available (requires CUDA toolkit)

### Testing

Run the test executable:
```bash
./build/src/nvtt/filtertest
```

## Architecture

The codebase is organized into four main libraries plus tools:

### Core Libraries

1. **nvcore** (`src/nvcore/`) - Foundation library
   - Platform abstraction (Windows, Linux, macOS, Darwin)
   - CPU detection (x86, x86_64, PPC)
   - Compiler abstraction (MSVC, GCC)
   - Core utilities: Debug, Memory, Containers, Ptr, StrLib, Stream
   - Uses poshlib for platform detection

2. **nvmath** (`src/nvmath/`) - Mathematics library
   - Vector, Matrix, Quaternion, Box, Color
   - Spherical harmonics, Monte Carlo sampling
   - Triangle math, Basis transformations
   - Random number generation

3. **nvimage** (`src/nvimage/`) - Image processing library
   - Image I/O (TGA, PNG, PSD, DDS, JPG)
   - Float and fixed-point image handling
   - Color blocks and DXT blocks
   - Filters, mipmapping, normal map generation
   - DirectDraw Surface (DDS) format support
   - Hole filling, quantization

4. **nvtt** (`src/nvtt/`) - Main texture compression library
   - Public API: `nvtt.h`, `nvtt.cpp`
   - Compression formats: DXT1/BC1, DXT1a/BC1a, DXT3/BC2, DXT5/BC3, DXT5n/BC3n, BC4, BC5
   - Three compression quality modes: Fast, Optimal, Single-color
   - Optional CUDA acceleration (`cuda/` subdirectory)
   - Integrates squish library for additional compression algorithms
   - C wrapper API: `nvtt_wrapper.h/cpp`

### Tools

Located in `src/nvtt/tools/`:
- **nvcompress** - Main command-line compression tool (compress.cpp)
- **nvdecompress** - DDS decompression tool
- **nvddsinfo** - DDS file information viewer
- **nvimgdiff** - Image comparison with PSNR/angular deviation metrics
- **nvassemble** - Texture assembly tool
- **nvzoom** - Image resizing tool
- **nvcompressui** - Qt-based GUI (only built if Qt4 is found, not on MSVC)

### CUDA Acceleration

When CUDA is detected, GPU-accelerated compression is available:
- Kernel implementations: `src/nvtt/cuda/CompressKernel.cu`
- CUDA utilities and math: `CudaUtils.h/cpp`, `CudaMath.h`
- Automatically disabled on systems without CUDA or with driver/runtime mismatch
- Not used for small mipmaps (CPU is faster)

## Command-Line Tool Usage

```bash
nvcompress [options] infile [outfile]
```

**Input formats:** TGA, PNG, PSD, DDS, JPG
**Output format:** DDS

**Common options:**
- `-color` - Input is a color map (default)
- `-normal` - Input is a normal map
- `-nomips` - Disable mipmap generation
- `-fast` - Fast compression
- `-nocuda` - Disable CUDA acceleration
- `-bc1` / `-bc2` / `-bc3` / `-bc4` / `-bc5` - Compression format

## Key Implementation Details

### Library Linkage

All libraries support both static and shared linking via CMake options. API exports are controlled via:
- `NVCORE_API`, `NVMATH_API`, `NVIMAGE_API`, `NVTT_API` macros
- Platform-specific DLL export/import on Windows
- GCC visibility attributes on Unix

### Compression Pipeline

The main compression flow:
1. Load image via nvimage (ImageIO)
2. Process through InputOptions (resize, mipmap generation, normal map conversion)
3. Apply CompressionOptions (format, quality settings)
4. Output via OutputHandler interface
5. Write to DDS file via OutputOptions

### Dependencies

- **squish** - Bundled in `src/nvtt/squish/` for additional DXT compression
- **poshlib** - Bundled in `src/nvcore/poshlib/` for platform detection
- **CUDA** - Optional, auto-detected at build time
- **Qt4** - Optional, only for GUI tool
- **OpenGL/GLUT** - Optional, for some visualization tools

## File Organization

- `src/` - All source code
- `cmake/` - CMake helper scripts (FindGLUT, OptimalOptions, etc.)
- `project/vc8/` - Visual Studio 8 solution files
- `gnuwin32/` - Windows GNU utilities and headers
- Build outputs go to `build/` directory (created by configure script)
