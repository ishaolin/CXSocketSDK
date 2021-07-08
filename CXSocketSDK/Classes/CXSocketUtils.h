//
//  CXSocketUtils.h
//  Pods
//
//  Created by wshaolin on 2018/12/26.
//

#import "CXSocketDefines.h"

@class GPBMessage;

@interface CXSocketUtils : NSObject

@end

CX_SOCKET_EXTERN GPBMessage *GPBMessageParseFromData(Class clazz, NSData *data, NSError **error);
