//
//  IIOnboardingProgressView.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIOnboardingProgressView.h"

#import "InfinitColor.h"

static NSUInteger _total_count = 5;

@implementation IIOnboardingProgressView

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
  double d_x = floor(self.bounds.size.width / (_total_count + 1));
  for (NSUInteger i = 1; i < (_total_count + 1); i++)
  {
    NSPoint center = NSMakePoint(floor(self.bounds.origin.x + (i * d_x)),
                                 floor(self.bounds.size.height / 2.0f));
    NSBezierPath* circle = [self _circleWithCenter:center ofRadius:5.0f];
    NSColor* color = (i == self.progress_count ? [NSColor blackColor]
                                               : [InfinitColor colorWithGray:204]);
    [color set];
    [circle fill];
  }
}

- (void)setProgress_count:(NSUInteger)progress_count
{
  _progress_count = progress_count;
  [self setNeedsDisplay:YES];
}

#pragma mark - Helpers

- (NSBezierPath*)_circleWithCenter:(NSPoint)point
                          ofRadius:(double)radius
{
  NSRect rect = NSMakeRect(point.x - radius, point.y - radius, 2.0f * radius, 2.0f * radius);
  NSBezierPath* res = [NSBezierPath bezierPathWithOvalInRect:rect];
  return res;
}

@end
