//
//  CXSocketMessageParser.h
//  Pods
//
//  Created by wshaolin on 2019/8/5.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CXSocketDataParseType) {
    // Varint32编解码（Java）详见：http://www.ppkanshu.com/index.php/post/2280.html
    // PB内部实现：ReadRawVarint32FromData(const uint8_t **data)，定义在GPBUtilities.m中
    CXSocketDataParseRawVarint32
};

@class CXSocketMessageParser;

@protocol CXSocketMessageParserDelegate <NSObject>

@optional

- (void)socketMessageParser:(CXSocketMessageParser *)parser didParseMessage:(NSData *)data;

@end

@interface CXSocketMessageParser : NSObject {
@private
    NSMutableData *_data;
    BOOL _parsing;
}

@property (nonatomic, assign, readonly) CXSocketDataParseType parseType;
@property (nonatomic, weak) id<CXSocketMessageParserDelegate> delegate;

- (instancetype)init; // Default CXSocketDataParseRawVarint32
- (instancetype)initWithParseType:(CXSocketDataParseType)parseType;

- (void)appendData:(NSData *)data;

@end
