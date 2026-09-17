// Synthetic lossless JPEG 2000 round trips for the upgraded decoder.
#include <OpenJPEG/openjpeg.h>
#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>
#include <unistd.h>

static void require(bool value, const char* message) {
    if (!value) throw std::runtime_error(message);
}
int main() {
    try {
        for (int bits : {8, 12, 16}) for (bool sign : {false, true}) {
            std::string filename = (std::filesystem::temp_directory_path() /
                ("unsething-codec-" + std::to_string(getpid()) + ".j2k")).string();
            opj_image_cmptparm_t component{};
            component.dx = component.dy = 1;
            component.w = component.h = 64;
            component.prec = bits;
            component.sgnd = sign;
            auto image = opj_image_create(1, &component, OPJ_CLRSPC_GRAY);
            require(image, "create image");
            image->x1 = image->y1 = 64;
            std::vector<int> expected(4096);
            for (int n = 0; n < 4096; ++n) {
                expected[n] = (n * 37 % (1 << bits)) - (sign ? (1 << (bits-1)) : 0);
                image->comps[0].data[n] = expected[n];
            }
            opj_cparameters_t parameters;
            opj_set_default_encoder_parameters(&parameters);
            parameters.tcp_numlayers = 1;
            parameters.tcp_rates[0] = 0;
            parameters.cp_disto_alloc = 1;
            parameters.irreversible = 0;
            auto encoder = opj_create_compress(OPJ_CODEC_J2K);
            require(opj_setup_encoder(encoder, &parameters, image), "setup encoder");
            auto output = opj_stream_create_default_file_stream(filename.c_str(), OPJ_FALSE);
            require(output, "open output");
            require(opj_start_compress(encoder, image, output), "start encoder");
            require(opj_encode(encoder, output), "encode");
            require(opj_end_compress(encoder, output), "end encoder");
            opj_stream_destroy(output);
            opj_destroy_codec(encoder);
            opj_image_destroy(image);
            auto decoder = opj_create_decompress(OPJ_CODEC_J2K);
            opj_dparameters_t settings;
            opj_set_default_decoder_parameters(&settings);
            require(opj_setup_decoder(decoder, &settings), "setup decoder");
            auto input = opj_stream_create_default_file_stream(filename.c_str(), OPJ_TRUE);
            image = nullptr;
            require(opj_read_header(input, decoder, &image), "read header");
            require(image->numcomps == 1 && image->comps[0].prec == bits && image->comps[0].sgnd == sign, "pixel metadata");
            require(opj_decode(decoder, input, image) && opj_end_decompress(decoder, input), "decode");
            require(image->comps[0].w == 64 && image->comps[0].h == 64, "dimensions");
            for (int n = 0; n < 4096; ++n) require(image->comps[0].data[n] == expected[n], "pixel mismatch");
            opj_image_destroy(image);
            opj_stream_destroy(input);
            opj_destroy_codec(decoder);
            std::filesystem::remove(filename);
            std::cout << "PASS " << bits << " bit " << (sign ? "signed" : "unsigned") << '\n';
        }
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n'; return 1;
    }
}
