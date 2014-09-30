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

#define INFINIT_VIDEO_PLAYS 2

//#define SKIP_CODE_SIGNATURE_VALIDATION

@implementation IIAppDelegate
{
@private
  NSString* _device_id;
  NSRunningApplication* _running_infinit;

  NSDictionary* _tagline_attrs;
  NSDictionary* _status_attrs;

  NSString* _launch_app_path;
  BOOL _finishing;
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
    NSMutableParagraphStyle* centered_style =
      [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    centered_style.alignment = NSCenterTextAlignment;
    NSFont* tagline_font = [NSFont fontWithName:@"Montserrat" size:16.0];
    NSFont* status_font = [NSFont fontWithName:@"Montserrat" size:14.0];
    _tagline_attrs = @{NSFontAttributeName: tagline_font,
                       NSParagraphStyleAttributeName: centered_style,
                       NSForegroundColorAttributeName: [self colourR:60 G:60 B:60 A:1.0]};
    _status_attrs = @{NSFontAttributeName: status_font,
                      NSParagraphStyleAttributeName: centered_style,
                      NSForegroundColorAttributeName: [self colourR:165 G:165 B:165 A:1.0]};
    _launch_app_path = nil;
    _finishing = NO;
  }
  return self;
}

- (NSColor*)colourR:(NSUInteger)red
                  G:(NSUInteger)green
                  B:(NSUInteger)blue
                  A:(CGFloat)alpha
{
  return [NSColor colorWithDeviceRed:(((CGFloat)red)/255.0)
                               green:(((CGFloat)green)/255.0)
                                blue:(((CGFloat)blue)/255.0)
                               alpha:alpha];
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)setStatusLabelString:(NSString*)str
{
  self.status_label.attributedStringValue =
    [[NSAttributedString alloc] initWithString:str
                                    attributes:_status_attrs];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
  self.tagline_label.attributedStringValue =
    [[NSAttributedString alloc] initWithString:NSLocalizedString(@"WELCOME TO INFINIT", nil)
                                    attributes:_tagline_attrs];
  [self setStatusLabelString:NSLocalizedString(@"DOWNLOADING...", nil)];
  [self ensureDeviceId];
  [IIMetricsReporter sendMetric:INFINIT_METRIC_START_INSTALL];

  self.video_view.delegate = self;
  self.video_view.url =
    [[NSBundle mainBundle] URLForResource:@"tutorial_send" withExtension:@"mp4"];

  [self.video_view play];

  self.window.level = NSFloatingWindowLevel;

  self.progress_bar.indeterminate = YES;
  [self.progress_bar startAnimation:nil];

  _running_infinit = nil;

  for (NSRunningApplication* app in [[NSWorkspace sharedWorkspace] runningApplications])
  {
    if ([app.bundleIdentifier isEqualToString:INFINIT_BUNDLE_IDENTIFIER] &&
        ![app isEqual:[NSRunningApplication currentApplication]])
    {
      NSLog(@"Found running Infinit, will terminate");
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
    _device_id = [[[NSUUID UUID] UUIDString] lowercaseString];
    [_device_id writeToFile:device_id_path
                 atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:nil];
    NSLog(@"Made device_id: %@", _device_id);
  }
  _device_id =
    [[_device_id stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
  [IIMetricsReporter setDeviceId:_device_id];
}

- (void)beginInstall
{
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


    [self setStatusLabelString:NSLocalizedString(@"INSTALLING...", nil)];

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
    [IIMetricsReporter sendMetric:INFINIT_METRIC_FINISH_INSTALL];
    _launch_app_path = [app_path copy];
    if (self.video_view.play_count >= INFINIT_VIDEO_PLAYS)
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
  if (_finishing)
    return;
  _finishing = YES;
  NSString* finisher_path =
    [[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:INFINIT_FINISHER_PATH];

  NSString* pid = [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]];

  NSArray* arguments = @[pid, app_path];

  [NSTask launchedTaskWithLaunchPath:finisher_path arguments:arguments];
  // Wait for metrics to be sent.
  [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:1.5];
}

- (void)displayErrorMessage:(NSString*)message
                  withTitle:(NSString*)title
{
  NSString* error_msg = [NSString stringWithFormat:@"%@ - %@", title, message];
  [self setStatusLabelString:error_msg.uppercaseString];

  if (self.progress_bar.isIndeterminate)
  {
    [self.progress_bar stopAnimation:nil];
    self.progress_bar.indeterminate = NO;
    self.progress_bar.doubleValue = 1.0;
  }
}

//- Video Player Protocol --------------------------------------------------------------------------

- (void)finishedPlayOfVideo:(IIVideoPlayerView*)sender
{
  if (_launch_app_path && self.video_view.play_count >= INFINIT_VIDEO_PLAYS)
    [self startFinisherProcessWithAppPath:_launch_app_path];
}

@end
