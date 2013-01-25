//
// GNBrowser.rb
// Gmail Notifr
//
// Created by James Chen on 2/19/12.
// Copyright 2012 ashchan.com. All rights reserved.
//

#import "GNBrowser.h"

@implementation GNBrowser

NSString *const DefaultBrowserIdentifier = @"default";

+ (NSArray *)all {
    return @[
        @[@"Default", DefaultBrowserIdentifier],
        @[@"Safari", @"com.apple.Safari"],
        @[@"Google Chrome", @"com.google.Chrome"],
        @[@"Firefox", @"org.mozilla.firefox"]
    ];
}

+ (BOOL)isDefault:(NSString *)identifier {
    return [[self all][0] containsObject:identifier];
}

+ (NSString *)getNameByIdentifier:(NSString *)identifier {
    for (NSArray *item in [self all]) {
        if ([identifier isEqualToString:item[1]]) {
            return item[0];
        }
    }
    return nil;
}

+ (NSString *)getIdentifierByName:(NSString *)name {
    for (NSArray *item in [self all]) {
        if ([name isEqualToString:item[0]]) {
            return item[1];
        }
    }
    return nil;
}

@end