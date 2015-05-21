//
//  IIOnboardingAbstractViewController.h
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IIOnboardingProgressView.h"

@interface IIOnboardingAbstractViewController : NSViewController

@property (nonatomic, readonly) BOOL final_screen;
@property (nonatomic, readonly) NSUInteger screen_number;

- (void)aboutToAnimate;
- (void)finishedAnimate;

@end
