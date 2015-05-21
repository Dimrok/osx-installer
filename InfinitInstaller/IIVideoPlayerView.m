//
//  IIVideoPlayerView.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 30/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IIVideoPlayerView.h"

#import <AVFoundation/AVFoundation.h>

@interface IIVideoPlayerView ()

@property (nonatomic, readonly) AVPlayer* player;

@end

@implementation IIVideoPlayerView

#pragma mark - Init

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
    self.wantsLayer = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFinished:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.player pause];
}

#pragma mark - Set URL

- (void)setUrl:(NSURL*)url
{
  _url = url;
  _player = [AVPlayer playerWithURL:self.url];
  _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
  _player.muted = YES;
  AVPlayerLayer* player_layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
  self.layer = player_layer;
}

#pragma mark - Playback

- (void)play
{
  _play_count = 0;
  [self.player play];
}

- (void)pause
{
  [self.player pause];
}

- (void)videoFinished:(NSNotification*)notification
{
  _play_count += 1;
  [self.delegate finishedPlayOfVideo:self];
  [self.player seekToTime:kCMTimeZero];
}

@end
