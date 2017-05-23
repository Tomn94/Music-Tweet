//
//  ViewController.h
//  Music Tweet
//
//  Created by Tomn on 12/04/2014.
//  Copyright (c) 2014 U969H3GXLU. All rights reserved.
//

@import UIKit;
@import MediaPlayer;
@import SafariServices;
#import "TDOAuth.h"
#import "Secrets.h"

@interface ViewController : UIViewController {
    BOOL previousArtworkState;
    
    NSString *twitterUserToken;
    NSString *twitterUserSecret;
}

@property (weak, nonatomic) IBOutlet UITextView  *textField;
@property (weak, nonatomic) IBOutlet UISwitch    *artwork;
@property (weak, nonatomic) IBOutlet UIImageView *artworkView;
@property (weak, nonatomic) IBOutlet UIButton    *tweetBtn;

@end
