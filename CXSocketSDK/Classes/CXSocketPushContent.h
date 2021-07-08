//
//  CXSocketPushContent.h
//  Pods
//
//  Created by wshaolin on 2019/3/29.
//

#import <CXFoundation/CXFoundation.h>

typedef NSString *CXSocketPushContentType;

@interface CXSocketPushContent : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *taskId;

@property (nonatomic, copy) CXSocketPushContentType type;
@property (nonatomic, strong) NSDictionary<NSString *, id> *info;

@end
