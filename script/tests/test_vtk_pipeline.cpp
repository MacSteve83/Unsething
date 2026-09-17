#include <vtkNew.h>
#include <vtkSphereSource.h>
#include <vtkPolyData.h>
#include <vtkPolyDataNormals.h>
#include <vtkVersion.h>
#include <vtkImageImport.h>
#include <vtkImageData.h>
#include <vector>
#include <cmath>
#include <iostream>
int main() {
    vtkNew<vtkSphereSource> sphere;
    sphere->SetRadius(10.0); sphere->SetThetaResolution(32); sphere->SetPhiResolution(32);
    vtkNew<vtkPolyDataNormals> normals;
    normals->SetInputConnection(sphere->GetOutputPort()); normals->Update();
    auto mesh = normals->GetOutput();
    if (mesh->GetNumberOfPoints() < 900 || mesh->GetNumberOfCells() < 1800) return 1;
    double bounds[6]; mesh->GetBounds(bounds);
    for (int axis = 0; axis < 3; ++axis)
        if (std::abs(bounds[axis * 2] + 10.0) > 0.1 || std::abs(bounds[axis * 2 + 1] - 10.0) > 0.1) return 2;
    std::vector<unsigned short> voxels(32 * 32 * 32, 0);
    voxels[16 + 16 * 32 + 15 * 32 * 32] = 2200;
    vtkNew<vtkImageImport> reader;
    reader->SetImportVoidPointer(voxels.data());
    reader->SetWholeExtent(0, 31, 0, 31, 1, 30);
    reader->SetDataExtentToWholeExtent();
    reader->SetDataScalarTypeToUnsignedShort();
    reader->SetNumberOfScalarComponents(1);
    reader->Update();
    reader->SetDataSpacing(3.5, 3.5, 3.5);
    reader->Update();
    double center = reader->GetOutput()->GetScalarComponentAsDouble(16, 16, 16, 0);
    if (center != 2200) { std::cerr << "VTK imported center: " << center << " expected 2200\n"; return 3; }
    std::cout << "PASS VTK " << vtkVersion::GetVTKVersion() << " surface geometry, bounds and repeated volume import\n";
}
