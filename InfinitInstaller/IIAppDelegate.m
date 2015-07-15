//
//  IIAppDelegate.m
//  InfinitInstaller
//
//  Created by Nick Jensen on 3/31/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IIAppDelegate.h"

#import "IICodeFinder.h"
#import "IIMetricsReporter.h"
#import "IIOnboardingButtonCell.h"
#import "IIOnboardingViewController1.h"
#import "IIOnboardingViewController2.h"
#import "IIOnboardingViewController3.h"
#import "IIOnboardingViewController4.h"
#import "IIOnboardingViewController5.h"
#import "IIOnboardingViewController6.h"
#import "IIOnboardingProgressView.h"

#import "InfinitColor.h"

#import "SUCodeSigningVerifier.h"

#define INFINIT_BASE_URL @"https://download.infinit.io/macosx/app"
#define INFINIT_APP_NAME @"Infinit.app"
#define INFINIT_FINISHER_PATH @"InfinitInstallFinisher.app/Contents/MacOS/InfinitInstallFinisher"
#define INFINIT_BUNDLE_IDENTIFIER @"io.infinit.InfinitApplication"

#ifdef DEBUG
# define SKIP_CODE_SIGNATURE_VALIDATION
#endif

@interface IIAppDelegate () <IIOnboardingViewController6Protocol,
                             NSApplicationDelegate,
                             SUUnarchiverDelegate>

@property (nonatomic, weak) IBOutlet NSButton* back_button;
@property (nonatomic, weak) IBOutlet NSButton* next_button;
@property (nonatomic, weak) IBOutlet NSView* onboarding_view;
@property (nonatomic, weak) IBOutlet IIOnboardingProgressView* progress_view;
@property (nonatomic, unsafe_unretained) IBOutlet NSWindow* window;

@property (nonatomic, strong) AFHTTPClient* client;
@property (nonatomic, readonly) NSString* code;
@property (nonatomic, readonly) NSString* device_id;
@property (nonatomic, readonly) double download_progress;
@property (nonatomic, readonly) NSString* launch_app_path;
@property (atomic, readwrite) BOOL reached_final;
@property (atomic, readwrite) BOOL ready_to_install;
@property (nonatomic, readonly) NSRunningApplication* running_infinit;
@property (nonatomic, strong) SUDiskImageUnarchiver* unarchiver;

@property (nonatomic, readonly) IIOnboardingAbstractViewController* current_onboarding;
@property (nonatomic, readonly) IIOnboardingViewController1* onboarding_1;
@property (nonatomic, readonly) IIOnboardingViewController2* onboarding_2;
@property (nonatomic, readonly) IIOnboardingViewController3* onboarding_3;
@property (nonatomic, readonly) IIOnboardingViewController4* onboarding_4;
@property (nonatomic, readonly) IIOnboardingViewController5* onboarding_5;
@property (nonatomic, readonly) IIOnboardingViewController6* onboarding_6;

@end

@implementation IIAppDelegate

@synthesize onboarding_1 = _onboarding_1;
@synthesize onboarding_2 = _onboarding_2;
@synthesize onboarding_3 = _onboarding_3;
@synthesize onboarding_4 = _onboarding_4;
@synthesize onboarding_5 = _onboarding_5;
@synthesize onboarding_6 = _onboarding_6;

- (id)init
{
  if (self = [super init])
  {
    _device_id = @"unknown";
    NSNotificationCenter* notification_center = [[NSWorkspace sharedWorkspace] notificationCenter];
    [notification_center addObserver:self
                            selector:@selector(anApplicationTerminated:)
                                name:NSWorkspaceDidTerminateApplicationNotification
                              object:nil];
    _launch_app_path = nil;
    self.ready_to_install = NO;
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
  self.window.alphaValue = 0.0f;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(150 * NSEC_PER_MSEC)),
                 dispatch_get_main_queue(), ^
  {
    [self.window center];
    self.window.alphaValue = 1.0f;
  });
  NSColor* text_color = [NSColor whiteColor];
  NSMutableAttributedString* back_str = [self.back_button.attributedTitle mutableCopy];
  [back_str addAttribute:NSForegroundColorAttributeName
                   value:text_color
                   range:NSMakeRange(0, back_str.string.length)];
  self.back_button.attributedTitle = back_str;
  ((IIOnboardingButtonCell*)self.back_button.cell).background_color =
  [InfinitColor colorWithGray:216];
  NSMutableAttributedString* next_str = [self.next_button.attributedTitle mutableCopy];
  [next_str addAttribute:NSForegroundColorAttributeName
                   value:text_color
                   range:NSMakeRange(0, next_str.length)];
  self.next_button.attributedTitle = next_str;
  ((IIOnboardingButtonCell*)self.next_button.cell).background_color =
    [InfinitColor colorFromPalette:InfinitPaletteColorBurntSienna];
  self.window.title = NSLocalizedString(@"Infinit", nil);
  [self.window standardWindowButton:NSWindowMiniaturizeButton].hidden =YES;
  [self.window standardWindowButton:NSWindowZoomButton].hidden = YES;
  [self showOnboardingController:self.onboarding_1 animated:NO reverse:NO];

  _code = [[IICodeFinder sharedInstance] getCode];
  [self ensureDeviceId];
  [IIMetricsReporter sendMetric:INFINIT_METRIC_START_INSTALL];

  self.window.level = NSFloatingWindowLevel;

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
  const char* data = getenv("INFINIT_HOME");
  NSString* infinit_dir_path = nil;
  if (data != NULL && data[0] != '\0')
    infinit_dir_path = [NSString stringWithUTF8String:data];
  if (infinit_dir_path.length == 0)
    infinit_dir_path = [NSHomeDirectory() stringByAppendingPathComponent:@".infinit"];
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
  NSCharacterSet* whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  BOOL make_device_id = NO;
  if (have_device_id)
  {
    _device_id = [NSString stringWithContentsOfFile:device_id_path
                                           encoding:NSUTF8StringEncoding
                                              error:nil];
    _device_id = [self.device_id stringByTrimmingCharactersInSet:whitespace];
    if (!self.device_id.length)
      make_device_id = YES;
    else
      NSLog(@"Read device_id: %@", self.device_id);
  }
  else
  {
    make_device_id = YES;
  }
  if (make_device_id)
  {
    _device_id = [[[NSUUID UUID] UUIDString] lowercaseString];
    [self.device_id writeToFile:device_id_path
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:nil];
    NSLog(@"Made device_id: %@", self.device_id);
  }
  _device_id = [self.device_id stringByTrimmingCharactersInSet:whitespace].lowercaseString;
  [IIMetricsReporter setDeviceId:self.device_id];
}

- (void)beginInstall
{
  [AFKissXMLRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"application/rss+xml"]];

  self.client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:INFINIT_BASE_URL]];
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
      NSString* version_str = [item attributeForName:@"sparkle:version"].stringValue;
      NSInteger version_num =
        [version_str stringByReplacingOccurrencesOfString:@"." withString:@""].intValue;
      if (version_num > latest_version_number)
      {
        latest_version_number = version_num;
        latest_version_url = [item attributeForName:@"url"].stringValue;
      }
    }
    [self startDownloadingLatestBuildAtURL:[NSURL URLWithString:latest_version_url]];
  } failure:^(AFHTTPRequestOperation* operation, NSError* error)
  {
    [self showErrorTitle:NSLocalizedString(@"Unable to fetch Infinit.dmg", nil)
                 message:NSLocalizedString(@"Please check your Internet connection and relaunch the installer. If this issue persists, contact support@infinit.io.", nil)];

  }];
}

- (void)startDownloadingLatestBuildAtURL:(NSURL*)url
{
  NSAssert([url.lastPathComponent hasSuffix:@".dmg"], @"Invalid URL, not a dmg.");

  NSLog(@"Downloading %@", url);
  [IIMetricsReporter sendMetric:INFINIT_METRIC_START_DOWNLOAD];

  NSString* uuid = [NSUUID UUID].UUIDString;
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
  [download setDownloadProgressBlock:^(NSUInteger bytes_read,
                                       long long total_bytes_read,
                                       long long total_bytes_expected)
  {
    _download_progress = (double)total_bytes_read / (double)total_bytes_expected;
  }];
  [download setCompletionBlockWithSuccess:^(AFHTTPRequestOperation* operation, id responseObject)
  {
    if (self.running_infinit)
      [self ensureOldInfinitKilled:self.running_infinit];
    [IIMetricsReporter sendMetric:INFINIT_METRIC_FINISH_DOWNLOAD];
    [self extractDMGArchiveAtPath:local_file_path];
  } failure:^(AFHTTPRequestOperation* operation, NSError* error)
  {
    [self showErrorTitle:NSLocalizedString(@"Unable to fetch Infinit.dmg", nil)
                 message:NSLocalizedString(@"Please check your Internet connection and relaunch the installer. If this issue persists, contact support@infinit.io.", nil)];
  }];
  [download start];
}

- (void)extractDMGArchiveAtPath:(NSString*)file_path
{
  if (!self.unarchiver)
  {
    self.unarchiver = [SUDiskImageUnarchiver unarchiverForPath:file_path];
    self.unarchiver.delegate = self;
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
    [self showErrorTitle:NSLocalizedString(@"Infinit not signed correctly", nil)
                 message:NSLocalizedString(@"The downloaded version of Infinit was not signed correctly. Try to relaunch the installer or contact support@infinit.io.", nil)];
    NSLog(@"Code sign error: %@", error.localizedDescription);
  }
#endif
  if (valid_codesign)
  {
    [IIMetricsReporter sendMetric:INFINIT_METRIC_FINISH_INSTALL];
    _launch_app_path = [app_path copy];
    self.ready_to_install = YES;
    if (self.reached_final)
      [self startFinisherProcess];
  }
}

- (void)unarchiverDidFail:(SUUnarchiver*)unarchiver_
{
  [self showErrorTitle:NSLocalizedString(@"Unable to extract Infinit", nil)
               message:NSLocalizedString(@"Unable to extract Infinit. Please relaunch the installer to try again. If this issue persists, contact support@infinit.io.", nil)];
}

- (void)startFinisherProcess
{
  if (!self.ready_to_install)
    return;
  static dispatch_once_t _install_token = 0;
  dispatch_once(&_install_token, ^
  {
    NSString* finisher_path =
      [[NSBundle mainBundle].sharedSupportPath stringByAppendingPathComponent:INFINIT_FINISHER_PATH];

    NSString* pid = [NSString stringWithFormat:@"%d", [NSProcessInfo processInfo].processIdentifier];

    NSMutableArray* arguments = [NSMutableArray arrayWithArray:@[pid, self.launch_app_path]];
    if (self.code.length)
      [arguments addObject:self.code];

    [NSTask launchedTaskWithLaunchPath:finisher_path arguments:arguments];
    // Wait for metrics to be sent.
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:1.5f];
  });
}

#pragma mark - Button Handling

- (IBAction)backClicked:(id)sender
{
  IIOnboardingAbstractViewController* last_controller = nil;
  switch (self.current_onboarding.screen_number)
  {
    case 2:
      last_controller = self.onboarding_1;
      break;
    case 3:
      last_controller = self.onboarding_2;
      break;
    case 4:
      last_controller = self.onboarding_3;
      break;
    case 5:
      last_controller = self.onboarding_4;
      break;
    case 6:
      last_controller = self.onboarding_5;
      break;

    default:
      return;
  }
  if (last_controller)
    [self showOnboardingController:last_controller animated:YES reverse:YES];
}

- (IBAction)nextClicked:(id)sender
{
  IIOnboardingAbstractViewController* next_controller = nil;
  switch (self.current_onboarding.screen_number)
  {
    case 1:
      next_controller = self.onboarding_2;
      break;
    case 2:
      next_controller = self.onboarding_3;
      break;
    case 3:
      next_controller = self.onboarding_4;
      break;
    case 4:
      next_controller = self.onboarding_5;
      break;
    case 5:
      if (self.ready_to_install)
      {
        self.back_button.enabled = NO;
        self.next_button.enabled = NO;
        [self startFinisherProcess];
        return;
      }
      else
      {
        next_controller = self.onboarding_6;
        break;
      }

    default:
      return;
  }
  if (next_controller)
    [self showOnboardingController:next_controller animated:YES reverse:NO];
}

#pragma mark - Onboarding Animations

- (void)showOnboardingController:(IIOnboardingAbstractViewController*)controller
                        animated:(BOOL)animate
                         reverse:(BOOL)reverse
{
  if (controller == self.current_onboarding)
    return;
  IIOnboardingAbstractViewController* old_onboarding = self.current_onboarding;
  _current_onboarding = controller;
  self.progress_view.progress_count = controller.screen_number;
  self.back_button.hidden = (controller.screen_number == 1);
  self.next_button.hidden = (controller.screen_number == 6);
  self.progress_view.hidden = (controller.screen_number == 6);
  if (controller.final_screen)
    self.reached_final = YES;
  if (old_onboarding)
    [old_onboarding aboutToAnimate];
  if (!animate)
  {
    [self.onboarding_view addSubview:controller.view];
    if (old_onboarding)
      [old_onboarding.view removeFromSuperview];
    [controller finishedAnimate];
    return;
  }
  [self.onboarding_view addSubview:controller.view
                        positioned:NSWindowAbove
                        relativeTo:old_onboarding.view];
  controller.view.alphaValue = 0.0f;
  CGFloat dx = self.onboarding_view.bounds.size.width;
  if (reverse)
    dx = -dx;
  controller.view.frame = NSMakeRect(dx,
                                     0.0f,
                                     controller.view.bounds.size.width,
                                     controller.view.bounds.size.height);
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context)
  {
    context.duration = 0.5f;
    if (old_onboarding)
    {
      old_onboarding.view.animator.alphaValue = 0.0f;
      old_onboarding.view.animator.frame = NSMakeRect(-dx,
                                                      0.0f,
                                                      controller.view.bounds.size.width,
                                                      controller.view.bounds.size.height);
    }
    controller.view.animator.alphaValue = 1.0f;
    controller.view.animator.frame = self.onboarding_view.bounds;
  } completionHandler:^
  {
    if (old_onboarding)
      [old_onboarding.view removeFromSuperview];
    [controller finishedAnimate];
  }];
}

#pragma mark - Progress Delegate

- (double)currentDownloadProgress
{
  return self.download_progress;
}

#pragma mark - Lazy Loaders

- (IIOnboardingViewController1*)onboarding_1
{
  if (!_onboarding_1)
  {
    NSString* name = NSStringFromClass(IIOnboardingViewController1.class);
    _onboarding_1 = [[IIOnboardingViewController1 alloc] initWithNibName:name bundle:nil];
  }
  return _onboarding_1;
}

- (IIOnboardingViewController2*)onboarding_2
{
  if (!_onboarding_2)
  {
    NSString* name = NSStringFromClass(IIOnboardingVideoAbstractViewController.class);
    _onboarding_2 = [[IIOnboardingViewController2 alloc] initWithNibName:name bundle:nil];
  }
  return _onboarding_2;
}

- (IIOnboardingViewController3*)onboarding_3
{
  if (!_onboarding_3)
  {
    NSString* name = NSStringFromClass(IIOnboardingVideoAbstractViewController.class);
    _onboarding_3 = [[IIOnboardingViewController3 alloc] initWithNibName:name bundle:nil];
  }
  return _onboarding_3;
}

- (IIOnboardingViewController4*)onboarding_4
{
  if (!_onboarding_4)
  {
    NSString* name = NSStringFromClass(IIOnboardingVideoAbstractViewController.class);
    _onboarding_4 = [[IIOnboardingViewController4 alloc] initWithNibName:name bundle:nil];
  }
  return _onboarding_4;
}

- (IIOnboardingViewController5*)onboarding_5
{
  if (!_onboarding_5)
  {
    NSString* name = NSStringFromClass(IIOnboardingViewController5.class);
    _onboarding_5 = [[IIOnboardingViewController5 alloc] initWithNibName:name bundle:nil];
  }
  return _onboarding_5;
}

- (IIOnboardingViewController6*)onboarding_6
{
  if (!_onboarding_6)
  {
    NSString* name = NSStringFromClass(IIOnboardingViewController6.class);
    _onboarding_6 = [[IIOnboardingViewController6 alloc] initWithNibName:name bundle:nil];
    _onboarding_6.delegate = self;
  }
  return _onboarding_6;
}

#pragma mark - Error

- (void)showErrorTitle:(NSString*)title
               message:(NSString*)message
{
  NSAlert* alert = [NSAlert alertWithMessageText:title
                                   defaultButton:NSLocalizedString(@"OK", nil)
                                 alternateButton:nil 
                                     otherButton:nil
                       informativeTextWithFormat:@"%@", message];
  [alert runModal];
  exit(0);
}

@end
