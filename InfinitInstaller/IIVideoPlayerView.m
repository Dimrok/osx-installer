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
@property (nonatomic, readonly) dispatch_once_t init_token;

@end

@implementation IIVideoPlayerView

#pragma mark - Init

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.player pause];
}

#pragma mark - Set URL

- (void)setUrl:(NSURL*)url
{
  dispatch_once(&_init_token, ^
  {
    self.wantsLayer = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFinished:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
  });
  for (CALayer* layer in self.layer.sublayers)
    [layer removeFromSuperlayer];
  _url = url;
  _player = [AVPlayer playerWithURL:self.url];
  _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
  _player.muted = YES;
  AVPlayerLayer* player_layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
  player_layer.frame = self.layer.bounds;
  [self.layer addSublayer:player_layer];
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

- (void)restart
{
  [self.player seekToTime:kCMTimeZero];
}

- (void)videoFinished:(NSNotification*)notification
{
  _play_count += 1;
  [self.delegate finishedPlayOfVideo:self];
  [self.player seekToTime:kCMTimeZero];
}

@end
