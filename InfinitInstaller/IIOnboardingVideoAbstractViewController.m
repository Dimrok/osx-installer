//
//  IIOnboardingVideoAbstractViewController.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIOnboardingVideoAbstractViewController.h"

#import "IIVideoPlayerView.h"
#import "InfinitColor.h"

@interface IIOnboardingVideoAbstractViewController ()

@property (nonatomic, weak) IBOutlet IIVideoPlayerView* video_view;

@end

static NSFont* _bold_font = nil;
static NSColor* _bold_color = nil;

@implementation IIOnboardingVideoAbstractViewController

- (void)aboutToAnimate
{
  [super aboutToAnimate];
  [self.video_view pause];
}

- (void)finishedAnimate
{
  [super finishedAnimate];
  [self.video_view play];
}

#pragma mark - Video URL

- (void)setVideo_url:(NSURL*)video_url
{
  self.video_view.url = video_url;
}

#pragma mark - Helpers

- (void)boldLabel:(NSTextField*)label
           string:(NSString*)string
{
  NSRange range = [label.stringValue rangeOfString:string];
  if (range.location == NSNotFound)
    return;
  if (!_bold_font)
    _bold_font = [NSFont fontWithName:@"SourceSansPro-Bold" size:15.0f];
  if (!_bold_color)
    _bold_color = [InfinitColor colorWithGray:68];
  NSMutableAttributedString* temp_str = [label.attributedStringValue mutableCopy];
  [temp_str addAttribute:NSFontAttributeName value:_bold_font range:range];
  [temp_str addAttribute:NSForegroundColorAttributeName
                   value:_bold_color
                   range:range];
  label.attributedStringValue = temp_str;
}

@end
