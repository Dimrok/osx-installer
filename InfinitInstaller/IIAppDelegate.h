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

@interface IIAppDelegate : NSObject <NSApplicationDelegate, SUUnarchiverDelegate>

@property (nonatomic, weak) IBOutlet NSWindow* window;
@property (nonatomic, weak) IBOutlet NSTextField* status_label;
@property (nonatomic, weak) IBOutlet NSProgressIndicator* progress_bar;
@property (nonatomic, strong) AFHTTPClient* client;
@property (nonatomic, strong) SUDiskImageUnarchiver* unarchiver;

@end
