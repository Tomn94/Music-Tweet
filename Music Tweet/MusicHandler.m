//
//  MusicHandler.m
//  Music Tweet
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

#import "MusicHandler.h"

@implementation MusicHandler

+ (MusicHandler *) sharedHandler {
    static MusicHandler *instance = nil;
    if (instance == nil) {
        
        static dispatch_once_t pred;        // Lock
        dispatch_once(&pred, ^{             // This code is called at most once per app
            instance = [[MusicHandler allocWithZone:NULL] init];
        });
        
        /* Init first data with current track */
        [instance reset];
    }
    return instance;
}

+ (BOOL) hasItemPlaying
{
    if (MPMediaLibrary.authorizationStatus != MPMediaLibraryAuthorizationStatusAuthorized)
        return NO;
    
    MPMediaItem *currentItem = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
    
    return currentItem != nil;
}

+ (NSString *) generateTweetText
{
    if (![MusicHandler hasItemPlaying])
        return @"";
    
    MPMediaItem *currentItem = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
    
    /* Set up text with seperators and music info */
    NSString *s1 = @"#NP ▶️ ";
    NSString *s2 = [s1 stringByAppendingString:[currentItem valueForProperty:MPMediaItemPropertyTitle]];
    NSString *s3 = [s2 stringByAppendingString:@" — "];
    NSString *s4 = [s3 stringByAppendingString:[currentItem valueForProperty:MPMediaItemPropertyArtist]];
    NSString *sLast = [s4 stringByAppendingString:@"\n"];
    
    return sLast;
}

+ (MPMediaItemArtwork *) fetchCurrentArtwork
{
    if (![MusicHandler hasItemPlaying])
        return nil;
    
    MPMediaItem *currentItem = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
    
    return [currentItem valueForProperty:MPMediaItemPropertyArtwork];
}

- (UIImage *) getArtwork
{
    return [self getArtworkAt:ARTWORK_SIZE];
}

- (UIImage *) getArtworkAt:(CGSize)size
{
    return [_artwork imageWithSize:size];
}

- (void) reset
{
    /* Regenerate content */
    [self setTweetText:[MusicHandler generateTweetText]];
    [self setArtwork:[MusicHandler fetchCurrentArtwork]];
}

@end
