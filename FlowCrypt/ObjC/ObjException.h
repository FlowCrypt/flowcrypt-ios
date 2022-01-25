//
//  ObjException.h
//  FlowCrypt
//
//  Created by  Ivan Ushakov on 25.01.2022
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObjException : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end

NS_ASSUME_NONNULL_END
