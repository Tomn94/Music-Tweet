//
//  ViewController.h
//  Music Tweet
//
//  Created by Tomn on 12/04/2014.
//  Copyright (c) 2014 U969H3GXLU. All rights reserved.
//

@import UIKit;
@import SafariServices;
#import "MusicHandler.h"
#import "TwitterHandler.h"
#import "ConnectivityHandler.h"

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView  *textField;
@property (weak, nonatomic) IBOutlet UISwitch    *artwork;
@property (weak, nonatomic) IBOutlet UIImageView *artworkView;
@property (weak, nonatomic) IBOutlet UIButton    *tweetBtn;

@end
