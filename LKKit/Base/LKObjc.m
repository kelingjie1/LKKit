//
//  LKObjc.m
//  LKKit
//
//  Created by lingtonke on 16/6/8.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

#import "LKObjc.h"
#import <objc/runtime.h>

@implementation LKObjc

+ (void)lk_tryCatchFinally:(void (^)())tryBlock catchBlock:(void (^)(NSException *exception))catchBlock finallyBlock:(void (^)())finallyBlock
{
    @try
    {
        if (tryBlock)
        {
            tryBlock();
        }
    }
    @catch (NSException *exception)
    {
        if (catchBlock)
        {
            catchBlock(exception);
        }
    }
    @finally
    {
        if (finallyBlock)
        {
            finallyBlock();
        }
    }
}


@end

@implementation NSObject (LKKit)

- (void)lk_setAssociatedObject:(NSString * _Nonnull)key value:(id _Nonnull)value
{
    objc_setAssociatedObject(self, [key UTF8String], value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id _Nullable)lk_getAssociatedObject:(NSString * _Nonnull)key
{
    return objc_getAssociatedObject(self, [key UTF8String]);
}

@end


@implementation LKExceptionError

+ (id)errorWithException:(NSException *)exception
{
    LKExceptionError *error = [[LKExceptionError alloc] initWithException:exception];
    return error;
}

- (instancetype)initWithException:(NSException *)exception
{
    if (self = [super initWithDomain:exception.name code:-1 userInfo:exception.userInfo])
    {
        self.exception = exception;
    }
    return self;
}

@end