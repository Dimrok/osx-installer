//
//  IIAppDelegate.m
//  InfinitInstaller
//
//  Created by Nick Jensen on 3/31/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "IIAppDelegate.h"
#import "SUCodeSigningVerifier.h"

#define INFINIT_BASE_URL @"http://download.infinit.io"
#define INFINIT_ERROR_DOMAIN @"com.infinit.io.error"
#define INFINIT_APP_NAME @"Infinit.app"
#define INFINIT_FINISHER_PATH @"InfinitInstallFinisher.app/Contents/MacOS/InfinitInstallFinisher"

#define SKIP_CODE_SIGNATURE_VALIDATION

@implementation IIAppDelegate

@synthesize statusLabel, progressBar, client, unarchiver;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    NSAssert([SUCodeSigningVerifier hostApplicationIsCodeSigned], @"This installer is not code signed");
    
    [self closeInstallerWindow];
    
    [statusLabel setStringValue:@"Checking for latest ..."];
    
    [AFKissXMLRequestOperation addAcceptableContentTypes:
     [NSSet setWithObject:@"application/rss+xml"]];
    
    client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:INFINIT_BASE_URL]];
    [client setStringEncoding:NSUTF8StringEncoding];
    [client registerHTTPOperationClass:[AFKissXMLRequestOperation class]];
    [client getPath:@"sparkle-cast.xml"
         parameters:nil
            success:^(AFHTTPRequestOperation *operation, id XML) {
    
                NSError *error = nil;
                NSArray *items = [XML nodesForXPath:@"//enclosure" error:&error];
                
                NSString *latestVersionURL = nil;
                NSInteger latestVersionNumber = 0;
                
                for (DDXMLElement *item in items) {
                    
                    NSString *versionString = [[item attributeForName:@"sparkle:version"] stringValue];
                    NSInteger versionNumber = [[versionString stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
                    
                    if (versionNumber > latestVersionNumber) {
                        
                        latestVersionNumber = versionNumber;
                        latestVersionURL = [[item attributeForName:@"url"] stringValue];
                    }
                }
                
                [self startDownloadingLatestBuildAtURL:[NSURL URLWithString:latestVersionURL]];
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                [self displayErrorMessage:[error localizedDescription] withTitle:@"Appcast Error"];
            }];
}

- (void)startDownloadingLatestBuildAtURL:(NSURL *)URL {
    
    NSAssert([[URL lastPathComponent] hasSuffix:@".dmg"], @"Invalid URL, not a dmg.");

    NSLog(@"Downloading %@", URL);
    
    [statusLabel setStringValue:
     [NSString stringWithFormat:@"Downloading %@ ...", [URL lastPathComponent]]];
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *temporaryPath = [NSTemporaryDirectory() stringByAppendingString:uuid];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:temporaryPath
                              withIntermediateDirectories:NO
                                               attributes:nil
                                                    error:nil];
    
    NSString *localFilePath = [temporaryPath stringByAppendingPathComponent:[URL lastPathComponent]];
    
    NSOutputStream *outputStream;
    outputStream = [NSOutputStream outputStreamToFileAtPath:localFilePath append:NO];
    
    NSMutableURLRequest *request;
    request = [[[NSMutableURLRequest alloc] initWithURL:URL] autorelease];
    [request setHTTPMethod:@"GET"];
    
    AFHTTPRequestOperation *download;
    download = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    [download setOutputStream:outputStream];
    [download setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        [progressBar setDoubleValue:((double)totalBytesRead / (double)totalBytesExpectedToRead)];
    }];
    [download setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [self extractDMGArchiveAtPath:localFilePath];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [self displayErrorMessage:[error localizedDescription] withTitle:@"Download Error"];
    }];
    [download start];
}

- (void)extractDMGArchiveAtPath:(NSString *)filePath {
    
    if (!unarchiver) {
        
        unarchiver = [[SUDiskImageUnarchiver unarchiverForPath:filePath] retain];
        [unarchiver setDelegate:self];
        
        [statusLabel setStringValue:
         [NSString stringWithFormat:@"Extracting %@ ...", [filePath lastPathComponent]]];
        
        [progressBar setIndeterminate:YES];
        [progressBar startAnimation:nil];
        
        [unarchiver start];
    }
}

- (void)unarchiverDidFinish:(SUUnarchiver *)unarchiver_ {

    NSString *archiveDirectory = [[unarchiver archivePath] stringByDeletingLastPathComponent];
    NSString *appPath = [archiveDirectory stringByAppendingPathComponent:INFINIT_APP_NAME];
    
#ifdef SKIP_CODE_SIGNATURE_VALIDATION
    BOOL hasValidCodeSigning = YES;
#else
    [statusLabel setStringValue:
     [NSString stringWithFormat:@"Verifying %@ ...", INFINIT_APP_NAME]];
    NSLog(@"Verifying code signature on %@", appPath);
    NSError *error = nil;
    BOOL hasValidCodeSigning = [SUCodeSigningVerifier codeSignatureIsValidAtPath:appPath error:&error];
    if (!hasValidCodeSigning) {
        
        [self displayErrorMessage:[error localizedDescription] withTitle:@"Verification Error"];
    }
#endif
    if (hasValidCodeSigning) {
        
        [self startFinisherProcessWithAppPath:appPath];
    }
}

- (void)unarchiverDidFail:(SUUnarchiver *)unarchiver_ {
    
    [self displayErrorMessage:@"Unable to extract DMG file." withTitle:@"Extract Error"];
}

- (void)startFinisherProcessWithAppPath:(NSString *)appPath {
    
    [statusLabel setStringValue:@"Finishing up ..."];
    
    NSString *finisherPath;
    finisherPath = [[[NSBundle mainBundle] sharedSupportPath]
                    stringByAppendingPathComponent:INFINIT_FINISHER_PATH];

    NSString *processID;
    processID = [NSString stringWithFormat:@"%d",
                 [[NSProcessInfo processInfo] processIdentifier]];
    
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects:processID, appPath, nil];
    
    NSTask *finisher;
    finisher = [NSTask launchedTaskWithLaunchPath:finisherPath
                                        arguments:arguments];
    [NSApp terminate:self];
}

- (void)closeInstallerWindow {
    
    NSAppleScript *scriptObject = [[NSAppleScript alloc] initWithSource:
                                   @"\
                                   tell application \"Finder\"\n\
                                        close Finder window \"Infinit Installer\"\n\
                                   end tell"];
    [scriptObject executeAndReturnError:nil];
    [scriptObject release];
}

- (void)displayErrorMessage:(NSString *)message withTitle:(NSString *)title {

    NSString *errorMessage;
    errorMessage = [NSString stringWithFormat:@"%@ - %@",
                    title, message];
    [statusLabel setStringValue:errorMessage];
    
    if ([progressBar isIndeterminate]) {

        [progressBar stopAnimation:nil];
        [progressBar setIndeterminate:NO];
        [progressBar setDoubleValue:1.0];
    }
}

- (void)dealloc {
    
    [client release];
    [unarchiver release];
    
    [super dealloc];
}

@end
