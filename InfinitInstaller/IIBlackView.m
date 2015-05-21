//
//  IIBlackView.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIBlackView.h"

@implementation IIBlackView

- (void)drawRect:(NSRect)dirtyRect
{
  [[NSColor blackColor] set];
  NSRectFill(dirtyRect);
}

@end
