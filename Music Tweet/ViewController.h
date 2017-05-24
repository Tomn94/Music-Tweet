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

@interface ViewController : UIViewController {
    BOOL previousArtworkState;
    
    NSString *twitterUserToken;
    NSString *twitterUserSecret;
    
    NSString *twitterSignInToken;
}

@property (weak, nonatomic) IBOutlet UITextView  *textField;
@property (weak, nonatomic) IBOutlet UISwitch    *artwork;
@property (weak, nonatomic) IBOutlet UIImageView *artworkView;
@property (weak, nonatomic) IBOutlet UIButton    *tweetBtn;

@end
