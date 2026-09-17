#include <dcmtk/config/osconfig.h>
#include <dcmtk/dcmdata/dctk.h>
#include <dcmtk/dcmjpeg/djencode.h>
#include <dcmtk/dcmjpeg/djdecode.h>
#include <dcmtk/dcmjpeg/djrplol.h>
#include <iostream>
#include <stdexcept>
extern int gForce1024RescaleInterceptForCT;
static void check(bool ok, const char *what) { if (!ok) throw std::runtime_error(what); }
int main() {
    DJEncoderRegistration::registerCodecs(); DJDecoderRegistration::registerCodecs();
    try {
        DcmDataset original;
        original.putAndInsertString(DCM_SOPClassUID, UID_CTImageStorage);
        original.putAndInsertString(DCM_SOPInstanceUID, "1.2.826.0.1.3680043.10.999.99");
        original.putAndInsertString(DCM_PhotometricInterpretation, "MONOCHROME2");
        original.putAndInsertString(DCM_RescaleIntercept, "-1000");
        original.putAndInsertString(DCM_RescaleSlope, "1");
        original.putAndInsertUint16(DCM_Rows, 16); original.putAndInsertUint16(DCM_Columns, 16);
        original.putAndInsertUint16(DCM_SamplesPerPixel, 1);
        original.putAndInsertUint16(DCM_BitsAllocated, 16); original.putAndInsertUint16(DCM_BitsStored, 12);
        original.putAndInsertUint16(DCM_HighBit, 11); original.putAndInsertUint16(DCM_PixelRepresentation, 0);
        Uint16 pixels[256]; for (int i=0;i<256;++i) pixels[i]=500+i;
        original.putAndInsertUint16Array(DCM_PixelData,pixels,256);
        DJ_RPLossless params(1,0);
        check(original.chooseRepresentation(EXS_JPEGProcess14SV1, &params).good(), "JPEG encode");
        original.removeAllButCurrentRepresentations();
        for (int compatibility=0;compatibility<2;++compatibility) {
            DcmDataset decoded(original); gForce1024RescaleInterceptForCT=compatibility;
            check(decoded.chooseRepresentation(EXS_LittleEndianExplicit,nullptr).good(), "JPEG decode");
            Float64 intercept=0; check(decoded.findAndGetFloat64(DCM_RescaleIntercept,intercept).good(), "intercept");
            check(intercept == (compatibility ? -1024 : -1000), "intercept mismatch");
            const Uint16 *actual=nullptr; unsigned long count=0;
            check(decoded.findAndGetUint16Array(DCM_PixelData,actual,&count).good() && count==256,"pixel count");
            for (int i=0;i<256;++i) check(actual[i]+intercept == pixels[i]-1000,"CT value changed");
        }
        gForce1024RescaleInterceptForCT=0;
        std::cout << "PASS DCMTK JPEG CT rescale preserves calibrated values with compatibility on/off\n";
    } catch (const std::exception &e) { std::cerr << e.what() << '\n'; return 1; }
    DJDecoderRegistration::cleanup(); DJEncoderRegistration::cleanup();
}
