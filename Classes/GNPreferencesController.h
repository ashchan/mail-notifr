//
//  GNPreferencesController.h
//  Gmail Notifr
//
//  Created by James Chen on 1/27/13.
//  Copyright (c) 2013 ashchan.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GNPreferencesController : NSWindowController

@property (strong) NSArray *modules;

+ (GNPreferencesController *)sharedController;

@end
