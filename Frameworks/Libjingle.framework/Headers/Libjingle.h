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

// In this header, you should import all the public headers of your framework using statements like #import <Libjingle/PublicHeader.h>

#import <Libjingle/RTCPeerConnection.h>
#import <Libjingle/RTCPeerConnectionDelegate.h>
#import <Libjingle/RTCPeerConnectionFactory.h>
#import <Libjingle/RTCSessionDescriptionDelegate.h>
#import <Libjingle/RTCICEServer.h>
#import <Libjingle/RTCMediaConstraints.h>
#import <Libjingle/RTCMediaStream.h>
#import <Libjingle/RTCPair.h>
#import <Libjingle/RTCSessionDescription.h>
#import <Libjingle/RTCICECandidate.h>
#import <Libjingle/RTCVideoCapturer.h>

