//
//  IIHoverImageButton.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 21/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IIHoverImageButton.h"

@interface IIHoverImageButton ()

@property (nonatomic, readonly) NSImage* normal_image;
@property (nonatomic, readonly) NSTrackingArea* tracking_area;
@property (nonatomic, readwrite) dispatch_once_t load_token;

@end

@implementation IIHoverImageButton

#pragma mark - Init

- (id)initWithCoder:(NSCoder*)coder
{
  if (self = [super initWithCoder:coder])
  {
    _hand_cursor = YES;
  }
  return self;
}

- (void)dealloc
{
  if (self.tracking_area)
  {
    [self removeTrackingArea:self.tracking_area];
    _tracking_area = nil;
  }
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  dispatch_once(&_load_token, ^
  {
    if (self.normal_image == nil)
      _normal_image = [self.image copy];
  });
}

#pragma mark - NSControl

- (void)resetCursorRects
{
  if (self.hand_cursor)
    [self addCursorRect:self.bounds cursor:[NSCursor pointingHandCursor]];
  else
    [super resetCursorRects];
}

#pragma mark - Hover

- (void)createTrackingArea
{
  _tracking_area = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:(NSTrackingMouseEnteredAndExited |
                                                         NSTrackingActiveAlways)
                                                  owner:self
                                               userInfo:nil];

  [self addTrackingArea:self.tracking_area];

  NSPoint mouse_loc = self.window.mouseLocationOutsideOfEventStream;
  mouse_loc = [self convertPoint:mouse_loc fromView:nil];
  if (NSPointInRect(mouse_loc, self.bounds))
    [self mouseEntered:nil];
  else
    [self mouseExited:nil];
}

- (void)updateTrackingAreas
{
  if (self.tracking_area && [self.trackingAreas containsObject:self.tracking_area])
    return;
  [self createTrackingArea];
  [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
  self.image = self.hover_image;
  [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent*)theEvent
{
  self.image = self.normal_image;
  [self setNeedsDisplay:YES];
}

@end
