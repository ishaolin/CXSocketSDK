//
//  CXCoordinateSocketUploader.m
//  Pods
//
//  Created by wshaolin on 2018/6/22.
//

#import "CXCoordinateSocketUploader.h"
#import "CXSocketManager.h"
#import <CXFoundation/CXFoundation.h>

@interface CXCoordinateSocketUploader () {
    CXTimer *_uploadTimer;
    
    NSMutableArray<CoordinateRequest *> *_coordinates;
    CLLocation *_location;
    NSUInteger _timerCount;
}

@end

@implementation CXCoordinateSocketUploader

+ (instancetype)sharedUploader{
    static CXCoordinateSocketUploader *_coordinateSocketUploader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _coordinateSocketUploader = [[self alloc] init];
    });
    
    return _coordinateSocketUploader;
}

- (instancetype)init{
    if(self = [super init]){
        _coordinates = [NSMutableArray array];
        _timeInterval = 10.0;
        _groupCount = 20;
    }
    
    return self;
}

- (void)setGroupCount:(NSUInteger)groupCount{
    _groupCount = MAX(MIN(groupCount, 50), 5);
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval{
    _timeInterval = MAX(MIN(timeInterval, 30.0), 1.0);
}

- (void)startUpload{
    if(_isUploading){
        return;
    }
    
    _isUploading = YES;
    [_coordinates removeAllObjects];
    _location = nil;
    [self addUploadTimer];
}

- (void)stopUpload{
    if(_isUploading){
        [self removeUploadTimer];
        _isUploading = NO;
    }
}

- (void)receiveLocation:(CLLocation *)location{
    if(!location){
        return;
    }
    
    if(_location && [_location distanceFromLocation:location] < 1.0){
        // 当前点与上一个点距离小于1米，丢弃，避免数据量过大
        return;
    }
    
    _location = location;
    CoordinateRequest *coordinate = [CoordinateRequest message];
    coordinate.type = CoordinateType_SosoGcjCoordinate;
    coordinate.lat = location.coordinate.latitude;
    coordinate.lon = location.coordinate.longitude;
    coordinate.course = location.course;
    coordinate.speed = location.speed;
    coordinate.timestamp = (int64_t)(location.timestamp.timeIntervalSince1970 * 1000);
    coordinate.provider = 1; // 固定GPS
    [_coordinates addObject:coordinate];
    
    if(_coordinates.count >= _groupCount){
        if(!_isUploading){
            [_coordinates removeObjectAtIndex:0];
        }
        
        [self executeUploadCoordinates];
    }
}

- (void)addUploadTimer{
    if(_uploadTimer){
        return;
    }
    
    _uploadTimer = [CXTimer taskTimerWithConfig:^(CXTimerConfig *config) {
        config.target = self;
        config.action = @selector(handleUploadTimer:);
        config.interval = 1.0;
        config.repeats = YES;
    }];
    [_uploadTimer fire];
}

- (void)handleUploadTimer:(CXTimer *)uploadTimer{
    _timerCount ++;
    if(_timerCount / self.timeInterval < 0){
        return;
    }
    _timerCount = 0;
    
    if(CXArrayIsEmpty(_coordinates)){
        if(!_location){
            return;
        }
        
        CoordinateRequest *coordinate = [CoordinateRequest message];
        coordinate.type = CoordinateType_SosoGcjCoordinate;
        coordinate.lat = _location.coordinate.latitude;
        coordinate.lon = _location.coordinate.longitude;
        coordinate.course = _location.course;
        coordinate.speed = _location.speed;
        coordinate.timestamp = (int64_t)(_location.timestamp.timeIntervalSince1970 * 1000);
        coordinate.provider = 1; // 固定GPS
        [_coordinates addObject:coordinate];
    }
    
    [self executeUploadCoordinates];
}

- (void)removeUploadTimer{
    if(_uploadTimer.isValid){
        [_uploadTimer invalidate];
    }
    
    _uploadTimer = nil;
}

- (void)executeUploadCoordinates{
    if(![CXSocketManager sharedManager].isConnected){
        [_coordinates removeAllObjects];
        return;
    }
    
    CoordinatePackageRequest *message = [CoordinatePackageRequest message];
    message.timestamp = (int64_t)([NSDate date].timeIntervalSince1970 * 1000);
    message.userId = [self.dataSource userIdInCoordinateSocketUploader:self];
    message.coordinateArray = [NSMutableArray arrayWithArray:[_coordinates copy]];
    if([self.dataSource respondsToSelector:@selector(cityIdInCoordinateSocketUploader:)]){
        message.cityId = [self.dataSource cityIdInCoordinateSocketUploader:self];
    }
    [_coordinates removeAllObjects];
    
    CXSocketMessageData *messageData = [[CXSocketMessageData alloc] initWithMsgData:message msgType:MessageType_CoordinatePull];
    messageData.sendCallback = ^(CXSocketCode code, NSError * _Nullable error) {
        if(code == CXSocketCodeOK){
            LOG_INFO(@"[socket] coordinates upload success.");
        }else{
            LOG_INFO(@"[socket] coordinates upload failed.");
        }
    };
    
    [[CXSocketManager sharedManager] sendMessageData:messageData];
}

@end
