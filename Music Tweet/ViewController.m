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
        [self connect];
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
                        _artwork.enabled = illustration;
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

- (void) connect
{
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"]];
    
    NSString *callback = @"musictweet://";
    NSString *nonce = [ViewController generateNonce];
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    NSString *signature = @"";
    
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"OAuth oauth_callback=\"%@\", oauth_consumer_key=\"%@\", oauth_nonce=\"%@\", oauth_signature=\"%@\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"%ld\", oauth_version=\"1.0\"", callback, TWITTER_APP_CONSUMER_KEY, nonce, signature, (long)timestamp]
   forHTTPHeaderField:@"Authorization"];
    
    
    NSURLSessionDataTask *task;
}

- (void) tweet
{
    
}

+ (NSString *) generateNonce
{
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity:32];
    
    for (int i = 0; i < 32; i++)
        [randomString appendFormat: @"%C", [letters characterAtIndex:arc4random_uniform((uint32_t)letters.length)]];
    
    return [randomString copy];
}

+ (NSString *) generateSignature
{
    
    return nil;
}

@end
