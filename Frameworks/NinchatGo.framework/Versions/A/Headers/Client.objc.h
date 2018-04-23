// Objective-C API for talking to github.com/ninchat/ninchat-go/mobile Go package.
//   gobind -lang=objc github.com/ninchat/ninchat-go/mobile
//
// File is generated by gobind. Do not edit.

#ifndef __Client_H__
#define __Client_H__

@import Foundation;
#include "Universe.objc.h"


@class ClientCaller;
@class ClientEvent;
@class ClientEvents;
@class ClientPayload;
@class ClientProps;
@class ClientSession;
@class ClientStrings;
@protocol ClientCloseHandler;
@class ClientCloseHandler;
@protocol ClientConnActiveHandler;
@class ClientConnActiveHandler;
@protocol ClientConnStateHandler;
@class ClientConnStateHandler;
@protocol ClientEventHandler;
@class ClientEventHandler;
@protocol ClientLogHandler;
@class ClientLogHandler;
@protocol ClientPropVisitor;
@class ClientPropVisitor;
@protocol ClientSessionEventHandler;
@class ClientSessionEventHandler;

@protocol ClientCloseHandler <NSObject>
- (void)onClose;
@end

@protocol ClientConnActiveHandler <NSObject>
- (void)onConnActive;
@end

@protocol ClientConnStateHandler <NSObject>
- (void)onConnState:(NSString*)state;
@end

@protocol ClientEventHandler <NSObject>
- (void)onEvent:(ClientProps*)params payload:(ClientPayload*)payload lastReply:(BOOL)lastReply;
@end

@protocol ClientLogHandler <NSObject>
- (void)onLog:(NSString*)msg;
@end

@protocol ClientPropVisitor <NSObject>
- (BOOL)visitBool:(NSString*)p0 p1:(BOOL)p1 error:(NSError**)error;
- (BOOL)visitNumber:(NSString*)p0 p1:(double)p1 error:(NSError**)error;
- (BOOL)visitObject:(NSString*)p0 p1:(ClientProps*)p1 error:(NSError**)error;
- (BOOL)visitString:(NSString*)p0 p1:(NSString*)p1 error:(NSError**)error;
- (BOOL)visitStringArray:(NSString*)p0 p1:(ClientStrings*)p1 error:(NSError**)error;
@end

@protocol ClientSessionEventHandler <NSObject>
- (void)onSessionEvent:(ClientProps*)params;
@end

@interface ClientCaller : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (instancetype)init;
- (ClientEvents*)call:(ClientProps*)params payload:(ClientPayload*)payload error:(NSError**)error;
- (void)setAddress:(NSString*)address;
@end

@interface ClientEvent : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (instancetype)init;
// skipped field Event.Params with unsupported type: map[string]interface{}

// skipped field Event.Payload with unsupported type: []github.com/ninchat/ninchat-go.Frame

- (BOOL)lastReply;
- (void)setLastReply:(BOOL)v;
- (ClientPayload*)getPayload;
- (ClientProps*)getProps;
- (NSString*)string;
@end

@interface ClientEvents : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (instancetype)init;
- (ClientEvent*)get:(long)i;
- (long)length;
- (NSString*)string;
@end

@interface ClientPayload : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (instancetype)init;
- (void)append:(NSData*)blob;
- (NSData*)get:(long)i;
- (long)length;
- (NSString*)string;
@end

@interface ClientProps : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (instancetype)init;
- (BOOL)accept:(id<ClientPropVisitor>)callback error:(NSError**)error;
- (BOOL)getBool:(NSString*)key val:(BOOL*)val error:(NSError**)error;
- (BOOL)getFloat:(NSString*)key val:(double*)val error:(NSError**)error;
- (BOOL)getInt:(NSString*)key val:(long*)val error:(NSError**)error;
- (ClientProps*)getObject:(NSString*)key error:(NSError**)error;
- (NSString*)getString:(NSString*)key error:(NSError**)error;
- (ClientStrings*)getStringArray:(NSString*)key error:(NSError**)error;
- (void)setBool:(NSString*)key val:(BOOL)val;
- (void)setFloat:(NSString*)key val:(double)val;
- (void)setInt:(NSString*)key val:(long)val;
- (void)setObject:(NSString*)key ref:(ClientProps*)ref;
- (void)setString:(NSString*)key val:(NSString*)val;
- (void)setStringArray:(NSString*)key ref:(ClientStrings*)ref;
- (NSString*)string;
@end

@interface ClientSession : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (instancetype)init;
- (void)close;
- (BOOL)open:(NSError**)error;
- (BOOL)send:(ClientProps*)params payload:(ClientPayload*)payload error:(NSError**)error;
- (void)setAddress:(NSString*)address;
- (void)setOnClose:(id<ClientCloseHandler>)callback;
- (void)setOnConnActive:(id<ClientConnActiveHandler>)callback;
- (void)setOnConnState:(id<ClientConnStateHandler>)callback;
- (void)setOnEvent:(id<ClientEventHandler>)callback;
- (void)setOnLog:(id<ClientLogHandler>)callback;
- (void)setOnSessionEvent:(id<ClientSessionEventHandler>)callback;
- (BOOL)setParams:(ClientProps*)params error:(NSError**)error;
@end

@interface ClientStrings : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (instancetype)init;
- (void)append:(NSString*)val;
- (NSString*)get:(long)i;
- (long)length;
- (NSString*)string;
@end

FOUNDATION_EXPORT ClientCaller* ClientNewCaller(void);

FOUNDATION_EXPORT ClientPayload* ClientNewPayload(void);

FOUNDATION_EXPORT ClientProps* ClientNewProps(void);

FOUNDATION_EXPORT ClientSession* ClientNewSession(void);

FOUNDATION_EXPORT ClientStrings* ClientNewStrings(void);

@class ClientCloseHandler;

@class ClientConnActiveHandler;

@class ClientConnStateHandler;

@class ClientEventHandler;

@class ClientLogHandler;

@class ClientPropVisitor;

@class ClientSessionEventHandler;

@interface ClientCloseHandler : NSObject <goSeqRefInterface, ClientCloseHandler> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (void)onClose;
@end

@interface ClientConnActiveHandler : NSObject <goSeqRefInterface, ClientConnActiveHandler> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (void)onConnActive;
@end

@interface ClientConnStateHandler : NSObject <goSeqRefInterface, ClientConnStateHandler> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (void)onConnState:(NSString*)state;
@end

@interface ClientEventHandler : NSObject <goSeqRefInterface, ClientEventHandler> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (void)onEvent:(ClientProps*)params payload:(ClientPayload*)payload lastReply:(BOOL)lastReply;
@end

@interface ClientLogHandler : NSObject <goSeqRefInterface, ClientLogHandler> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (void)onLog:(NSString*)msg;
@end

@interface ClientPropVisitor : NSObject <goSeqRefInterface, ClientPropVisitor> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (BOOL)visitBool:(NSString*)p0 p1:(BOOL)p1 error:(NSError**)error;
- (BOOL)visitNumber:(NSString*)p0 p1:(double)p1 error:(NSError**)error;
- (BOOL)visitObject:(NSString*)p0 p1:(ClientProps*)p1 error:(NSError**)error;
- (BOOL)visitString:(NSString*)p0 p1:(NSString*)p1 error:(NSError**)error;
- (BOOL)visitStringArray:(NSString*)p0 p1:(ClientStrings*)p1 error:(NSError**)error;
@end

@interface ClientSessionEventHandler : NSObject <goSeqRefInterface, ClientSessionEventHandler> {
}
@property(strong, readonly) id _ref;

- (instancetype)initWithRef:(id)ref;
- (void)onSessionEvent:(ClientProps*)params;
@end

#endif
