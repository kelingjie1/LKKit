//
//  LKKit.h
//  LKKit
//
//  Created by lingtonke on 16/6/16.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LKLog(x) [[LKLogManager shareInstance] log:x level:LKLogLevelMessage]
#define LKLogWarning(x) [[LKLogManager shareInstance] log:x level:LKLogLevelWarning]
#define LKLogError(x) [[LKLogManager shareInstance] log:x level:LKLogLevelError]
