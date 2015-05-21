//
//  IIHoverImageButton.h
//  InfinitInstaller
//
//  Created by Christopher Crone on 21/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IIHoverImageButton : NSButton

@property (nonatomic, readwrite) BOOL hand_cursor; // Defaults to YES;
@property (nonatomic, readwrite) NSImage* hover_image;

@end
