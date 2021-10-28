//
//  FfmpegWrapper.m
//  Plugin
//
//  Created by Valentin Rentzsch  on 28.10.21.
//  Copyright © 2021 Max Lynch. All rights reserved.
//

#include "FfmpegWrapper.h"


@implementation FfmpegWrapper

+ (NSString *) executeCommand:(NSString *)command {
//    NSLog(@"FFMPEG starting command");
//
//    FFmpegSession *session = [FFmpegKit execute:command];
//    ReturnCode *returnCode = [session getReturnCode];
//    if ([ReturnCode isSuccess:returnCode]) {
//        NSLog(@"FFMPEG sucess");
//        // SUCCESS
//
//    } else if ([ReturnCode isCancel:returnCode]) {
//        NSLog(@"FFMPEG cancel");
//        // CANCEL
//
//    } else {
//
//        // FAILURE
//        NSLog(@"FFMPEG fail");
//        NSLog(@"Command failed with state %@ and rc %@.%@", [FFmpegKitConfig sessionStateToString:[session getState]], returnCode, [session getFailStackTrace]);
//
//    }
    return command;
}

@end
