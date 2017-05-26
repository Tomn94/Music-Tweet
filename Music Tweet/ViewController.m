//
//  ViewController.m
//  Music Tweet
//
//  Created by Tomn on 12/04/2014.
//  Copyright (c) 2014 U969H3GXLU. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    /* Background vertical gradient for the whole view */
    CAGradientLayer *gradientLayer = [CAGradientLayer new];
    gradientLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [gradientLayer setLocations:@[@0.f, @1.f]];
    [gradientLayer setColors:@[(id)[UIColor colorWithRed:1 green:0.176 blue:0.394 alpha:1].CGColor,
                               (id)[UIColor colorWithRed:1 green:0.361 blue:0.188 alpha:1].CGColor]];
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
    
    /* Round corners for text view & artwork preview */
    _textField.layer.cornerRadius = 5;
    _textField.clipsToBounds = YES;
    
    _artworkView.layer.cornerRadius = 5;
    _artworkView.clipsToBounds = YES;
    
    
    /* Load Artwork Switch state from previous settings */
    _artwork.on = [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_ARTWORK_KEY];
    
    
    /* Update Artwork Switch if settings changed (e.g. by Apple Watch) */
    NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
    [notifCenter addObserver:self
                    selector:@selector(artworkSettingsChanged:)
                        name:@"artworkSettingsChanged" object:nil];
    
    /* Receive whether something went wrong, or good actually, and inform the user */
    [notifCenter addObserver:self
                    selector:@selector(tweeted)
                        name:@"tweetSuccess" object:nil];
    [notifCenter addObserver:self
                    selector:@selector(errorOccurred:)
                        name:@"errorOccurred" object:nil];
    
    /* Receive events throughout Sign In with Twitter process */
    [notifCenter addObserver:self
                    selector:@selector(connectionRequested:)
                        name:@"connectionRequested" object:nil];
    [notifCenter addObserver:self
                    selector:@selector(connectionEstablished)
                        name:@"receivedCallback" object:nil];
    [notifCenter addObserver:self
                    selector:@selector(signInFinished)
                        name:@"signInFinished" object:nil];
    
    
    /* Init tweet text & artwork at launch with updated data */
    [self reset];
}

/**
 Display a white status bar to match the colored background

 @return Light status bar style indeed
 */
- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


#pragma mark - Actions

/**
 Called when Tweet button is pressed
 */
- (IBAction) share
{
    if (!_tweetBtn.isEnabled)
        return;
    
    /* Disable button after 1st tap to avoid tweet duplication */
    _tweetBtn.enabled = NO;
    [NSTimer scheduledTimerWithTimeInterval:4 repeats:NO block:^(NSTimer * _Nonnull timer) {
        _tweetBtn.enabled = YES;
    }];
    
    /* Start tweeting process, or login if not already connected to Twitter API */
    if ([TwitterHandler.sharedHandler isConnected])
        [TwitterHandler.sharedHandler tweet];
    else
        [TwitterHandler.sharedHandler requestToken];
}

/**
 Called when Reset button is pressed
 Set text to template using track & artist, update artwork preview, and artwork setting
 */
- (IBAction) reset
{
    /* Disable everything by default, if we have no access */
    _textField.text = @"";
    _tweetBtn.enabled = NO;
    _artworkView.image = nil;
    
    /* Request access to the music library of the user */
    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
        
        NSString *errorMessage = @"Error: Unable to know which song is currently playing";
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
            /* Handle different cases for authorization */
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
                    
                /* Only case that's interesting for the user, if accepted */
                case MPMediaLibraryAuthorizationStatusAuthorized: {
                    
                    /* Remove stored data and regenerate text & artwork */
                    [MusicHandler.sharedHandler reset];
                    
                    /* Check if music player app has currently a song, at least in memory */
                    if (MusicHandler.hasItemPlaying)
                    {
                        _tweetBtn.enabled = YES;
                        
                        UIImage *illustration = [MusicHandler.sharedHandler getArtworkAt:CGSizeMake(100, 100)];
                        _artworkView.image = illustration;
                        
                        /* Disable and deactivate Artwork switch if there's no artwork */
                        if (illustration == nil)
                            [_artwork setOn:NO];
                        [_artwork setEnabled:illustration != nil && [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_ARTWORK_KEY]];
                        
                        /* Update text and show keyboard for any quick editing */
                        _textField.text = [MusicHandler.sharedHandler tweetText];
                        [_textField becomeFirstResponder];
                        
                        /* Share changes to Watch */
                        [ConnectivityHandler.sharedHandler sendInfo];
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
}


#pragma mark - Text View delegate

/**
 Called whenever text changes.
 We'll store the new text and push changes to the Watch

 @param textView Text view being monitored
 @param range Range of the text being edited
 @param text New text at the specified range
 @return YES, since we always allow the text to be changed
 */
- (BOOL)        textView:(UITextView *)textView
 shouldChangeTextInRange:(NSRange)range
         replacementText:(NSString *)text
{
    NSString *proposedNewString = [textView.text stringByReplacingCharactersInRange:range
                                                                         withString:text];
    
    /* Update stored text to prepare the future tweet */
    [MusicHandler.sharedHandler setTweetText:proposedNewString];
    
    /* Send to Watch */
    [ConnectivityHandler.sharedHandler sendInfo];
    
    return YES;
}


#pragma mark - Switch updates

/**
 Called when the user taps the switch
 */
- (IBAction) artworkActivationChanged
{
    /* Save settings for next launch */
    [[NSUserDefaults standardUserDefaults] setBool:_artwork.isOn
                                            forKey:DEFAULTS_ARTWORK_KEY];
    
    /* Tell Watch to update its Switch too */
    [ConnectivityHandler.sharedHandler artworkActivationChanged:_artwork.isOn];
}

/**
 Called when the Watch changed Artwork settings

 @param notif Dictionary with an "on" key and a Bool value associated, describing the new state
 */
- (void) artworkSettingsChanged:(NSNotification *)notif
{
    /* Make sure we're on the UI thread */
    dispatch_async(dispatch_get_main_queue(), ^{
        
        /* Generally the text view is the 1st responder, leading to a latency.
           Bypassing this by temporarily setting Switch 1st responder */
        BOOL forceUpdate = _textField.isFirstResponder;
        if (forceUpdate)
            [_artwork becomeFirstResponder];
        
        [_artwork setOn:[notif.userInfo[@"on"] boolValue]];
        
        if (forceUpdate)
            [_textField becomeFirstResponder];
    });
}


#pragma mark - Twitter callbacks

/**
 TwitterHandler required the user to login on Twitter.com and to approve the app

 @param notif Dictionary containing the "url" key to display
 */
- (void) connectionRequested:(NSNotification *)notif
{
    NSURL *url = [NSURL URLWithString:notif.userInfo[@"url"]];
    
    /* Use in-app browser if available */
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

/**
 Hide in-app browser when Twitter redirects back to the app
 */
- (void) connectionEstablished
{
    if ([SFSafariViewController class])
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

/**
 Called at the end of Sign In with Twitter process
 */
- (void) signInFinished
{
    /* Ask whether the user wants to continue and tweet displayed text & artwork */
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"You're connected!"
                                                                   message:@"Tweeting your music now…"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Let's go"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
        [TwitterHandler.sharedHandler tweet];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Changed my mind"
                                              style:UIAlertActionStyleDestructive handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/**
 Play a sound and a haptic feedback when tweeting succeeded
 */
- (void) tweeted
{
    AudioServicesPlaySystemSound(1016);
    
    if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10")) {
        UINotificationFeedbackGenerator *generator = [UINotificationFeedbackGenerator new];
        [generator prepare];
        [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
    }
}

/**
 Display an alert if Sign In with Twitter or Tweeting went wrong

 @param notif Dictionary containing "title" and "message" keys
 */
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
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:^{
        if (SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(@"10"))
            [generator notificationOccurred:UINotificationFeedbackTypeError];
    }];
}

@end
