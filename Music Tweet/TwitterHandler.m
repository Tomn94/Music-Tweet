//
//  TwitterHandler.m
//  Music Tweet
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

#import "TwitterHandler.h"

@implementation TwitterHandler

+ (TwitterHandler *) sharedHandler {
    static TwitterHandler *instance = nil;
    if (instance == nil) {
        
        static dispatch_once_t pred;        // Lock
        dispatch_once(&pred, ^{             // This code is called at most once per app
            instance = [[TwitterHandler allocWithZone:NULL] init];
        });
        
        instance->_lastTweetTime = 0;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];  // FIXME: Use Keychain
        instance->_twitterUserToken  = [defaults objectForKey:DEFAULTS_TOKEN_KEY];
        instance->_twitterUserSecret = [defaults objectForKey:DEFAULTS_SECRET_KEY];
    }
    return instance;
}

+ (void) isLoading:(BOOL)hasActiveRequest
{
    static NSInteger loadingCount = 0;
    
    if (hasActiveRequest)
        ++loadingCount;
    else
        --loadingCount;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:loadingCount > 0];
}

- (void) success
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tweetSuccess"
                                                        object:nil];
    
    [ConnectivityHandler.sharedHandler tweeted];
}

- (void) error:(NSString *)title
       message:(NSString *)message
{
    NSDictionary *content = @{ @"title": title,
                               @"message": message };
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"errorOccurred"
                                                        object:nil
                                                      userInfo:content];
    
    [ConnectivityHandler.sharedHandler sendAlert:content];
}

#pragma mark - Sign In with Twitter

- (void) requestToken
{
    _twitterSignInToken = nil;
    
    NSURLRequest *request = [TDOAuth URLRequestForPath:@"/oauth/request_token"
                                        POSTParameters:@{ @"oauth_callback": @"musictweet://sign" }
                                                  host:@"api.twitter.com"
                                           consumerKey:TWITTER_APP_CONSUMER_KEY
                                        consumerSecret:TWITTER_APP_CONSUMER_SECRET
                                           accessToken:nil
                                           tokenSecret:nil];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        [TwitterHandler isLoading:NO];
        
        if (error == nil && data != nil)
        {
            NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *token = nil;
            NSString *secret = nil;
            NSString *confirmation = nil;
            NSArray *parameters = [raw componentsSeparatedByString:@"&"];
            for (NSString *parameter in parameters) {
                NSArray *keyValue = [parameter componentsSeparatedByString:@"="];
                if ([keyValue count] == 2) {
                    if ([keyValue[0] isEqualToString:@"oauth_token"])
                        token = keyValue[1];
                    else if ([keyValue[0] isEqualToString:@"oauth_token_secret"])
                        secret = keyValue[1];
                    else if ([keyValue[0] isEqualToString:@"oauth_callback_confirmed"])
                        confirmation = keyValue[1];
                }
            }
            if (token != nil && secret != nil &&
                ([confirmation isEqualToString:@"1"] || [[confirmation lowercaseString] isEqualToString:@"true"])) {
                
                _twitterSignInToken = token;
                [self engageConnection];
            }
            else
                [self error:@"Error"
                    message:@"Unable to get a valid Sign In Token from Twitter"];
        }
        else
            [self error:@"Network Error"
                message:@"Unable to get a Sign In Token from Twitter"];
    }];
    [task resume];
    [TwitterHandler isLoading:YES];
}

- (void) engageConnection
{
    NSString *url = @"https://api.twitter.com/oauth/authenticate?oauth_token=";
    NSString *token = [_twitterSignInToken stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLHostAllowedCharacterSet];
    url = [url stringByAppendingString:token];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"connectionRequested"
                                                        object:nil
                                                      userInfo:@{ @"url": url }];
}

- (void) receivedCallback:(NSDictionary *)info
{   
    if (info == nil || info[@"denied"] != nil)
        return;
    
    if (_twitterSignInToken == nil)
    {
        [self error:@"Error"
            message:@"Please retry, the previously requested token is unknown"];
        return;
    }
    
    if (info[@"oauth_token"] != nil && info[@"oauth_verifier"] != nil)
    {
        if ([info[@"oauth_token"] isEqualToString:_twitterSignInToken])
            [self requestAccessToken:info];
        else
            [self error:@"Error"
                message:@"Twitter token differs from request"];
    }
    else
        [self error:@"Error"
            message:@"Unable to get back access confirmation values by Twitter"];
}

- (void) requestAccessToken:(NSDictionary *)tokens
{
    _twitterSignInToken = nil;
    
    NSURLRequest *request = [TDOAuth URLRequestForPath:@"/oauth/access_token"
                                        POSTParameters:@{ @"oauth_verifier": tokens[@"oauth_verifier"] }
                                                  host:@"api.twitter.com"
                                           consumerKey:TWITTER_APP_CONSUMER_KEY
                                        consumerSecret:TWITTER_APP_CONSUMER_SECRET
                                           accessToken:tokens[@"oauth_token"]
                                           tokenSecret:nil];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        [TwitterHandler isLoading:NO];
        
        if (error == nil && data != nil)
        {
            NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *token = nil;
            NSString *secret = nil;
            NSArray *parameters = [raw componentsSeparatedByString:@"&"];
            for (NSString *parameter in parameters) {
                NSArray *keyValue = [parameter componentsSeparatedByString:@"="];
                if ([keyValue count] == 2) {
                    if ([keyValue[0] isEqualToString:@"oauth_token"])
                        token = keyValue[1];
                    else if ([keyValue[0] isEqualToString:@"oauth_token_secret"])
                        secret = keyValue[1];
                }
            }
            if (token != nil && secret != nil) {
                
                _twitterUserToken  = token;
                _twitterUserSecret = secret;
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:_twitterUserToken  forKey:DEFAULTS_TOKEN_KEY];
                [defaults setObject:_twitterUserSecret forKey:DEFAULTS_SECRET_KEY];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"signInFinished"
                                                                    object:nil];
            }
            else
                [self error:@"Error"
                    message:@"Unable to get a valid Access Token from Twitter"];
        }
        else
            [self error:@"Network Error"
                message:@"Unable to get an Access Token from Twitter"];
    }];
    [task resume];
    [TwitterHandler isLoading:YES];
}

#pragma mark - Post on Twitter

- (void) tweet
{
    if ([[NSDate date] timeIntervalSinceReferenceDate] < _lastTweetTime + 4) {
        return;
    }
    _lastTweetTime = [[NSDate date] timeIntervalSinceReferenceDate];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_ARTWORK_KEY]) {
        [self tweetArtwork];
    } else {
        [self tweetTextWith:nil];
    }
}

- (void) tweetArtwork
{
    UIImage *illustration = [MusicHandler.sharedHandler getArtwork];
    if (illustration == nil)
    {
        [self tweetTextWith:nil];
        return;
    }
    
    NSURLRequest *request = [TDOAuth URLRequestForPath:@"/1.1/media/upload.json"
                                            parameters:nil
                                                  host:@"upload.twitter.com"
                                           consumerKey:TWITTER_APP_CONSUMER_KEY
                                        consumerSecret:TWITTER_APP_CONSUMER_SECRET
                                           accessToken:_twitterUserToken
                                           tokenSecret:_twitterUserSecret
                                                scheme:@"https"
                                         requestMethod:@"POST"
                                          dataEncoding:TDOAuthContentTypeMultipartForm
                                          headerValues:nil
                                       signatureMethod:TDOAuthSignatureMethodHmacSha1
                                           rawPOSTData:@[ @{ @"name": @"media",
                                                             @"file": @"artwork",
                                                             @"type": @"image/jpeg",
                                                             @"data": UIImageJPEGRepresentation(illustration, 0.8) }]];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        [TwitterHandler isLoading:NO];
        
        if (error == nil && data != nil)
        {
            NSInteger statusCode = 0;
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                statusCode = httpResponse.statusCode;
            }
            
            if (statusCode == 200)
            {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                
                if (json != nil && json[@"media_id"] != nil)
                    [self tweetTextWith:@[ json[@"media_id"] ]];
                else
                    [self error:@"Error"
                        message:@"Unable to get ID for uploaded media"];
            }
            else
            {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                
                NSString *title = @"Error";
                NSString *message = @"Unable to upload media";
                if (json != nil && json[@"errors"] != nil && [json[@"errors"] count] > 0)
                {
                    title   = [title   stringByAppendingFormat:@" %@",   [json[@"errors"] firstObject][@"code"]];
                    message = [message stringByAppendingFormat:@":\n%@", [json[@"errors"] firstObject][@"message"]];
                }
                
                [self error:title
                    message:message];
            }
        }
        else
            [self error:@"Network Error"
                message:@"Unable to upload media"];
    }];
    [task resume];
    [TwitterHandler isLoading:YES];
}

- (void) tweetTextWith:(NSArray*)mediaIDs
{
    NSString *text = [MusicHandler.sharedHandler tweetText];
    if (text == nil)
        return;
    
    NSMutableDictionary *parameters = @{ @"status": text }.mutableCopy;
    
    if (mediaIDs != nil)
        [parameters setObject:[mediaIDs componentsJoinedByString:@","]
                       forKey:@"media_ids"];
    
    NSURLRequest *request = [TDOAuth URLRequestForPath:@"/1.1/statuses/update.json"
                                        POSTParameters:parameters
                                                  host:@"api.twitter.com"
                                           consumerKey:TWITTER_APP_CONSUMER_KEY
                                        consumerSecret:TWITTER_APP_CONSUMER_SECRET
                                           accessToken:_twitterUserToken
                                           tokenSecret:_twitterUserSecret];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        [TwitterHandler isLoading:NO];
        
        if (error == nil && data != nil)
        {
            NSInteger statusCode = 0;
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                statusCode = httpResponse.statusCode;
            }
            
            if (statusCode == 200)
                [self success];
            else
            {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                
                NSString *title = @"Error";
                NSString *message = @"Unable to tweet";
                if (json != nil && json[@"errors"] != nil && [json[@"errors"] count] > 0)
                {
                    title   = [title   stringByAppendingFormat:@" %@",   [json[@"errors"] firstObject][@"code"]];
                    message = [message stringByAppendingFormat:@":\n%@", [json[@"errors"] firstObject][@"message"]];
                }
                
                [self error:title
                    message:message];
            }
        }
        else
            [self error:@"Network Error"
                message:@"Unable to tweet"];
    }];
    [task resume];
    [TwitterHandler isLoading:YES];
}

@end
