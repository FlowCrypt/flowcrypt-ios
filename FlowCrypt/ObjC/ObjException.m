//
//  ObjException.m
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 25.01.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

#import "ObjException.h"

@implementation ObjException

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try
    {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception)
    {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

@end
