"""Compile and exercise the real Objective-C path resolver on disposable folders."""
from pathlib import Path
import subprocess, tempfile
root = Path(__file__).resolve().parents[2]
s = (root/'Horos/Sources/DicomDatabase.mm').read_bytes().decode('latin1')
method = s[s.index('+(NSString*)baseDirPathForPath:'):s.index('+(NSString*)baseDirPathForMode:')]
code = '''#import <Foundation/Foundation.h>
NSString *OsirixDataDirName = @"Unsething Data";
@interface DicomDatabase : NSObject
+(NSString*)baseDirPathForPath:(NSString*)path;
@end
@implementation DicomDatabase
''' + method + '''
@end
int main(int argc, char **argv) { @autoreleasepool {
 NSString *root = [NSString stringWithUTF8String:argv[1]];
 for (NSString *name in @[@"Unsething Data", @"Horos Data", @"OsiriX Data", @"Osirix Data"]) {
  NSString *base = [root stringByAppendingPathComponent:name];
  [[NSFileManager defaultManager] createDirectoryAtPath:base withIntermediateDirectories:YES attributes:nil error:nil];
  for (NSNumber *hasIndex in @[@NO, @YES]) {
  if (hasIndex.boolValue) [@"test index" writeToFile:[base stringByAppendingPathComponent:@"Database.sql"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
  for (NSString *suffix in @[@"", @"Database.sql", @"DATABASE.noindex/1/image.dcm"]) {
   NSString *input = suffix.length ? [base stringByAppendingPathComponent:suffix] : base;
   NSCAssert([[DicomDatabase baseDirPathForPath:input] isEqualToString:base], @"Redirected legacy path: %@", input);
  }
  }
 }
 NSCAssert([[DicomDatabase baseDirPathForPath:root] isEqualToString:[root stringByAppendingPathComponent:@"Unsething Data"]], @"Default changed");
 puts("PASS: legacy paths remain exact without an index, including nested files and spelling variants");
} }
'''
with tempfile.TemporaryDirectory(prefix='unsething-path-tests-') as d:
 p=Path(d); (p/'test.m').write_text(code)
 subprocess.run(['clang','-framework','Foundation',str(p/'test.m'),'-o',str(p/'test')],check=True)
 subprocess.run([str(p/'test'),str(p/'fixtures')],check=True)
