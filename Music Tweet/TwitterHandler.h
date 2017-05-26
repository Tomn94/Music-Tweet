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
#import "Secrets.h"

#define SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define DEFAULTS_ARTWORK_KEY @"publishArtwork"
#define DEFAULTS_TOKEN_KEY   @"twitterUserToken"
#define DEFAULTS_SECRET_KEY  @"twitterUserSecret"

@interface TwitterHandler : NSObject

@property (strong, nonatomic) NSString *twitterUserToken;
@property (strong, nonatomic) NSString *twitterUserSecret;

@property (strong, nonatomic) NSString *twitterSignInToken;

@property (assign, nonatomic) NSTimeInterval lastTweetTime;

+ (TwitterHandler *) sharedHandler;

- (BOOL) isConnected;
- (void) requestToken;
- (void) receivedCallback:(NSDictionary *)info;
- (void) tweet;

@end
