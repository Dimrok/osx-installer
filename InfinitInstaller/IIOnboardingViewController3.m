//
//  IIOnboardingViewController3.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIOnboardingViewController3.h"

@interface IIOnboardingViewController3 ()
@end

static dispatch_once_t _first_load_token = 0;

@implementation IIOnboardingViewController3

- (void)dealloc
{
  _first_load_token = 0;
}

- (NSUInteger)screen_number
{
  return 3;
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  dispatch_once(&_first_load_token, ^
  {
    self.top_label.stringValue = NSLocalizedString(@"Send to other Infinit users", nil);
    self.top_info.stringValue = NSLocalizedString(@"With your friends on Infinit, you can send files and folders of any size for free without having to enter an email address.", nil);
    self.bottom_info.stringValue = NSLocalizedString(@"Oh, and it’s super secure and way faster than services like email, Dropbox, WeTransfer etc.", nil);
    [self boldLabel:self.top_info string:NSLocalizedString(@"any size for free", nil)];
    [self boldLabel:self.bottom_info string:NSLocalizedString(@"super secure", nil)];
    [self boldLabel:self.bottom_info string:NSLocalizedString(@"way faster", nil)];
    self.video_url = [[NSBundle mainBundle] URLForResource:@"send-contact" withExtension:@"mp4"];
  });
}

@end
