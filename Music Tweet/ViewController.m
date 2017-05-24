//
//  ViewController.m
//  Music Tweet
//
//  Created by Tomn on 12/04/2014.
//  Copyright (c) 2014 U969H3GXLU. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer new];
    gradientLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [gradientLayer setLocations:@[@0.f, @1.f]];
    [gradientLayer setColors:@[(id)[UIColor colorWithRed:1 green:0.176 blue:0.394 alpha:1].CGColor,
                               (id)[UIColor colorWithRed:1 green:0.361 blue:0.188 alpha:1].CGColor]];
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
    
    _textField.layer.cornerRadius = 5;
    _textField.clipsToBounds = YES;
    
    _artworkView.layer.cornerRadius = 5;
    _artworkView.clipsToBounds = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{ DEFAULTS_ARTWORK_KEY: @YES }];
    
    previousArtworkState = [defaults boolForKey:DEFAULTS_ARTWORK_KEY];
    _artwork.on = previousArtworkState;
    
    lastTweetTime = 0;
    
    twitterUserToken  = [defaults objectForKey:DEFAULTS_TOKEN_KEY];  // FIXME: Use Keychain
    twitterUserSecret = [defaults objectForKey:DEFAULTS_SECRET_KEY];
    
    [self reset:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(twitter_receivedCallback:)
                                                 name:@"receivedCallback" object:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

/**
   Share text & eventually artwork on Twitter
 */
- (IBAction)share:(id)sender
{
    if (!_tweetBtn.isEnabled)
        return;
    
    if (twitterUserToken == nil || [twitterUserToken isEqualToString:@""])
        [self twitter_requestToken];
    else
        [self tweet];
}

/**
   Displays the current track info on the view controller
 */
- (IBAction)reset:(id)sender {
    
    _textField.text = @"";
    _tweetBtn.enabled = NO;
    _artworkView.image = nil;
    
    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
        
        NSString *errorMessage = @"Error: Unable to know which song is currently playing";
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
            switch (status)
            {
                case MPMediaLibraryAuthorizationStatusNotDetermined:
                    _textField.text = [errorMessage stringByAppendingString:@" because of an unknown reason"];
                    break;
                    
                case MPMediaLibraryAuthorizationStatusDenied:
                    _textField.text = [errorMessage stringByAppendingString:@" unless you allow the app to access your Media Library"];
                    break;
                    
                case MPMediaLibraryAuthorizationStatusRestricted:
                    _textField.text = [errorMessage stringByAppendingString:@" because of corporate or parental settings disabling access to your Media Library"];
                    break;
                    
                case MPMediaLibraryAuthorizationStatusAuthorized: {
                    
                    MPMediaItem *currentItem = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
                    if (currentItem)
                    {
                        NSString *s1 = @"#NP ▶️ ";
                        NSString *s2 = [s1 stringByAppendingString:[currentItem valueForProperty:MPMediaItemPropertyTitle]];
                        NSString *s3 = [s2 stringByAppendingString:@" — "];
                        NSString *s4 = [s3 stringByAppendingString:[currentItem valueForProperty:MPMediaItemPropertyArtist]];
                        NSString *sLast = [s4 stringByAppendingString:@"\n"];
                        
                        _textField.text = sLast;
                        _tweetBtn.enabled = YES;
                        
                        UIImage *illustration = [[currentItem valueForProperty:MPMediaItemPropertyArtwork] imageWithSize:CGSizeMake(600, 600)];
                        if (_artwork.isEnabled)
                            previousArtworkState = _artwork.isOn;
                        _artwork.enabled = illustration != nil;
                        if (!illustration) {
                            _artwork.on = NO;
                        } else {
                            _artworkView.image = illustration;
                            _artwork.on = previousArtworkState;
                        }
                        
                        [_textField becomeFirstResponder];
                    }
                    else
                        _textField.text = @"No song is currently playing or paused…";
                    
                    break;
                }
                    
                default:
                    break;
            }
        });
    }];
}

- (IBAction) artworkActivationChanged {
    
    [[NSUserDefaults standardUserDefaults] setBool:_artwork.isOn
                                            forKey:DEFAULTS_ARTWORK_KEY];
}


#pragma mark - Twitter

- (void) twitter_requestToken
{
    twitterSignInToken = nil;
    
    NSURLRequest *request = [TDOAuth URLRequestForPath:@"/oauth/request_token"
                                        POSTParameters:@{ @"oauth_callback": @"musictweet://sign" }
                                                  host:@"api.twitter.com"
                                           consumerKey:TWITTER_APP_CONSUMER_KEY
                                        consumerSecret:TWITTER_APP_CONSUMER_SECRET
                                           accessToken:nil
                                           tokenSecret:nil];
    
    /* Create & send network task */
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
         [ViewController isLoading:NO];
         
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
                 
                 twitterSignInToken = token;
                 [self twitter_engageConnection];
             }
             else
             {
                 UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                message:@"Unable to get a valid Sign In Token from Twitter"
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                 [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                 [self presentViewController:alert animated:YES completion:nil];
             }
         }
         else
         {
             UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                            message:@"Unable to get a Sign In Token from Twitter"
                                                                     preferredStyle:UIAlertControllerStyleAlert];
             [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
             [self presentViewController:alert animated:YES completion:nil];
         }
    }];
    [task resume];
    [ViewController isLoading:YES];
}

- (void) twitter_engageConnection
{
    NSURL *url = [NSURL URLWithString:[@"https://api.twitter.com/oauth/authenticate?oauth_token=" stringByAppendingString:[twitterSignInToken stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLHostAllowedCharacterSet]]];
    
    if ([SFSafariViewController class])
    {
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url
                                                             entersReaderIfAvailable:NO];
        [self presentViewController:safari animated:YES completion:nil];
    }
    else
        [[UIApplication sharedApplication] openURL:url];
}

- (void) twitter_receivedCallback:(NSNotification *)notif
{
    if ([SFSafariViewController class])
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    
    if (notif.userInfo[@"denied"] != nil)
        return;
    
    if (twitterSignInToken == nil)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:@"Please retry, the previously requested token is unknown"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    if (notif.userInfo[@"oauth_token"] != nil && notif.userInfo[@"oauth_verifier"] != nil)
    {
        if ([notif.userInfo[@"oauth_token"] isEqualToString:twitterSignInToken])
            [self twitter_requestAccessToken:notif.userInfo];
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:@"Twitter token differs from request"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:@"Unable to back access confirmation by Twitter"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void) twitter_requestAccessToken:(NSDictionary *)tokens
{
    twitterSignInToken = nil;
    
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
        [ViewController isLoading:NO];
                                                       
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
                
                twitterUserToken  = token;
                twitterUserSecret = secret;
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:twitterUserToken  forKey:DEFAULTS_TOKEN_KEY];
                [defaults setObject:twitterUserSecret forKey:DEFAULTS_SECRET_KEY];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"You're connected!"
                                                                               message:@"Tweeting your music now…"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Let's go" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [self tweet];
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:@"Changed my mind" style:UIAlertActionStyleDestructive handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
            else
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                               message:@"Unable to get a valid Access Token from Twitter"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:@"Unable to get an Access Token from Twitter"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
    [task resume];
    [ViewController isLoading:YES];
}

- (void) tweet
{
    if (twitterUserToken == nil || twitterUserSecret == nil)
    {
        [self twitter_requestToken];
        return;
    }
    
    if ([[NSDate date] timeIntervalSinceReferenceDate] < lastTweetTime + 4) {
        return;
    }
    lastTweetTime = [[NSDate date] timeIntervalSinceReferenceDate];
    
    _tweetBtn.enabled = NO;
    [NSTimer scheduledTimerWithTimeInterval:4 repeats:NO block:^(NSTimer * _Nonnull timer) {
        _tweetBtn.enabled = YES;
    }];
    
    if (_artwork.isOn && _artwork.isEnabled && _artworkView.image != nil) {
        [self tweetArtwork];
    } else {
        [self tweetTextWith:nil];
    }
}

- (void) tweetArtwork
{
    UIImage *illustration = _artworkView.image;
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
                                           accessToken:twitterUserToken
                                           tokenSecret:twitterUserSecret
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
        [ViewController isLoading:NO];
        
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
                {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                   message:@"Unable to get ID for uploaded media"
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                }
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
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Error"
                                                                           message:@"Unable to upload media"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
    [task resume];
    [ViewController isLoading:YES];
}

- (void) tweetTextWith:(NSArray*)mediaIDs
{
    NSMutableDictionary *parameters = @{ @"status": _textField.text }.mutableCopy;
    
    if (mediaIDs != nil)
        [parameters setObject:[mediaIDs componentsJoinedByString:@","]
                       forKey:@"media_ids"];
    
    NSURLRequest *request = [TDOAuth URLRequestForPath:@"/1.1/statuses/update.json"
                                        POSTParameters:parameters
                                                  host:@"api.twitter.com"
                                           consumerKey:TWITTER_APP_CONSUMER_KEY
                                        consumerSecret:TWITTER_APP_CONSUMER_SECRET
                                           accessToken:twitterUserToken
                                           tokenSecret:twitterUserSecret];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        [ViewController isLoading:NO];
        UINotificationFeedbackGenerator *generator;
        if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10")) {
            generator = [UINotificationFeedbackGenerator new];
            [generator prepare];
            [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
        }
        
        if (error == nil && data != nil)
        {
            NSInteger statusCode = 0;
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                statusCode = httpResponse.statusCode;
            }
            
            if (statusCode == 200)
            {
                AudioServicesPlaySystemSound(1016);
                if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10")) {
                    [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
                }
            }
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
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                
                if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10")) {
                    [generator notificationOccurred:UINotificationFeedbackTypeError];
                }
            }
        }
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Error"
                                                                           message:@"Unable to tweet"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            
            if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10")) {
                [generator notificationOccurred:UINotificationFeedbackTypeError];
            }
        }
    }];
    [task resume];
    [ViewController isLoading:YES];
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

@end
