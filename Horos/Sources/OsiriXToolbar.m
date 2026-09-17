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

#import "OsiriXToolbar.h"
#import "ViewerController.h"
#import "ToolbarPanel.h"
#import "NSWindow+N2.h"
#import <objc/runtime.h>

NSString * const UnsethingToolbarSizeDefaultsKey = @"UnsethingToolbarSizeLevel";
NSString * const UnsethingToolbarSizeDidChangeNotification = @"UnsethingToolbarSizeDidChangeNotification";

static NSInteger const UnsethingToolbarSizeControlTag = 901201;
static char UnsethingToolbarOriginalImageKey;

NSInteger UnsethingToolbarSizeLevel(void)
{
    NSInteger level = [[NSUserDefaults standardUserDefaults] integerForKey: UnsethingToolbarSizeDefaultsKey];
    if( level < 0) level = 0;
    if( level > 2) level = 2;
    return level;
}

NSSize UnsethingToolbarIconSize(void)
{
    NSInteger level = UnsethingToolbarSizeLevel();
    CGFloat side = 32.0 + (level * 8.0);
    return NSMakeSize(side, side);
}

CGFloat UnsethingToolbarPanelHeightExtra(void)
{
    return UnsethingToolbarSizeLevel() * 12.0;
}

static CGFloat UnsethingToolbarLabelWidth(NSToolbarItem *item)
{
    NSString *label = [item label];
    if( label == nil)
        label = [item paletteLabel];
    if( [label length] == 0)
        return 0;

    NSDictionary *attributes = [NSDictionary dictionaryWithObject: [NSFont systemFontOfSize: 11] forKey: NSFontAttributeName];
    return [label sizeWithAttributes: attributes].width;
}

void UnsethingApplyToolbarItemSizing(NSToolbarItem *item)
{
    if( item == nil)
        return;

    [item setBordered: NO];
    if( [item view] != nil)
        return;

    NSImage *image = [item image];
    if( image == nil)
        return;

    if( objc_getAssociatedObject(item, &UnsethingToolbarOriginalImageKey) == nil)
    {
        objc_setAssociatedObject(item, &UnsethingToolbarOriginalImageKey, image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    NSImage *originalImage = objc_getAssociatedObject(item, &UnsethingToolbarOriginalImageKey);
    NSSize iconSize = UnsethingToolbarIconSize();
    NSImage *scaledImage = [originalImage copy];
    [scaledImage setScalesWhenResized: YES];
    [scaledImage setSize: iconSize];
    [item setImage: scaledImage];
    [scaledImage release];

    CGFloat width = MAX(iconSize.width + 18.0, UnsethingToolbarLabelWidth(item) + 14.0);
    CGFloat height = iconSize.height;
    [item setMinSize: NSMakeSize(width, height)];
    [item setMaxSize: NSMakeSize(width + 20.0, height)];
}

static BOOL UnsethingViewContainsToolbarDisplayPopup(NSView *view)
{
    if( [view isKindOfClass: [NSPopUpButton class]])
    {
        NSPopUpButton *popup = (NSPopUpButton *) view;
        for( NSMenuItem *item in [popup itemArray])
        {
            NSString *title = [item title];
            if( [title isEqualToString: @"Icone e testo"] ||
                [title isEqualToString: @"Icona e testo"] ||
                [title isEqualToString: @"Icons and Text"] ||
                [title isEqualToString: @"Icon and Text"])
                return YES;
        }
    }

    for( NSView *subview in [view subviews])
    {
        if( UnsethingViewContainsToolbarDisplayPopup(subview))
            return YES;
    }

    return NO;
}

static NSView *UnsethingToolbarDisplayPopup(NSView *view)
{
    if( [view isKindOfClass: [NSPopUpButton class]])
    {
        NSPopUpButton *popup = (NSPopUpButton *) view;
        for( NSMenuItem *item in [popup itemArray])
        {
            NSString *title = [item title];
            if( [title isEqualToString: @"Icone e testo"] ||
                [title isEqualToString: @"Icona e testo"] ||
                [title isEqualToString: @"Icons and Text"] ||
                [title isEqualToString: @"Icon and Text"])
                return view;
        }
    }

    for( NSView *subview in [view subviews])
    {
        NSView *popup = UnsethingToolbarDisplayPopup(subview);
        if( popup != nil)
            return popup;
    }

    return nil;
}

static void UnsethingHideSystemSmallSizeControl(NSView *view)
{
    if( [view isKindOfClass: [NSButton class]])
    {
        NSString *title = [(NSButton *) view title];
        if( [title isEqualToString: @"Usa dimensioni ridotte"] ||
            [title isEqualToString: @"Use Small Size"] ||
            [title isEqualToString: @"Use small size"])
        {
            [view setHidden: YES];
            return;
        }
    }

    for( NSView *subview in [view subviews])
        UnsethingHideSystemSmallSizeControl(subview);
}

@implementation OsiriXToolbar

- (void)runCustomizationPalette:(id)sender
{
	[super runCustomizationPalette: sender];
    [self performSelector: @selector(unsethingInstallSizeControlInCustomizationPalette) withObject: nil afterDelay: 0.1];
}

- (void)unsethingToolbarSizeChanged:(id)sender
{
    NSInteger level = [sender selectedTag];
    [[NSUserDefaults standardUserDefaults] setInteger: level forKey: UnsethingToolbarSizeDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[self class] applyCurrentSizeToAllToolbars];
    [[NSNotificationCenter defaultCenter] postNotificationName: UnsethingToolbarSizeDidChangeNotification object: self];
}

- (void)unsethingInstallSizeControlInCustomizationPalette
{
    for( NSWindow *window in [NSApp windows])
    {
        NSView *contentView = [window contentView];
        if( contentView == nil)
            continue;
        if( [contentView viewWithTag: UnsethingToolbarSizeControlTag] != nil)
            continue;
        if( UnsethingViewContainsToolbarDisplayPopup(contentView) == NO)
            continue;

        NSRect bounds = [contentView bounds];
        if( bounds.size.height < 120)
            continue;

        UnsethingHideSystemSmallSizeControl(contentView);

        NSView *displayPopup = UnsethingToolbarDisplayPopup(contentView);
        if( displayPopup == nil)
            continue;

        NSTextField *label = [[[NSTextField alloc] initWithFrame: NSZeroRect] autorelease];
        [label setStringValue: @"Grandezza:"];
        [label setBezeled: NO];
        [label setDrawsBackground: NO];
        [label setEditable: NO];
        [label setSelectable: NO];
        [label setFont: [NSFont systemFontOfSize: 13]];
        [label setTranslatesAutoresizingMaskIntoConstraints: NO];
        [label setTag: UnsethingToolbarSizeControlTag];
        [contentView addSubview: label];

        NSPopUpButton *popup = [[[NSPopUpButton alloc] initWithFrame: NSZeroRect pullsDown: NO] autorelease];
        [popup addItemWithTitle: @"Normale"];
        [[popup lastItem] setTag: 0];
        [popup addItemWithTitle: @"Icone +1"];
        [[popup lastItem] setTag: 1];
        [popup addItemWithTitle: @"Icone +2"];
        [[popup lastItem] setTag: 2];
        [popup selectItemWithTag: UnsethingToolbarSizeLevel()];
        [popup setTarget: self];
        [popup setAction: @selector(unsethingToolbarSizeChanged:)];
        [popup setTranslatesAutoresizingMaskIntoConstraints: NO];
        [popup setTag: UnsethingToolbarSizeControlTag + 1];
        [contentView addSubview: popup];

        // Anchor to the actual system control, which may be in a nested view.
        [NSLayoutConstraint activateConstraints: @[
            [[label leadingAnchor] constraintEqualToAnchor: [displayPopup trailingAnchor] constant: 24],
            [[label firstBaselineAnchor] constraintEqualToAnchor: [displayPopup firstBaselineAnchor]],
            [[popup leadingAnchor] constraintEqualToAnchor: [label trailingAnchor] constant: 8],
            [[popup firstBaselineAnchor] constraintEqualToAnchor: [displayPopup firstBaselineAnchor]],
            [[popup widthAnchor] constraintEqualToConstant: 145],
            [[popup heightAnchor] constraintEqualToAnchor: [displayPopup heightAnchor]]
        ]];
    }
}

+ (void)applyCurrentSizeToAllToolbars
{
    for( NSWindow *window in [NSApp windows])
    {
        NSToolbar *toolbar = [window toolbar];
        if( toolbar == nil)
            continue;

        for( NSToolbarItem *item in [toolbar items])
            UnsethingApplyToolbarItemSizing(item);

        [toolbar validateVisibleItems];
        [[window contentView] layoutSubtreeIfNeeded];
    }
}

@end
