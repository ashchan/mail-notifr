//
//  MailNotifr-Bridging-Header.h.h
//  Mail Notifr
//
//  Created by James Chen on 2021/06/11.
//  Copyright © 2021 ashchan.com. All rights reserved.
//

#ifndef MailNotifr_Bridging_Header_h_h
#define MailNotifr_Bridging_Header_h_h

#import <MASShortcut/Shortcut.h>
#import "GNPreferences.h"
#import "GNAccount.h"
#import "GNBrowser.h"
#import "GNChecker.h"
#import "GNPreferencesController.h"
#import "GNAccountMenuController.h"

extern NSString *const PrefsToolbarItemAccounts;
extern NSString *const PrefsToolbarItemSettings;
extern NSString *const PrefsToolbarItemInfo;
extern NSString *const GNPreferencesSelection;
extern NSString *const GNShowUnreadCountChangedNotification;
extern NSString *const GNAccountAddedNotification;
extern NSString *const GNAccountRemovedNotification;
extern NSString *const GNAccountChangedNotification;
extern NSString *const GNAccountsReorderedNotification;
extern NSString *const GNCheckingAccountNotification;
extern NSString *const GNAccountMenuUpdateNotification;
extern NSString *const GNDefaultsKeyCheckAllShortcut;

#endif /* MailNotifr_Bridging_Header_h_h */
