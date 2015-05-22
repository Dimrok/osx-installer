//
//  IIOnboardingButtonCell.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 20/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIOnboardingButtonCell.h"

#import "InfinitColor.h"

static NSColor* _h_color = nil;

@implementation IIOnboardingButtonCell

- (void)drawBezelWithFrame:(NSRect)frame
                    inView:(NSView*)controlView
{
  CGFloat corner_radius = floor(frame.size.height / 2.0f);
  NSBezierPath* bg = [NSBezierPath bezierPathWithRoundedRect:frame
                                                     xRadius:corner_radius
                                                     yRadius:corner_radius];
  [self.background_color set];
  [bg fill];
}

- (void)highlight:(BOOL)flag
        withFrame:(NSRect)cellFrame
           inView:(NSView*)controlView
{
  if (flag)
  {
    if (!_h_color)
      _h_color = [InfinitColor colorWithGray:0 alpha:0.3f];
    CGFloat corner_radius = floor(cellFrame.size.height / 2.0f);
    NSBezierPath* bg = [NSBezierPath bezierPathWithRoundedRect:cellFrame
                                                       xRadius:corner_radius
                                                       yRadius:corner_radius];
    [_h_color set];
    [bg fill];
  }
  else
  {
    [self drawBezelWithFrame:cellFrame inView:controlView];
    [self drawTitle:self.attributedTitle withFrame:cellFrame inView:controlView];
  }
}

- (NSRect)drawTitle:(NSAttributedString*)title
          withFrame:(NSRect)frame
             inView:(NSView*)controlView
{
  NSSize text_size = title.size;
  NSRect title_rect = NSMakeRect(floor((NSWidth(controlView.bounds) - text_size.width) / 2.0f),
                                 floor((NSHeight(controlView.bounds) - text_size.height) / 2.0f) - 1.0f,
                                 text_size.width, text_size.height);
  [title drawInRect:title_rect];
  return title_rect;
}

@end
