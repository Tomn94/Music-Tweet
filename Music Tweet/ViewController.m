//
//  ViewController.m
//  Music Tweet
//
//  Created by Tomn on 12/04/2014.
//  Copyright (c) 2014 U969H3GXLU. All rights reserved.
//

#import "ViewController.h"

#define DEFAULTS_ARTWORK_KEY @"publishArtwork"
#define DEFAULTS_TOKEN_KEY   @"twitterUserToken"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
    gradientLayer.frame = CGRectMake(0, 0, [[self view] frame].size.width, [[self view] frame].size.height);
    [gradientLayer setLocations:@[@0.f, @1.f]];
    [gradientLayer setColors:@[(id)[UIColor colorWithRed:1 green:0.176 blue:0.394 alpha:1].CGColor,
                               (id)[UIColor colorWithRed:1 green:0.361 blue:0.188 alpha:1].CGColor]];
    [[[self view] layer] insertSublayer:gradientLayer atIndex:0];
    
    _textField.layer.cornerRadius = 5;
    _textField.clipsToBounds = YES;
    
    _artworkView.layer.cornerRadius = 5;
    _artworkView.clipsToBounds = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{ DEFAULTS_ARTWORK_KEY: @YES }];
    
    previousArtworkState = [defaults boolForKey:DEFAULTS_ARTWORK_KEY];
    _artwork.on = previousArtworkState;
    
    twitterUserToken = [defaults objectForKey:DEFAULTS_TOKEN_KEY]; // FIXME: Use Keychain
    
    [self reset:nil];
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
                        
                        UIImage *illustration = [[currentItem valueForProperty:MPMediaItemPropertyArtwork] imageWithSize:CGSizeMake(50, 50)];
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
    [[NSUserDefaults standardUserDefaults] setBool:_artwork.isOn forKey:DEFAULTS_ARTWORK_KEY];
}


#pragma mark - Twitter

- (void) twitter_requestToken
{
    NSURLRequest *request = [TDOAuth URLRequestForPath:@"/oauth/request_token"
                                        POSTParameters:@{ @"oauth_callback" : @"musictweet://sign" }
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
                                                   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {;
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
                 
                 [self twitter_engageConnection:token];
             }
             else
             {
                 UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                message:raw//TODO: @"Unable to get a valid Sign In Token from Twitter"
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

- (void) twitter_engageConnection:(NSString *)token
{
    NSURL *url = [NSURL URLWithString:[@"https://api.twitter.com/oauth/authenticate?oauth_token=" stringByAppendingString:[token stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLHostAllowedCharacterSet]]];
    
    if ([SFSafariViewController class])
    {
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url
                                                             entersReaderIfAvailable:NO];
        [self presentViewController:safari animated:YES completion:nil];
    }
    else
        [[UIApplication sharedApplication] openURL:url];
}

- (void) tweet
{
    
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
