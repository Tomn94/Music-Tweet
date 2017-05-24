//
//  MusicHandler.m
//  Music Tweet
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

#import "MusicHandler.h"

@implementation MusicHandler

+ (BOOL) hasItemPlaying
{
    if (MPMediaLibrary.authorizationStatus != MPMediaLibraryAuthorizationStatusAuthorized)
        return NO;
    
    MPMediaItem *currentItem = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
    return currentItem != nil;
}

+ (NSString *) generateTweetText
{
    if (!self.hasItemPlaying)
        return nil;
    
    MPMediaItem *currentItem = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
    
    NSString *s1 = @"#NP ▶️ ";
    NSString *s2 = [s1 stringByAppendingString:[currentItem valueForProperty:MPMediaItemPropertyTitle]];
    NSString *s3 = [s2 stringByAppendingString:@" — "];
    NSString *s4 = [s3 stringByAppendingString:[currentItem valueForProperty:MPMediaItemPropertyArtist]];
    NSString *sLast = [s4 stringByAppendingString:@"\n"];
    
    return sLast;
}

+ (UIImage *) getCurrentArtwork
{
    return [self getCurrentArtwork:ARTWORK_SIZE];
}

+ (UIImage *) getCurrentArtwork:(CGSize)size
{
    if (!self.hasItemPlaying)
        return nil;
    
    MPMediaItem *currentItem = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
    
    return [[currentItem valueForProperty:MPMediaItemPropertyArtwork] imageWithSize:size];
}

@end
