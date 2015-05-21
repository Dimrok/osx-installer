//
//  IIBorderView.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIBorderView.h"

#import "InfinitColor.h"

@implementation IIBorderView

- (void)drawRect:(NSRect)dirtyRect
{
  [[InfinitColor colorWithGray:237] set];
  NSRectFill(dirtyRect);
}

@end
