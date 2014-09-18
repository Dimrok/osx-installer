//
//  IIAppDelegate.m
//  InfinitInstaller
//
//  Created by Nick Jensen on 3/31/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IIAppDelegate.h"
#import "IIMetricsReporter.h"
#import "SUCodeSigningVerifier.h"

#define INFINIT_BASE_URL @"http://download.infinit.io"
#define INFINIT_ERROR_DOMAIN @"com.infinit.io.error"
#define INFINIT_APP_NAME @"Infinit.app"
#define INFINIT_FINISHER_PATH @"InfinitInstallFinisher.app/Contents/MacOS/InfinitInstallFinisher"
#define INFINIT_BUNDLE_IDENTIFIER @"io.infinit.InfinitApplication"

//#define SKIP_CODE_SIGNATURE_VALIDATION

@implementation IIAppDelegate
{
@private
  NSString* _device_id;
  NSRunningApplication* _running_infinit;
}

- (id)init
{
  if (self = [super init])
  {
    _device_id = @"unknown";
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(anApplicationTerminated:)
                                                               name:NSWorkspaceDidTerminateApplicationNotification
                                                             object:nil];
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
  [self ensureDeviceId];
  [IIMetricsReporter sendMetric:INFINIT_METRIC_START_INSTALL];

  self.window.level = NSFloatingWindowLevel;

  self.pacman.animate = YES;
  self.progress_bar.indeterminate = YES;
  [self.progress_bar startAnimation:nil];

  _running_infinit = nil;

  for (NSRunningApplication* app in [[NSWorkspace sharedWorkspace] runningApplications])
  {
    if ([app.bundleIdentifier isEqualToString:INFINIT_BUNDLE_IDENTIFIER] &&
        ![app isEqual:[NSRunningApplication currentApplication]])
    {
      NSLog(@"Found running Infinit, will terminate");
      self.status_label.stringValue = NSLocalizedString(@"Quitting existing Infinit...", nil);
      _running_infinit = app;
      [app terminate];
    }
  }
  [self beginInstall];
}

- (void)anApplicationTerminated:(NSNotification*)notification
{
  NSDictionary* user_info = notification.userInfo;
  NSRunningApplication* app = [user_info valueForKey:@"NSWorkspaceApplicationKey"];
  if ([[app bundleIdentifier] isEqualToString:INFINIT_BUNDLE_IDENTIFIER])
  {
    NSLog(@"Got notification for termination of existing Infinit");
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(ensureOldInfinitKilled:)
                                               object:app];
  }
}

- (void)ensureOldInfinitKilled:(NSRunningApplication*)app
{
  if (app.terminated)
  {
    NSLog(@"Exisiting Infinit already terminated");
  }
  else
  {
    NSLog(@"Force terminating exiting Infinit");
    [app forceTerminate];
  }
}

- (void)ensureDeviceId
{
  NSString* infinit_dir_path = [NSHomeDirectory() stringByAppendingPathComponent:@".infinit"];
  BOOL have_infinit_dir =
  [[NSFileManager defaultManager] fileExistsAtPath:infinit_dir_path isDirectory:nil];
  if (!have_infinit_dir)
  {
    [[NSFileManager defaultManager] createDirectoryAtPath:infinit_dir_path
                              withIntermediateDirectories:NO
                                               attributes:nil
                                                    error:nil];
  }
  NSString* device_id_path = [infinit_dir_path stringByAppendingPathComponent:@"device.uuid"];
  BOOL have_device_id = [[NSFileManager defaultManager] fileExistsAtPath:device_id_path
                                                             isDirectory:nil];
  BOOL make_device_id = NO;
  if (have_device_id)
  {
    _device_id = [NSString stringWithContentsOfFile:device_id_path
                                           encoding:NSUTF8StringEncoding
                                              error:nil];
    _device_id =
      [_device_id stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (_device_id.length == 0)
      make_device_id = YES;
    else
      NSLog(@"Read device_id: %@", _device_id);
  }
  else
  {
    make_device_id = YES;
  }
  if (make_device_id)
  {
    _device_id = [[NSUUID UUID] UUIDString];
    [_device_id writeToFile:device_id_path
                 atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:nil];
    NSLog(@"Made device_id: %@", _device_id);
  }
  _device_id =
    [_device_id stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [IIMetricsReporter setDeviceId:_device_id];
}

- (void)beginInstall
{
  self.status_label.stringValue = NSLocalizedString(@"Checking for latest...", nil);

  [AFKissXMLRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"application/rss+xml"]];

  self.client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:INFINIT_BASE_URL]];
  self.client.stringEncoding = NSUTF8StringEncoding;
  [self.client registerHTTPOperationClass:[AFKissXMLRequestOperation class]];
  [self.client getPath:@"sparkle-cast.xml"
            parameters:nil
               success:^(AFHTTPRequestOperation* operation, id XML)
   {

     NSError* error = nil;
     NSArray* items = [XML nodesForXPath:@"//enclosure" error:&error];

     NSString* latest_version_url = nil;
     NSInteger latest_version_number = 0;

     for (DDXMLElement* item in items)
     {

       NSString* version_str = [[item attributeForName:@"sparkle:version"] stringValue];
       NSInteger version_num =
       [[version_str stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];

       if (version_num > latest_version_number)
       {
         latest_version_number = version_num;
         latest_version_url = [[item attributeForName:@"url"] stringValue];
       }
     }

     [self startDownloadingLatestBuildAtURL:[NSURL URLWithString:latest_version_url]];
   }
               failure:^(AFHTTPRequestOperation* operation, NSError* error)
   {
     [self displayErrorMessage:[error localizedDescription] withTitle:@"Appcast Error"];
   }];
}

- (void)startDownloadingLatestBuildAtURL:(NSURL*)url
{
  NSAssert([url.lastPathComponent hasSuffix:@".dmg"], @"Invalid URL, not a dmg.");

  NSLog(@"Downloading %@", url);
  [IIMetricsReporter sendMetric:INFINIT_METRIC_START_DOWNLOAD];

  NSString* app_name = [url.lastPathComponent stringByDeletingPathExtension];

  self.status_label.stringValue =
    [NSString stringWithFormat:@"%@ %@...", NSLocalizedString(@"Downloading", nil), app_name];

  NSString* uuid = [[NSUUID UUID] UUIDString];
  NSString* temp_path = [NSTemporaryDirectory() stringByAppendingString:uuid];

  [[NSFileManager defaultManager] createDirectoryAtPath:temp_path
                            withIntermediateDirectories:NO
                                             attributes:nil
                                                  error:nil];

  NSString* local_file_path = [temp_path stringByAppendingPathComponent:url.lastPathComponent];

  NSOutputStream* output_stream =
    [NSOutputStream outputStreamToFileAtPath:local_file_path append:NO];

  NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
  request.HTTPMethod = @"GET";

  AFHTTPRequestOperation* download = [[AFHTTPRequestOperation alloc] initWithRequest:request];
  download.outputStream = output_stream;
  [download setDownloadProgressBlock:^(NSUInteger bytes_read, long long total_bytes_read, long long total_bytes_expected)
  {
    self.progress_bar.doubleValue = (double)total_bytes_read / (double)total_bytes_expected;
  }];
  [download setCompletionBlockWithSuccess:^(AFHTTPRequestOperation* operation, id responseObject)
  {
    if (_running_infinit)
      [self ensureOldInfinitKilled:_running_infinit];
    [IIMetricsReporter sendMetric:INFINIT_METRIC_FINISH_DOWNLOAD];
    [self extractDMGArchiveAtPath:local_file_path];
  }
                                  failure:^(AFHTTPRequestOperation* operation, NSError* error)
  {
    [self displayErrorMessage:error.localizedDescription withTitle:@"Download Error"];
  }];
  [self.progress_bar stopAnimation:nil];
  self.progress_bar.indeterminate = NO;
  self.progress_bar.doubleValue = 0.0;
  [download start];
}

- (void)extractDMGArchiveAtPath:(NSString*)file_path
{
  if (!self.unarchiver)
  {
    self.unarchiver = [SUDiskImageUnarchiver unarchiverForPath:file_path];
    self.unarchiver.delegate = self;

    NSString* app_name = [file_path.lastPathComponent stringByDeletingPathExtension];

    self.status_label.stringValue =
      [NSString stringWithFormat:@"%@ %@...", NSLocalizedString(@"Extracting", nil), app_name];

    self.progress_bar.indeterminate = YES;
    [self.progress_bar startAnimation:nil];

    [self.unarchiver start];
  }
}

- (void)unarchiverDidFinish:(SUUnarchiver*)unarchiver_
{
  NSString* archive_dir = [self.unarchiver.archivePath stringByDeletingLastPathComponent];
  NSString* app_path = [archive_dir stringByAppendingPathComponent:INFINIT_APP_NAME];

#ifdef SKIP_CODE_SIGNATURE_VALIDATION
  BOOL valid_codesign = YES;
#else
  NSString* app_name = [INFINIT_APP_NAME stringByDeletingPathExtension];
  self.status_label.stringValue =
    [NSString stringWithFormat:@"%@ %@...", NSLocalizedString(@"Verifying", nil), app_name];
  NSLog(@"Verifying code signature on %@", app_path);
  NSError* error = nil;
  BOOL valid_codesign = [SUCodeSigningVerifier codeSignatureIsValidAtPath:app_path error:&error];
  if (!valid_codesign)
  {
    [self displayErrorMessage:error.localizedDescription
                    withTitle:NSLocalizedString(@"Verification Error", nil)];
    NSLog(@"Code sign error: %@", error.localizedDescription);
  }
#endif
  if (valid_codesign)
  {
    [self startFinisherProcessWithAppPath:app_path];
  }
}

- (void)unarchiverDidFail:(SUUnarchiver*)unarchiver_
{
  [self displayErrorMessage:NSLocalizedString(@"Unable to extract DMG file.", nil)
                  withTitle:NSLocalizedString(@"Extract Error", nil)];
}

- (void)startFinisherProcessWithAppPath:(NSString*)app_path
{
  [IIMetricsReporter sendMetric:INFINIT_METRIC_FINISH_INSTALL];
  self.status_label.stringValue = NSLocalizedString(@"Installing...", nil);

  NSString* finisher_path =
    [[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:INFINIT_FINISHER_PATH];

  NSString* pid = [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]];

  NSArray* arguments = @[pid, app_path];

  [NSTask launchedTaskWithLaunchPath:finisher_path arguments:arguments];
  // Wait for metrics to be sent.
  [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:5.0];
}

- (void)displayErrorMessage:(NSString*)message
                  withTitle:(NSString*)title
{
  NSString* error_msg = [NSString stringWithFormat:@"%@ - %@", title, message];
  self.status_label.stringValue = error_msg;

  if (self.progress_bar.isIndeterminate)
  {
    [self.progress_bar stopAnimation:nil];
    self.progress_bar.indeterminate = NO;
    self.progress_bar.doubleValue = 1.0;
  }
}

@end
