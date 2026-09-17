#import <Foundation/Foundation.h>
#import "../../Horos/Sources/UnsethingDefaultAlbumNames.h"
static int checks = 0;
#define CHECK(x) do { ++checks; if (!(x)) { NSLog(@"FAIL line %d: %s",__LINE__,#x); return 1; } } while(0)
int main(int argc, const char **argv) { @autoreleasepool {
    CHECK(argc == 2);
    NSString *resources = [NSString stringWithUTF8String:argv[1]];
    NSDictionary *italian = [NSDictionary dictionaryWithContentsOfFile:[resources stringByAppendingPathComponent:@"Italian.lproj/Localizable.strings"]];
    CHECK(italian.count > 0);
    NSString *tmp = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingString:@".bundle"]];
    NSFileManager *fm = NSFileManager.defaultManager;
    for (NSString *lang in @[@"Italian",@"en"]) {
        NSString *dir = [tmp stringByAppendingPathComponent:[lang stringByAppendingString:@".lproj"]];
        CHECK([fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL]);
        CHECK([fm copyItemAtPath:[resources stringByAppendingPathComponent:[[lang stringByAppendingPathExtension:@"lproj"] stringByAppendingPathComponent:@"Localizable.strings"]] toPath:[dir stringByAppendingPathComponent:@"Localizable.strings"] error:NULL]);
    }
    [@{@"CFBundleIdentifier":@"it.unsething.album-localization-test",@"CFBundleDevelopmentRegion":@"en"} writeToFile:[tmp stringByAppendingPathComponent:@"Info.plist"] atomically:YES];
    NSBundle *bundle = [NSBundle bundleWithPath:tmp];
    CHECK(bundle != nil);
    NSDictionary *index = UnsethingDefaultAlbumNameIndex(bundle);
    NSDictionary *descriptors = UnsethingDefaultAlbumDescriptors();
    CHECK(descriptors.count == 19);
    NSBundle *englishBundle = [NSBundle bundleWithPath:[tmp stringByAppendingPathComponent:@"en.lproj"]];
    NSBundle *italianBundle = [NSBundle bundleWithPath:[tmp stringByAppendingPathComponent:@"Italian.lproj"]];
    for (NSString *key in descriptors) {
        BOOL smart = descriptors[key] != NSNull.null;
        NSString *predicate = smart ? descriptors[key] : nil;
        NSString *name = italian[key];
        CHECK(name.length > 0);
        NSString *resolved = UnsethingDefaultAlbumKey(name,predicate,smart,index);
        CHECK([resolved isEqualToString:key]);
        CHECK([[englishBundle localizedStringForKey:resolved value:resolved table:nil] isEqualToString:key]);
        CHECK([[italianBundle localizedStringForKey:resolved value:resolved table:nil] isEqualToString:name]);
        CHECK([UnsethingDefaultAlbumKey(key,predicate,smart,index) isEqualToString:key]);
    }
    CHECK(UnsethingDefaultAlbumKey(@"I miei casi",@"(date >= $NSDATE_LASTHOUR)",YES,index) == nil);
    CHECK(UnsethingDefaultAlbumKey(italian[@"Just Acquired (last hour)"],@"(modality == 'CT')",YES,index) == nil);
    CHECK(UnsethingDefaultAlbumKey(italian[@"Just Acquired (last hour)"],@"(date >= $NSDATE_LASTHOUR)",NO,index) == nil);
    CHECK(UnsethingDefaultAlbumKey(nil,nil,NO,index) == nil);
    CHECK([UnsethingDefaultAlbumKey(italian[@"Today MR"],@"(ANY series.modality CONTAINS[cd] 'MR') AND (date >= $NSDATE_TODAY)",YES,index) isEqualToString:@"Today MR"]);
    CHECK([UnsethingDefaultAlbumKey(italian[@"Cases with comments"],@"(ANY series.comment != '' AND ANY series.comment != NIL) OR (comment != '' AND comment != NIL)",YES,index) isEqualToString:@"Cases with comments"]);
    CHECK([fm removeItemAtPath:tmp error:NULL]);
    NSLog(@"PASS: %d checks of default album localization, language round-trip and custom albums",checks);
} return 0; }
