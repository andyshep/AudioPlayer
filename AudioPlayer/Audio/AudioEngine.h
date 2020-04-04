//
//  AudioEngine.h
//  AudioPlayer
//
//  Created by Andrew Shepard on 4/4/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioEngine: NSObject

- (void)startPlaybackOfURL:(NSURL *)url;
- (void)stopPlayback;

@end

NS_ASSUME_NONNULL_END
