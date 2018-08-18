//
//  NINWebRTCClient.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 14/08/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NINSessionManager;
@class NINWebRTCServerInfo;
@class NINWebRTCClient;
@class RTCVideoTrack;

/**
 * Delegate protocol for NINWebRTCClient. All the methods are called on the main thread.
 */
@protocol NINWebRTCClientDelegate <NSObject>

/** A new local video track was initiated. */
-(void) webrtcClient:(NINWebRTCClient*)client didReceiveLocalVideoTrack:(RTCVideoTrack*)localVideoTrack;

/** A new remote video track was initiated. */
-(void) webrtcClient:(NINWebRTCClient*)client didReceiveRemoteVideoTrack:(RTCVideoTrack*)remoteVideoTrack;

/** An unrecoverable error occurred. */
-(void) webrtcClient:(NINWebRTCClient*)client didGetError:(NSError*)error;

@end

/**
 * WebRTC client.
 */
@interface NINWebRTCClient : NSObject

/** Client delegate for receiving video tracks and other updates. */
@property (nonatomic, weak) id<NINWebRTCClientDelegate> delegate;

/** Creates a new client. */
+(instancetype) clientWithSessionManager:(NINSessionManager*)sessionManager stunServers:(NSArray<NINWebRTCServerInfo*>*)stunServers turnServers:(NSArray<NINWebRTCServerInfo*>*)turnServers;

@end
