//
//  GNPreferencesController.m
//  Gmail Notifr
//
//  Created by James Chen on 1/27/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//
//  http://mattballdesign.com/blog/2008/10/01/building-a-preferences-window/

#import "GNPreferencesController.h"
#import "PrefsAccountsViewController.h"
#import "PrefsSettingsViewController.h"
#import "PrefsInfoViewController.h"
#import "GNPreferences.h"

@interface GNPreferencesController () <NSToolbarDelegate, NSWindowDelegate>

@property (strong) id eventMonitor;

@end

@implementation GNPreferencesController {
    id _currentModule;
}

+ (GNPreferencesController *)sharedController {
    static GNPreferencesController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[GNPreferencesController alloc] init];
        controller.modules = @[
            [[PrefsAccountsViewController alloc] init],
            [[PrefsSettingsViewController alloc] init],
            [[PrefsInfoViewController alloc] init]
        ];
    });

    return controller;
}

- (id)init {
    if (self = [super init]) {
        NSWindow *prefsWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 550, 260) styleMask:NSTitledWindowMask | NSClosableWindowMask backing:NSBackingStoreBuffered defer:YES];
        [prefsWindow setShowsToolbarButton:NO];
        prefsWindow.delegate = self;
        self.window = prefsWindow;
        [self setupToolbar];
    }

    return self;
}

- (void)showWindow:(id)sender {
    if (!self.eventMonitor) {
        self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^NSEvent *(NSEvent *event) {
            NSUInteger flags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
            NSString *key = [event charactersIgnoringModifiers];
            if (flags == NSCommandKeyMask && [key isEqualToString:@"w"] && [event.window isEqualTo:self.window]) {
                [self.window performClose:nil];
                return nil;
            }

            return event;
        }];
    }

    [[self window] center];
    [super showWindow:sender];
}

- (BOOL)windowShouldClose:(id)sender {
    if (self.eventMonitor) {
        [NSEvent removeMonitor:self.eventMonitor];
        self.eventMonitor = nil;
    }
    return YES;
}

- (void)setModules:(NSArray *)newModules {
    _modules = newModules;
    NSToolbar *toolbar = [[self window] toolbar];
    if ([[toolbar items] count] > 0) {
        return;
    }

    for (id module in _modules) {
        [toolbar insertItemWithItemIdentifier:[module identifier] atIndex:[[toolbar items] count]];
    }

    NSString *savedIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:GNPreferencesSelection];
    id defaultModule = [self moduleForIdentifier:savedIdentifier];
    if (!defaultModule) {
        defaultModule = _modules[0];
    }
    [self switchToModule:defaultModule];
}

// NSToolbarDelegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    id module = [self moduleForIdentifier:itemIdentifier];
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    if (module) {
        [item setLabel:[module title]];
        [item setImage:[module image]];
        [item setTarget:self];
        [item setAction:@selector(selectModule:)];
    }

    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    NSMutableArray *identifiers = [[NSMutableArray alloc] initWithCapacity:[self.modules count]];
    for (id item in self.modules) {
        [identifiers addObject:[item identifier]];
    }

    return identifiers;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return nil;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarAllowedItemIdentifiers:toolbar];
}

#pragma mark - Private Methods

- (void)setupToolbar {
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"preferencesToolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [[self window] setToolbar:toolbar];
}

- (id)moduleForIdentifier:(NSString *)identifier {
    for (id module in self.modules) {
        if ([[module identifier] isEqualToString:identifier]) {
            return module;
        }
    }

    return nil;
}

- (void)switchToModule:(id)module {
    [[_currentModule view] removeFromSuperview];

    NSView *newView = [module view];
    NSRect windowFrame = [[self window] frameRectForContentRect:[newView frame]];
    windowFrame.origin = self.window.frame.origin;
    windowFrame.origin.y -= windowFrame.size.height - self.window.frame.size.height;
    [[self window] setFrame:windowFrame display:YES animate:YES];

    [[[self window] toolbar] setSelectedItemIdentifier:[module identifier]];
    [[self window] setTitle:[module title]];

    _currentModule = module;

    [[[self window] contentView] addSubview:[_currentModule view]];
    [[self window] setInitialFirstResponder:[_currentModule view]];
 
    [[NSUserDefaults standardUserDefaults] setObject:[module identifier] forKey:GNPreferencesSelection];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)selectModule:(id)sender {
    id module = [self moduleForIdentifier:[sender itemIdentifier]];
    if (module) {
        [self switchToModule:module];
    }
}

@end
