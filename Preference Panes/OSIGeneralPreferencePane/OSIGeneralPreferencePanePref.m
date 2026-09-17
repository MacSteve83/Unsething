/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/


#import "OSIGeneralPreferencePanePref.h"
#import "NSPreferencePane+OsiriX.h"
#import "AppController.h"
#import "DefaultsOsiriX.h"
#import "N2Debug.h"

static NSString *OSICanonicalLanguageIdentifier(NSString *languageIdentifier)
{
    if( languageIdentifier == nil)
        return nil;

    NSString *languageCode = [[NSLocale componentsFromLocaleIdentifier: languageIdentifier] objectForKey: NSLocaleLanguageCode];
    if( [languageCode isEqualToString: @"en"])
        return @"English";
    if( [languageCode isEqualToString: @"it"])
        return @"Italian";
    if( [languageCode isEqualToString: @"ja"])
        return @"ja-JP";
    
    if( [languageIdentifier caseInsensitiveCompare: @"English"] == NSOrderedSame || [languageIdentifier caseInsensitiveCompare: @"en"] == NSOrderedSame)
        return @"English";
    
    if( [languageIdentifier caseInsensitiveCompare: @"Italian"] == NSOrderedSame || [languageIdentifier caseInsensitiveCompare: @"it"] == NSOrderedSame)
        return @"Italian";
    
    if( [languageIdentifier caseInsensitiveCompare: @"Japanese"] == NSOrderedSame || [languageIdentifier caseInsensitiveCompare: @"ja"] == NSOrderedSame || [languageIdentifier caseInsensitiveCompare: @"ja-JP"] == NSOrderedSame)
        return @"ja-JP";
    
    return languageIdentifier;
}

static NSArray *OSILanguagePreferenceListForIdentifier(NSString *languageIdentifier)
{
    NSString *canonicalIdentifier = OSICanonicalLanguageIdentifier(languageIdentifier);
    
    if( [canonicalIdentifier isEqualToString: @"English"])
        return [NSArray arrayWithObjects: @"English", @"en", nil];
    
    if( [canonicalIdentifier isEqualToString: @"Italian"])
        return [NSArray arrayWithObjects: @"Italian", @"it", @"English", @"en", nil];
    
    if( [canonicalIdentifier isEqualToString: @"ja-JP"])
        return [NSArray arrayWithObjects: @"ja-JP", @"ja", @"English", @"en", nil];
    
    if( canonicalIdentifier)
        return [NSArray arrayWithObjects: canonicalIdentifier, @"English", @"en", nil];
    
    return [NSArray arrayWithObjects: @"English", @"en", nil];
}

static NSString *OSICurrentSavedLanguageIdentifier(void)
{
    NSArray *savedLanguages = [[NSUserDefaults standardUserDefaults] objectForKey: @"AppleLanguages"];
    
    if( [savedLanguages count])
        return OSICanonicalLanguageIdentifier([savedLanguages objectAtIndex: 0]);
    
    if( [[[NSBundle mainBundle] preferredLocalizations] count])
        return OSICanonicalLanguageIdentifier([[[NSBundle mainBundle] preferredLocalizations] objectAtIndex: 0]);
    
    return nil;
}

static NSString *OSIDisplayNameForLanguageIdentifier(NSString *languageIdentifier)
{
    NSString *name = [[NSLocale currentLocale] displayNameForKey: NSLocaleIdentifier value: languageIdentifier];
    
    if( name.length == 0)
        name = languageIdentifier;
    
    return name;
}

@interface OSILanguageOption : NSObject
{
    NSString *_foldername;
    NSString *_language;
    BOOL _active;
    id _owner;
}

@property(nonatomic, copy) NSString *foldername;
@property(nonatomic, copy) NSString *language;
@property(nonatomic, assign) BOOL active;
@property(nonatomic, assign) id owner;

- (id)initWithFolderName:(NSString *)foldername language:(NSString *)language active:(BOOL)active owner:(id)owner;
- (void)setActiveSilently:(BOOL)active;

@end

@implementation OSILanguageOption

@synthesize foldername = _foldername;
@synthesize language = _language;
@synthesize active = _active;
@synthesize owner = _owner;

- (id)initWithFolderName:(NSString *)foldername language:(NSString *)language active:(BOOL)active owner:(id)owner
{
    self = [super init];
    if( self)
    {
        self.foldername = foldername;
        self.language = language;
        _active = active;
        self.owner = owner;
    }
    
    return self;
}

- (void)setActive:(BOOL)active
{
    if( _active == active)
        return;
    
    if( active && [_owner respondsToSelector: @selector(selectLanguageOption:)])
        [_owner performSelector: @selector(selectLanguageOption:) withObject: self];
    else if( active == NO)
        return;
    else
        [self setActiveSilently: active];
}

- (void)setActiveSilently:(BOOL)active
{
    if( _active == active)
        return;
    
    [self willChangeValueForKey: @"active"];
    _active = active;
    [self didChangeValueForKey: @"active"];
}

- (id)valueForKey:(NSString *)key
{
    if( [key isEqualToString: @"foldername"])
        return self.foldername;
    
    if( [key isEqualToString: @"language"])
        return self.language;
    
    if( [key isEqualToString: @"active"])
        return [NSNumber numberWithBool: self.active];
    
    return [super valueForKey: key];
}

- (void)dealloc
{
    self.foldername = nil;
    self.language = nil;
    
    [super dealloc];
}

@end

@interface IsQualityEnabled: NSValueTransformer {}
@end
@implementation IsQualityEnabled
+ (Class)transformedValueClass { return [NSNumber class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)item {
   if( [item intValue] == 3 || [item intValue] == 4)
		return [NSNumber numberWithBool: YES];
	else
		return [NSNumber numberWithBool: NO];
}
@end

@implementation OSIGeneralPreferencePanePref

@synthesize languages;

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
        self.languages = [NSMutableArray array];
        NSString *selectedLanguage = OSICurrentSavedLanguageIdentifier();
        BOOL selectedLanguageFound = NO;
        NSMutableSet *foundLanguages = [NSMutableSet set];
        
        for( NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: [[NSBundle mainBundle] resourcePath] error: nil])
        {
            if( [[file pathExtension] isEqualToString: @"lproj"])
            {
                NSString *foldername = OSICanonicalLanguageIdentifier([file stringByDeletingPathExtension]);
                if( [foundLanguages containsObject: foldername])
                    continue;
                [foundLanguages addObject: foldername];
                
                BOOL active = (selectedLanguage == nil || [selectedLanguage isEqualToString: foldername]) && selectedLanguageFound == NO;
                if( active)
                    selectedLanguageFound = YES;
                
                [languages addObject: [[[OSILanguageOption alloc] initWithFolderName: foldername language: OSIDisplayNameForLanguageIdentifier(foldername) active: active owner: self] autorelease]];
            }
        }
        
        if( selectedLanguageFound == NO && [languages count])
            [[languages objectAtIndex: 0] setActiveSilently: YES];
        
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIGeneralPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
        
        [compressionSettingsWindow retain];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
	}
	
	return self;
}

- (NSUInteger) kakaduAvailable
{
	return [AppController isKDUEngineAvailable];
}

- (NSUInteger) JP2KWriter
{
	return [[NSUserDefaults standardUserDefaults] boolForKey: @"useDCMTKForJP2K"];
}

- (void) setJP2KWriter:(NSUInteger) v
{
	[[NSUserDefaults standardUserDefaults] setBool: v forKey: @"useDCMTKForJP2K"];
	
	[self willChangeValueForKey: @"JP2KWriter"];
	[self didChangeValueForKey: @"JP2KWriter"];
	
	[self willChangeValueForKey: @"JP2KEngine"];
	[self didChangeValueForKey: @"JP2KEngine"];
}

- (void) setJP2KEngine: (NSUInteger) val;
{	
	if( val == 1) // Kakadu
	{
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"UseKDUForJPEG2000"];
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"UseOpenJpegForJPEG2000"];
	}
	
	if( val == 0) // OpenJPEG
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"UseKDUForJPEG2000"];
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"UseOpenJpegForJPEG2000"];
	}
	
	[self willChangeValueForKey: @"JP2KWriter"];
	[self didChangeValueForKey: @"JP2KWriter"];
	
	[self willChangeValueForKey: @"JP2KEngine"];
	[self didChangeValueForKey: @"JP2KEngine"];
}

- (NSUInteger) JP2KEngine
{
	if( [AppController isKDUEngineAvailable] == 1 && [[NSUserDefaults standardUserDefaults] boolForKey: @"UseKDUForJPEG2000"])
	{
		return 1; // Kakadu
	}
	
	if( [AppController isKDUEngineAvailable] == 0 && [[NSUserDefaults standardUserDefaults] boolForKey: @"UseKDUForJPEG2000"])
	{
		return 0; // OpenJPEG
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseOpenJpegForJPEG2000"])
	{
		return 0; // OpenJPEG
	}
	
	return 0; // OpenJPEG
}

- (IBAction) resetPreferences: (id) sender
{
	NSInteger result = NSRunInformationalAlertPanel( NSLocalizedString(@"Reset Preferences", nil), NSLocalizedString(@"Are you sure you want to reset ALL preferences of Horos? All the preferences will be reseted to their default values.", nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"OK",nil),  nil);
	
	if( result == NSAlertAlternateReturn)
	{
		for( NSString *k in [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys])
			[[NSUserDefaults standardUserDefaults] removeObjectForKey: k];
		
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (IBAction) savePreferences: (id) sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
    
    NSSavePanel *save = [NSSavePanel savePanel];
    
    [save setAllowedFileTypes: [NSArray arrayWithObject: @"plist"]];
    [save setNameFieldStringValue: @"Horos-Preferences.plist"];
    
    if( [save runModal] == NSFileHandlingPanelOKButton)
	{
        NSDictionary *defaultsPreferences = [DefaultsOsiriX getDefaults];
        NSMutableDictionary *customizedPreferences = [NSMutableDictionary dictionary];
        
        for( NSString *k in [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys])
        {
            if( [defaultsPreferences objectForKey: k] == nil || [[[NSUserDefaults standardUserDefaults] objectForKey: k] isEqual: [defaultsPreferences objectForKey: k]] == NO)
                [customizedPreferences setObject: [[NSUserDefaults standardUserDefaults] objectForKey: k] forKey: k];
        }
        
		[customizedPreferences writeToURL: save.URL atomically: YES];
	}
}

+ (void) errorMessage:(NSURL*) url
{
    NSRunAlertPanel( NSLocalizedString( @"Preferences", nil), NSLocalizedString( @"Failed to download and synchronize preferences from this URL: %@", nil), NSLocalizedString( @"OK", nil), nil, nil, url.absoluteString);
}

+ (void) addPreferencesFromURL: (NSURL*) url
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    BOOL succeed = NO;
    
    if( url)
    {
        NSLog( @"--- loading preferences from URL: %@", url);
        
        @try {
            BOOL activated = NO;
            if( [NSThread isMainThread] == NO)
                activated = [[NSUserDefaults standardUserDefaults] boolForKey: @"SyncPreferencesFromURL"];
            
            NSDictionary *customizedPreferences = [NSDictionary dictionaryWithContentsOfURL: url];
            
            if( customizedPreferences)
            {
                for( NSString *key in customizedPreferences)
                    [[NSUserDefaults standardUserDefaults] setObject: [customizedPreferences objectForKey: key] forKey: key];
                
                succeed = YES;
                
                if( [NSThread isMainThread] == NO)
                {
                    [[NSUserDefaults standardUserDefaults] setObject: url.absoluteString forKey: @"SyncPreferencesURL"];
                    [[NSUserDefaults standardUserDefaults] setBool: activated forKey: @"SyncPreferencesFromURL"];
                }
            }
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
        NSLog( @"--- loading preferences from URL: %@ - DONE", url);
    }
    
    if( succeed == NO)
        [[OSIGeneralPreferencePanePref class] performSelectorOnMainThread: @selector( errorMessage:) withObject: url waitUntilDone: NO];
    
    [pool release];
}

- (IBAction) refreshPreferencesURLSync:(id)sender
{
    [[[self mainView] window] makeFirstResponder: nil];
    
    if( [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] stringForKey: @"SyncPreferencesURL"]] == nil)
        NSRunInformationalAlertPanel( NSLocalizedString(@"Sync Preferences", nil), NSLocalizedString(@"The provided URL doesn't seem correct. Check it's validity.", nil), NSLocalizedString(@"OK",nil), nil,  nil);
    else
    {
        NSInteger result = NSRunInformationalAlertPanel( NSLocalizedString(@"Sync Preferences", nil), NSLocalizedString(@"Are you sure you want to replace  current preferences with the preferences stored at this URL? You cannot undo this operation.", nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"OK",nil),  nil);
        
        if( result == NSAlertAlternateReturn)
            [NSThread detachNewThreadSelector: @selector( addPreferencesFromURL:) toTarget: [OSIGeneralPreferencePanePref class] withObject: [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] stringForKey: @"SyncPreferencesURL"]]];
    }
}

- (IBAction) loadPreferences: (id) sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
    
    NSOpenPanel *open = [NSOpenPanel openPanel];
    
    open.canChooseFiles = YES;
	open.canChooseDirectories = NO;
	open.canCreateDirectories = NO;
	open.allowsMultipleSelection = NO;
	open.message = NSLocalizedString(@"Select the preferences file (plist) to load:", nil);
	
    if( [open runModal] == NSFileHandlingPanelOKButton)
    {
        NSInteger result = NSRunInformationalAlertPanel( NSLocalizedString(@"Load Preferences", nil), NSLocalizedString(@"Are you sure you want to replace  current preferences with the preferences stored in this file? You cannot undo this operation.", nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"OK",nil),  nil);
        
        if( result == NSAlertAlternateReturn)
            [OSIGeneralPreferencePanePref addPreferencesFromURL: open.URL];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)initialize
{
	IsQualityEnabled *a = [[[IsQualityEnabled alloc] init] autorelease];
	
	[NSValueTransformer setValueTransformer:a forName:@"IsQualityEnabled"];
}

- (void) dealloc
{
	NSLog(@"dealloc OSIGeneralPreferencePanePref");
	
    [languages release];
    
    [compressionSettingsWindow release];
    
    [_tlos release]; _tlos = nil;
    
	[super dealloc];
}

- (void)selectLanguageOption:(OSILanguageOption *)selectedLanguage
{
    NSString *selectedIdentifier = OSICanonicalLanguageIdentifier(selectedLanguage.foldername);
    BOOL languageChanged = ![OSICurrentSavedLanguageIdentifier() isEqualToString: selectedIdentifier];

    for( OSILanguageOption *language in languages)
        [language setActiveSilently: language == selectedLanguage];
    
    [[NSUserDefaults standardUserDefaults] setObject: OSILanguagePreferenceListForIdentifier(selectedLanguage.foldername) forKey: @"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if( languageChanged)
    {
        // The bundle still uses the previous language until restart, so choose
        // this message from the newly selected language instead.
        BOOL italian = [selectedIdentifier isEqualToString: @"Italian"];
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = italian ? @"Riavvio richiesto" : @"Restart required";
        alert.informativeText = italian
            ? @"Riavvia Unsething per rendere effettiva la modifica della lingua."
            : @"Restart Unsething for the language change to take effect.";
        [alert addButtonWithTitle: @"OK"];

        NSWindow *window = [[self mainView] window];
        if( window)
            [alert beginSheetModalForWindow: window completionHandler: nil];
        else
            [alert runModal];
    }
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
    
    BOOL enabled = NO;
    
    for( NSDictionary *d in languages)
    {
        if( [[d valueForKey: @"active"] boolValue])
            enabled = YES;
    }
    
    // At least one language must be active !
    if( enabled == NO)
        [[languages objectAtIndex: 0] setValue: [NSNumber numberWithBool: YES] forKey: @"active"];
    
    for( OSILanguageOption *language in languages)
    {
        if( language.active)
        {
            [[NSUserDefaults standardUserDefaults] setObject: OSILanguagePreferenceListForIdentifier(language.foldername) forKey: @"AppleLanguages"];
            break;
        }
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void) applyLanguagesIfNeeded
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) endEditCompressionSettings:(id) sender
{
	[compressionSettingsWindow orderOut:sender];
	[NSApp endSheet: compressionSettingsWindow returnCode:[sender tag]];
	
	if( [sender tag] == 1)
	{
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject: compressionSettingsCopy forKey: @"CompressionSettings"];
		[[NSUserDefaults standardUserDefaults] setObject: compressionSettingsLowResCopy forKey: @"CompressionSettingsLowRes"];
	}
	
	[compressionSettingsCopy autorelease];
	[compressionSettingsLowResCopy autorelease];
}

- (IBAction) editCompressionSettings:(id) sender
{
    if( [[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettings"] count] < 14)
    {
        NSLog( @"*** reset compression settings");
        [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"CompressionSettings"];
    }
    
    if( [[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettingsLowRes"] count] < 14)
    {
        NSLog( @"*** reset compression settings");
        [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"CompressionSettingsLowRes"];
    }
    
    compressionSettingsCopy = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettings"] copy];
    compressionSettingsLowResCopy = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettingsLowRes"] copy];
    
    [NSApp beginSheet: compressionSettingsWindow modalForWindow: [[self mainView] window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

@end
