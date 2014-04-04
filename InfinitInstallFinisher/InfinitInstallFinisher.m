//
//  main.m
//  InfinitInstallFinisher
//
//  Created by Nick Jensen on 4/1/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define INFINIT_APP_PATH @"/Applications/Infinit.app"

@interface InfinitTerminationListener : NSObject {
    
	pid_t parentProcessID;
    NSString *appPath;
}

- (id)initWithParentProcessID:(pid_t)ppid installLocation:(NSString *)path;

@end

@implementation InfinitTerminationListener

- (id)initWithParentProcessID:(pid_t)ppid installLocation:(NSString *)path {

    if ((self = [super init])) {
     
        parentProcessID = ppid;
        appPath = [path copy];
        
        BOOL alreadyTerminated = (getppid() == 1); // ppid is launchd (1) => parent terminated already
        
        if (alreadyTerminated) {
            
            [self finishInstallationAndLaunchInfinit];
        }
        else {
            
            NSNotificationCenter *notificationCenter;
            notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
            [notificationCenter addObserver:self
                                   selector:@selector(applicationDidTerminate:)
                                       name:NSWorkspaceDidTerminateApplicationNotification
                                     object:nil];
        }
    }
	return self;
}

- (void)applicationDidTerminate:(NSNotification *)notification {
    
    NSDictionary *info = [notification userInfo];
    pid_t terminatedProcessID = [[info valueForKey:@"NSApplicationProcessIdentifier"] intValue];

    if (parentProcessID == terminatedProcessID) {

        [self finishInstallationAndLaunchInfinit];
    }
}

- (void)finishInstallationAndLaunchInfinit {
    
    NSLog(@"Parent process (%d) has quit.", parentProcessID);
    NSLog(@"Finishing Installation of: %@", appPath);
    
    NSError *error = nil;
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    if ([mgr fileExistsAtPath:INFINIT_APP_PATH]) {
        
        [mgr removeItemAtPath:INFINIT_APP_PATH error:&error];
    }
    
    [mgr copyItemAtPath:appPath toPath:INFINIT_APP_PATH error:&error];
    
    [[NSWorkspace sharedWorkspace] launchApplication:INFINIT_APP_PATH];

    [NSApp terminate:nil];
}

- (void)dealloc {
	
    NSNotificationCenter *notificationCenter;
    notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [notificationCenter removeObserver:self];
    
    [appPath release];
    
	[super dealloc];
}

@end


int main(int argc, const char * argv[]) {

    int status = EXIT_SUCCESS;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (argc == 3) {

        pid_t parentProcessID = atoi(argv[1]);
        NSString *appPath = [NSString stringWithUTF8String:argv[2]];
        BOOL appExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:appPath];
        
        if (parentProcessID != 0 && appExistsAtPath) {
            
            InfinitTerminationListener *listener;
            listener = [[[InfinitTerminationListener alloc]
                         initWithParentProcessID:parentProcessID installLocation:appPath] autorelease];
 
            [[NSApplication sharedApplication] run];
        }
        else {
         
            NSLog(@"%s invalid arguments.", argv[0]);

            status = EXIT_FAILURE;
        }
    }
    else {

        NSLog(@"%s invalid number of arguments.", argv[0]);

        status = EXIT_FAILURE;
    }
    
	[pool drain];
	
	return status;
}
