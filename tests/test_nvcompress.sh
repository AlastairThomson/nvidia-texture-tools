#!/usr/bin/env bash
#
# Test suite for nvcompress ARM64 build verification
# Verifies that the macOS ARM64 build produces valid DDS texture files
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NVCOMPRESS="$PROJECT_ROOT/build/src/nvtt/nvcompress"
NVDECOMPRESS="$PROJECT_ROOT/build/src/nvtt/nvdecompress"
IMAGES_DIR="$SCRIPT_DIR/images"
RESULTS_DIR="$SCRIPT_DIR/results"
BASELINES_DIR="$SCRIPT_DIR/baselines"

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test results log
TEST_LOG="$RESULTS_DIR/test_results.log"
CHECKSUMS_FILE="$BASELINES_DIR/checksums.txt"

# Initialize
mkdir -p "$RESULTS_DIR"
mkdir -p "$BASELINES_DIR"
echo "NVIDIA Texture Tools - nvcompress Test Suite" > "$TEST_LOG"
echo "=============================================" >> "$TEST_LOG"
echo "Date: $(date)" >> "$TEST_LOG"
echo "Build: ARM64 macOS" >> "$TEST_LOG"
echo "" >> "$TEST_LOG"

# Verify nvcompress exists
if [ ! -f "$NVCOMPRESS" ]; then
    echo -e "${RED}ERROR: nvcompress not found at $NVCOMPRESS${NC}"
    exit 1
fi

echo -e "${BLUE}NVIDIA Texture Tools - nvcompress Test Suite${NC}"
echo -e "${BLUE}==============================================${NC}"
echo ""
echo "nvcompress: $NVCOMPRESS"
echo "Test images: $IMAGES_DIR"
echo "Results: $RESULTS_DIR"
echo ""

# Function to run a test
run_test() {
    local test_name="$1"
    local input_file="$2"
    local output_file="$3"
    shift 3
    local args=("$@")

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo -n "Testing: $test_name ... "
    echo "========================================" >> "$TEST_LOG"
    echo "Test: $test_name" >> "$TEST_LOG"
    echo "Command: $NVCOMPRESS ${args[*]} $input_file $output_file" >> "$TEST_LOG"

    # Run nvcompress
    if "$NVCOMPRESS" "${args[@]}" "$input_file" "$output_file" >> "$TEST_LOG" 2>&1; then
        # Check if output file was created
        if [ -f "$output_file" ]; then
            # Check if output file has reasonable size (> 100 bytes)
            local file_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
            if [ "$file_size" -gt 100 ]; then
                # Verify DDS magic number
                local magic=$(xxd -p -l 4 "$output_file" 2>/dev/null)
                if [ "$magic" = "44445320" ]; then  # "DDS " in hex
                    echo -e "${GREEN}PASS${NC}"
                    echo "Result: PASS" >> "$TEST_LOG"
                    PASSED_TESTS=$((PASSED_TESTS + 1))

                    # Generate checksum for baseline
                    local checksum=$(shasum -a 256 "$output_file" | awk '{print $1}')
                    echo "$test_name:$checksum" >> "$CHECKSUMS_FILE"
                    return 0
                else
                    echo -e "${RED}FAIL${NC} (invalid DDS magic number)"
                    echo "Result: FAIL - invalid DDS magic number: $magic" >> "$TEST_LOG"
                    FAILED_TESTS=$((FAILED_TESTS + 1))
                    return 1
                fi
            else
                echo -e "${RED}FAIL${NC} (file too small: $file_size bytes)"
                echo "Result: FAIL - file too small: $file_size bytes" >> "$TEST_LOG"
                FAILED_TESTS=$((FAILED_TESTS + 1))
                return 1
            fi
        else
            echo -e "${RED}FAIL${NC} (no output file)"
            echo "Result: FAIL - no output file created" >> "$TEST_LOG"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    else
        echo -e "${RED}FAIL${NC} (nvcompress error)"
        echo "Result: FAIL - nvcompress returned error" >> "$TEST_LOG"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Clear previous checksums
> "$CHECKSUMS_FILE"

echo -e "${YELLOW}=== Format Coverage Tests ===${NC}"

# BC1 (DXT1) - No alpha
run_test "BC1-color-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_bc1_color.dds" -bc1

# BC1a - Binary alpha
run_test "BC1a-color-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_bc1a_color.dds" -bc1a

# BC2 (DXT3) - Explicit alpha
run_test "BC2-color-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_bc2_color.dds" -bc2

# BC3 (DXT5) - Interpolated alpha
run_test "BC3-color-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_bc3_color.dds" -bc3

# BC3n - Normal map format
run_test "BC3n-color-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_bc3n_color.dds" -bc3n

# BC4 - Single channel
run_test "BC4-color-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_bc4_color.dds" -bc4

# BC5 - Two channel (3Dc/ATI2)
run_test "BC5-color-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_bc5_color.dds" -bc5

# RGB uncompressed
run_test "RGB-color-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_rgb_color.dds" -rgb

echo ""
echo -e "${YELLOW}=== Input Format Tests ===${NC}"

# TGA input
run_test "TGA-input" "$IMAGES_DIR/lena_color.tga" "$RESULTS_DIR/test_tga_input.dds" -bc1

# PNG input
run_test "PNG-input" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_png_input.dds" -bc1

# JPEG input
run_test "JPEG-input" "$IMAGES_DIR/test_pattern.jpg" "$RESULTS_DIR/test_jpg_input.dds" -bc1

echo ""
echo -e "${YELLOW}=== Image Type Tests ===${NC}"

# Color map (default)
run_test "ColorMap-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_colormap.dds" -color -bc3

# Normal map
run_test "NormalMap-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_normalmap.dds" -normal -bc3n

# Alpha channel
run_test "Alpha-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_alpha.dds" -alpha -bc3

# Convert to normal map
run_test "ToNormal-512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_tonormal.dds" -tonormal -bc3n

echo ""
echo -e "${YELLOW}=== Quality & Speed Tests ===${NC}"

# Default quality
run_test "Quality-Default" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_quality_default.dds" -bc3

# Fast compression
run_test "Quality-Fast" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_quality_fast.dds" -fast -bc3

# No CUDA
run_test "NoCUDA" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_nocuda.dds" -nocuda -bc3

echo ""
echo -e "${YELLOW}=== Mipmap Tests ===${NC}"

# Default (with mipmaps)
run_test "Mipmaps-Default" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_mipmaps_default.dds" -bc1

# No mipmaps
run_test "Mipmaps-None" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_mipmaps_none.dds" -nomips -bc1

echo ""
echo -e "${YELLOW}=== Resolution Tests ===${NC}"

# 256x256
run_test "Res-256x256" "$IMAGES_DIR/color_256x256.png" "$RESULTS_DIR/test_256x256.dds" -bc1

# 512x512
run_test "Res-512x512" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_512x512.dds" -bc1

# 1024x1024
run_test "Res-1024x1024" "$IMAGES_DIR/color_1024x1024.png" "$RESULTS_DIR/test_1024x1024.dds" -bc1

# Small (32x32)
run_test "Res-32x32" "$IMAGES_DIR/small_32x32.png" "$RESULTS_DIR/test_32x32.dds" -bc1

echo ""
echo -e "${YELLOW}=== Edge Cases ===${NC}"

# Non-power-of-two
run_test "NonPOT-300x400" "$IMAGES_DIR/nonpot_300x400.png" "$RESULTS_DIR/test_nonpot.dds" -bc1

# Wrapping modes
run_test "Wrap-Clamp" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_wrap_clamp.dds" -clamp -bc1
run_test "Wrap-Repeat" "$IMAGES_DIR/color_512x512.png" "$RESULTS_DIR/test_wrap_repeat.dds" -repeat -bc1

# ============================================
# Summary
# ============================================

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}============================================${NC}"
echo "Total Tests:  $TOTAL_TESTS"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Test Results:" >> "$TEST_LOG"
    echo "  Total:  $TOTAL_TESTS" >> "$TEST_LOG"
    echo "  Passed: $PASSED_TESTS" >> "$TEST_LOG"
    echo "  Failed: $FAILED_TESTS" >> "$TEST_LOG"
    echo "" >> "$TEST_LOG"
    echo "All tests PASSED" >> "$TEST_LOG"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Check $TEST_LOG for details.${NC}"
    echo ""
    echo "Test Results:" >> "$TEST_LOG"
    echo "  Total:  $TOTAL_TESTS" >> "$TEST_LOG"
    echo "  Passed: $PASSED_TESTS" >> "$TEST_LOG"
    echo "  Failed: $FAILED_TESTS" >> "$TEST_LOG"
    echo "" >> "$TEST_LOG"
    echo "Some tests FAILED" >> "$TEST_LOG"
    exit 1
fi
