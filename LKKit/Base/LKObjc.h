//
//  LKObjc.h
//  LKKit
//
//  Created by lingtonke on 16/6/8.
//  Copyright © 2016年 lingtonke. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LKObjc : NSObject


+ (void)lk_tryCatchFinally:(nullable void(^)())tryBlock catchBlock:(nullable void(^)( NSException * _Nonnull exception))catchBlock finallyBlock:(nullable void(^)())finallyBlock;

@end

@interface NSObject (LKKit)

- (void)lk_setAssociatedObject:(NSString * _Nonnull)key value:(id _Nonnull)value;

- (id _Nullable)lk_getAssociatedObject:(NSString * _Nonnull)key;
@end

@interface LKExceptionError : NSError

@property (nonatomic) NSException  * _Nonnull exception;

+ errorWithException:( NSException* _Nonnull )exception;
-(_Nonnull instancetype)initWithException:(NSException * _Nonnull)exception;

@end
