//
//  CXSocketDefines.h
//  Pods
//
//  Created by wshaolin on 2018/12/26.
//

#ifndef CXSocketDefines_h
#define CXSocketDefines_h

#import <Foundation/Foundation.h>

#if defined(__cplusplus)
#define CX_SOCKET_EXTERN   extern "C"
#else
#define CX_SOCKET_EXTERN   extern
#endif

typedef NS_ENUM(NSInteger, CXSocketCode) {
    CXSocketCodeOK,
    CXSocketCodeBadParam,
    CXSocketCodeInternalError,
    CXSocketCodeNotConnected,
    CXSocketCodeConnectionExisted,
    CXSocketCodeServiceUnavailable,
    CXSocketCodeTimeout
};

typedef void(^CXSocketCallback)(CXSocketCode code, NSError * _Nullable error);

#endif /* CXSocketDefines_h */
