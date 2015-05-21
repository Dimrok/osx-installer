//
//  IICodeFinder.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 13/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "IICodeFinder.h"

@import DiskArbitration;
@import IOKit;

#define kInfinitFingerprintKey    @"INFINIT_FINGERPRINT"
#define kInfinitFingerprintLength 16

static IICodeFinder* _instance = nil;
static dispatch_once_t _instance_token = 0;

@implementation IICodeFinder

- (id)init
{
  NSCAssert(_instance == nil, @"Use sharedInstance.");
  if (self = [super init])
  {
  }
  return self;
}

+ (instancetype)sharedInstance
{
  dispatch_once(&_instance_token, ^
  {
    _instance = [[IICodeFinder alloc] init];
  });
  return _instance;
}

- (NSString*)dmgPath
{
  NSString* volume_path = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
  DASessionRef session = DASessionCreate(kCFAllocatorDefault);
  CFURLRef path_url = (__bridge CFURLRef)[NSURL URLWithString:volume_path];
  DADiskRef disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, path_url);
  CFRelease(session);
  if (!disk)
  {
    NSLog(@"Not in mounted volume");
#ifndef DEBUG
    NSString* title = NSLocalizedString(@"Launch the installer from the disk image", nil);
    NSString* message = NSLocalizedString(@"Reopen the disk image you downloaded and launch the installer directly from there. If you have any trouble, contact support@infinit.io.", nil);
    NSAlert* alert = [NSAlert alertWithMessageText:title
                                     defaultButton:NSLocalizedString(@"OK", nil)
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", message];
    [alert runModal];
    exit(0);
#endif
    return nil;
  }
  io_service_t service = DADiskCopyIOMedia(disk);
  CFRelease(disk);
  for (int i = 0; i < 4; i++)
  {
    io_service_t parent;
    IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent);
    IOObjectRelease(service);
    service = parent;
  }
  CFDictionaryRef characteristics =
    IORegistryEntryCreateCFProperty(service,
                                    CFSTR("Protocol Characteristics"),
                                    kCFAllocatorDefault,
                                    0);
  CFDataRef c_data = CFDictionaryGetValue(characteristics, CFSTR("Virtual Interface Location Path"));
  NSData* data = (__bridge NSData*)c_data;
  IOObjectRelease(service);
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString*)getCode
{
  NSString* path = [self dmgPath];
  if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    return nil;
  NSString* file = [NSString stringWithContentsOfFile:path
                                             encoding:NSASCIIStringEncoding
                                                error:nil];
  NSRange finger_range = [file rangeOfString:kInfinitFingerprintKey];
  if (finger_range.location == NSNotFound)
    return nil;
  NSRange code_range = NSMakeRange(finger_range.location + finger_range.length + 1,
                                   kInfinitFingerprintLength);
  return [file substringWithRange:code_range];
}

@end
