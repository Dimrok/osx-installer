//
//  SUCodeSigningVerifier.m
//  Sparkle
//
//  Created by Andy Matuschak on 7/5/12.
//
//

#import <Security/CodeSigning.h>
#import <Security/SecCode.h>
#import "SUCodeSigningVerifier.h"

@implementation SUCodeSigningVerifier

+ (BOOL)codeSignatureIsValidAtPath:(NSString *)destinationPath error:(NSError *__autoreleasing *)error
{
  OSStatus result;
  SecRequirementRef requirement = NULL;
  SecStaticCodeRef staticCode = NULL;
  SecCodeRef hostCode = NULL;
  NSBundle *newBundle;
  CFErrorRef cfError = NULL;
  if (error) {
    *error = nil;
  }

  result = SecCodeCopySelf(kSecCSDefaultFlags, &hostCode);
  if (result != noErr) {
    NSLog(@"Failed to copy host code %d", result);
    goto finally;
  }

  result = SecCodeCopyDesignatedRequirement(hostCode, kSecCSDefaultFlags, &requirement);
  if (result != noErr) {
    NSLog(@"Failed to copy designated requirement. Code Signing OSStatus code: %d", result);
    goto finally;
  }

  newBundle = [NSBundle bundleWithPath:destinationPath];
  if (!newBundle) {
    NSLog(@"Failed to load NSBundle for update");
    result = -1;
    goto finally;
  }

  result = SecStaticCodeCreateWithPath((__bridge CFURLRef)[newBundle executableURL], kSecCSDefaultFlags, &staticCode);
  if (result != noErr) {
    NSLog(@"Failed to get static code %d", result);
    goto finally;
  }

  result = SecStaticCodeCheckValidityWithErrors(staticCode, kSecCSDefaultFlags | kSecCSCheckAllArchitectures, requirement, &cfError);

  if (cfError) {
    NSError *tmpError = CFBridgingRelease(cfError);
    if (error) *error = tmpError;
  }

  if (result != noErr) {
    if (result == errSecCSUnsigned) {
      NSLog(@"The host app is signed, but the new version of the app is not signed using Apple Code Signing. Please ensure that the new app is signed and that archiving did not corrupt the signature.");
    }
    if (result == errSecCSReqFailed) {
      CFStringRef requirementString = nil;
      if (SecRequirementCopyString(requirement, kSecCSDefaultFlags, &requirementString) == noErr) {
        NSLog(@"Code signature of the new version doesn't match the old version: %@. Please ensure that old and new app is signed using exactly the same certificate.", requirementString);
        CFRelease(requirementString);
      }

      [self logSigningInfoForCode:hostCode label:@"host info"];
      [self logSigningInfoForCode:staticCode label:@"new info"];
    }
  }

finally:
  if (hostCode) CFRelease(hostCode);
  if (staticCode) CFRelease(staticCode);
  if (requirement) CFRelease(requirement);
  return (result == noErr);
}

static id valueOrNSNull(id value) {
  return value ? value : [NSNull null];
}

+ (void)logSigningInfoForCode:(SecStaticCodeRef)code label:(NSString*)label {
  CFDictionaryRef signingInfo = nil;
  const SecCSFlags flags = kSecCSSigningInformation | kSecCSRequirementInformation | kSecCSDynamicInformation | kSecCSContentInformation;
  if (SecCodeCopySigningInformation(code, flags, &signingInfo) == noErr) {
    NSDictionary *signingDict = CFBridgingRelease(signingInfo);
    NSMutableDictionary *relevantInfo = [NSMutableDictionary dictionary];
    for (NSString *key in @[@"format", @"identifier", @"requirements", @"teamid", @"signing-time"]) {
      relevantInfo[key] = valueOrNSNull(signingDict[key]);
    }
    NSDictionary *infoPlist = signingDict[@"info-plist"];
    relevantInfo[@"version"] = valueOrNSNull(infoPlist[@"CFBundleShortVersionString"]);
    relevantInfo[@"build"] = valueOrNSNull(infoPlist[(__bridge NSString *)kCFBundleVersionKey]);
    NSLog(@"%@: %@", label, relevantInfo);
  }
}

+ (BOOL)hostApplicationIsCodeSigned
{
  OSStatus result;
  SecCodeRef hostCode = NULL;
  result = SecCodeCopySelf(kSecCSDefaultFlags, &hostCode);
  if (result != 0) return NO;

  SecRequirementRef requirement = NULL;
  result = SecCodeCopyDesignatedRequirement(hostCode, kSecCSDefaultFlags, &requirement);
  if (hostCode) CFRelease(hostCode);
  if (requirement) CFRelease(requirement);
  return (result == 0);
}

@end