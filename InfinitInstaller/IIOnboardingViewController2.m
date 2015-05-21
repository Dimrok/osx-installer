//
//  IIOnboardingViewController2.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIOnboardingViewController2.h"

@interface IIOnboardingViewController2 ()
@end

static dispatch_once_t _first_load_token = 0;

@implementation IIOnboardingViewController2

- (void)dealloc
{
  _first_load_token = 0;
}

- (NSUInteger)screen_number
{
  return 2;
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  dispatch_once(&_first_load_token, ^
  {
    self.top_label.stringValue = NSLocalizedString(@"Send to an email address", nil);
    self.top_info.stringValue = NSLocalizedString(@"Simply drag & drop your files and folders, enter the recipient’s email address and click ‘Send’.", nil);
    self.bottom_info.stringValue = NSLocalizedString(@"The recipient will receive an email with options to download the files directly or install Infinit.", nil);
    [self boldLabel:self.top_info string:NSLocalizedString(@"email address", nil)];
    [self boldLabel:self.bottom_info string:NSLocalizedString(@"download the files directly", nil)];
    self.video_url = [[NSBundle mainBundle] URLForResource:@"send-email" withExtension:@"mp4"];
  });
}

@end
