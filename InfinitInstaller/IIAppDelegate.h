//
//  IIAppDelegate.h
//  InfinitInstaller
//
//  Created by Nick Jensen on 3/31/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AFNetworking/AFNetworking.h>
#import <AFKissXMLRequestOperation/AFKissXMLRequestOperation.h>

#import "SUDiskImageUnarchiver.h"
#import "IIVideoPlayerView.h"

@interface IIAppDelegate : NSObject <NSApplicationDelegate,
                                     SUUnarchiverDelegate,
                                     IIVideoPlayerProtocol>

@property (nonatomic, strong) AFHTTPClient* client;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* progress_bar;
@property (nonatomic, weak) IBOutlet NSTextField* tagline_label;
@property (nonatomic, weak) IBOutlet NSTextField* instruction_label;
@property (nonatomic, weak) IBOutlet NSTextField* status_label;
@property (nonatomic, strong) SUDiskImageUnarchiver* unarchiver;
@property (nonatomic, weak) IBOutlet IIVideoPlayerView* video_view;
@property (nonatomic, assign) IBOutlet NSWindow* window;

@end
