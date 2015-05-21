//
//  IIOnboardingViewController4.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIOnboardingViewController4.h"

@interface IIOnboardingViewController4 ()
@end

static dispatch_once_t _first_load_token = 0;

@implementation IIOnboardingViewController4

- (void)dealloc
{
  _first_load_token = 0;
}

- (NSUInteger)screen_number
{
  return 4;
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  dispatch_once(&_first_load_token, ^
  {
    self.top_label.stringValue = NSLocalizedString(@"Receive from Infinit users", nil);
    self.top_info.stringValue = NSLocalizedString(@"Receiving files with one click. Just open Infinit and click the ‘Accept’ button to start the transfer. You’ll even be notified when the files are available.", nil);
    self.bottom_info.stringValue = @"";
    [self boldLabel:self.top_info string:NSLocalizedString(@"Receiving", nil)];
    [self boldLabel:self.top_info string:NSLocalizedString(@"click the ‘Accept’ button", nil)];
    [self boldLabel:self.top_info string:NSLocalizedString(@"notified", nil)];
    self.video_url = [[NSBundle mainBundle] URLForResource:@"accept" withExtension:@"mp4"];
  });
}

@end
