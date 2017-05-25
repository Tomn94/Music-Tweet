//
//  AppDelegate.m
//  Music Tweet
//
//  Created by Tomn on 12/04/2014.
//  Copyright (c) 2014 U969H3GXLU. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

/**
 Called upon app launch
 Refer to Apple Documentation for further information

 @param application This singleton application object
 @param launchOptions May contain data indicating reason why the app has been launched
 @return YES if everything went well
 */
- (BOOL)          application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /* Register default settings */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{ DEFAULTS_ARTWORK_KEY: @YES }];
    
    /* Start communicating with Apple Watch */
    [ConnectivityHandler.sharedHandler startSession];
    
    return YES;
}


#pragma mark - Twitter Sign In process

/**
 Twitter callback after user login.
 Gets the `oauth_verifier` value from Twitter in the OAuth process after Step 2
 c.f. https://dev.twitter.com/web/sign-in/implementing

 @param application This singleton object
 @param url Callback URL
 @param sourceApplication Bundle ID of the app requesting
 @param annotation Property list with provided information
 @return YES if the callback has been completly handled
 */
- (BOOL) application:(UIApplication *)application
             openURL:(NSURL *)url
   sourceApplication:(NSString *)sourceApplication
          annotation:(id)annotation
{
    if ([url.scheme isEqualToString:@"musictweet"])
    {
        /* Get query parameters, separated by `&` */
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        NSArray *pairs = [url.query componentsSeparatedByString:@"&"];
        
        /* Split their keys & values */
        for (NSString *pair in pairs)
        {
            NSArray *elements = [pair componentsSeparatedByString:@"="];
            
            NSString *key = [elements[0] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
            NSString *val = [elements[1] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
            
            [dict setObject:val forKey:key];
        }
        
        /* Dismiss web view */
        [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedCallback"
                                                            object:nil
                                                          userInfo:dict];
        
        /* Continue Sign In process */
        [TwitterHandler.sharedHandler receivedCallback:dict];
        
        return YES;
    }
    
    return NO;
}


#pragma mark - Handoff

/**
 Called when Handing-off Apple Watch activity to iOS

 @param application This running application
 @param userActivity Current task performed to be continued
 @param restorationHandler Specific use
 @return Whether the app handled the activity
 */
- (BOOL)  application:(UIApplication *)application
 continueUserActivity:(NSUserActivity *)userActivity
   restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
{
    /* Everything is already synced, nothing much to do here */
    return YES;
}

@end
