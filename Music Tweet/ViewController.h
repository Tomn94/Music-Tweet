//
//  ViewController.h
//  Music Tweet
//
//  Created by Tomn on 12/04/2014.
//  Copyright (c) 2014 U969H3GXLU. All rights reserved.
//

@import UIKit;
@import SafariServices;
@import AudioToolbox;
#import "MusicHandler.h"
#import "TwitterHandler.h"
#import "ConnectivityHandler.h"

/**
 Check method availability for iOS SDK calls

 @param v Lowest iOS version requested
 @return YES if the current version of iOS is equal or newer that the requested one
 */
#define SYSTEM_VERSION_GREATERTHAN_OR_EQUALTO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

/**
 One and only screen of the app.
 Shows a text view and an image view to preview text & image to tweet,
 with also a switch for text-only tweets,
 and validation & reset buttons.
 */
@interface ViewController : UIViewController <UITextViewDelegate>

/// Editable text for the tweet, containing track & artist by default
@property (weak, nonatomic) IBOutlet UITextView  *textField;

/// Switch to tweet artwork or only text
@property (weak, nonatomic) IBOutlet UISwitch    *artwork;

/// Artwork preview
@property (weak, nonatomic) IBOutlet UIImageView *artworkView;

/// Validation button
@property (weak, nonatomic) IBOutlet UIButton    *tweetBtn;


/**
 Share text, and artwork eventually, on Twitter
 */
- (IBAction) share;

/**
 Displays the current track info on the view controller
 */
- (IBAction) reset;

@end
