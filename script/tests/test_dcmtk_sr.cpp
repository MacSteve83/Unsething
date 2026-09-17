// Round-trip the SR metadata and image references used by Unsething annotations.
#include <dcmtk/config/osconfig.h>
#include <dcmtk/dcmdata/dctk.h>
#include <dcmtk/dcmsr/dsrdoc.h>
#include <iostream>
#include <stdexcept>
static void check(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}
int main() {
    try {
        DSRDocument sr;
        check(sr.createNewDocument(DSRTypes::DT_ComprehensiveSR).good(), "create SR");
        check(sr.setPatientName("SYNTHETIC^LIBRARYTEST").good(), "patient name");
        check(sr.setPatientID("SYNTHETIC-ONLY").good(), "patient ID");
        check(sr.setInstanceNumber("3").good(), "instance number");
        check(sr.getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container) != 0, "root");
        sr.getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", "Annotations"));
        check(sr.getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Image, DSRTypes::AM_belowCurrent) != 0, "image node");
        sr.getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.10", "99HUG", "Image Reference"));
        DSRImageReferenceValue reference(UID_SecondaryCaptureImageStorage, "1.2.826.0.1.3680043.10.999.1");
        check(sr.getTree().getCurrentContentItem().setImageReference(reference).good(), "reference");
        DcmDataset data;
        check(sr.write(data).good(), "write SR");
        DSRDocument restored;
        check(restored.read(data).good(), "read SR");
        OFString value;
        check(restored.getPatientName(value).good() && value == "SYNTHETIC^LIBRARYTEST", "name mismatch");
        check(restored.getInstanceNumber(value).good() && value == "3", "instance mismatch");
        check(restored.getTree().gotoNamedNode(DSRCodedEntryValue("IHE.10", "99HUG", "Image Reference"), OFTrue, OFTrue) != 0, "missing image reference");
        check(restored.getTree().getCurrentContentItem().getImageReference().getSOPInstanceUID() == "1.2.826.0.1.3680043.10.999.1", "reference mismatch");
        const Uint8 expected[] = {0, 1, 128, 255};
        check(data.putAndInsertUint8Array(DcmTag(DCM_OsirixROI, EVR_OB), expected, 4).good(), "ROI write");
        const Uint8 *actual = nullptr; unsigned long count = 0;
        check(data.findAndGetUint8Array(DCM_OsirixROI, actual, &count).good() && count == 4 && memcmp(actual, expected, 4) == 0, "ROI bytes mismatch");
        std::cout << "PASS DCMTK " << PACKAGE_VERSION << " SR metadata, image references and ROI bytes\n";
    } catch (const std::exception &error) { std::cerr << error.what() << '\n'; return 1; }
}
