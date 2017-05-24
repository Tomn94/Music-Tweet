//
//  ViewController.h
//  Music Tweet
//
//  Created by Tomn on 12/04/2014.
//  Copyright (c) 2014 U969H3GXLU. All rights reserved.
//

@import UIKit;
@import MediaPlayer;
@import AudioToolbox;
@import SafariServices;
#import "TDOAuth.h"
#import "Secrets.h"

#define SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define DEFAULTS_ARTWORK_KEY @"publishArtwork"
#define DEFAULTS_TOKEN_KEY   @"twitterUserToken"
#define DEFAULTS_SECRET_KEY  @"twitterUserSecret"

@interface ViewController : UIViewController {
    
    BOOL previousArtworkState;
    
    NSTimeInterval lastTweetTime;
    
    NSString *twitterUserToken;
    NSString *twitterUserSecret;
    
    NSString *twitterSignInToken;
}

+ (NSString *) generateTweetText;

@property (weak, nonatomic) IBOutlet UITextView  *textField;
@property (weak, nonatomic) IBOutlet UISwitch    *artwork;
@property (weak, nonatomic) IBOutlet UIImageView *artworkView;
@property (weak, nonatomic) IBOutlet UIButton    *tweetBtn;

@end
