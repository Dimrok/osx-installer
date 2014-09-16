//
//  SUUnarchiver_Private.m
//  Sparkle
//
//  Created by Andy Matuschak on 6/17/08.
//  Copyright 2008 Andy Matuschak. All rights reserved.
//

#import "SUUnarchiver_Private.h"

@implementation SUUnarchiver (Private)

- (id)initWithPath:(NSString *)path
{
	if ((self = [super init]))
	{
		archivePath = [path copy];
	}
	return self;
}

+ (BOOL)canUnarchivePath:(NSString *)path
{
	return NO;
}

- (void)notifyDelegateOfExtractedLength:(NSNumber *)length
{
	if ([self.delegate respondsToSelector:@selector(unarchiver:extractedLength:)])
		[self.delegate unarchiver:self extractedLength:[length unsignedLongValue]];
}

- (void)notifyDelegateOfSuccess
{
	if ([self.delegate respondsToSelector:@selector(unarchiverDidFinish:)])
		[self.delegate performSelector:@selector(unarchiverDidFinish:) withObject:self];
}

- (void)notifyDelegateOfFailure
{
	if ([self.delegate respondsToSelector:@selector(unarchiverDidFail:)])
		[self.delegate performSelector:@selector(unarchiverDidFail:) withObject:self];
}

static NSMutableArray *gUnarchiverImplementations;

+ (void)registerImplementation:(Class)implementation
{
	if (!gUnarchiverImplementations)
		gUnarchiverImplementations = [[NSMutableArray alloc] init];
	[gUnarchiverImplementations addObject:implementation];
}

+ (NSArray *)unarchiverImplementations
{
	return [NSArray arrayWithArray:gUnarchiverImplementations];
}

@end
