//
//  CXSocketManager.h
//  Pods
//
//  Created by wshaolin on 2018/6/21.
//

#import "CollectSvr.pbobjc.h"
#import "CXSocketDefines.h"

#define CX_SOCKET_VERSION_1_0_0 @"1.0.0"

@class CXSocketManager;
@class CXSocketMessageData;

NS_ASSUME_NONNULL_BEGIN

typedef void(^CXSocketMessageReceiptBlock)(CollectMessage * _Nullable receipt, NSError * _Nullable error);

@protocol CXSocketManagerDelegate <NSObject>

@optional

- (void)socketManager:(CXSocketManager *)socketManager
    didReceiveMessage:(nullable CollectMessage *)message
                error:(nullable NSError *)error;

- (void)socketManagerDidFinishLogin:(CXSocketManager *)socketManager;

- (void)socketManagerDidDisconnect:(CXSocketManager *)socketManager
                             error:(nullable NSError *)error;

- (void)socketManagerDidConsumeReconnectionTimes:(CXSocketManager *)socketManager;

@end

@protocol CXSocketManagerDataSource <NSObject>

@required

- (LoginRequest *)loginMessageInSocketManager:(CXSocketManager *)socketManager;

- (UserInfoMessage *)userInfoMessageInSocketManager:(CXSocketManager *)socketManager;

@end

@interface CXSocketManager : NSObject

@property (nonatomic, assign, readonly) BOOL isConnected;

@property (nonatomic, weak, nullable) id<CXSocketManagerDataSource> dataSource;
@property (nonatomic, weak, nullable) id<CXSocketManagerDelegate> delegate;

+ (instancetype)sharedManager;

- (CXSocketCode)connectWithURL:(NSString *)URL callback:(CXSocketCallback)callback;

- (CXSocketCode)reconnect:(BOOL)isAutoRetry;
- (CXSocketCode)disconnect;
- (BOOL)canReconnect;

- (CXSocketCode)sendMessageData:(CXSocketMessageData *)msgData;

@end

@interface CXSocketMessageData : NSObject

@property (nonatomic, strong, readonly) GPBMessage *msgData;
@property (nonatomic, assign, readonly) MessageType msgType;
@property (nonatomic, assign, readonly) uint64_t timeStamp;

/// Defaults NO，It is recommended to keep the default value.
@property (nonatomic, assign, getter = isReceiptEnabled) BOOL receiptEnabled;

@property (nonatomic, copy, nullable) CXSocketCallback sendCallback;
@property (nonatomic, copy, nullable) CXSocketMessageReceiptBlock receiptBlock; // Not implemented

- (instancetype)initWithMsgData:(nonnull GPBMessage *)msgData msgType:(MessageType)msgType;

@end

NS_ASSUME_NONNULL_END
