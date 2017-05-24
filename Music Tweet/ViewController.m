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
    
    _artwork.on = [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_ARTWORK_KEY];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(artworkSettingsChanged:)
                                                 name:@"artworkSettingsChanged" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(signInFinished)
                                                 name:@"signInFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionRequested:)
                                                 name:@"connectionRequested" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionEstablished)
                                                 name:@"receivedCallback" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(errorOccurred:)
                                                 name:@"errorOccurred" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tweeted)
                                                 name:@"tweetSuccess" object:nil];
    
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
    
    _tweetBtn.enabled = NO;
    [NSTimer scheduledTimerWithTimeInterval:4 repeats:NO block:^(NSTimer * _Nonnull timer) {
        _tweetBtn.enabled = YES;
    }];
    
    NSString *token = TwitterHandler.sharedHandler.twitterUserToken;
    if (token == nil || [token isEqualToString:@""])
        [TwitterHandler.sharedHandler requestToken];
    else
        [TwitterHandler.sharedHandler tweet];
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
                    
                    [MusicHandler.sharedHandler reset];
                    
                    if (MusicHandler.hasItemPlaying)
                    {
                        _textField.text = [MusicHandler.sharedHandler tweetText];
                        _tweetBtn.enabled = YES;
                        
                        UIImage *illustration = [MusicHandler.sharedHandler getArtworkAt:CGSizeMake(100, 100)];
                        _artworkView.image = illustration;
                        if (illustration == nil)
                            [_artwork setOn:NO];
                        [_artwork setEnabled:illustration != nil && [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_ARTWORK_KEY]];
                        
                        [_textField becomeFirstResponder];
                    }
                    else
                    {
                        _textField.text = @"No song is currently playing or paused…";
                        [_artwork setOn:NO];
                        [_artwork setEnabled:NO];
                    }
                    
                    break;
                }
                    
                default:
                    break;
            }
        });
    }];
    
    [ConnectivityHandler.sharedHandler sendInfo];
}


- (BOOL)        textView:(UITextView *)textView
 shouldChangeTextInRange:(NSRange)range
         replacementText:(NSString *)text
{
    NSString *proposedNewString = [textView.text stringByReplacingCharactersInRange:range
                                                                         withString:text];
    [MusicHandler.sharedHandler setTweetText:proposedNewString];
    
    [ConnectivityHandler.sharedHandler sendInfo];
    
    return YES;
}

- (IBAction) artworkActivationChanged
{
    [[NSUserDefaults standardUserDefaults] setBool:_artwork.isOn
                                            forKey:DEFAULTS_ARTWORK_KEY];
    
    [ConnectivityHandler.sharedHandler artworkActivationChanged:_artwork.isOn];
}

- (void) artworkSettingsChanged:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL forceUpdate = _textField.isFirstResponder;
        if (forceUpdate)
            [_artwork becomeFirstResponder];
        
        [_artwork setOn:[notif.userInfo[@"on"] boolValue]];
        
        if (forceUpdate)
            [_textField becomeFirstResponder];
    });
}

#pragma mark - Sign In with Twitter

- (void) signInFinished
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"You're connected!"
                                                                   message:@"Tweeting your music now…"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Let's go" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [TwitterHandler.sharedHandler tweet];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Changed my mind" style:UIAlertActionStyleDestructive handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) connectionRequested:(NSNotification *)notif
{
    NSURL *url = [NSURL URLWithString:notif.userInfo[@"url"]];
    
    if ([SFSafariViewController class])
    {
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url
                                                             entersReaderIfAvailable:NO];
        [self presentViewController:safari animated:YES completion:nil];
    }
    else
        [[UIApplication sharedApplication] openURL:url
                                           options:@{} completionHandler:nil];
}

- (void) connectionEstablished
{
    if ([SFSafariViewController class])
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) tweeted
{
    AudioServicesPlaySystemSound(1016);
    if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10")) {
        UINotificationFeedbackGenerator *generator = [UINotificationFeedbackGenerator new];
        [generator prepare];
        [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
    }
}

- (void) errorOccurred:(NSNotification *)notif
{
    UINotificationFeedbackGenerator *generator;
    if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10")) {
        generator = [UINotificationFeedbackGenerator new];
        [generator prepare];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:notif.userInfo[@"title"]
                                                                   message:notif.userInfo[@"message"]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:^{
        if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10"))
            [generator notificationOccurred:UINotificationFeedbackTypeError];
    }];
}

@end
