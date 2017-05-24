//
//  MusicHandler.m
//  Music Tweet
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

#import "MusicHandler.h"

@implementation MusicHandler

+ (NSString *) generateTweetText
{
    if (MPMediaLibrary.authorizationStatus != MPMediaLibraryAuthorizationStatusAuthorized)
        return nil;
    
    MPMediaItem *currentItem = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
    if (!currentItem)
        return nil;
    
    NSString *s1 = @"#NP ▶️ ";
    NSString *s2 = [s1 stringByAppendingString:[currentItem valueForProperty:MPMediaItemPropertyTitle]];
    NSString *s3 = [s2 stringByAppendingString:@" — "];
    NSString *s4 = [s3 stringByAppendingString:[currentItem valueForProperty:MPMediaItemPropertyArtist]];
    NSString *sLast = [s4 stringByAppendingString:@"\n"];
    
    return sLast;
}

+ (UIImage *) getCurrentArtwork
{
    if (MPMediaLibrary.authorizationStatus != MPMediaLibraryAuthorizationStatusAuthorized)
        return nil;
    
    MPMediaItem *currentItem = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
    if (!currentItem)
        return nil;
    
    return [[currentItem valueForProperty:MPMediaItemPropertyArtwork] imageWithSize:ARTWORK_SIZE];
}

@end
