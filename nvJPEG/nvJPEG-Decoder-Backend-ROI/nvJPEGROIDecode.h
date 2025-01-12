/*
 * Copyright (c) 2021, NVIDIA CORPORATION. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of NVIDIA CORPORATION nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <algorithm>
#include <filesystem> // stdc++17

#include <string.h>  // strcmpi
#ifndef _WIN64
#include <sys/time.h>  // timings
#include <unistd.h>
#endif
#include <sys/types.h>


#include <cuda_runtime_api.h>
#include <nvjpeg.h>


#define CHECK_CUDA(call)                                                        \
    {                                                                           \
        cudaError_t _e = (call);                                                \
        if (_e != cudaSuccess)                                                  \
        {                                                                       \
            std::cout << "CUDA Runtime failure: '#" << _e << "' at " <<  __FILE__ << ":" << __LINE__ << std::endl;\
            return EXIT_FAILURE;                                                \
        }                                                                       \
    }

#define CHECK_NVJPEG(call)                                                      \
    {                                                                           \
        nvjpegStatus_t _e = (call);                                             \
        if (_e != NVJPEG_STATUS_SUCCESS)                                        \
        {                                                                       \
            std::cout << "NVJPEG failure: '#" << _e << "' at " <<  __FILE__ << ":" << __LINE__ << std::endl;\
            return EXIT_FAILURE;                                                            \
        }                                                                       \
    }

namespace fs = std::filesystem;

int dev_malloc(void **p, size_t s) { return (int)cudaMalloc(p, s); }

int dev_free(void *p) { return (int)cudaFree(p); }

int host_malloc(void** p, size_t s, unsigned int f) { return (int)cudaHostAlloc(p, s, f); }

int host_free(void* p) { return (int)cudaFreeHost(p); }

typedef std::vector<std::string> FileNames;
typedef std::vector<std::vector<char> > FileData;
constexpr int pipeline_stages = 2;

struct decode_per_thread_params {
  cudaStream_t stream;
  nvjpegJpegState_t dec_state_cpu;
  nvjpegJpegState_t dec_state_gpu;
  nvjpegBufferPinned_t pinned_buffers[pipeline_stages];
  nvjpegBufferDevice_t device_buffer;
  nvjpegJpegStream_t  jpeg_streams[pipeline_stages];
  nvjpegDecodeParams_t nvjpeg_decode_params;
  nvjpegJpegDecoder_t nvjpeg_dec_cpu;
  nvjpegJpegDecoder_t nvjpeg_dec_gpu;
};

struct decode_params_t {
  std::string input_dir;
  int batch_size;
  int total_images;
  int dev;
  int warmup;
  int num_threads;
  int offset_x;
  int offset_y;
  int roi_width;
  int roi_height;
  bool roi_on;
  int backend_enum;

  cudaStream_t global_stream;

  nvjpegHandle_t nvjpeg_handle;

  std::vector<decode_per_thread_params> nvjpeg_per_thread_data;
  nvjpegOutputFormat_t fmt;
  bool write_decoded;
  std::string output_dir;

};

int create_nvjpeg_data(nvjpegHandle_t&  nvjpeg_handle, decode_per_thread_params& params){
  static_assert(pipeline_stages >=2, "We need at least two stages in the pipeline to allow buffering of the states, "
                                     "so the re-allocations won't interfere with asynchronous execution.");
   // stream for decoding
  CHECK_CUDA( cudaStreamCreateWithFlags(&params.stream, cudaStreamNonBlocking));

  CHECK_NVJPEG(nvjpegDecoderCreate(nvjpeg_handle, NVJPEG_BACKEND_HYBRID, &params.nvjpeg_dec_cpu));
  CHECK_NVJPEG(nvjpegDecoderCreate(nvjpeg_handle, NVJPEG_BACKEND_GPU_HYBRID, &params.nvjpeg_dec_gpu));
  CHECK_NVJPEG(nvjpegDecoderStateCreate(nvjpeg_handle, params.nvjpeg_dec_cpu, &params.dec_state_cpu));
  CHECK_NVJPEG(nvjpegDecoderStateCreate(nvjpeg_handle, params.nvjpeg_dec_gpu, &params.dec_state_gpu));

  CHECK_NVJPEG(nvjpegBufferDeviceCreate(nvjpeg_handle, NULL, &params.device_buffer));

  for(int i = 0; i < pipeline_stages; i++) {
    CHECK_NVJPEG(nvjpegBufferPinnedCreate(nvjpeg_handle, NULL, &params.pinned_buffers[i]));
    CHECK_NVJPEG(nvjpegJpegStreamCreate(nvjpeg_handle, &params.jpeg_streams[i]));
  }

  CHECK_NVJPEG(nvjpegStateAttachDeviceBuffer(params.dec_state_cpu, params.device_buffer));
  CHECK_NVJPEG(nvjpegStateAttachDeviceBuffer(params.dec_state_gpu, params.device_buffer));
  return EXIT_SUCCESS;
}

int destroy_nvjpeg_data(decode_per_thread_params& params) {

  for(int i = 0; i < pipeline_stages; i++) {
    CHECK_NVJPEG(nvjpegJpegStreamDestroy(params.jpeg_streams[i]));
    CHECK_NVJPEG(nvjpegBufferPinnedDestroy(params.pinned_buffers[i]));
  }
  CHECK_NVJPEG(nvjpegBufferDeviceDestroy(params.device_buffer));
  CHECK_NVJPEG(nvjpegJpegStateDestroy(params.dec_state_cpu));
  CHECK_NVJPEG(nvjpegJpegStateDestroy(params.dec_state_gpu));
  CHECK_NVJPEG(nvjpegDecoderDestroy(params.nvjpeg_dec_cpu));
  CHECK_NVJPEG(nvjpegDecoderDestroy(params.nvjpeg_dec_gpu));

  CHECK_CUDA(cudaStreamDestroy(params.stream));
  return EXIT_SUCCESS;
}

int read_next_batch(FileNames &image_names, int batch_size,
                    FileNames::iterator &cur_iter, FileData &raw_data,
                    std::vector<size_t> &raw_len, FileNames &current_names) {
  int counter = 0;

  while (counter < batch_size) {
    if (cur_iter == image_names.end()) {
      std::cerr << "Image list is too short to fill the batch, adding files "
                   "from the beginning of the image list"
                << std::endl;
      cur_iter = image_names.begin();
    }

    if (image_names.size() == 0) {
      std::cerr << "No valid images left in the input list, exit" << std::endl;
      return EXIT_FAILURE;
    }

    // Read an image from disk.
    std::ifstream input(cur_iter->c_str(),
                        std::ios::in | std::ios::binary | std::ios::ate);
    if (!(input.is_open())) {
      std::cerr << "Cannot open image: " << *cur_iter
                << ", removing it from image list" << std::endl;
      image_names.erase(cur_iter);
      continue;
    }

    // Get the size
    std::streamsize file_size = input.tellg();
    input.seekg(0, std::ios::beg);
    // resize if buffer is too small
    if (raw_data[counter].size() < file_size) {
      raw_data[counter].resize(file_size);
    }
    if (!input.read(raw_data[counter].data(), file_size)) {
      std::cerr << "Cannot read from file: " << *cur_iter
                << ", removing it from image list" << std::endl;
      image_names.erase(cur_iter);
      continue;
    }
    raw_len[counter] = file_size;

    current_names[counter] = *cur_iter;

    counter++;
    cur_iter++;
  }
  return EXIT_SUCCESS;
}

// prepare buffers for RGBi output format
int prepare_buffers(FileData &file_data, std::vector<size_t> &file_len,
                    std::vector<int> &img_width, std::vector<int> &img_height,
                    std::vector<nvjpegImage_t> &ibuf,
                    std::vector<nvjpegImage_t> &isz, FileNames &current_names,
                    decode_params_t &params) {
  int widths[NVJPEG_MAX_COMPONENT];
  int heights[NVJPEG_MAX_COMPONENT];
  int channels;
  nvjpegChromaSubsampling_t subsampling;

  for (int i = 0; i < file_data.size(); i++) {
    CHECK_NVJPEG(nvjpegGetImageInfo(
        params.nvjpeg_handle, (unsigned char *)file_data[i].data(), file_len[i],
        &channels, &subsampling, widths, heights));

    img_width[i] = widths[0];
    img_height[i] = heights[0];

    // check if the ROI exceeds the image boundaries
    // If within ROI, set the buffer size to match the ROI
    if (params.roi_on && (widths[0] > params.offset_x + params.roi_width && heights[0] > params.offset_y + params.roi_height)){
      widths[0] = params.roi_width;
      heights[0] = params.roi_height;
    }

    std::cout << "Processing: " << current_names[i] << std::endl;
    std::cout << "Image is " << channels << " channels." << std::endl;
    for (int c = 0; c < channels; c++) {
      std::cout << "Channel #" << c << " size: " << widths[c] << " x "
                << heights[c] << std::endl;
    }

    switch (subsampling) {
      case NVJPEG_CSS_444:
        std::cout << "YUV 4:4:4 chroma subsampling" << std::endl;
        break;
      case NVJPEG_CSS_440:
        std::cout << "YUV 4:4:0 chroma subsampling" << std::endl;
        break;
      case NVJPEG_CSS_422:
        std::cout << "YUV 4:2:2 chroma subsampling" << std::endl;
        break;
      case NVJPEG_CSS_420:
        std::cout << "YUV 4:2:0 chroma subsampling" << std::endl;
        break;
      case NVJPEG_CSS_411:
        std::cout << "YUV 4:1:1 chroma subsampling" << std::endl;
        break;
      case NVJPEG_CSS_410:
        std::cout << "YUV 4:1:0 chroma subsampling" << std::endl;
        break;
      case NVJPEG_CSS_GRAY:
        std::cout << "Grayscale JPEG " << std::endl;
        break;
      case NVJPEG_CSS_UNKNOWN:
        std::cout << "Unknown chroma subsampling" << std::endl;
        return EXIT_FAILURE;
    }

    int mul = 1;
    // in the case of interleaved RGB output, write only to single channel, but
    // 3 samples at once
    if (params.fmt == NVJPEG_OUTPUT_RGBI || params.fmt == NVJPEG_OUTPUT_BGRI) {
      channels = 1;
      mul = 3;
    }
    // in the case of rgb create 3 buffers with sizes of original image
    else if (params.fmt == NVJPEG_OUTPUT_RGB ||
             params.fmt == NVJPEG_OUTPUT_BGR) {
      channels = 3;
      widths[1] = widths[2] = widths[0];
      heights[1] = heights[2] = heights[0];
    }

    // realloc output buffer if required
    for (int c = 0; c < channels; c++) {
      int aw = mul * widths[c];
      int ah = heights[c];
      int sz = aw * ah;
      ibuf[i].pitch[c] = aw;
      if (sz > isz[i].pitch[c]) {
        if (ibuf[i].channel[c]) {
          CHECK_CUDA(cudaFree(ibuf[i].channel[c]));
        }
        CHECK_CUDA(cudaMalloc((void**)&ibuf[i].channel[c], sz));
        isz[i].pitch[c] = sz;
      }
    }
  }
  return EXIT_SUCCESS;
}

int release_buffers(std::vector<nvjpegImage_t> &ibuf) {
  for (int i = 0; i < ibuf.size(); i++) {
    for (int c = 0; c < NVJPEG_MAX_COMPONENT; c++)
      if (ibuf[i].channel[c]) CHECK_CUDA(cudaFree(ibuf[i].channel[c]));
  }
  return EXIT_SUCCESS;
}

// *****************************************************************************
// reading input directory to file list
// -----------------------------------------------------------------------------
int readInput(const std::string &sInputPath, std::vector<std::string> &filelist)
{
    int error_code = 0;

    fs::file_status s = fs::status(sInputPath);
    switch (s.type()) {
        case fs::file_type::not_found:
            std::cerr << "Error: cannot find input path " << sInputPath << std::endl;
            error_code = 1;
            break;

        case fs::file_type::regular:
            filelist.push_back(sInputPath);
            break;

        case fs::file_type::directory:
            try {
                const fs::path p(sInputPath);

                for (auto const& it : fs::recursive_directory_iterator(p)) {
                    if (it.symlink_status().type() == fs::file_type::regular)
                        filelist.push_back(it.path().string());
                }
            }
            catch (fs::filesystem_error &err) {
                std::cerr << "Error: " << err.what() << std::endl;
                error_code = 1;
            }
            break;

        default:
            std::cerr << "Error: unsupported file type for input path " << sInputPath << std::endl;
            error_code = 1;
            break;
    }

    return error_code;
}

// *****************************************************************************
// check for inputDirExists
// -----------------------------------------------------------------------------
int inputDirExists(const char *pathname) {
    return fs::status(pathname).type() == fs::file_type::directory ? 1 : 0;
}

// *****************************************************************************
// check for getInputDir
// -----------------------------------------------------------------------------
int getInputDir(std::string &input_dir, const char *executable_path) {
  int found = 0;
  if (executable_path != 0) {
    std::string executable_name = std::string(executable_path);
#if defined(WIN32) || defined(_WIN32) || defined(WIN64) || defined(_WIN64)
    // Windows path delimiter
    size_t delimiter_pos = executable_name.find_last_of('\\');
    executable_name.erase(0, delimiter_pos + 1);

    if (executable_name.rfind(".exe") != std::string::npos) {
      // we strip .exe, only if the .exe is found
      executable_name.resize(executable_name.size() - 4);
    }
#else
    // Linux & OSX path delimiter
    size_t delimiter_pos = executable_name.find_last_of('/');
    executable_name.erase(0, delimiter_pos + 1);
#endif

    // Search in default paths for input images.
    std::string pathname = "";
    const char *searchPath[] = {
        "./images"};

    for (unsigned int i = 0; i < sizeof(searchPath) / sizeof(char *); ++i) {
      std::string pathname(searchPath[i]);
      size_t executable_name_pos = pathname.find("<executable_name>");

      // If there is executable_name variable in the searchPath
      // replace it with the value
      if (executable_name_pos != std::string::npos) {
        pathname.replace(executable_name_pos, strlen("<executable_name>"),
                         executable_name);
      }

      if (inputDirExists(pathname.c_str())) {
        input_dir = pathname + "/";
        found = 1;
        break;
      }
    }
  }
  return found;
}

// write bmp, input - RGB, device
int writeBMP(const char *filename, const unsigned char *d_chanR, int pitchR,
             const unsigned char *d_chanG, int pitchG,
             const unsigned char *d_chanB, int pitchB, int width, int height) {
  unsigned int headers[13];
  FILE *outfile;
  int extrabytes;
  int paddedsize;
  int x;
  int y;
  int n;
  int red, green, blue;

  std::vector<unsigned char> vchanR(height * width);
  std::vector<unsigned char> vchanG(height * width);
  std::vector<unsigned char> vchanB(height * width);
  unsigned char *chanR = vchanR.data();
  unsigned char *chanG = vchanG.data();
  unsigned char *chanB = vchanB.data();
  CHECK_CUDA(cudaMemcpy2D(chanR, (size_t)width, d_chanR, (size_t)pitchR,
                               width, height, cudaMemcpyDeviceToHost));
  CHECK_CUDA(cudaMemcpy2D(chanG, (size_t)width, d_chanG, (size_t)pitchR,
                               width, height, cudaMemcpyDeviceToHost));
  CHECK_CUDA(cudaMemcpy2D(chanB, (size_t)width, d_chanB, (size_t)pitchR,
                               width, height, cudaMemcpyDeviceToHost));

  extrabytes =
      4 - ((width * 3) % 4);  // How many bytes of padding to add to each
  // horizontal line - the size of which must
  // be a multiple of 4 bytes.
  if (extrabytes == 4) extrabytes = 0;

  paddedsize = ((width * 3) + extrabytes) * height;

  // Headers...
  // Note that the "BM" identifier in bytes 0 and 1 is NOT included in these
  // "headers".

  headers[0] = paddedsize + 54;  // bfSize (whole file size)
  headers[1] = 0;                // bfReserved (both)
  headers[2] = 54;               // bfOffbits
  headers[3] = 40;               // biSize
  headers[4] = width;            // biWidth
  headers[5] = height;           // biHeight

  // Would have biPlanes and biBitCount in position 6, but they're shorts.
  // It's easier to write them out separately (see below) than pretend
  // they're a single int, especially with endian issues...

  headers[7] = 0;           // biCompression
  headers[8] = paddedsize;  // biSizeImage
  headers[9] = 0;           // biXPelsPerMeter
  headers[10] = 0;          // biYPelsPerMeter
  headers[11] = 0;          // biClrUsed
  headers[12] = 0;          // biClrImportant

  if (!(outfile = fopen(filename, "wb"))) {
    std::cerr << "Cannot open file: " << filename << std::endl;
    return 1;
  }

  //
  // Headers begin...
  // When printing ints and shorts, we write out 1 character at a time to avoid
  // endian issues.
  //
  fprintf(outfile, "BM");

  for (n = 0; n <= 5; n++) {
    fprintf(outfile, "%c", headers[n] & 0x000000FF);
    fprintf(outfile, "%c", (headers[n] & 0x0000FF00) >> 8);
    fprintf(outfile, "%c", (headers[n] & 0x00FF0000) >> 16);
    fprintf(outfile, "%c", (headers[n] & (unsigned int)0xFF000000) >> 24);
  }

  // These next 4 characters are for the biPlanes and biBitCount fields.

  fprintf(outfile, "%c", 1);
  fprintf(outfile, "%c", 0);
  fprintf(outfile, "%c", 24);
  fprintf(outfile, "%c", 0);

  for (n = 7; n <= 12; n++) {
    fprintf(outfile, "%c", headers[n] & 0x000000FF);
    fprintf(outfile, "%c", (headers[n] & 0x0000FF00) >> 8);
    fprintf(outfile, "%c", (headers[n] & 0x00FF0000) >> 16);
    fprintf(outfile, "%c", (headers[n] & (unsigned int)0xFF000000) >> 24);
  }

  //
  // Headers done, now write the data...
  //

  for (y = height - 1; y >= 0;
       y--)  // BMP image format is written from bottom to top...
  {
    for (x = 0; x <= width - 1; x++) {
      red = chanR[y * width + x];
      green = chanG[y * width + x];
      blue = chanB[y * width + x];

      if (red > 255) red = 255;
      if (red < 0) red = 0;
      if (green > 255) green = 255;
      if (green < 0) green = 0;
      if (blue > 255) blue = 255;
      if (blue < 0) blue = 0;
      // Also, it's written in (b,g,r) format...

      fprintf(outfile, "%c", blue);
      fprintf(outfile, "%c", green);
      fprintf(outfile, "%c", red);
    }
    if (extrabytes)  // See above - BMP lines must be of lengths divisible by 4.
    {
      for (n = 1; n <= extrabytes; n++) {
        fprintf(outfile, "%c", 0);
      }
    }
  }

  fclose(outfile);
  return 0;
}

// write bmp, input - RGB, device
int writeBMPi(const char *filename, const unsigned char *d_RGB, int pitch,
              int width, int height) {
  unsigned int headers[13];
  FILE *outfile;
  int extrabytes;
  int paddedsize;
  int x;
  int y;
  int n;
  int red, green, blue;

  std::vector<unsigned char> vchanRGB(height * width * 3);
  unsigned char *chanRGB = vchanRGB.data();
  CHECK_CUDA(cudaMemcpy2D(chanRGB, (size_t)width * 3, d_RGB, (size_t)pitch,
                               width * 3, height, cudaMemcpyDeviceToHost));

  extrabytes =
      4 - ((width * 3) % 4);  // How many bytes of padding to add to each
  // horizontal line - the size of which must
  // be a multiple of 4 bytes.
  if (extrabytes == 4) extrabytes = 0;

  paddedsize = ((width * 3) + extrabytes) * height;

  // Headers...
  // Note that the "BM" identifier in bytes 0 and 1 is NOT included in these
  // "headers".
  headers[0] = paddedsize + 54;  // bfSize (whole file size)
  headers[1] = 0;                // bfReserved (both)
  headers[2] = 54;               // bfOffbits
  headers[3] = 40;               // biSize
  headers[4] = width;            // biWidth
  headers[5] = height;           // biHeight

  // Would have biPlanes and biBitCount in position 6, but they're shorts.
  // It's easier to write them out separately (see below) than pretend
  // they're a single int, especially with endian issues...

  headers[7] = 0;           // biCompression
  headers[8] = paddedsize;  // biSizeImage
  headers[9] = 0;           // biXPelsPerMeter
  headers[10] = 0;          // biYPelsPerMeter
  headers[11] = 0;          // biClrUsed
  headers[12] = 0;          // biClrImportant

  if (!(outfile = fopen(filename, "wb"))) {
    std::cerr << "Cannot open file: " << filename << std::endl;
    return 1;
  }

  //
  // Headers begin...
  // When printing ints and shorts, we write out 1 character at a time to avoid
  // endian issues.
  //

  fprintf(outfile, "BM");

  for (n = 0; n <= 5; n++) {
    fprintf(outfile, "%c", headers[n] & 0x000000FF);
    fprintf(outfile, "%c", (headers[n] & 0x0000FF00) >> 8);
    fprintf(outfile, "%c", (headers[n] & 0x00FF0000) >> 16);
    fprintf(outfile, "%c", (headers[n] & (unsigned int)0xFF000000) >> 24);
  }

  // These next 4 characters are for the biPlanes and biBitCount fields.

  fprintf(outfile, "%c", 1);
  fprintf(outfile, "%c", 0);
  fprintf(outfile, "%c", 24);
  fprintf(outfile, "%c", 0);

  for (n = 7; n <= 12; n++) {
    fprintf(outfile, "%c", headers[n] & 0x000000FF);
    fprintf(outfile, "%c", (headers[n] & 0x0000FF00) >> 8);
    fprintf(outfile, "%c", (headers[n] & 0x00FF0000) >> 16);
    fprintf(outfile, "%c", (headers[n] & (unsigned int)0xFF000000) >> 24);
  }

  //
  // Headers done, now write the data...
  //
  for (y = height - 1; y >= 0;
       y--)  // BMP image format is written from bottom to top...
  {
    for (x = 0; x <= width - 1; x++) {
      red = chanRGB[(y * width + x) * 3];
      green = chanRGB[(y * width + x) * 3 + 1];
      blue = chanRGB[(y * width + x) * 3 + 2];

      if (red > 255) red = 255;
      if (red < 0) red = 0;
      if (green > 255) green = 255;
      if (green < 0) green = 0;
      if (blue > 255) blue = 255;
      if (blue < 0) blue = 0;
      // Also, it's written in (b,g,r) format...

      fprintf(outfile, "%c", blue);
      fprintf(outfile, "%c", green);
      fprintf(outfile, "%c", red);
    }
    if (extrabytes)  // See above - BMP lines must be of lengths divisible by 4.
    {
      for (n = 1; n <= extrabytes; n++) {
        fprintf(outfile, "%c", 0);
      }
    }
  }

  fclose(outfile);
  return 0;
}


// *****************************************************************************
// parse parameters
// -----------------------------------------------------------------------------
int findParamIndex(const char **argv, int argc, const char *parm) {
  int count = 0;
  int index = -1;

  for (int i = 0; i < argc; i++) {
    if (strncmp(argv[i], parm, 100) == 0) {
      index = i;
      count++;
    }
  }

  if (count == 0 || count == 1) {
    return index;
  } else {
    std::cout << "Error, parameter " << parm
              << " has been specified more than once, exiting\n"
              << std::endl;
    return -1;
  }

  return -1;
}