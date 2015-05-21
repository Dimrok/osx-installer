//
//  IIOnboardingViewController6.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 21/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIOnboardingViewController6.h"

#import "IIHoverImageButton.h"

#define kInfinitDownloadURL @"https://infinit.io/download?utm_source=app&utm_medium=mac&utm_campaign=installer"

@interface IIOnboardingViewController6 ()

@property (nonatomic, weak) IBOutlet NSTextField* info_label;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* progress_indicator;
@property (nonatomic, weak) IBOutlet IIHoverImageButton* apple_button;
@property (nonatomic, weak) IBOutlet IIHoverImageButton* windows_button;
@property (nonatomic, weak) IBOutlet IIHoverImageButton* ios_button;
@property (nonatomic, weak) IBOutlet IIHoverImageButton* android_button;

@property (nonatomic, readonly) NSTimer* timer;

@end

static dispatch_once_t _first_load_token = 0;

@implementation IIOnboardingViewController6

#pragma mark - IIOnboardingAbstractViewController

- (BOOL)final_screen
{
  return YES;
}

- (NSUInteger)screen_number
{
  return 6;
}

- (void)aboutToAnimate
{
  [super aboutToAnimate];
  if (self.timer)
  {
    [self.timer invalidate];
    _timer = nil;
  }
}

- (void)finishedAnimate
{
  [super finishedAnimate];
  self.progress_indicator.doubleValue = [self.delegate currentDownloadProgress];
  _timer = [NSTimer timerWithTimeInterval:0.5f
                                   target:self
                                 selector:@selector(fetchProgress) 
                                 userInfo:nil
                                  repeats:YES];
  [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  dispatch_once(&_first_load_token, ^
  {
    self.apple_button.hover_image = [NSImage imageNamed:@"onboarding-icon-apple-hover"];
    self.windows_button.hover_image = [NSImage imageNamed:@"onboarding-icon-windows-hover"];
    self.ios_button.hover_image = [NSImage imageNamed:@"onboarding-icon-ios-hover"];
    self.android_button.hover_image = [NSImage imageNamed:@"onboarding-icon-android-hover"];
  });
}

#pragma mark - Button Handling

- (IBAction)buttonClicked:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kInfinitDownloadURL]];
}

#pragma mark - Progress Handling

- (void)fetchProgress
{
  double progress = [self.delegate currentDownloadProgress];
  if (self.progress_indicator.doubleValue == progress)
    return;
  if (progress >= 1.0f)
  {
    [self.timer invalidate];
    _timer = nil;
    self.info_label.stringValue = NSLocalizedString(@"Installing Infinit...", nil);
    if (self.progress_indicator.doubleValue < 1.0f)
    {
      [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
      {
        context.duration = 0.5f;
        self.progress_indicator.animator.doubleValue = 1.0f;
      } completionHandler:nil];
    }
    return;
  }
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.5f;
    self.progress_indicator.animator.doubleValue = progress;
  } completionHandler:nil];
}

@end
