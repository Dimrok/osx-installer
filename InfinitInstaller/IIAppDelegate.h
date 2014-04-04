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

@property (assign, nonatomic) IBOutlet NSWindow *window;
@property (assign, nonatomic) IBOutlet NSTextField *statusLabel;
@property (assign, nonatomic) IBOutlet NSProgressIndicator *progressBar;
@property (retain, nonatomic) AFHTTPClient *client;
@property (retain, nonatomic) SUDiskImageUnarchiver *unarchiver;

@end
