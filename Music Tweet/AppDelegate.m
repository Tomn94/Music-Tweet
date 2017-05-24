//
//  AppDelegate.m
//  Music Tweet
//
//  Created by Tomn on 12/04/2014.
//  Copyright (c) 2014 U969H3GXLU. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

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
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        NSArray *pairs = [url.query componentsSeparatedByString:@"&"];
        
        for (NSString *pair in pairs) {
            NSArray *elements = [pair componentsSeparatedByString:@"="];
            NSString *key = [elements[0] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
            NSString *val = [elements[1] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
            [dict setObject:val forKey:key];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"receivedCallback"
                                                            object:nil
                                                          userInfo:dict];
        
        return YES;
    }
    
    return NO;
}

@end
