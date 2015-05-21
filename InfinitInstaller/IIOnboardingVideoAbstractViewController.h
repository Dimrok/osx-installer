//
//  IIOnboardingVideoAbstractViewController.h
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIOnboardingAbstractViewController.h"

@interface IIOnboardingVideoAbstractViewController : IIOnboardingAbstractViewController

@property (nonatomic, weak) IBOutlet NSTextField* bottom_info;
@property (nonatomic, weak) IBOutlet NSTextField* top_info;
@property (nonatomic, weak) IBOutlet NSTextField* top_label;

@property (nonatomic, readwrite) NSURL* video_url;

- (void)boldLabel:(NSTextField*)label
           string:(NSString*)string;

@end
