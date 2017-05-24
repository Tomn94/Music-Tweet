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

@end
