//
//  IIOnboardingViewController6.h
//  InfinitInstaller
//
//  Created by Christopher Crone on 21/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIOnboardingAbstractViewController.h"

@protocol IIOnboardingViewController6Protocol <NSObject>

- (double)currentDownloadProgress;

@end;

@protocol IIOnboardingViewController6Protocol;

@interface IIOnboardingViewController6 : IIOnboardingAbstractViewController

@property (nonatomic, unsafe_unretained) id<IIOnboardingViewController6Protocol> delegate;

@end
