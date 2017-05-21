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
    // Do any additional setup after loading the view, typically from a nib.
    
    CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
    gradientLayer.frame = CGRectMake(0, 0, [[self view] frame].size.width, [[self view] frame].size.height);
    [gradientLayer setLocations:@[@0.f, @1.f]];
    [gradientLayer setColors:@[(id)[UIColor colorWithRed:1 green:0.176 blue:0.394 alpha:1].CGColor,
                               (id)[UIColor colorWithRed:1 green:0.361 blue:0.188 alpha:1].CGColor]];
    [[[self view] layer] insertSublayer:gradientLayer atIndex:0];
    
    _textField.layer.cornerRadius = 5;
    _textField.clipsToBounds = true;
    
    [self reset:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (IBAction)share:(id)sender
{
    if (!sender)
        return;
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        NSString *s1 = @"#NP ▶️ ";
        MPMediaItem *currentItem = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
        if (currentItem)
        {
            NSString *s2 = [s1 stringByAppendingString:[currentItem valueForProperty:MPMediaItemPropertyTitle]];
            NSString *s3 = [s2 stringByAppendingString:@" — "];
            NSString *s4 = [s3 stringByAppendingString:[currentItem valueForProperty:MPMediaItemPropertyArtist]];
            NSString *sLast = [s4 stringByAppendingString:@"\n"];
            
            SLComposeViewController *tweetSheet = [SLComposeViewController
                                                   composeViewControllerForServiceType:SLServiceTypeTwitter];
            [tweetSheet setInitialText:sLast];
            MPMediaItemArtwork *illustration = [currentItem valueForProperty:MPMediaItemPropertyArtwork];
            if (illustration && _artwork.isOn)
                [tweetSheet addImage:[illustration imageWithSize:CGSizeMake(320, 320)]];
            
            [self presentViewController:tweetSheet animated:YES completion:nil];
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"Un problème est survenu"
                                      message:@"Aucune musique lue ou en pause !"
                                      delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
        }
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Un problème est survenu"
                                  message:@"Impossible de tweeter !"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

/**
 Displays the current track info on the view controller
 */
- (IBAction)reset:(id)sender {
    
    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
        
        _tweetBtn.userInteractionEnabled = NO;
        NSString *errorMessage = @"Error: Unable to know why song is currently playing";
        
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
                    _tweetBtn.userInteractionEnabled = YES;
                }
                else
                    _textField.text = @"No song is currently playing or paused…";
                
                break;
            }
                
            default:
                break;
        }
    }];
}

@end
