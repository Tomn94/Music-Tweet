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

/**
 Update iOS Network Activity Indicator in the status bar

 @param hasActiveRequest YES if a new network activity requests the indicator,
                         FALSE if a network activity finished
 */
+ (void) isLoading:(BOOL)hasActiveRequest
{
    static NSInteger loadingCount = 0;
    
    if (hasActiveRequest)
        ++loadingCount;
    else
        --loadingCount;
    
    /* Display activity indicator if count is not zero */
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:loadingCount > 0];
}

/**
 Notifies the user an operation has succeeded by informing (UI) listeners
 */
- (void) success
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tweetSuccess"
                                                        object:nil];
    
    [ConnectivityHandler.sharedHandler tweeted];
}

/**
 Notifies the user an error has occured by informing (UI) listeners

 @param title Title of the error message
 @param message Text and description of the error
 */
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

- (BOOL) isConnected
{
    NSString *token  = TwitterHandler.sharedHandler.twitterUserToken;
    NSString *secret = TwitterHandler.sharedHandler.twitterUserSecret;
    
    return token  != nil && ![token  isEqualToString:@""] &&
           secret != nil && ![secret isEqualToString:@""];
}

- (void) requestToken
{
    _twitterSignInToken = nil;
    
    /* Configure OAuth request to have temporary token for sign in process */
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
            /* Get returned raw text data */
            NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            NSString *token  = nil;
            NSString *secret = nil;
            NSString *confirmation = nil;
            
            /* Extract confirmation and temporary token and secret */
            NSArray  *parameters = [raw componentsSeparatedByString:@"&"];
            for (NSString *parameter in parameters) {
                NSArray *keyValue = [parameter componentsSeparatedByString:@"="];
                if ([keyValue count] == 2) {
                    if ([keyValue[0]      isEqualToString:@"oauth_token"])
                        token  = keyValue[1];
                    else if ([keyValue[0] isEqualToString:@"oauth_token_secret"])
                        secret = keyValue[1];
                    else if ([keyValue[0] isEqualToString:@"oauth_callback_confirmed"])
                        confirmation = keyValue[1];
                }
            }
            
            /* Check confirmation and that we have data */
            if (token != nil && secret != nil &&
                ([confirmation isEqualToString:@"1"] || [[confirmation lowercaseString] isEqualToString:@"true"])) {
                
                /* Store temporary token and continue to phase 2 */
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
    
    /* Fire request */
    [task resume];
    [TwitterHandler isLoading:YES];
}

/**
 Phase 2 of Twitter Sign In process, after getting temporary tokens.
 We'll ask the user to sign in to their account in a browser
 */
- (void) engageConnection
{
    /* Build URL */
    NSString *url = @"https://api.twitter.com/oauth/authenticate?oauth_token=";
    NSString *token = [_twitterSignInToken stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLHostAllowedCharacterSet];
    url = [url stringByAppendingString:token];
    
    /* Let the UI present the browser */
    [[NSNotificationCenter defaultCenter] postNotificationName:@"connectionRequested"
                                                        object:nil
                                                      userInfo:@{ @"url": url }];
}

- (void) receivedCallback:(NSDictionary *)info
{
    /* Check that we have data, and no error */
    if (info == nil || info[@"denied"] != nil)
        return;
    
    /* Make sure we still have token from after phase 1 */
    if (_twitterSignInToken == nil)
    {
        [self error:@"Error"
            message:@"Please retry, the previously requested token is unknown"];
        return;
    }
    
    /* Check that we have the needed data */
    if (info[@"oauth_token"] != nil && info[@"oauth_verifier"] != nil)
    {
        /* Check we still have the good token */
        if ([info[@"oauth_token"] isEqualToString:_twitterSignInToken])
            
            /* Go to final phase 6 */
            [self requestAccessToken:info];
        else
            [self error:@"Error"
                message:@"Twitter token differs from request"];
    }
    else
        [self error:@"Error"
            message:@"Unable to get back access confirmation values by Twitter"];
}

/**
 Last phase (6), finally get user token and secret from temporary ones

 @param tokens Dictionary containing "oauth_token" and "oauth_verifier" keys
 */
- (void) requestAccessToken:(NSDictionary *)tokens
{
    /* Remove temporary token */
    _twitterSignInToken = nil;
    
    /* Configure OAuth request to have final tokens ending sign in process */
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
            /* Get returned raw text data */
            NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            NSString *token = nil;
            NSString *secret = nil;
            
            /* Extract confirmation and temporary token and secret */
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
            
            /* Check confirmation and that we have data */
            if (token != nil && secret != nil) {
                
                /* Save token and secret for reuse when tweeting */
                _twitterUserToken  = token;
                _twitterUserSecret = secret;
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:_twitterUserToken  forKey:DEFAULTS_TOKEN_KEY];
                [defaults setObject:_twitterUserSecret forKey:DEFAULTS_SECRET_KEY];
                
                /* Let the UI know that's finished */
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
    
    /* Fire request */
    [task resume];
    [TwitterHandler isLoading:YES];
}

#pragma mark - Post on Twitter

- (void) tweet
{
    /* Avoid double-tweeting */
    if ([[NSDate date] timeIntervalSinceReferenceDate] < _lastTweetTime + 4) {
        return;
    }
    _lastTweetTime = [[NSDate date] timeIntervalSinceReferenceDate];
    
    /* Decide if we need to tweet artwork according to settings */
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_ARTWORK_KEY]) {
        [self tweetArtwork];
    } else {
        [self tweetTextWith:nil];
    }
}

/**
 Upload artwork to Twitter before tweeting it
 */
- (void) tweetArtwork
{
    /* Get artwork from music library */
    UIImage *illustration = [MusicHandler.sharedHandler getArtwork];
    if (illustration == nil)
    {
        /* Sometimes Apple Music does not deliver artwork when streaming, so text-only */
        [self tweetTextWith:nil];
        return;
    }
    
    /* Configure OAuth upload request with parameters */
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
            /* Get HTTP response status */
            NSInteger statusCode = 0;
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                statusCode = httpResponse.statusCode;
            }
            
            if (statusCode == 200)
            {
                /* Get ID from uploaded media in response */
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                
                if (json != nil && json[@"media_id"] != nil)
                {
                    /* Proceed tweeting text with uploaded artwork */
                    [self tweetTextWith:@[ json[@"media_id"] ]];
                }
                else
                    [self error:@"Error"
                        message:@"Unable to get ID for uploaded media"];
            }
            else
            {
                /* Extract JSON error description if provided */
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                
                NSString *title = @"Error";
                NSString *message = @"Unable to upload media";
                if (json != nil && json[@"errors"] != nil && [json[@"errors"] count] > 0)
                {
                    title   = [title   stringByAppendingFormat:@" %@",   [json[@"errors"] firstObject][@"code"]];
                    message = [message stringByAppendingFormat:@":\n%@", [json[@"errors"] firstObject][@"message"]];
                }
                
                /* Pass to UI */
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

/**
 Post text to Twitter

 @param mediaIDs Array of media (artworks) ID strings to be published with tweet
                 nil if text-only
 */
- (void) tweetTextWith:(NSArray*)mediaIDs
{
    /* Get current text to tweet */
    NSString *text = [MusicHandler.sharedHandler tweetText];
    if (text == nil)
        return;
    
    /* Add it to request parameters */
    NSMutableDictionary *parameters = @{ @"status": text }.mutableCopy;
    
    /* Set up media IDs parameter if needed */
    if (mediaIDs != nil)
        [parameters setObject:[mediaIDs componentsJoinedByString:@","]
                       forKey:@"media_ids"];
    
    /* Configure OAuth request with parameters */
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
            /* Get HTTP response status */
            NSInteger statusCode = 0;
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                statusCode = httpResponse.statusCode;
            }
            
            if (statusCode == 200)
                [self success];
            else
            {
                /* Extract JSON error description if provided */
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                
                NSString *title = @"Error";
                NSString *message = @"Unable to tweet";
                if (json != nil && json[@"errors"] != nil && [json[@"errors"] count] > 0)
                {
                    title   = [title   stringByAppendingFormat:@" %@",   [json[@"errors"] firstObject][@"code"]];
                    message = [message stringByAppendingFormat:@":\n%@", [json[@"errors"] firstObject][@"message"]];
                }
                
                /* Pass to UI */
                [self error:title
                    message:message];
            }
        }
        else
            [self error:@"Network Error"
                message:@"Unable to tweet"];
    }];
    
    /* Fire request */
    [task resume];
    [TwitterHandler isLoading:YES];
}

@end
