//
//  TwitterHandler.h
//  Music Tweet
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

@import Foundation;
#import "TDOAuth.h"
#import "MusicHandler.h"
#import "ConnectivityHandler.h"
#import "Secrets.h" // Include 2 Strings defining TWITTER_APP_CONSUMER_KEY & TWITTER_APP_CONSUMER_SECRET

/// Key where Artwork Publishing With Tweet setting is stored in User Defaults
#define DEFAULTS_ARTWORK_KEY @"publishArtwork"

/// Key where Twitter API user token is stored in User Defaults
#define DEFAULTS_TOKEN_KEY   @"twitterUserToken"
/// Key where Twitter API user secret is stored in User Defaults
#define DEFAULTS_SECRET_KEY  @"twitterUserSecret"

/**
 Singleton object handling tweeting and connecting to Twitter API beforehand
 */
@interface TwitterHandler : NSObject

/**
 Use this class method to get a singleton instance
 
 @return Singleton object
 */
+ (TwitterHandler *) sharedHandler;

/// Twitter API user token
@property (strong, nonatomic) NSString *twitterUserToken;
/// Twitter API user secret
@property (strong, nonatomic) NSString *twitterUserSecret;

/// Temporary token given by Twitter API before getting final user token/secret
@property (strong, nonatomic) NSString *twitterSignInToken;

/// Timestamp of last tweet request, to avoid double-posting
@property (assign, nonatomic) NSTimeInterval lastTweetTime;

/**
 Quick verification whether the user is connected to Twitter API

 @return YES if we have a user token
 */
- (BOOL) isConnected;

/**
 Begin connection to Twitter API (phase 1)
 */
- (void) requestToken;

/**
 Continue connection to Twitter API after user login in browser (phase 5)

 @param info Dictionary containing "oauth_token" and "oauth_verifier" keys.
             "denied" ends the process.
 */
- (void) receivedCallback:(NSDictionary *)info;

/**
 Tweet using current (artwork) settings
 */
- (void) tweet;

@end
