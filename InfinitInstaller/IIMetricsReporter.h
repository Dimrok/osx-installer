//
//  IIMetricsReporter.h
//  InfinitInstaller
//
//  Created by Christopher Crone on 16/09/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum __InfinitMetricType
{
  INFINIT_METRIC_START_INSTALL,
  INFINIT_METRIC_START_DOWNLOAD,
  INFINIT_METRIC_FINISH_DOWNLOAD,
  INFINIT_METRIC_FINISH_INSTALL,
}
InfinitMetricType;


@interface IIMetricsReporter : NSObject <NSURLConnectionDelegate>

+ (void)setDeviceId:(NSString*)device_id;
+ (void)sendMetric:(InfinitMetricType)metric;

@end
