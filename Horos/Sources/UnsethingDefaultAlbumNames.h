// Display-only localization of legacy default albums. Same license as Unsething.
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

static NSDictionary *UnsethingDefaultAlbumDescriptors(void) {
    static NSDictionary *descriptors;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:@{
            @"Just Added (last hour)": @"(dateAdded >= $NSDATE_LASTHOUR)",
            @"Just Acquired (last hour)": @"(date >= $NSDATE_LASTHOUR)",
            @"Just Opened": @"(dateOpened >= $NSDATE_LAST6HOURS)",
            @"Cases with comments": @"(comment != '' AND comment != NIL)",
            @"Interesting Cases": NSNull.null
        }];
        for (NSString *modality in @[@"MR", @"CT", @"US", @"MG", @"CR", @"XA", @"RF"]) {
            d[[@"Today " stringByAppendingString:modality]] = [NSString stringWithFormat:@"(modality CONTAINS[cd] '%@') AND (date >= $NSDATE_TODAY)",modality];
            d[[@"Yesterday " stringByAppendingString:modality]] = [NSString stringWithFormat:@"(modality CONTAINS[cd] '%@') AND (date >= $NSDATE_YESTERDAY AND date <= $NSDATE_TODAY)",modality];
        }
        descriptors = [d copy];
    });
    return descriptors;
}

// Names were persisted in the language used when each archive was created.
// Recognize those translations, without changing names used as database keys.
static NSDictionary *UnsethingDefaultAlbumNameIndex(NSBundle *bundle) {
    NSMutableDictionary *index = [NSMutableDictionary dictionary];
    for (NSString *key in UnsethingDefaultAlbumDescriptors()) index[key] = key;
    for (NSString *localization in bundle.localizations) {
        NSString *path = [bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:localization];
        NSDictionary *strings = path ? [NSDictionary dictionaryWithContentsOfFile:path] : nil;
        for (NSString *key in UnsethingDefaultAlbumDescriptors()) {
            NSString *translated = strings[key];
            if ([translated isKindOfClass:NSString.class] && translated.length) index[translated] = key;
        }
    }
    return index;
}

static NSString *UnsethingDefaultAlbumKey(NSString *name, NSString *predicate, BOOL smart, NSDictionary *nameIndex) {
    NSString *key = name ? nameIndex[name] : nil;
    if (!key) return nil;
    id expected = UnsethingDefaultAlbumDescriptors()[key];
    if (expected == NSNull.null) return !smart && !predicate.length ? key : nil;
    if (!smart) return nil;
    NSString *normalized = [predicate stringByReplacingOccurrencesOfString:@"ANY series.modality" withString:@"modality"];
    if ([normalized isEqualToString:@"(ANY series.comment != '' AND ANY series.comment != NIL) OR (comment != '' AND comment != NIL)"])
        normalized = @"(comment != '' AND comment != NIL)";
    return [normalized isEqualToString:expected] ? key : nil;
}
