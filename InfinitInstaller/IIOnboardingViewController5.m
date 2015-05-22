//
//  IIOnboardingViewController5.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIOnboardingViewController5.h"

#import "IIHoverImageButton.h"

#define kInfinitDownloadURL @"https://infinit.io/download?utm_source=app&utm_medium=mac&utm_campaign=installer"

@interface IIOnboardingViewController5 ()

@property (nonatomic, weak) IBOutlet IIHoverImageButton* apple_button;
@property (nonatomic, weak) IBOutlet IIHoverImageButton* windows_button;
@property (nonatomic, weak) IBOutlet IIHoverImageButton* ios_button;
@property (nonatomic, weak) IBOutlet IIHoverImageButton* android_button;

@end

static dispatch_once_t _first_load_token = 0;

@implementation IIOnboardingViewController5

- (void)dealloc
{
  _first_load_token = 0;
}

- (NSUInteger)screen_number
{
  return 5;
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  dispatch_once(&_first_load_token, ^
  {
    self.top_label.stringValue = NSLocalizedString(@"Transfer file between your own devices", nil);
    self.top_info.stringValue = NSLocalizedString(@"Install Infinit on your other devices and transfer photos, videos, documents and more to your tablet or smartphone in the blink of an eye.", nil);
    self.bottom_info.stringValue = NSLocalizedString(@"Available on Windows, Mac, Linux, iOS and Android.", nil);
    [self boldLabel:self.top_info string:NSLocalizedString(@"tablet or smartphone", nil)];
    NSMutableAttributedString* temp_str = [self.bottom_info.attributedStringValue mutableCopy];
    [temp_str addAttribute:NSFontAttributeName
                     value:[NSFont fontWithName:@"SourceSansPro-It" size:15.0f]
                     range:NSMakeRange(0, temp_str.string.length)];
    self.bottom_info.attributedStringValue = temp_str;
    self.apple_button.hover_image = [NSImage imageNamed:@"onboarding-icon-apple-hover"];
    self.windows_button.hover_image = [NSImage imageNamed:@"onboarding-icon-windows-hover"];
    self.ios_button.hover_image = [NSImage imageNamed:@"onboarding-icon-ios-hover"];
    self.android_button.hover_image = [NSImage imageNamed:@"onboarding-icon-android-hover"];
    self.video_url = [[NSBundle mainBundle] URLForResource:@"send-device" withExtension:@"mp4"];
  });
}

#pragma mark - Button Handling

- (IBAction)buttonClicked:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kInfinitDownloadURL]];
}

@end
