//
//  main.m
//  InfinitInstallFinisher
//
//  Created by Nick Jensen on 4/1/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define INFINIT_APP_PATH @"/Applications/Infinit.app"

@interface InfinitTerminationListener : NSObject
{
@private
  pid_t _parent_pid;
  NSString* _app_path;
}

- (id)initWithParentProcessID:(pid_t)ppid
              installLocation:(NSString*)install_path;

@end

@implementation InfinitTerminationListener

- (id)initWithParentProcessID:(pid_t)ppid
              installLocation:(NSString*)install_path
{
  if ((self = [super init]))
  {
    _parent_pid = ppid;
    _app_path = [install_path copy];

    BOOL already_terminated = (getppid() == 1); // ppid is launchd (1) => parent terminated already

    if (already_terminated)
    {
      [self finishInstallationAndLaunchInfinit];
    }
    else
    {
      [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                             selector:@selector(applicationDidTerminate:)
                                                                 name:NSWorkspaceDidTerminateApplicationNotification
                                                               object:nil];
    }
  }
  return self;
}

- (void)applicationDidTerminate:(NSNotification*)notification
{
  NSDictionary* info = notification.userInfo;
  pid_t terminated_pid = [[info valueForKey:@"NSApplicationProcessIdentifier"] intValue];

  if (_parent_pid == terminated_pid)
    [self finishInstallationAndLaunchInfinit];
}

- (void)finishInstallationAndLaunchInfinit
{
  NSLog(@"Parent process (%d) has quit.", _parent_pid);
  NSLog(@"Finishing Installation of: %@", _app_path);

  NSError* error = nil;
  NSFileManager* mgr = [NSFileManager defaultManager];

  if ([mgr fileExistsAtPath:INFINIT_APP_PATH])
    [mgr removeItemAtPath:INFINIT_APP_PATH error:&error];

  [mgr copyItemAtPath:_app_path toPath:INFINIT_APP_PATH error:&error];

  [[NSWorkspace sharedWorkspace] launchApplication:INFINIT_APP_PATH];

  BOOL mounted_dmg = NO;

  NSArray* keys = [NSArray arrayWithObjects:NSURLVolumeNameKey, NSURLVolumeIsRemovableKey, nil];
  NSArray* urls =
  [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:keys options:0];
  for (NSURL* url in urls)
  {
    NSError* error;
    NSNumber* is_removable;
    NSString* volume_name;
    [url getResourceValue:&is_removable forKey:NSURLVolumeIsRemovableKey error:&error];
    if (is_removable.boolValue)
    {
      [url getResourceValue:&volume_name forKey:NSURLVolumeNameKey error:&error];
      if ([volume_name isEqualToString:@"Infinit"])
        mounted_dmg = YES;
    }
  }

  if (mounted_dmg)
  {
    NSString* script_str = @"\
    tell application \"Finder\"\n\
      tell disk \"Infinit\"\n\
        eject\n\
      end tell\n\
    end tell\n";
    NSAppleScript* eject_script = [[NSAppleScript alloc] initWithSource:script_str];
    [eject_script executeAndReturnError:nil];
  }

  [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (void)dealloc
{
  [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

@end


int main(int argc, const char * argv[])
{
  int status = EXIT_SUCCESS;
  @autoreleasepool
  {
    if (argc == 3)
    {
      pid_t parent_pid = atoi(argv[1]);
      NSString* app_path = [NSString stringWithUTF8String:argv[2]];
      BOOL app_exists = [[NSFileManager defaultManager] fileExistsAtPath:app_path];

      if (parent_pid != 0 && app_exists)
      {
        InfinitTerminationListener* listener;
        listener = [[InfinitTerminationListener alloc] initWithParentProcessID:parent_pid
                                                               installLocation:app_path];
        [[NSApplication sharedApplication] run];
      }
      else
      {
        NSLog(@"%s invalid arguments.", argv[0]);
        status = EXIT_FAILURE;
      }
    }
    else
    {
      NSLog(@"%s invalid number of arguments.", argv[0]);
      status = EXIT_FAILURE;
    }
  }
  return status;
}
