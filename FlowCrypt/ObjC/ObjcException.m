//
//  ObjcException.m
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 25.01.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

#import "ObjcException.h"

@implementation ObjcException

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try
    {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception)
    {
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        if (exception.userInfo != NULL)
        {
            userInfo = [[NSMutableDictionary alloc] initWithDictionary:exception.userInfo];
        }

        if (exception.reason != nil)
        {
            if (![userInfo.allKeys containsObject:NSLocalizedFailureReasonErrorKey])
            {
                [userInfo setObject:exception.reason forKey:NSLocalizedFailureReasonErrorKey];
            }
        }

        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:userInfo];
        return NO;
    }
}

@end
