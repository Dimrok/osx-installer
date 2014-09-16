//
//  SUUnarchiver.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/16/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//


#import "SUUnarchiver.h"
#import "SUUnarchiver_Private.h"

@implementation SUUnarchiver
@synthesize delegate;

+ (instancetype)unarchiverForPath:(NSString *)path {

	return [[self alloc] initWithPath:path];
}

- (NSString *)archivePath {
    
    return archivePath;
}

- (NSString *)description { return [NSString stringWithFormat:@"%@ <%@>", [self class], archivePath]; }

- (void)start
{
	// No-op
}

@end
