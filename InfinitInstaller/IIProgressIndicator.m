//
//  IIProgressIndicator.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 21/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIProgressIndicator.h"

#import "InfinitColor.h"

#import <QuartzCore/QuartzCore.h>

static CGFloat _corner_radius = 5.0f;
static NSColor* _outline_color = nil;
static NSColor* _fill_color = nil;

@implementation IIProgressIndicator

@synthesize doubleValue = _doubleValue;

- (void)drawRect:(NSRect)dirtyRect
{
  NSRect outline_rect = NSMakeRect(0.0f, 0.0f, self.bounds.size.width, 11.0f);
  NSBezierPath* outline = [NSBezierPath bezierPathWithRoundedRect:outline_rect
                                                          xRadius:_corner_radius
                                                          yRadius:_corner_radius];
  if (!_outline_color)
    _outline_color = [InfinitColor colorWithGray:235];
  [_outline_color set];
  [outline fill];
  NSRect fill_rect = NSMakeRect(0.0f,
                                0.0f,
                                floor(self.doubleValue / self.maxValue * self.bounds.size.width),
                                11.0f);
  NSBezierPath* fill = [NSBezierPath bezierPathWithRoundedRect:fill_rect
                                                       xRadius:_corner_radius
                                                       yRadius:_corner_radius];
  if (!_fill_color)
    _fill_color = [InfinitColor colorWithRed:43 green:190 blue:189];
  [_fill_color set];
  [fill fill];
}

- (void)setDoubleValue:(double)doubleValue
{
  _doubleValue = doubleValue;
  [self setNeedsDisplay:YES];
}

+ (id)defaultAnimationForKey:(NSString*)key
{
  if ([key isEqualToString:@"doubleValue"])
    return [CABasicAnimation animation];

  return [super defaultAnimationForKey:key];
}

@end
