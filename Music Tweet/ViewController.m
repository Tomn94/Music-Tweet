//
//  ViewController.m
//  Music Tweet
//
//  Created by Tomn on 12/04/2014.
//  Copyright (c) 2014 U969H3GXLU. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@end

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
    
    previousArtworkState = YES;
    
    [self reset:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (IBAction)share:(id)sender
{
    if (!_tweetBtn.isEnabled)
        return;
    
//    MPMediaItemArtwork *illustration = [currentItem valueForProperty:MPMediaItemPropertyArtwork];
//    if (illustration && _artwork.isOn)
//        [tweetSheet addImage:[illustration imageWithSize:CGSizeMake(320, 320)]];
        
}

/**
   Displays the current track info on the view controller
 */
- (IBAction)reset:(id)sender {
    
    _textField.text = @"";
    _tweetBtn.enabled = NO;
    
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
                        
                        MPMediaItemArtwork *illustration = [currentItem valueForProperty:MPMediaItemPropertyArtwork];
                        if (_artwork.isEnabled)
                            previousArtworkState = _artwork.isOn;
                        _artwork.enabled = illustration;
                        if (!illustration) {
                            _artwork.on = NO;
                        } else {
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

@end
