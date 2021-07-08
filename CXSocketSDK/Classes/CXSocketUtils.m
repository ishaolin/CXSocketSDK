//
//  CXSocketUtils.m
//  Pods
//
//  Created by wshaolin on 2018/12/26.
//

#import "CXSocketUtils.h"
#import <CXFoundation/CXLog.h>

#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
#define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
#import <Protobuf/GPBProtocolBuffers.h>
#else
#import "GPBProtocolBuffers.h"
#endif

@implementation CXSocketUtils

@end

GPBMessage *GPBMessageParseFromData(Class clazz, NSData *data, NSError **error){
    if(!clazz || !data){
        return nil;
    }
    
    GPBMessage *message = nil;
    @try {
        message = [clazz parseFromData:data error:error];
    } @catch(NSException *exception) {
        LOG_FATEL(@"[socket] %@ message parse exception: %@", NSStringFromClass(clazz), exception);
    }
    
    return message;
}
