# coding: utf-8

Pod::Spec.new do |s|
  s.name         = "NinchatSDK"
  s.version      = "0.0.29"
  s.summary      = "iOS SDK for Ninchat."
  s.description  = "For building iOS applications using Ninchat messaging."
  s.homepage     = "https://ninchat.com/"
  s.license      = { :type => "Ninchat", :file => "LICENSE.md" }
  s.author       = { "Matti Dahlbom" => "matti.dahlbom@qvik.fi" }
  s.source       = { :git => "https://github.com/somia/ninchat-sdk-ios.git", :tag => "#{s.version}" }

  s.ios.deployment_target = "9.0"

  # Handle the SDK itself as a subspec with dependencies to the frameworks
  s.subspec "SDK" do |ss|
    ss.source_files  = "NinchatSDK/**/*.{h,m}"
    ss.public_header_files = "NinchatSDK/*.h"
    ss.resource_bundles = {
        "NinchatSDKUI" => ["NinchatSDK/**/*.{storyboard,xib,xcassets,strings}"],
    }
  end

  # The SDK is our main spec
  s.default_subspec = "SDK"

  # Due to gomobile bind not supporting bitcode we must switch it off - for
  # the pod as well as the user target (app using the SDK). This is unfortunate,
  # but hopefully support will be there soon.
  # In addition we must suppress 'illegal text relocation' error for i386 platform
  s.pod_target_xcconfig = {
    "OTHER_LDFLAGS[arch=i386]" => "-Wl,-read_only_relocs,suppress -lstdc++",
    "ENABLE_BITCODE" => "NO"
  }
  s.user_target_xcconfig = {
      "ENABLE_BITCODE" => "NO"
  }

  # Our dependency (NinchatLowLevel) is a static library, so we must also be
  s.static_framework = true

  # Cocoapods dependencies
  s.dependency "AFNetworking", "~> 3.0"
  s.dependency "NinchatLowLevelClient", "~> 0"
  s.dependency "GoogleWebRTC", "~> 1.1"

  s.module_name = "NinchatSDK"
  s.requires_arc = true
end
