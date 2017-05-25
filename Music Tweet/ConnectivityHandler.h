//
//  ConnectivityHandler.h
//  Music Tweet
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

@import UIKit;
@import WatchConnectivity;
#import "ViewController.h"
#import "MusicHandler.h"

/**
 Singleton object handling emission & reception of messages with Apple Watch app counterpart
 */
@interface ConnectivityHandler : NSObject <WCSessionDelegate>
{
    /// Enables communication between devices
    WCSession *session;
}

/**
 Only usage of ConnectivityHandler is through its singleton, to share a unique `session`.
 Use this class method to get a singleton instance.

 @return Singleton object
 */
+ (ConnectivityHandler *) sharedHandler;


#pragma mark - Session basics

/**
 Starts connectivity with Apple Watch, if supported (currently only iPhone)
 */
- (void) startSession;


#pragma mark - Dispatch

/**
 Notify the Apple Watch the tweet has been sent,
 mainly for sound/haptic feedback purpose.
 
 Sent message structure:
     { "tweeted": true }
 */
- (void) tweeted;

/**
 Send latest tweet text and song artwork info to Apple Watch
 
 Sent message structure:
    { "info":
        { "text": String, "artworkMode": Bool, "artworkData": JPEGdata } }
    `artworkData` key may not be present
 */
- (void) sendInfo;

/**
 Send current settings about tweeting the artwork

 @param activated Whether the tweet should include the artwork
 
 Sent message structure:
      { "setArworkOn": Bool }
 */
- (void) artworkActivationChanged:(BOOL)activated;

/**
 Send feedback about an error that has occurred,
 the Apple Watch should display this as an alert.

 @param info Dictionary containing the `title` and the `message` of the alert
 
 Sent message structure:
    { "alert":
        { "title": String, "message": String } }
 */
- (void) sendAlert:(NSDictionary *)info;

@end
