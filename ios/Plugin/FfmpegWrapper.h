//
//  FfmpegWrapper.h
//  Plugin
//
//  Created by Valentin Rentzsch  on 28.10.21.
//  Copyright © 2021 Max Lynch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FfmpegWrapper : NSObject

+(NSString *) executeCommand: (NSString *)command;

@end

NS_ASSUME_NONNULL_END
