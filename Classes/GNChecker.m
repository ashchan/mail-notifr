//
// GNChecker.rb
// Gmail Notifr
//
// Created by James Chen on 8/27/09.
// Copyright (c) 2009 ashchan.com. All rights reserved.
//

#import "GNChecker.h"
#import "GNAccount.h"
#import <Growl/GrowlApplicationBridge.h>
#import "GNSound.h"

NSString *const GNCheckingAccountNotification   = @"GNCheckingAccountNotification";
NSString *const GNAccountMenuUpdateNotification = @"GNAccountMenuUpdateNotification";

@interface GNChecker () <NSURLConnectionDataDelegate>

@property (strong) GNAccount *account;

@end

@implementation GNChecker {
    NSTimer         *_timer;
    NSMutableArray  *_messages;
    NSUInteger      _messageCount;
    NSTimeInterval  _checkedAt;
    NSMutableData   *_downloadedData;
    NSInteger       _statusCode;
    BOOL            _hasUserError;
    BOOL            _hasConnectionError;
    NSTimeInterval  _newestDate;
}

- (id)initWithAccount:(GNAccount *)anAccount {
    if (self = [super init]) {
        self.account = anAccount;
        _messages = [[NSMutableArray alloc] init];
    }

    return self;
}

- (BOOL)isForAccount:(GNAccount *)anAccount {
    return [self isForGuid:anAccount.guid];
}

- (BOOL)isForGuid:(NSString *)guid {
    return [self.account.guid isEqualToString:guid];
}

- (NSArray *)messages {
    return _messages;
}

- (NSUInteger)messageCount {
    return [self isAccountEnabled] ? _messageCount : 0;
}

- (void)reset {
    [self cleanup];
    [[NSNotificationCenter defaultCenter] postNotificationName:GNCheckingAccountNotification object:self userInfo:@{@"guid": self.account.guid}];

    if ([self isAccountEnabled]) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:self.account.interval * 60 target:self selector:@selector(reset) userInfo:nil repeats:YES];
        [self check];
    } else {
        [self notifyMenuUpdate];
    }
}

- (void)cleanupAndQuit {
    [self cleanup];
    _timer = nil;
}

- (BOOL)hasUserError {
    return _hasUserError;
}

- (BOOL)hasConnectionError {
    return _hasConnectionError;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self processXMLWithData:_downloadedData statusCode:0];
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
    NSString *authenticationMethod = [protectionSpace authenticationMethod];
    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        [[challenge sender] useCredential:[NSURLCredential credentialForTrust:[protectionSpace serverTrust]]
               forAuthenticationChallenge:challenge];
    } else if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault]) {
        if ([challenge previousFailureCount] > 0) {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        } else {
            NSURLCredential *credential = [NSURLCredential credentialWithUser:self.account.username
                                                                     password:self.account.password
                                                                  persistence:NSURLCredentialPersistenceNone];
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        }
    } else {
        [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}
    
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _statusCode = [(NSHTTPURLResponse *)response statusCode];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_downloadedData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [self processXMLWithData:_downloadedData statusCode:_statusCode];
    });
}

#pragma mark - Private Methods

- (void)check {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://mail.google.com/mail/feed/atom"]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30];
    [request setHTTPShouldHandleCookies:NO];
    _downloadedData = [[NSMutableData alloc] init];
    _messageCount   = 0;
    _hasUserError   = NO;
    _hasConnectionError = NO;
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)cleanup {
    [_timer invalidate];
}

- (BOOL)isAccountEnabled {
    return self.account && self.account.enabled;
}

- (void)notifyMenuUpdate {
    [[NSNotificationCenter defaultCenter] postNotificationName:GNAccountMenuUpdateNotification object:nil userInfo:@{@"guid": self.account.guid, @"checkedAt": [self checkedAt]}];
}

- (NSString *)checkedAt {
    if (_checkedAt > 0) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        return [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_checkedAt]];
    } else {
        return @"NA";
    }
}

- (NSString *)normalizeMessageLink:(NSString *)link {
    NSString *result = [link copy];
    if ([self.account.username rangeOfString:@"@"].length > 0) {
        NSString *domain = [self.account.username componentsSeparatedByString:@"@"][1];
        if (![domain isEqualToString:@"gmail.com"] && ![domain isEqualToString:@"googlemail.com"]) {
            result = [link stringByReplacingOccurrencesOfString:@"/mail?" withString:[NSString stringWithFormat:@"/a/%@/?", domain]];
        }
    }

    return result;
}

- (NSDate *)dateFromString:(NSString *)string {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    });

    return [dateFormatter dateFromString:string];
}

- (void)notifyGrowlWithTitle:(NSString *)title description:(NSString *)description {
    [GrowlApplicationBridge notifyWithTitle:title
                                description:description
                           notificationName:@"new_messages"
                                   iconData:nil
                                   priority:0
                                   isSticky:NO
                               clickContext:title
                                 identifier:title];
}

- (void)notifyNotificationCenterWithTitle:(NSString *)title description:(NSString *)description {
    // NC support is through Growl SDK 2
    return;

    if (NSClassFromString(@"NSUserNotificationCenter")) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        [notification setValue:title forKey:@"title"];
        [notification setValue:description forKey:@"subtitle"];
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

- (void)processXMLWithData:(NSData *)data statusCode:(NSInteger)statusCode {
    [_messages removeAllObjects];

    if (statusCode == 200) {
        NSXMLDocument *feed = [[NSXMLDocument alloc] initWithData:data options:0 error:nil];
        _messageCount = [[[feed nodesForXPath:@"/feed/fullcount" error:nil][0] stringValue] integerValue];
        
        // return first 10 messages
        NSArray *messageNodes = [feed nodesForXPath:@"/feed/entry" error:nil];
        for (NSUInteger i = 0; i < MIN(_messageCount, 10); i++) {
            NSXMLElement *messageElement = messageNodes[i];
            // gmail atom gives time string like 2009-08-29T24:56:52Z
            // note 24 causes ArgumentError: argument out of range
            // make it 23 and guess it won't matter too much
            NSString *issued = [[messageElement elementsForName:@"issued"][0] stringValue];
            issued = [issued stringByReplacingOccurrencesOfString:@"T24" withString:@"T23"];

            NSDictionary *messageObject = @{
                @"link":    [self normalizeMessageLink:[[[messageElement elementsForName:@"link"][0] attributeForName:@"href"] stringValue]],
                @"author":  [[[messageElement elementsForName:@"author"][0] elementsForName:@"name"][0] stringValue],
                @"subject": [[messageElement elementsForName:@"title"][0] stringValue],
                @"id":      [[messageElement elementsForName:@"id"][0] stringValue],
                @"date":    [self dateFromString:issued],
                @"summary": [[messageElement elementsForName:@"summary"][0] stringValue]
            };
            [_messages addObject:messageObject];
        }
    } else if (statusCode == 401) {
        _hasUserError = YES;
    } else {
        _hasConnectionError = YES;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self processResult];
    });
}

- (void)processResult {
    _checkedAt = [[NSDate date] timeIntervalSince1970];

    BOOL shouldNotify = [self isAccountEnabled] && [_messages count] > 0;

    if (shouldNotify) {
        NSMutableArray *dates = [[NSMutableArray alloc] initWithCapacity:[_messages count]];
        for (NSDictionary *message in _messages) {
            [dates addObject:@([[message objectForKey:@"date"] timeIntervalSince1970])];
        }
        NSTimeInterval newestDate = [[dates valueForKeyPath:@"@max.doubleValue"] doubleValue];

        if (_newestDate > 0) {
            shouldNotify = newestDate > _newestDate;
        }
        _newestDate = newestDate;
    }

    [self notifyMenuUpdate];

    if (shouldNotify) {
        NSMutableArray *info = [[NSMutableArray alloc] init];
        for (NSDictionary *message in _messages) {
            NSString *messageInfo = [[message objectForKey:@"subject"] stringByAppendingFormat:@"\nFrom: %@", [message objectForKey:@"author"]];
            [info addObject:messageInfo];
        }

        NSString *notification = [info componentsJoinedByString:@"\n------------------------------\n\n"];
        if (_messageCount > [_messages count]) {
            notification = [notification stringByAppendingString:@"\n\n..."];
        }

        NSString *unreadCountFormat;
        if ([[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode] isEqualToString:@"ru"]) {
            NSUInteger count = _messageCount % 100;
            if ((count % 10 > 4) || (count % 10 == 0) || ((count > 10) && (count < 15))) {
                unreadCountFormat = NSLocalizedString(@"Unread Messages", nil);
            } else if (count % 10 == 1) {
                unreadCountFormat = NSLocalizedString(@"Unread Message", nil);
            } else {
                unreadCountFormat = NSLocalizedString(@"Unread Messages 2", nil);
            }
        } else {
            unreadCountFormat = _messageCount == 1 ? NSLocalizedString(@"Unread Message", nil) : NSLocalizedString(@"Unread Messages", nil);
        }
        NSString *unreadCount = [NSString stringWithFormat:unreadCountFormat, _messageCount];
                
        if (self.account.growl) {
            [self notifyGrowlWithTitle:self.account.username description:[@[unreadCount, notification] componentsJoinedByString:@"\n\n"]];
        }

        [self notifyNotificationCenterWithTitle:self.account.username description:unreadCount];
    }

    if (shouldNotify && ![self.account.sound isEqualToString:SoundNone]) {
        [[NSSound soundNamed:self.account.sound] play];
    }
}

@end
