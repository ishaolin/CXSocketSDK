// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: ParseMessage.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/GPBProtocolBuffers_RuntimeSupport.h>
#else
 #import "GPBProtocolBuffers_RuntimeSupport.h"
#endif

#import <stdatomic.h>

#import "ParseMessage.pbobjc.h"
// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#pragma mark - ParseMessageRoot

@implementation ParseMessageRoot

// No extensions in the file and no imports, so no need to generate
// +extensionRegistry.

@end

#pragma mark - ParseMessageRoot_FileDescriptor

static GPBFileDescriptor *ParseMessageRoot_FileDescriptor(void) {
  // This is called by +initialize so there is no need to worry
  // about thread safety of the singleton.
  static GPBFileDescriptor *descriptor = NULL;
  if (!descriptor) {
    GPB_DEBUG_CHECK_RUNTIME_VERSIONS();
    descriptor = [[GPBFileDescriptor alloc] initWithPackage:@""
                                                     syntax:GPBFileSyntaxProto3];
  }
  return descriptor;
}

#pragma mark - Enum MessageLiteType

GPBEnumDescriptor *MessageLiteType_EnumDescriptor(void) {
  static _Atomic(GPBEnumDescriptor*) descriptor = nil;
  if (!descriptor) {
    static const char *valueNames =
        "PingLite\000PushLiteMessage\000";
    static const int32_t values[] = {
        MessageLiteType_PingLite,
        MessageLiteType_PushLiteMessage,
    };
    GPBEnumDescriptor *worker =
        [GPBEnumDescriptor allocDescriptorForName:GPBNSStringifySymbol(MessageLiteType)
                                       valueNames:valueNames
                                           values:values
                                            count:(uint32_t)(sizeof(values) / sizeof(int32_t))
                                     enumVerifier:MessageLiteType_IsValidValue];
    GPBEnumDescriptor *expected = nil;
    if (!atomic_compare_exchange_strong(&descriptor, &expected, worker)) {
      [worker release];
    }
  }
  return descriptor;
}

BOOL MessageLiteType_IsValidValue(int32_t value__) {
  switch (value__) {
    case MessageLiteType_PingLite:
    case MessageLiteType_PushLiteMessage:
      return YES;
    default:
      return NO;
  }
}

#pragma mark - ContentLiteMessage

@implementation ContentLiteMessage

@dynamic type;
@dynamic body;

typedef struct ContentLiteMessage__storage_ {
  uint32_t _has_storage_[1];
  MessageLiteType type;
  NSData *body;
} ContentLiteMessage__storage_;

// This method is threadsafe because it is initially called
// in +initialize for each subclass.
+ (GPBDescriptor *)descriptor {
  static GPBDescriptor *descriptor = nil;
  if (!descriptor) {
    static GPBMessageFieldDescription fields[] = {
      {
        .name = "type",
        .dataTypeSpecific.enumDescFunc = MessageLiteType_EnumDescriptor,
        .number = ContentLiteMessage_FieldNumber_Type,
        .hasIndex = 0,
        .offset = (uint32_t)offsetof(ContentLiteMessage__storage_, type),
        .flags = (GPBFieldFlags)(GPBFieldOptional | GPBFieldHasEnumDescriptor),
        .dataType = GPBDataTypeEnum,
      },
      {
        .name = "body",
        .dataTypeSpecific.className = NULL,
        .number = ContentLiteMessage_FieldNumber_Body,
        .hasIndex = 1,
        .offset = (uint32_t)offsetof(ContentLiteMessage__storage_, body),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeBytes,
      },
    };
    GPBDescriptor *localDescriptor =
        [GPBDescriptor allocDescriptorForClass:[ContentLiteMessage class]
                                     rootClass:[ParseMessageRoot class]
                                          file:ParseMessageRoot_FileDescriptor()
                                        fields:fields
                                    fieldCount:(uint32_t)(sizeof(fields) / sizeof(GPBMessageFieldDescription))
                                   storageSize:sizeof(ContentLiteMessage__storage_)
                                         flags:GPBDescriptorInitializationFlag_None];
    #if defined(DEBUG) && DEBUG
      NSAssert(descriptor == nil, @"Startup recursed!");
    #endif  // DEBUG
    descriptor = localDescriptor;
  }
  return descriptor;
}

@end

int32_t ContentLiteMessage_Type_RawValue(ContentLiteMessage *message) {
  GPBDescriptor *descriptor = [ContentLiteMessage descriptor];
  GPBFieldDescriptor *field = [descriptor fieldWithNumber:ContentLiteMessage_FieldNumber_Type];
  return GPBGetMessageInt32Field(message, field);
}

void SetContentLiteMessage_Type_RawValue(ContentLiteMessage *message, int32_t value) {
  GPBDescriptor *descriptor = [ContentLiteMessage descriptor];
  GPBFieldDescriptor *field = [descriptor fieldWithNumber:ContentLiteMessage_FieldNumber_Type];
  GPBSetInt32IvarWithFieldInternal(message, field, value, descriptor.file.syntax);
}

#pragma mark - PingLiteRequest

@implementation PingLiteRequest

@dynamic seqId;

typedef struct PingLiteRequest__storage_ {
  uint32_t _has_storage_[1];
  int64_t seqId;
} PingLiteRequest__storage_;

// This method is threadsafe because it is initially called
// in +initialize for each subclass.
+ (GPBDescriptor *)descriptor {
  static GPBDescriptor *descriptor = nil;
  if (!descriptor) {
    static GPBMessageFieldDescription fields[] = {
      {
        .name = "seqId",
        .dataTypeSpecific.className = NULL,
        .number = PingLiteRequest_FieldNumber_SeqId,
        .hasIndex = 0,
        .offset = (uint32_t)offsetof(PingLiteRequest__storage_, seqId),
        .flags = (GPBFieldFlags)(GPBFieldOptional | GPBFieldTextFormatNameCustom),
        .dataType = GPBDataTypeInt64,
      },
    };
    GPBDescriptor *localDescriptor =
        [GPBDescriptor allocDescriptorForClass:[PingLiteRequest class]
                                     rootClass:[ParseMessageRoot class]
                                          file:ParseMessageRoot_FileDescriptor()
                                        fields:fields
                                    fieldCount:(uint32_t)(sizeof(fields) / sizeof(GPBMessageFieldDescription))
                                   storageSize:sizeof(PingLiteRequest__storage_)
                                         flags:GPBDescriptorInitializationFlag_None];
#if !GPBOBJC_SKIP_MESSAGE_TEXTFORMAT_EXTRAS
    static const char *extraTextFormatInfo =
        "\001\001\005\000";
    [localDescriptor setupExtraTextInfo:extraTextFormatInfo];
#endif  // !GPBOBJC_SKIP_MESSAGE_TEXTFORMAT_EXTRAS
    #if defined(DEBUG) && DEBUG
      NSAssert(descriptor == nil, @"Startup recursed!");
    #endif  // DEBUG
    descriptor = localDescriptor;
  }
  return descriptor;
}

@end

#pragma mark - PushLiteMessage

@implementation PushLiteMessage

@dynamic type;
@dynamic content;

typedef struct PushLiteMessage__storage_ {
  uint32_t _has_storage_[1];
  NSString *type;
  NSString *content;
} PushLiteMessage__storage_;

// This method is threadsafe because it is initially called
// in +initialize for each subclass.
+ (GPBDescriptor *)descriptor {
  static GPBDescriptor *descriptor = nil;
  if (!descriptor) {
    static GPBMessageFieldDescription fields[] = {
      {
        .name = "type",
        .dataTypeSpecific.className = NULL,
        .number = PushLiteMessage_FieldNumber_Type,
        .hasIndex = 0,
        .offset = (uint32_t)offsetof(PushLiteMessage__storage_, type),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
      {
        .name = "content",
        .dataTypeSpecific.className = NULL,
        .number = PushLiteMessage_FieldNumber_Content,
        .hasIndex = 1,
        .offset = (uint32_t)offsetof(PushLiteMessage__storage_, content),
        .flags = GPBFieldOptional,
        .dataType = GPBDataTypeString,
      },
    };
    GPBDescriptor *localDescriptor =
        [GPBDescriptor allocDescriptorForClass:[PushLiteMessage class]
                                     rootClass:[ParseMessageRoot class]
                                          file:ParseMessageRoot_FileDescriptor()
                                        fields:fields
                                    fieldCount:(uint32_t)(sizeof(fields) / sizeof(GPBMessageFieldDescription))
                                   storageSize:sizeof(PushLiteMessage__storage_)
                                         flags:GPBDescriptorInitializationFlag_None];
    #if defined(DEBUG) && DEBUG
      NSAssert(descriptor == nil, @"Startup recursed!");
    #endif  // DEBUG
    descriptor = localDescriptor;
  }
  return descriptor;
}

@end


#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)