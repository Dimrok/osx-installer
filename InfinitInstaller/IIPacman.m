//
//  IIPacman.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 17/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IIPacman.h"

@implementation IIPacman
{
@private
  CGFloat _radius;
  CGFloat _angle;
  CGFloat _max_angle;
  CGFloat _min_angle;
  CGFloat _increment;
  CGFloat _fps;
  CGFloat _speed_multiplier;
  NSColor* _colour;
  NSTimer* _timer;
  BOOL _grow;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
    _min_angle = 0.0;
    _angle = _min_angle;
    _max_angle = 120.0;
    _radius = floor(NSWidth(frameRect) / 2.0) - 2.0;
    _fps = 24.0;
    _speed_multiplier = 4.0;
    _increment = ((_max_angle - _min_angle) / _fps) * _speed_multiplier;
    _grow = YES;
    _colour = [self twoFiftySixBitColourRed:81 green:81 blue:72 alpha:1.0];
    self.hidden = YES;
  }
  return self;
}

- (void)dealloc
{
  [_timer invalidate];
  _timer = nil;
}

//- Drawing ----------------------------------------------------------------------------------------

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* outline = [NSBezierPath bezierPath];
  NSPoint centre = NSMakePoint(floor(NSWidth(self.bounds) / 2.0),
                               floor(NSHeight(self.bounds)/ 2.0));
  [outline moveToPoint:centre];
  NSPoint top_lip = NSMakePoint(floor(_radius * cos([self degToRad:_angle] / 2.0) + centre.x),
                                floor(_radius * sin([self degToRad:_angle] / 2.0)) + centre.y);
  [outline lineToPoint:top_lip];
  [outline appendBezierPathWithArcWithCenter:centre
                                      radius:_radius
                                  startAngle:(_angle / 2.0)
                                    endAngle:(-_angle / 2.0)];
  [outline closePath];
  [_colour set];
  [outline stroke];
  [outline fill];
}

//- Helpers ----------------------------------------------------------------------------------------

- (CGFloat)degToRad:(CGFloat)deg
{
  return (deg * M_PI / 180.0);
}

- (NSColor*)twoFiftySixBitColourRed:(NSUInteger)red
                              green:(NSUInteger)green
                               blue:(NSUInteger)blue
                              alpha:(CGFloat)alpha
{
  return [NSColor colorWithDeviceRed:(((CGFloat)red)/255.0)
                               green:(((CGFloat)green)/255.0)
                                blue:(((CGFloat)blue)/255.0)
                               alpha:alpha];
}

//- Animation --------------------------------------------------------------------------------------

- (void)setAnimate:(BOOL)animate
{
  if (_animate == animate)
    return;
  _animate = animate;
  if (_animate)
  {
    self.hidden = NO;
    [self setNeedsDisplay:YES];
    _timer = [NSTimer timerWithTimeInterval:1/_fps
                                     target:self
                                   selector:@selector(updatePacman:)
                                   userInfo:nil
                                    repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
  }
  else
  {
    self.hidden = YES;
    [_timer invalidate];
    _timer = nil;
  }
}

- (void)updatePacman:(NSTimer*)timer
{
  if (_angle >= _max_angle)
    _grow = NO;
  else if (_angle <= _min_angle + 0.1)
    _grow = YES;
  if (_grow)
    _angle += _increment;
  else
    _angle -= _increment;
  if (_angle < _min_angle + 0.1)
    _angle = _min_angle + 0.1;
  [self setNeedsDisplay:YES];
}

@end
