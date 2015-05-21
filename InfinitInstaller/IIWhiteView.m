//
//  IIWhiteView.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIWhiteView.h"

@implementation IIWhiteView

- (void)drawRect:(NSRect)dirtyRect
{
  [[NSColor whiteColor] set];
  NSRectFill(dirtyRect);
}

@end
