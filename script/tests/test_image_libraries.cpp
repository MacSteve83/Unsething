// Synthetic image processing and DICOM decoding, without patient archives.
#include <itkImage.h>
#include <itkBinaryThresholdImageFilter.h>
#include <itkVersion.h>
#include <GDCM/gdcmImageReader.h>
#include <GDCM/gdcmImage.h>
#include <GDCM/gdcmVersion.h>
#include <iostream>
#include <stdexcept>
#include <vector>
int main(int argc, char** argv) {
    try {
        using Image = itk::Image<unsigned short, 2>;
        auto image = Image::New();
        Image::SizeType size; size.Fill(5);
        image->SetRegions(size); image->Allocate();
        for (int i = 0; i < 25; ++i) image->GetBufferPointer()[i] = i;
        auto filter = itk::BinaryThresholdImageFilter<Image, Image>::New();
        filter->SetInput(image); filter->SetLowerThreshold(10); filter->SetUpperThreshold(20);
        filter->SetInsideValue(65535); filter->SetOutsideValue(0); filter->Update();
        for (int i = 0; i < 25; ++i) {
            if (filter->GetOutput()->GetBufferPointer()[i] != (i >= 10 && i <= 20 ? 65535 : 0))
                throw std::runtime_error("ITK pixel mismatch");
        }
        std::cout << "PASS ITK " << itk::Version::GetITKVersion() << " threshold pixels\n";
        if (argc != 2) throw std::runtime_error("DICOM fixture path required");
        gdcm::ImageReader reader; reader.SetFileName(argv[1]);
        if (!reader.Read()) throw std::runtime_error("GDCM read failed");
        auto& decoded = reader.GetImage();
        if (decoded.GetDimension(0) != 2 || decoded.GetDimension(1) != 2 || decoded.GetBufferLength() != 8)
            throw std::runtime_error("GDCM dimensions mismatch");
        std::vector<unsigned short> pixels(4);
        if (!decoded.GetBuffer(reinterpret_cast<char*>(pixels.data())) || pixels != std::vector<unsigned short>{0, 1, 2048, 4095})
            throw std::runtime_error("GDCM pixel mismatch");
        std::cout << "PASS GDCM " << gdcm::Version::GetVersion() << " DICOM pixels\n";
    } catch (const std::exception& e) { std::cerr << e.what() << '\n'; return 1; }
}
