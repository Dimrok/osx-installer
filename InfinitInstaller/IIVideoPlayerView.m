//
//  IIVideoPlayerView.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 30/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IIVideoPlayerView.h"

#import <AVFoundation/AVFoundation.h>

@implementation IIVideoPlayerView
{
  AVPlayer* _player;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
    self.wantsLayer = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFinished:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[_player currentItem]];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_player pause];
}

//- Set URL ----------------------------------------------------------------------------------------

- (void)setUrl:(NSURL*)url
{
  _url = url;
  _player = [AVPlayer playerWithURL:_url];
  _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
  _player.muted = YES;
  AVPlayerLayer* player_layer = [AVPlayerLayer playerLayerWithPlayer:_player];
  self.layer = player_layer;
}

//- Video Playback ---------------------------------------------------------------------------------

- (void)play
{
  _play_count = 0;
  [_player play];
}

- (void)pause
{
  [_player pause];
}

- (void)videoFinished:(NSNotification*)notification
{
  _play_count += 1;
  [_delegate finishedPlayOfVideo:self];
  [_player seekToTime:kCMTimeZero];
}

@end
