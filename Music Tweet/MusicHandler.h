//
//  MusicHandler.h
//  Music Tweet
//
//  Created by Tomn on 24/05/2017.
//  Copyright © 2017 U969H3GXLU. All rights reserved.
//

@import MediaPlayer;

/// Default artwork size when shared on the network
#define ARTWORK_SIZE CGSizeMake(600, 600)

/**
 Singleton object handling link between user music library and the app
 */
@interface MusicHandler : NSObject

/**
 Use this class method to get a singleton instance

 @return Singleton object
 */
+ (MusicHandler *) sharedHandler;

/**
 Useful to check if the app has access to the music library
 and that some track is playing

 @return True if some song is available to share
 */
+ (BOOL) hasItemPlaying;

/**
 Create a new text with updated music info currently playing.
 Base string is "#NP ▶️ Title — Artist\n"

 @return Text to tweet
 */
+ (NSString *) generateTweetText;

/**
 Get the updated music artwork currently playing

 @return Artwork item, independent from image size
 */
+ (MPMediaItemArtwork *) fetchCurrentArtwork;


/// Current text storage, set by `reset` then the user
@property (strong, nonatomic) NSString *tweetText;

/// Current artwork storage, set by `reset`
@property (strong, nonatomic) MPMediaItemArtwork *artwork;


/**
 Returns currently stored artwork at default size

 @return Song illustration
 */
- (UIImage *) getArtwork;

/**
 Returns currently stored artwork at custom size

 @param size Size requested for the artwork
 @return Smallest available image that is at least as large as the requested size
 */
- (UIImage *) getArtworkAt:(CGSize)size;

/**
 Reset stored data from current song playing
 */
- (void) reset;

@end
