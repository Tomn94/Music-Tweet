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
      replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler
{
    if (message[@"action"] != nil)
    {
        if ([message[@"action"] isEqualToString:@"tweet"])
        {
            NSString *token = TwitterHandler.sharedHandler.twitterUserToken;
            if (token == nil || [token isEqualToString:@""])
                [self sendAlert:@{ @"title":   @"First time you tweet?",
                                   @"message": @"Please tweet using the iPhone app to Sign In with Twitter.\nEverything will be in order for the next time!"}];
            else
                [TwitterHandler.sharedHandler tweet];
        }
    }
    else if (message[@"get"] != nil)
    {
        if ([message[@"get"] isEqualToString:@"info"])
            [self sendInfos];
    }
    else if (message[@"setArworkOn"] != nil)
    {
        [[NSUserDefaults standardUserDefaults] setBool:[message[@"setArworkOn"] boolValue]
                                                forKey:DEFAULTS_ARTWORK_KEY];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"artworkSettingsChanged"
                                                            object:nil
                                                          userInfo:@{ @"on": @YES }];
    }
}

#pragma mark - Dispatch

- (void) sendInfos
{
    
}

- (void) artworkActivationChanged:(BOOL)activated
{
    
}

- (void) sendAlert:(NSDictionary *)infos
{
    
}

@end
