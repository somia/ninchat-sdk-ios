// Objective-C API for talking to github.com/ninchat/ninchat-go/mobile Go package.
//   gobind -lang=objc -prefix="NINLowLevel" github.com/ninchat/ninchat-go/mobile
//
// File is generated by gobind. Do not edit.

#ifndef __NINLowLevelClient_H__
#define __NINLowLevelClient_H__

@import Foundation;
#include "ref.h"
#include "Universe.objc.h"


@class NINLowLevelClientCaller;
@class NINLowLevelClientEvent;
@class NINLowLevelClientEvents;
@class NINLowLevelClientJSON;
@class NINLowLevelClientObjects;
@class NINLowLevelClientPayload;
@class NINLowLevelClientProps;
@class NINLowLevelClientSession;
@class NINLowLevelClientStrings;
@protocol NINLowLevelClientCloseHandler;
@class NINLowLevelClientCloseHandler;
@protocol NINLowLevelClientConnActiveHandler;
@class NINLowLevelClientConnActiveHandler;
@protocol NINLowLevelClientConnStateHandler;
@class NINLowLevelClientConnStateHandler;
@protocol NINLowLevelClientEventHandler;
@class NINLowLevelClientEventHandler;
@protocol NINLowLevelClientLogHandler;
@class NINLowLevelClientLogHandler;
@protocol NINLowLevelClientPropVisitor;
@class NINLowLevelClientPropVisitor;
@protocol NINLowLevelClientSessionEventHandler;
@class NINLowLevelClientSessionEventHandler;

@protocol NINLowLevelClientCloseHandler <NSObject>
- (void)onClose;
@end

@protocol NINLowLevelClientConnActiveHandler <NSObject>
- (void)onConnActive;
@end

@protocol NINLowLevelClientConnStateHandler <NSObject>
- (void)onConnState:(NSString* _Nullable)state;
@end

@protocol NINLowLevelClientEventHandler <NSObject>
- (void)onEvent:(NINLowLevelClientProps* _Nullable)params payload:(NINLowLevelClientPayload* _Nullable)payload lastReply:(BOOL)lastReply;
@end

@protocol NINLowLevelClientLogHandler <NSObject>
- (void)onLog:(NSString* _Nullable)msg;
@end

@protocol NINLowLevelClientPropVisitor <NSObject>
- (BOOL)visitBool:(NSString* _Nullable)p0 p1:(BOOL)p1 error:(NSError* _Nullable* _Nullable)error;
- (BOOL)visitNumber:(NSString* _Nullable)p0 p1:(double)p1 error:(NSError* _Nullable* _Nullable)error;
- (BOOL)visitObject:(NSString* _Nullable)p0 p1:(NINLowLevelClientProps* _Nullable)p1 error:(NSError* _Nullable* _Nullable)error;
- (BOOL)visitObjectArray:(NSString* _Nullable)p0 p1:(NINLowLevelClientObjects* _Nullable)p1 error:(NSError* _Nullable* _Nullable)error;
- (BOOL)visitString:(NSString* _Nullable)p0 p1:(NSString* _Nullable)p1 error:(NSError* _Nullable* _Nullable)error;
- (BOOL)visitStringArray:(NSString* _Nullable)p0 p1:(NINLowLevelClientStrings* _Nullable)p1 error:(NSError* _Nullable* _Nullable)error;
@end

@protocol NINLowLevelClientSessionEventHandler <NSObject>
- (void)onSessionEvent:(NINLowLevelClientProps* _Nullable)params;
@end

@interface NINLowLevelClientCaller : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nullable instancetype)init;
- (NINLowLevelClientEvents* _Nullable)call:(NINLowLevelClientProps* _Nullable)params payload:(NINLowLevelClientPayload* _Nullable)payload error:(NSError* _Nullable* _Nullable)error;
- (void)setAddress:(NSString* _Nullable)address;
@end

@interface NINLowLevelClientEvent : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
// skipped field Event.Params with unsupported type: map[string]interface{}

// skipped field Event.Payload with unsupported type: []github.com/ninchat/ninchat-go.Frame

@property (nonatomic) BOOL lastReply;
- (NINLowLevelClientProps* _Nullable)getParams;
- (NINLowLevelClientPayload* _Nullable)getPayload;
- (NSString* _Nonnull)string;
@end

@interface NINLowLevelClientEvents : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
- (NINLowLevelClientEvent* _Nullable)get:(long)i;
- (long)length;
- (NSString* _Nonnull)string;
@end

@interface NINLowLevelClientJSON : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nullable instancetype)init:(NSString* _Nullable)s;
@end

@interface NINLowLevelClientObjects : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
- (NINLowLevelClientProps* _Nullable)get:(long)i;
- (long)length;
- (NSString* _Nonnull)string;
@end

@interface NINLowLevelClientPayload : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nullable instancetype)init;
- (void)append:(NSData* _Nullable)blob;
- (NSData* _Nullable)get:(long)i;
- (long)length;
- (NSString* _Nonnull)string;
@end

@interface NINLowLevelClientProps : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nullable instancetype)init;
- (BOOL)accept:(id<NINLowLevelClientPropVisitor> _Nullable)callback error:(NSError* _Nullable* _Nullable)error;
- (BOOL)getBool:(NSString* _Nullable)key val:(BOOL* _Nullable)val error:(NSError* _Nullable* _Nullable)error;
- (BOOL)getFloat:(NSString* _Nullable)key val:(double* _Nullable)val error:(NSError* _Nullable* _Nullable)error;
- (BOOL)getInt:(NSString* _Nullable)key val:(long* _Nullable)val error:(NSError* _Nullable* _Nullable)error;
- (NINLowLevelClientProps* _Nullable)getObject:(NSString* _Nullable)key error:(NSError* _Nullable* _Nullable)error;
- (NINLowLevelClientObjects* _Nullable)getObjectArray:(NSString* _Nullable)key error:(NSError* _Nullable* _Nullable)error;
- (NSString* _Nonnull)getString:(NSString* _Nullable)key error:(NSError* _Nullable* _Nullable)error;
- (NINLowLevelClientStrings* _Nullable)getStringArray:(NSString* _Nullable)key error:(NSError* _Nullable* _Nullable)error;
- (void)setBool:(NSString* _Nullable)key val:(BOOL)val;
- (void)setFloat:(NSString* _Nullable)key val:(double)val;
- (void)setInt:(NSString* _Nullable)key val:(long)val;
- (void)setJSON:(NSString* _Nullable)key ref:(NINLowLevelClientJSON* _Nullable)ref;
- (void)setObject:(NSString* _Nullable)key ref:(NINLowLevelClientProps* _Nullable)ref;
- (void)setString:(NSString* _Nullable)key val:(NSString* _Nullable)val;
- (void)setStringArray:(NSString* _Nullable)key ref:(NINLowLevelClientStrings* _Nullable)ref;
- (NSString* _Nonnull)string;
@end

@interface NINLowLevelClientSession : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nullable instancetype)init;
- (void)close;
- (BOOL)open:(NSError* _Nullable* _Nullable)error;
- (BOOL)send:(NINLowLevelClientProps* _Nullable)params payload:(NINLowLevelClientPayload* _Nullable)payload actionId:(int64_t* _Nullable)actionId error:(NSError* _Nullable* _Nullable)error;
- (void)setAddress:(NSString* _Nullable)address;
- (void)setOnClose:(id<NINLowLevelClientCloseHandler> _Nullable)callback;
- (void)setOnConnActive:(id<NINLowLevelClientConnActiveHandler> _Nullable)callback;
- (void)setOnConnState:(id<NINLowLevelClientConnStateHandler> _Nullable)callback;
- (void)setOnEvent:(id<NINLowLevelClientEventHandler> _Nullable)callback;
- (void)setOnLog:(id<NINLowLevelClientLogHandler> _Nullable)callback;
- (void)setOnSessionEvent:(id<NINLowLevelClientSessionEventHandler> _Nullable)callback;
- (BOOL)setParams:(NINLowLevelClientProps* _Nullable)params error:(NSError* _Nullable* _Nullable)error;
@end

@interface NINLowLevelClientStrings : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nullable instancetype)init;
- (void)append:(NSString* _Nullable)val;
- (NSString* _Nonnull)get:(long)i;
- (long)length;
- (NSString* _Nonnull)string;
@end

FOUNDATION_EXPORT NINLowLevelClientCaller* _Nullable NINLowLevelClientNewCaller(void);

FOUNDATION_EXPORT NINLowLevelClientJSON* _Nullable NINLowLevelClientNewJSON(NSString* _Nullable s);

FOUNDATION_EXPORT NINLowLevelClientPayload* _Nullable NINLowLevelClientNewPayload(void);

FOUNDATION_EXPORT NINLowLevelClientProps* _Nullable NINLowLevelClientNewProps(void);

FOUNDATION_EXPORT NINLowLevelClientSession* _Nullable NINLowLevelClientNewSession(void);

FOUNDATION_EXPORT NINLowLevelClientStrings* _Nullable NINLowLevelClientNewStrings(void);

@class NINLowLevelClientCloseHandler;

@class NINLowLevelClientConnActiveHandler;

@class NINLowLevelClientConnStateHandler;

@class NINLowLevelClientEventHandler;

@class NINLowLevelClientLogHandler;

@class NINLowLevelClientPropVisitor;

@class NINLowLevelClientSessionEventHandler;

@interface NINLowLevelClientCloseHandler : NSObject <goSeqRefInterface, NINLowLevelClientCloseHandler> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (void)onClose;
@end

@interface NINLowLevelClientConnActiveHandler : NSObject <goSeqRefInterface, NINLowLevelClientConnActiveHandler> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (void)onConnActive;
@end

@interface NINLowLevelClientConnStateHandler : NSObject <goSeqRefInterface, NINLowLevelClientConnStateHandler> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (void)onConnState:(NSString* _Nullable)state;
@end

@interface NINLowLevelClientEventHandler : NSObject <goSeqRefInterface, NINLowLevelClientEventHandler> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (void)onEvent:(NINLowLevelClientProps* _Nullable)params payload:(NINLowLevelClientPayload* _Nullable)payload lastReply:(BOOL)lastReply;
@end

@interface NINLowLevelClientLogHandler : NSObject <goSeqRefInterface, NINLowLevelClientLogHandler> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (void)onLog:(NSString* _Nullable)msg;
@end

@interface NINLowLevelClientPropVisitor : NSObject <goSeqRefInterface, NINLowLevelClientPropVisitor> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (BOOL)visitBool:(NSString* _Nullable)p0 p1:(BOOL)p1 error:(NSError* _Nullable* _Nullable)error;
- (BOOL)visitNumber:(NSString* _Nullable)p0 p1:(double)p1 error:(NSError* _Nullable* _Nullable)error;
- (BOOL)visitObject:(NSString* _Nullable)p0 p1:(NINLowLevelClientProps* _Nullable)p1 error:(NSError* _Nullable* _Nullable)error;
- (BOOL)visitObjectArray:(NSString* _Nullable)p0 p1:(NINLowLevelClientObjects* _Nullable)p1 error:(NSError* _Nullable* _Nullable)error;
- (BOOL)visitString:(NSString* _Nullable)p0 p1:(NSString* _Nullable)p1 error:(NSError* _Nullable* _Nullable)error;
- (BOOL)visitStringArray:(NSString* _Nullable)p0 p1:(NINLowLevelClientStrings* _Nullable)p1 error:(NSError* _Nullable* _Nullable)error;
@end

@interface NINLowLevelClientSessionEventHandler : NSObject <goSeqRefInterface, NINLowLevelClientSessionEventHandler> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (void)onSessionEvent:(NINLowLevelClientProps* _Nullable)params;
@end

#endif
