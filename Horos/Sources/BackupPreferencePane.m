/*=========================================================================
 This file is part of Unsething.
 ============================================================================*/

#import "BackupPreferencePane.h"

@implementation BackupPreferencePane

- (void)loadMainView
{
    NSView *view = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 620, 260)] autorelease];

    NSImageView *iconView = [[[NSImageView alloc] initWithFrame:NSMakeRect(38, 150, 72, 72)] autorelease];
    [iconView setImage:[NSImage imageNamed:@"BackupPreferences"]];
    [iconView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [view addSubview:iconView];

    NSTextField *titleField = [[[NSTextField alloc] initWithFrame:NSMakeRect(130, 184, 440, 30)] autorelease];
    [titleField setStringValue:NSLocalizedString(@"Backup", nil)];
    [titleField setFont:[NSFont boldSystemFontOfSize:22]];
    [titleField setBezeled:NO];
    [titleField setDrawsBackground:NO];
    [titleField setEditable:NO];
    [titleField setSelectable:NO];
    [view addSubview:titleField];

    NSTextField *descriptionField = [[[NSTextField alloc] initWithFrame:NSMakeRect(130, 112, 430, 66)] autorelease];
    [descriptionField setStringValue:NSLocalizedString(@"Configure Time Machine to protect the Unsething database and clinical data stored on this Mac.", nil)];
    [descriptionField setFont:[NSFont systemFontOfSize:13]];
    [descriptionField setBezeled:NO];
    [descriptionField setDrawsBackground:NO];
    [descriptionField setEditable:NO];
    [descriptionField setSelectable:NO];
    [descriptionField setLineBreakMode:NSLineBreakByWordWrapping];
    [[descriptionField cell] setWraps:YES];
    [view addSubview:descriptionField];

    NSButton *button = [[[NSButton alloc] initWithFrame:NSMakeRect(130, 68, 230, 32)] autorelease];
    [button setTitle:NSLocalizedString(@"Open Time Machine Settings", nil)];
    [button setBezelStyle:NSRoundedBezelStyle];
    [button setTarget:self];
    [button setAction:@selector(openTimeMachinePreferences:)];
    [view addSubview:button];

    NSTextField *hintField = [[[NSTextField alloc] initWithFrame:NSMakeRect(130, 34, 430, 22)] autorelease];
    [hintField setStringValue:NSLocalizedString(@"Make sure the Unsething Data folder is included in the backup.", nil)];
    [hintField setFont:[NSFont systemFontOfSize:11]];
    [hintField setTextColor:[NSColor secondaryLabelColor]];
    [hintField setBezeled:NO];
    [hintField setDrawsBackground:NO];
    [hintField setEditable:NO];
    [hintField setSelectable:NO];
    [view addSubview:hintField];

    [self setMainView:view];
}

- (IBAction)openTimeMachinePreferences:(id)sender
{
    NSArray *preferenceURLs = [NSArray arrayWithObjects:
                               @"x-apple.systempreferences:com.apple.Time-Machine-Settings.extension",
                               @"x-apple.systempreferences:com.apple.preference.timemachine",
                               nil];

    for( NSString *urlString in preferenceURLs)
    {
        if( [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]])
            return;
    }

    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/TimeMachine.prefPane"];
}

@end
