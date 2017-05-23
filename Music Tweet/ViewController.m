//
//  ViewController.m
//  Music Tweet
//
//  Created by Tomn on 12/04/2014.
//  Copyright (c) 2014 U969H3GXLU. All rights reserved.
//

#import "ViewController.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>

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

- (void) connect
{
}

- (void) sendRequest:(NSString *)url
              method:(NSString *)method
                 get:(NSDictionary *)getParameters
                post:(NSDictionary *)postParameters
             options:(NSUInteger)options
{
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession              *defaultSession      = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                                   delegate:nil
                                                                              delegateQueue:[NSOperationQueue mainQueue]];
    
    NSString *nonce = [ViewController generateNonce];
    NSString *signMethod = @"HMAC-SHA1";
    NSString *callback = @"musictweet://";
    NSString *timestamp = [NSString stringWithFormat:@"%.f", [[NSDate date] timeIntervalSince1970]];
    NSString *version = @"1.0";
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:getParameters];
    [parameters addEntriesFromDictionary:postParameters];
    [parameters addEntriesFromDictionary:
     @{ @"oauth_consumer_key": [TWITTER_APP_CONSUMER_KEY stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
        @"oauth_nonce": [nonce stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
        @"oauth_signature_method": [signMethod stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
        @"oauth_timestamp": [timestamp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
        @"oauth_version": [version stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] }];
    if (options == 1)
        [parameters setObject:[callback stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                       forKey:@"oauth_callback"];
    else
        [parameters setObject:[twitterUserToken stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                       forKey:@"oauth_token"];
    
    NSMutableArray *parametersArray = [NSMutableArray array];
    for (NSString *parameterKey in parameters) {
        [parametersArray addObject:[parameterKey stringByAppendingFormat:@"=\"%@\"", parameters[parameterKey]]];
    }
    parametersArray = [[parametersArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    
    NSString *parametersString = [parametersArray componentsJoinedByString:@"&"];
    
    NSString *base = [method stringByAppendingFormat:@"&%@&%@",
                      [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                      [parametersString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *signature = [ViewController hmacSHA1for:base
                                           withSecret:[[TWITTER_APP_CONSUMER_SECRET stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByAppendingFormat:@"&%@",
                                                       [twitterUserSecret stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    [parameters setObject:signature forKey:@"oauth_signature"];
    [parametersArray addObject:[NSString stringWithFormat:@"oauth_signature=\"%@\"", signature]];
    
    
    NSString *URLWithGET = url;
    if (getParameters != nil && [getParameters count] > 0)
    {
        NSMutableString *GETInURL = [NSMutableString string];
        int i = 0;
        for (NSString *getKey in getParameters)
        {
            if (i != 0)
                [GETInURL appendString:@"&"];
            [GETInURL appendFormat:@"%@=%@", getKey, getParameters[getKey]];
            i++;
        }
        URLWithGET = [@"https://api.twitter.com/oauth/request_token?" stringByAppendingString:GETInURL];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:URLWithGET]];
    [request setHTTPMethod:method];
    [request setValue:[NSString stringWithFormat:@"OAuth %@", [parametersArray componentsJoinedByString:@", "]]
                       forHTTPHeaderField:@"Authorization"];
    
    if (postParameters != nil && [postParameters count] > 0)
    {
        NSMutableString *postBody = [NSMutableString string];
        int i = 0;
        for (NSString *postKey in postParameters) {
            if (i != 0)
                [postBody appendString:@"&"];
            [postBody appendFormat:@"%@=%@", postKey, postParameters[postKey]];
            i++;
        }
        [request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
//    NSURLSessionDataTask *task;
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

+ (NSString *) hmacSHA1for:(NSString *)data
                withSecret:(NSString *)key
{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                          length:sizeof(cHMAC)];
    
    NSString *hash = [HMAC base64EncodedStringWithOptions:0];
    
    return hash;
}

@end
