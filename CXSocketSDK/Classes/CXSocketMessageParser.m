//
//  CXSocketMessageParser.m
//  Pods
//
//  Created by wshaolin on 2019/8/5.
//

#import "CXSocketMessageParser.h"

#define CX_MSG_PARSE_ERROR -1

static inline int8_t CXSocketReadRawByteFromData(NSData *data, int32_t *index){
    if(*index >= data.length){
        return CX_MSG_PARSE_ERROR;
    }
    
    int8_t byte = ((int8_t *)data.bytes)[*index];
    *index += 1;
    
    return byte;
}

static inline int32_t CXSocketVarint32DataBodySizeFromData(NSData *data, int32_t *headSize){
    int8_t byte = CXSocketReadRawByteFromData(data, headSize);
    if(byte >= 0){
        return byte;
    }
    
    int32_t bodySize = byte & 0x7F;
    if((byte = CXSocketReadRawByteFromData(data, headSize)) >= 0){
        bodySize |= byte << 7;
        return bodySize;
    }
    
    bodySize |= (byte & 0x7F) << 7;
    if((byte = CXSocketReadRawByteFromData(data, headSize)) >= 0){
        bodySize |= byte << 14;
        return bodySize;
    }
    
    bodySize |= (byte & 0x7F) << 14;
    if((byte = CXSocketReadRawByteFromData(data, headSize)) >= 0){
        bodySize |= byte << 21;
        return bodySize;
    }
    
    bodySize |= (byte & 0x7F) << 21;
    bodySize |= (byte = CXSocketReadRawByteFromData(data, headSize)) << 28;
    if(byte >= 0){
        return bodySize;
    }
    
    // Discard upper 32 bits.
    for(int32_t i = 0; i < 5; i ++){
        if(CXSocketReadRawByteFromData(data, headSize) >= 0){
            return bodySize;
        }
    }
    
    return CX_MSG_PARSE_ERROR;
}

@implementation CXSocketMessageParser

- (instancetype)init{
    return [self initWithParseType:CXSocketDataParseRawVarint32];
}

- (instancetype)initWithParseType:(CXSocketDataParseType)parseType{
    if(self = [super init]){
        _parseType = parseType;
        _data = [NSMutableData data];
    }
    return self;
}

- (void)appendData:(NSData *)data{
    if(!data){
        return;
    }
    
    [_data appendData:data];
    
    if(_parsing){
        return;
    }
    
    switch (_parseType) {
        case CXSocketDataParseRawVarint32:{
            [self parseDataByRawVarint32];
        }
            break;
        default:
            break;
    }
}

- (void)parseDataByRawVarint32{
    _parsing = YES;
    
    int32_t headSize = 0;
    int32_t bodySize = CXSocketVarint32DataBodySizeFromData(_data, &headSize);
    if(bodySize == CX_MSG_PARSE_ERROR){
        // 数据有误
        _parsing = NO;
        return;
    }
    
    if(headSize + bodySize > _data.length){
        // 数据不完整
        _parsing = NO;
        return;
    }
    
    // 一条完整的消息
    NSData *data = [_data subdataWithRange:NSMakeRange(headSize, bodySize)];
    if([_delegate respondsToSelector:@selector(socketMessageParser:didParseMessage:)]){
        [_delegate socketMessageParser:self didParseMessage:data];
    }
    [_data replaceBytesInRange:NSMakeRange(0, headSize + bodySize) withBytes:NULL length:0];
    
    // 尝试解析下一条消息
    [self parseDataByRawVarint32];
}

@end
