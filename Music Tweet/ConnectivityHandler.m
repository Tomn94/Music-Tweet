//
//  ConnectivityHandler.m
//  Music Tweet
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

#import "ConnectivityHandler.h"

@implementation ConnectivityHandler

+ (ConnectivityHandler *) sharedHandler {
    static ConnectivityHandler *instance = nil;
    if (instance == nil) {
        
        static dispatch_once_t pred;        // Lock
        dispatch_once(&pred, ^{             // This code is called at most once per app
            instance = [[ConnectivityHandler allocWithZone:NULL] init];
        });
        
        if (WCSession.isSupported)
            instance->session = [WCSession defaultSession];
    }
    return instance;
}

- (void) startSession
{
    if (!WCSession.isSupported)
        return;
    
    session.delegate = self;
    [session activateSession];
}

- (BOOL) isSessionValid
{
    if (!WCSession.isSupported)
        return NO;
    
    return session.paired && session.watchAppInstalled && session.reachable;
}

#pragma mark - Required by delegate

- (void)               session:(WCSession *)session
activationDidCompleteWithState:(WCSessionActivationState)activationState
                         error:(NSError *)error
{

}

- (void) sessionDidBecomeInactive:(WCSession *)session
{
    
}

- (void) sessionDidDeactivate:(WCSession *)session
{
    
}

#pragma mark - Reception

- (void)   session:(WCSession *)session
 didReceiveMessage:(NSDictionary<NSString *,id> *)message
{
    if (message[@"action"] != nil)
    {
        if ([message[@"action"] isEqualToString:@"tweet"])
        {
            NSString *token = TwitterHandler.sharedHandler.twitterUserToken;
            if (token == nil || [token isEqualToString:@""])
                [self sendAlert:@{ @"title":   @"First time you tweet?",
                                   @"message": @"Please use the iPhone app to Sign In with Twitter.\nEverything will be in order next time!"}];
            else
                [TwitterHandler.sharedHandler tweet];
        }
    }
    if (message[@"setArworkOn"] != nil)
    {
        BOOL activated = [message[@"setArworkOn"] boolValue];
        
        [[NSUserDefaults standardUserDefaults] setBool:activated
                                                forKey:DEFAULTS_ARTWORK_KEY];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"artworkSettingsChanged"
                                                            object:nil
                                                          userInfo:@{ @"on": @(activated) }];
    }
}

- (void)   session:(WCSession *)session
 didReceiveMessage:(NSDictionary<NSString *,id> *)message
      replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler
{
    if (message[@"get"] != nil)
    {
        if ([message[@"get"] isEqualToString:@"info"])
        {
            replyHandler([self infoToSend]);
        }
    }
}

#pragma mark - Dispatch

- (NSDictionary *) infoToSend
{
    NSMutableDictionary *info = @{ @"text": @"",
                                   @"artworkMode": @([[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_ARTWORK_KEY]) }.mutableCopy;
    
    NSString *text = [MusicHandler.sharedHandler tweetText];
    if (text)
        info[@"text"] = [MusicHandler.sharedHandler tweetText];
    
    UIImage *artwork = [MusicHandler.sharedHandler getArtworkAt:CGSizeMake(100, 100)];
    if (artwork)
        info[@"artworkData"] = UIImageJPEGRepresentation(artwork, 0.8);
    
    return info;
}

- (void) tweeted
{
    [session sendMessage:@{ @"tweeted": @(YES) }
            replyHandler:nil
            errorHandler:nil];
}

- (void) sendInfo
{
    if (!self.isSessionValid)
        return;
    
    [session sendMessage:@{ @"info": [self infoToSend] }
            replyHandler:nil
            errorHandler:nil];
}


- (void) artworkActivationChanged:(BOOL)activated
{
    if (!self.isSessionValid)
        return;
    
    [session sendMessage:@{ @"setArworkOn": @(activated) }
            replyHandler:nil
            errorHandler:nil];
}

- (void) sendAlert:(NSDictionary *)info
{
    if (!self.isSessionValid)
        return;
    
    if (info == nil || info[@"title"] == nil || info[@"message"] == nil)
        return;
    
    [session sendMessage:@{ @"alert": @{ @"title":   info[@"title"],
                                         @"message": info[@"message"] } }
            replyHandler:nil
            errorHandler:nil];
}

@end
