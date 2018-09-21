//
//  Libjingle.h
//  Libjingle
//
//  Created by Matti Dahlbom on 20/09/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for Libjingle.
FOUNDATION_EXPORT double LibjingleVersionNumber;

//! Project version string for Libjingle.
FOUNDATION_EXPORT const unsigned char LibjingleVersionString[];

#import "RTCAVFoundationVideoSource.h"
#import "RTCAudioSource.h"
#import "RTCAudioTrack.h"
#import "RTCDataChannel.h"
#import "RTCEAGLVideoView.h"
#import "RTCFileLogger.h"
#import "RTCI420Frame.h"
#import "RTCICECandidate.h"
#import "RTCICEServer.h"
#import "RTCLogging.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaSource.h"
#import "RTCMediaStream.h"
#import "RTCMediaStreamTrack.h"
#import "RTCOpenGLVideoRenderer.h"
#import "RTCPair.h"
#import "RTCPeerConnection.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCPeerConnectionInterface.h"
#import "RTCSessionDescription.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCStatsDelegate.h"
#import "RTCStatsReport.h"
#import "RTCTypes.h"
#import "RTCVideoCapturer.h"
#import "RTCVideoRenderer.h"
#import "RTCVideoSource.h"
#import "RTCVideoTrack.h"

