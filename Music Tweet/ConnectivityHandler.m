//
//  ConnectivityHandler.m
//  Music Tweet
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

#import "ConnectivityHandler.h"

@implementation ConnectivityHandler

+ (ConnectivityHandler *) sharedHandler
{
    static ConnectivityHandler *instance = nil;
    if (instance == nil)
    {
        static dispatch_once_t pred;        // Lock
        dispatch_once(&pred, ^{             // This code is called at most once per app
            instance = [[ConnectivityHandler allocWithZone:NULL] init];
        });
        
        /* Initialize session on supported devices */
        if (WCSession.isSupported)
            instance->session = [WCSession defaultSession];
    }
    return instance;
}


#pragma mark - Session basics

- (void) startSession
{
    if (!WCSession.isSupported)
        return;
    
    session.delegate = self;
    [session activateSession];
}

/**
 Indicates whether messages can be exchanged between devices

 @return YES if matches hardware, software & network conditions
 */
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

/**
 Handles reception of messages from Watch that don't require a reply

 @param session Session carrying the message
 @param message Content of the message,
                typically a main key describing the intent, and its content
 */
- (void)   session:(WCSession *)session
 didReceiveMessage:(NSDictionary<NSString *,id> *)message
{
    /* Handles a set of actions */
    if (message[@"action"] != nil)
    {
        /* User tapped Tweet on the Watch */
        if ([message[@"action"] isEqualToString:@"tweet"])
        {
            /* If the user has not yet signed in with Twitter,
               Ask them to do so on the iPhne */
            NSString *token = TwitterHandler.sharedHandler.twitterUserToken;
            if (token == nil || [token isEqualToString:@""])
                [self sendAlert:@{ @"title":   @"First time you tweet?",
                                   @"message": @"Please use the iPhone app to Sign In with Twitter.\nEverything will be in order next time!"}];
            
            /* Otherwise begin tweet publication process */
            else
                [TwitterHandler.sharedHandler tweet];
        }
    }
    
    /* If the user changed Artwork settings on the Watch */
    if (message[@"setArworkOn"] != nil)
    {
        BOOL activated = [message[@"setArworkOn"] boolValue];
        
        /* Edit on-device stored settings */
        [[NSUserDefaults standardUserDefaults] setBool:activated
                                                forKey:DEFAULTS_ARTWORK_KEY];
        
        /* Update iOS UI */
        [[NSNotificationCenter defaultCenter] postNotificationName:@"artworkSettingsChanged"
                                                            object:nil
                                                          userInfo:@{ @"on": @(activated) }];
    }
}

/**
 Handles reception of messages from Watch that don't require a reply
 
 @param session Session carrying the message
 @param message Content of the message,
                typically a main key describing the intent, and its content
 @param replyHandler Block called by the counterpart as a reply
 */
- (void)   session:(WCSession *)session
 didReceiveMessage:(NSDictionary<NSString *,id> *)message
      replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler
{
    /* Handles multiple values to be recuperated */
    if (message[@"get"] != nil)
    {
        /* If we need tweet text and artwork */
        if ([message[@"get"] isEqualToString:@"info"])
        {
            /* Send back tweet text, artwork and its settings to the Watch */
            replyHandler([self infoToSend]);
        }
    }
}


#pragma mark - Dispatch

/**
 Compute info dictionary to send so as apps on iOS & watchOS share the same track info

 @return A dictionary with the tweet text,
         whether artwork should be published,
         and eventually an artwork of the current track
 */
- (NSDictionary *) infoToSend
{
    /* Prepare package to send */
    NSMutableDictionary *info = @{ @"text": @"",
                                   @"artworkMode": @([[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_ARTWORK_KEY]) }.mutableCopy;
    
    /* Fill with current tweet text */
    NSString *text = [MusicHandler.sharedHandler tweetText];
    if (text)
        info[@"text"] = [MusicHandler.sharedHandler tweetText];
    
    /* Fill with current artwork */
    UIImage *artwork = [MusicHandler.sharedHandler getArtworkAt:CGSizeMake(100, 100)];
    if (artwork)
        info[@"artworkData"] = UIImageJPEGRepresentation(artwork, 0.8);
    
    return info;
}

- (void) tweeted
{
    if (!self.isSessionValid)
        return;
    
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
    
    /* Filter `info` dictionary */
    if (info == nil || info[@"title"] == nil || info[@"message"] == nil)
        return;
    
    [session sendMessage:@{ @"alert": @{ @"title":   info[@"title"],
                                         @"message": info[@"message"] } }
            replyHandler:nil
            errorHandler:nil];
}

@end
