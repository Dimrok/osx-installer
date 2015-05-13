//
//  IICodeFinder.h
//  InfinitInstaller
//
//  Created by Christopher Crone on 13/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IICodeFinder : NSObject

+ (instancetype)sharedInstance;

- (NSString*)getCode;

@end
