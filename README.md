# Ninchat iOS SDK Integrator's Guide

This document describes integrating the Ninchat iOS SDK into an iOS application.

## Installation

Install the SDK via CocoaPods.

Example Podfile:

```
platform :ios, '9.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/somia/ninchat-podspecs.git'

def all_pods
  pod 'NinchatSDK', '~> 0.0.1'
end

target 'NinchatSDKTestClient' do
  all_pods
end

target 'NinchatSDKTestClientTests' do
  all_pods
end
```

Install by running `pod install`.

## Usage

#### Creating the API client

The SDK's API client is to be re-created every time a new chat session is started; once it has terminated, it cannot be used any more and must be disposed of to deallocate memory.

To initialize the client, you need a server address and a configuration key (and optionallya site secret). These will point the SDK to your chat server realm. You obtain these from Ninchat.

You must keep a reference to the created API client instance until the SDK UI terminates.

```swift
import NinchatSDK

self.ninchatSession = NINChatSession(configKey: configKey, queueID: queueID)
self.ninchatSession.delegate = self
```

##### Optional parameters

* `siteSecret` is optional and may not be required for your deployment
* `queueID` define a valid queue ID to join the queue directly; specify nil to show queue selection view.

#### Starting the API client

The SDK must perform some asynchornous networking tasks before it is ready to use; this is done by calling the `start` method as follows:

```swift
ninchatSession.start { [weak self] error in
    if let error = error {
        log.error("Ninchat SDK chat session failed to start with error: \(error))")
        self?.ninchatSession = nil
        //TODO insert your error handling steps here
        return
    }
}
```


#### Showing the SDK UI

Once you have started the API client, you can retrieve its UI to be displayed in your application's UI stack. Typically you would do this within the `start` callback upon successful completion. The API returns an `UIViewController` which you must display using a `UINavigationController` as such:

```swift
guard let controller = self?.ninchatSession.viewController(withNavigationController: false) else {
    log.error("Failed to instantiate SDK UI")
    //TODO insert your error handling steps here
    return
}

self.navigationController?.setNavigationBarHidden(true, animated: true)
self.navigationController?.pushViewController(controller, animated: true)
```

If your application doesn't use an `UINavigationController`, specify `withNavigationController: true` and the SDK will provide one for you.

#### Implementing the API client's delegate methods

The SDK uses a delegate pattern for providing callbacks into the host application. See below for implementing these methods. All of these methods are always called on the main UI thread.

```swift
// MARK: From NINChatSessionDelegate

/// This method is called when the chat session has terminated.
/// The host app should remove the SDK UI from its UI stack and restore
/// the navigation bar if it uses one.
func ninchatDidEnd(_ ninchat: NINChatSession) {
    log.debug("Ninchat session ended; removing the SDK UI");
    self.navigationController?.popToViewController(self, animated: true)
    ninchatSession = nil
    self.navigationController?.setNavigationBarHidden(false, animated: true)
}

/// This method is called when ever loading an overrideable graphics asset;
/// the host app may supply a custom UIImage to be shown in the SDK UI.
/// For any asset it does NOT wish to override, return nil.
func ninchat(_ session: NINChatSession, overrideImageAssetForKey assetKey: NINImageAssetKey) -> UIImage? {
    switch assetKey {
    case .queueViewProgressIndicator:
        return UIImage.init(named: "icon_queue_progress_indicator")
    default:
        return nil
    }
}

/// This method is called when ever a low-level API event is received.
/// The host application may respond to these events by using the exposed
/// low-level library; see NINChatSession.session. Optional method.
func ninchat(_ session: NINChatSession, onLowLevelEvent params: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) {
    let eventType = try! params.getString("event")
    switch eventType {
    case "channel_joined":
        log.debug("We joined a channel.");
    default:
        break
    }
}

/// This method is called when the SDK emits a log message. Optional method.
func ninchat(_ session: NINChatSession, didOutputSDKLog message: String) {
    log.debug("** NINCHAT SDK **: \(message)")
}
```

#### Info.plist keys Required by the SDK

The host application must define the following keys in its `Info.plist` file:

* `NSPhotoLibraryUsageDescription` - For accessing photos
* `NSMicrophoneUsageDescription` - For video conferencing
* `NSCameraUsageDescription` - For video conferencing

## Low level API

The SDK exposes the low-level communications interface as `NINChatSession.session`. The host app may use this object to communicate to the server, bypassing the SDK logic.

See [Ninchat API Reference](https://github.com/ninchat/ninchat-api/blob/v2/api.md) for information about the API's outbound Actions and inbound Events.

## Contact

If you have any questions, contact:
* Matti Dahlbom / Qvik <matti@qvik.com>
