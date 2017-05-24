//
//  MusicHandler.h
//  Music Tweet
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

@import MediaPlayer;

#define ARTWORK_SIZE CGSizeMake(600, 600)

@interface MusicHandler : NSObject

+ (NSString *) generateTweetText;
+ (UIImage *)  getCurrentArtwork;

@end
