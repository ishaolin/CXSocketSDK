//
//  CXCoordinateSocketUploader.h
//  Pods
//
//  Created by wshaolin on 2018/6/22.
//

#import <CoreLocation/CoreLocation.h>

@class CXCoordinateSocketUploader;

@protocol CXCoordinateSocketUploaderDataSource <NSObject>

@required

- (NSString *)userIdInCoordinateSocketUploader:(CXCoordinateSocketUploader *)coordinateUploader;

@optional

- (NSString *)cityIdInCoordinateSocketUploader:(CXCoordinateSocketUploader *)coordinateUploader;

@end

@interface CXCoordinateSocketUploader : NSObject

@property (nonatomic, assign, readonly) BOOL isUploading;

/// 定时器上报间隔，默认10.0，Range [1.0, 30.0]，需要在startUpload之前设置
@property (nonatomic, assign) NSTimeInterval timeInterval;

/// 上报的一组坐标数据的个数，默认20，Range [5, 50]，需要在startUpload之前设置
@property (nonatomic, assign) NSUInteger groupCount;

@property (nonatomic, weak) id<CXCoordinateSocketUploaderDataSource> dataSource;

+ (instancetype)sharedUploader;

- (void)startUpload;

- (void)stopUpload;

- (void)receiveLocation:(CLLocation *)location;

@end
