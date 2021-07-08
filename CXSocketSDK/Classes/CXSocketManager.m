//
//  CXSocketManager.m
//  Pods
//
//  Created by wshaolin on 2018/6/21.
//

#import "CXSocketManager.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "CXSocketMessageParser.h"
#import <CXFoundation/CXFoundation.h>
#import "CXSocketUtils.h"

#define SOCKET_MSG_SEND_TIMEOUT          10.0    // 写数据超时时间
#define SOCKET_MSG_READ_TIMEOUT          -1.0    // 读数据超时时间，不超时
#define SOCKET_CONNECT_TIMEOUT           10.0    // 连接超时时间
#define SOCKET_RECONNECT_TIMEOUT         5.0     // 自动重连时间
#define SOCKET_RECONNECT_COUNT           5       // 自动重连次数
#define SOCKET_MSG_WAIT_RECEIPT_TIMEOUT  10.0    // 等待回执的超时时间
#define SOCKET_CACHE_CONNECTION_URL_KEY  @"SOCKET_CACHE_CONNECTION_URL_KEY"

static inline void SocketCacheConnectionURLSet(NSURL *URL){
    [[NSUserDefaults standardUserDefaults] setURL:URL forKey:SOCKET_CACHE_CONNECTION_URL_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static inline NSURL *SocketCacheConnectionURLGet(void){
    return [[NSUserDefaults standardUserDefaults] URLForKey:SOCKET_CACHE_CONNECTION_URL_KEY];
}

@interface CXSocketManager () <GCDAsyncSocketDelegate, CXSocketMessageParserDelegate> {
    GCDAsyncSocket *_asyncSocket;
    NSMutableDictionary<NSNumber *, CXSocketMessageData *> *_messageQueue;
    long _writeTag;
    int32_t _heartbeatSeqId;
    NSInteger _reconnectCount;
    NSTimer *_heartbeatTimer;
    NSTimer *_reconnectTimer;
    CXSocketMessageParser *_messageParser;
    NSMutableDictionary<NSNumber *, NSNumber *> *_receiptRelations;
    NSURL *_connectURL;
}

@property (nonatomic, copy) CXSocketCallback connectionCallback;

@end

@implementation CXSocketManager

+ (instancetype)sharedManager{
    static CXSocketManager *_socketManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _socketManager = [[self alloc] init];
    });
    
    return _socketManager;
}

- (instancetype)init{
    if(self = [super init]){
        _messageQueue = [NSMutableDictionary dictionary];
        
        _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        _messageParser = [[CXSocketMessageParser alloc] initWithParseType:CXSocketDataParseRawVarint32];
        _messageParser.delegate = self;
        
        _receiptRelations = [NSMutableDictionary dictionary];
        _receiptRelations[@(MessageType_LoginResponse)] = @(MessageType_LoginRequest);
        _receiptRelations[@(MessageType_Userinforesponse)] = @(MessageType_Userinfo);
        
        SocketCacheConnectionURLSet(nil);
    }
    
    return self;
}

- (CXSocketCode)connectWithURL:(NSString *)URLString callback:(CXSocketCallback)callback{
    NSURL *URL = [NSURL URLWithString:URLString];
    if(!URL || !URL.host || !URL.port){
        return CXSocketCodeBadParam;
    }
    
    self.connectionCallback = callback;
    CXSocketCode code = [self privateConnectWithURL:URL];
    if(code != CXSocketCodeOK){
        self.connectionCallback = nil;
    }
    
    return code;
}

- (CXSocketCode)privateConnectWithURL:(NSURL *)URL{
    if(self.isConnected){
        return CXSocketCodeConnectionExisted;
    }
    
    _connectURL = URL;
    if([_asyncSocket connectToHost:_connectURL.host
                            onPort:_connectURL.port.intValue
                       withTimeout:SOCKET_CONNECT_TIMEOUT
                             error:nil]){
        return CXSocketCodeOK;
    }else{
        return CXSocketCodeInternalError;
    }
}

- (CXSocketCode)sendMessageData:(CXSocketMessageData *)msgData{
    return [self sendMessageData:msgData timeout:SOCKET_MSG_SEND_TIMEOUT];
}

- (CXSocketCode)sendMessageData:(CXSocketMessageData *)msgData timeout:(NSTimeInterval)timeout{
    if(!msgData){
        return CXSocketCodeBadParam;
    }
    
    if(!_asyncSocket.isConnected){
        return CXSocketCodeNotConnected;
    }
    
    long tag = _writeTag ++;
    CollectMessage *message = [CollectMessage message];
    message.data_p = msgData.msgData.data;
    message.messageType = msgData.msgType;
    _messageQueue[@(tag)] = msgData;
    
    [_asyncSocket writeData:message.delimitedData withTimeout:timeout tag:tag];
    [self removeWaitForReceiptTimeoutMessageDataIfNeed];
    
    return CXSocketCodeOK;
}

- (void)removeWaitForReceiptTimeoutMessageDataIfNeed{
    if(_messageQueue.count < 2){
        return;
    }
    
    NSMutableArray<NSNumber *> *timeoutMessageKeys = [NSMutableArray array];
    uint64_t timeStamp = (uint64_t)([NSDate date].timeIntervalSince1970 * 1000);
    [_messageQueue enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, CXSocketMessageData * _Nonnull obj, BOOL * _Nonnull stop) {
        if(!obj.isReceiptEnabled){
            return;
        }
        
        if(timeStamp - obj.timeStamp > SOCKET_MSG_WAIT_RECEIPT_TIMEOUT * 1000){
            [timeoutMessageKeys addObject:key];
        }
    }];
    
    if(timeoutMessageKeys.count > 0){
        [_messageQueue removeObjectsForKeys:timeoutMessageKeys];
    }
}

- (void)invokeMessageSendCallback:(CXSocketCode)code tag:(long)tag error:(NSError *)error{
    CXSocketMessageData *messageData = _messageQueue[@(tag)];
    if(!messageData){
        return;
    }
    
    if(messageData.sendCallback){
        messageData.sendCallback(code, error);
    }
    
    if(messageData.isReceiptEnabled && messageData.receiptBlock){
        return;
    }
    
    [_messageQueue removeObjectForKey:@(tag)];
}

- (void)invokeMessageReceiptBlock:(CollectMessage *)receipt error:(NSError *)error{
    NSNumber *messageType = _receiptRelations[@(receipt.messageType)];
    if(!messageType){
        return;
    }
    
    __block CXSocketMessageData *messageData = nil;
    __block NSNumber *dataKey = nil;
    [_messageQueue enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, CXSocketMessageData * _Nonnull obj, BOOL * _Nonnull stop) {
        if(obj.msgType == messageType.intValue){
            messageData = obj;
            dataKey = key;
            *stop = YES;
        }
    }];
    
    if(!messageData){
        return;
    }
    
    if(messageData.isReceiptEnabled){
        !messageData.receiptBlock ?: messageData.receiptBlock(receipt, error);
    }
    
    [_messageQueue removeObjectForKey:dataKey];
}

- (BOOL)isConnected{
    return _asyncSocket.isConnected;
}

- (CXSocketCode)reconnect:(BOOL)isAutoRetry{
    NSURL *URL = SocketCacheConnectionURLGet();
    if(!URL){
        return CXSocketCodeBadParam;
    }
    
    if(!isAutoRetry){
        return [self privateConnectWithURL:URL];
    }
    
    [self addReconnectTimer];
    return CXSocketCodeOK;
}

- (CXSocketCode)disconnect{
    _connectURL = nil;
    SocketCacheConnectionURLSet(nil);
    
    if(_asyncSocket.isDisconnected){
        return CXSocketCodeNotConnected;
    }
    
    [_asyncSocket disconnect];
    return CXSocketCodeOK;
}

- (BOOL)canReconnect{
    if(self.isConnected){
        return NO;
    }
    
    return SocketCacheConnectionURLGet() != nil;
}

- (void)socketMessageParser:(CXSocketMessageParser *)parser didParseMessage:(NSData *)data{
    NSError *error = nil;
    CollectMessage *message = (CollectMessage *)GPBMessageParseFromData([CollectMessage class], data, &error);
    if(message.messageType != MessageType_LoginResponse &&
       message.messageType != MessageType_Pong &&
       message.messageType != MessageType_Userinforesponse){
        if(message.messageType == MessageType_Closechannel){
            SocketCacheConnectionURLSet(nil);
        }
        
        if([self.delegate respondsToSelector:@selector(socketManager:didReceiveMessage:error:)]){
            [self.delegate socketManager:self didReceiveMessage:message error:error];
        }
    }
    
    if(message.messageType == MessageType_Pong){
        LOG_INFO(@"[socket] receive pong message.");
    }
    
    [self invokeMessageReceiptBlock:message error:error];
    [self removeWaitForReceiptTimeoutMessageDataIfNeed];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)socket didReadData:(NSData *)data withTag:(long)tag{
    [_messageParser appendData:data];
    
    [socket readDataWithTimeout:SOCKET_MSG_READ_TIMEOUT tag:0];
}

- (void)socket:(GCDAsyncSocket *)socket didWriteDataWithTag:(long)tag{
    [self invokeMessageSendCallback:CXSocketCodeOK tag:tag error:nil];
    
    [socket readDataWithTimeout:SOCKET_MSG_READ_TIMEOUT tag:0];
}

- (void)socket:(GCDAsyncSocket *)socket didConnectToHost:(NSString *)host port:(uint16_t)port{
    if(_connectURL){
        SocketCacheConnectionURLSet(_connectURL);
        _connectURL = nil;
    }
    
    _heartbeatSeqId = 0;
    _writeTag = 0;
    
    [self removeReconnectTimer];
    !self.connectionCallback ?: self.connectionCallback(CXSocketCodeOK, nil);
    [self sendLoginMessage];
}

- (void)sendLoginMessage{
    LoginRequest *loginMessage = [self.dataSource loginMessageInSocketManager:self];
    if(!loginMessage.version){
        loginMessage.version = CX_SOCKET_VERSION_1_0_0;
    }
    NSAssert(loginMessage != nil, @"[socket] login message is nil.");
    
    CXSocketMessageData *loginMessageData = [[CXSocketMessageData alloc] initWithMsgData:loginMessage msgType:MessageType_LoginRequest];
    loginMessageData.receiptEnabled = YES; // 需要回执
    loginMessageData.sendCallback = ^(CXSocketCode code, NSError * _Nullable error) {
        if(code == CXSocketCodeOK){
            LOG_INFO(@"[socket] login message send success.");
        }else{
            LOG_INFO(@"[socket] login message send failed. error: %@", error);
        }
    };
    
    @weakify(self)
    loginMessageData.receiptBlock = ^(CollectMessage * _Nullable receipt, NSError * _Nullable error) {
        @strongify(self)
        LoginResponse *loginResponse = (LoginResponse *)GPBMessageParseFromData([LoginResponse class], receipt.data_p, &error);
        if(!loginResponse){
            return;
        }
        
        if(loginResponse.errorCode == LoginErrorCode_Success){
            if([self.delegate respondsToSelector:@selector(socketManagerDidFinishLogin:)]){
                [self.delegate socketManagerDidFinishLogin:self];
            }
            
            [self addHeartbeatTimer];
            [self sendUserInfoMessage];
        }else if(loginResponse.errorCode == LoginErrorCode_ErrorRetry){
            [self sendLoginMessage];
        }else if(loginResponse.errorCode == LoginErrorCode_ErrorClose){
            LOG_INFO(@"[socket] login failed. socket connection closed.");
            SocketCacheConnectionURLSet(nil);
            
            if([self.delegate respondsToSelector:@selector(socketManagerDidConsumeReconnectionTimes:)]){
                [self.delegate socketManagerDidConsumeReconnectionTimes:self];
            }
        }
    };
    
    [self sendMessageData:loginMessageData];
}

- (void)sendUserInfoMessage{
    UserInfoMessage *userInfoMessage = [self.dataSource userInfoMessageInSocketManager:self];
    if(!userInfoMessage.version){
        userInfoMessage.version = CX_SOCKET_VERSION_1_0_0;
    }
    NSAssert(userInfoMessage != nil, @"[socket] user info message is nil.");
    
    CXSocketMessageData *userInfoMessageData = [[CXSocketMessageData alloc] initWithMsgData:userInfoMessage msgType:MessageType_Userinfo];
    userInfoMessageData.receiptEnabled = YES; // 需要回执
    userInfoMessageData.sendCallback = ^(CXSocketCode code, NSError * _Nullable error) {
        if(code == CXSocketCodeOK){
            LOG_INFO(@"[socket] user info message send success.");
        }else{
            LOG_INFO(@"[socket] user info message send failed. error: %@", error);
        }
    };
    
    @weakify(self)
    userInfoMessageData.receiptBlock = ^(CollectMessage * _Nullable receipt, NSError * _Nullable error) {
        @strongify(self)
        UserInfoResponse *userInfoResponse = (UserInfoResponse *)GPBMessageParseFromData([UserInfoResponse class], receipt.data_p, &error);
        if(!userInfoResponse){
            return;
        }
        
        if(!userInfoResponse.result){
            [self sendUserInfoMessage];
        }
    };
    
    [self sendMessageData:userInfoMessageData];
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    [self invokeMessageSendCallback:CXSocketCodeTimeout tag:tag error:nil];
    return 0;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error{
    if(_connectURL && error.code == GCDAsyncSocketConnectTimeoutError){
        SocketCacheConnectionURLSet(_connectURL);
    }
    _connectURL = nil;
    
    CXSocketCode code = CXSocketCodeInternalError;
    if(error.code == GCDAsyncSocketConnectTimeoutError){ // 超时
        code = CXSocketCodeTimeout;
    }else if(error.code == GCDAsyncSocketBadParamError){ // 参数错误
        code = CXSocketCodeBadParam;
    }else if(error.code == 35 || error.code == 51){ // 服务不可用
        code = CXSocketCodeServiceUnavailable;
    }
    
    !self.connectionCallback ?: self.connectionCallback(code, error);
    
    if([self.delegate respondsToSelector:@selector(socketManagerDidDisconnect:error:)]){
        [self.delegate socketManagerDidDisconnect:self error:error];
    }
    
    [_messageQueue removeAllObjects];
    [self removeHeartbeatTimer];
    
    if(code == CXSocketCodeServiceUnavailable){
        [self removeReconnectTimer];
    }else{
        [self reconnect:YES];
    }
}

- (void)addHeartbeatTimer{
    if(_heartbeatTimer){
        return;
    }
    
    _heartbeatSeqId = 0;
    _heartbeatTimer = [NSTimer timerWithTimeInterval:30.0
                                              target:self
                                            selector:@selector(handleHeartbeatTimer:)
                                            userInfo:nil
                                             repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_heartbeatTimer forMode:NSRunLoopCommonModes];
    [_heartbeatTimer fire];
}

- (void)handleHeartbeatTimer:(NSTimer *)heartbeatTimer{
    if(!self.isConnected){
        return;
    }
    
    _heartbeatSeqId ++;
    PingMessage *heartbeat = [PingMessage message];
    heartbeat.seqId = _heartbeatSeqId;
    
    CXSocketMessageData *messageData = [[CXSocketMessageData alloc] initWithMsgData:heartbeat msgType:MessageType_Ping];
    messageData.sendCallback = ^(CXSocketCode code, NSError * _Nullable error) {
        if(code == CXSocketCodeOK){
            LOG_INFO(@"[socket] ping message send success.");
        }else{
            LOG_INFO(@"[socket] ping message send failed. error: %@", error);
        }
    };
    
    [self sendMessageData:messageData];
}

- (void)removeHeartbeatTimer{
    if(_heartbeatTimer.isValid){
        [_heartbeatTimer invalidate];
    }
    
    _heartbeatTimer = nil;
}

- (void)addReconnectTimer{
    if(_reconnectTimer){
        return;
    }
    
    _reconnectCount = 0;
    _reconnectTimer = [NSTimer timerWithTimeInterval:SOCKET_RECONNECT_TIMEOUT
                                              target:self
                                            selector:@selector(handleReconnectTimer:)
                                            userInfo:nil
                                             repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_reconnectTimer forMode:NSRunLoopCommonModes];
    [_reconnectTimer fire];
}

- (void)handleReconnectTimer:(NSTimer *)reconnectTimer{
    _reconnectCount ++;
    
    if(_reconnectCount <= SOCKET_RECONNECT_COUNT){
        if([self reconnect:NO] != CXSocketCodeOK){
            [self removeReconnectTimer];
        }else{
            LOG_INFO(@"[socket] reconnect retry %@ ....", @(_reconnectCount));
        }
    }else{
        SocketCacheConnectionURLSet(nil);
        [self removeReconnectTimer];
        
        if([self.delegate respondsToSelector:@selector(socketManagerDidConsumeReconnectionTimes:)]){
            [self.delegate socketManagerDidConsumeReconnectionTimes:self];
        }
    }
}

- (void)removeReconnectTimer{
    if(_reconnectTimer.isValid){
        [_reconnectTimer invalidate];
    }
    
    _reconnectTimer = nil;
}

@end

@implementation CXSocketMessageData

- (instancetype)initWithMsgData:(GPBMessage *)msgData msgType:(MessageType)msgType{
    if(!msgData){
        return nil;
    }
    
    if(self = [super init]){
        _receiptEnabled = NO;
        _timeStamp = (uint64_t)([NSDate date].timeIntervalSince1970 * 1000);
        _msgData = msgData;
        _msgType = msgType;
    }
    
    return self;
}

@end
