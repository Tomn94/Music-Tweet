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

@interface ConnectivityHandler : NSObject <WCSessionDelegate>
{
    WCSession *session;
}

+ (ConnectivityHandler *) sharedHandler;
- (void) startSession;

- (void) tweeted;
- (void) sendInfo;
- (void) artworkActivationChanged:(BOOL)activated;
- (void) sendAlert:(NSDictionary *)info;

@end
