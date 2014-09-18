//
//  IIMetricsReporter.m
//  InfinitInstaller
//
//  Created by Christopher Crone on 16/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IIMetricsReporter.h"

#import <AFNetworking/AFNetworking.h>

#define INFINIT_METRICS_PROTOCOL @"http"
#define INFINIT_METRICS_HOST @"metrics.9.0.api.production.infinit.io"
#define INFINIT_METRICS_PORT 80
//#define INFINIT_METRICS_HOST @"127.0.0.1"
//#define INFINIT_METRICS_PORT 8282
#define INFINIT_METRICS_COLLECTION @"users"

static IIMetricsReporter* _instance = nil;

@implementation IIMetricsReporter
{
@private
  NSURL* _metrics_url;
  NSDictionary* _http_headers;
  NSString* _device_id;
}

//- Initialisation ---------------------------------------------------------------------------------

- (id)init
{
  if (self = [super init])
  {
    NSString* url_str =
      [NSString stringWithFormat:@"%@://%@:%d/%@",
       INFINIT_METRICS_PROTOCOL, INFINIT_METRICS_HOST, INFINIT_METRICS_PORT, INFINIT_METRICS_COLLECTION];
    _metrics_url = [[NSURL alloc] initWithString:url_str];
    NSString* version =
      [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString* user_agent = [[NSString alloc] initWithFormat:@"InfinitInstaller/%@ (OS X)", version];
    _http_headers = @{@"User-Agent": user_agent,
                      @"Content-Type": @"application/json"};
  }
  return self;
}

- (void)dealloc
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

+ (IIMetricsReporter*)sharedInstance
{
  if (_instance == nil)
    _instance = [[IIMetricsReporter alloc] init];
  return _instance;
}

+ (void)setDeviceId:(NSString*)device_id
{
  [[IIMetricsReporter sharedInstance] _setDeviceId:device_id];
}

- (void)_setDeviceId:(NSString*)device_id
{
  _device_id = device_id;
}

//- Send Metric ------------------------------------------------------------------------------------

+ (void)sendMetric:(InfinitMetricType)metric
{
  [[IIMetricsReporter sharedInstance] _sendMetric:metric];
}

- (void)_sendMetric:(InfinitMetricType)metric
{
  NSDate* now = [NSDate date];
  NSNumber* timestamp = [NSNumber numberWithDouble:now.timeIntervalSince1970];
  NSDictionary* metric_dict = @{
    @"event": [self _eventName:metric],
    @"os": @"OS X",
    @"os_version": [self _osVersionString],
    @"timestamp": timestamp,
    @"device_id": _device_id,
    @"user": @"unknown",
  };
  NSData* json_data = [NSJSONSerialization dataWithJSONObject:metric_dict options:0 error:nil];
  NSMutableURLRequest* request =
  [[NSMutableURLRequest alloc] initWithURL:_metrics_url
                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                           timeoutInterval:10.0];
  request.HTTPMethod = @"POST";
  request.HTTPBody = json_data;
  request.HTTPShouldUsePipelining = YES;
  [request setAllHTTPHeaderFields:_http_headers];
  NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  [connection start];
}

//- Helpers ----------------------------------------------------------------------------------------

- (NSString*)_eventName:(InfinitMetricType)metric
{
  switch (metric)
  {
    case INFINIT_METRIC_START_INSTALL:
      return @"installer/begin";
    case INFINIT_METRIC_START_DOWNLOAD:
      return @"installer/download_start";
    case INFINIT_METRIC_FINISH_DOWNLOAD:
      return @"installer/download_finish";
    case INFINIT_METRIC_FINISH_INSTALL:
      return @"installer/end";

    default:
      return @"installer/unknown";
  }
}

- (NSString*)_osVersionString
{
  NSNumber* major_version = [self _osMajorVersion];
  NSNumber* minor_version = [self _osMinorVersion];
  NSNumber* bugfix_version = [self _osBugfixVersion];
  if (major_version.integerValue == -1 ||
      minor_version.integerValue == -1 ||
      bugfix_version.integerValue == -1)
  {
    return @"Unknown";
  }
  else
  {
    return [NSString stringWithFormat:@"%@.%@.%@", major_version, minor_version, bugfix_version];
  }
}

- (NSNumber*)_osMajorVersion
{
  SInt32 major_version;
  if (Gestalt(gestaltSystemVersionMajor, &major_version) == noErr)
    return [NSNumber numberWithInt:major_version];
  else
    return nil;
}

- (NSNumber*)_osMinorVersion
{
  SInt32 minor_version;
  if (Gestalt(gestaltSystemVersionMinor, &minor_version) == noErr)
    return [NSNumber numberWithInt:minor_version];
  else
    return nil;
}

- (NSNumber*)_osBugfixVersion
{
  SInt32 bugfix_version;
  if (Gestalt(gestaltSystemVersionBugFix, &bugfix_version) == noErr)
    return [NSNumber numberWithInt:bugfix_version];
  else
    return nil;
}

//- NSURLConnectionDelegate ------------------------------------------------------------------------

- (void)connection:(NSURLConnection*)connection
  didFailWithError:(NSError*)error
{
  NSLog(@"%@: unable to sent metric: %@", self.description, error.description);
  // Do nothing
}

- (void)connection:(NSURLConnection*)connection
didReceiveResponse:(NSURLResponse*)response
{
  // Do nothing
}

@end
