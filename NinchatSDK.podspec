# coding: utf-8

Pod::Spec.new do |s|
  s.name         = "NinchatSDK"
  s.version      = "0.0.7"
  s.summary      = "iOS SDK for Ninchat."
  s.description  = "For building applications using Ninchat messaging."
  s.homepage     = "https://ninchat.com/"
  s.license      = { :type => "Ninchat", :file => "LICENSE.md" }
  s.author       = { "Matti Dahlbom" => "matti.dahlbom@qvik.fi" }
  s.source       = { :git => "https://github.com/somia/ninchat-sdk-ios.git", :tag => "#{s.version}" }

  s.ios.deployment_target = "9.0"

  # Handle the Go library as a subspec
  s.subspec "Go" do |gs|
    gs.vendored_frameworks = "Frameworks/Client.framework"
  end

  # Handle the SDK itself as a subspec with a dependency to the Go lib
  s.subspec "SDK" do |ss|
    ss.dependency "#{s.name}/Go"
    ss.source_files  = "NinchatSDK/**/*.{h,m}"
    ss.public_header_files = "NinchatSDK/**/*.h"
    ss.prefix_header_file = "NinchatSDK/PrefixHeader.pch"
    ss.resource_bundles = {
        "NinchatSDKUI" => ["NinchatSDK/**/*.{storyboard,xib}"],
    }
  end

  # Due to gomobile bind not supporting bitcode we must switch it off - for
  # the pod as well as the user target (app using the SDK). This is unfortunate,
  # but hopefully support will be there soon.
  # In addition we must suppress 'illegal text relocation' error for i386 platform
  s.pod_target_xcconfig = {
    "OTHER_LDFLAGS[arch=i386]" => "-Wl,-read_only_relocs,suppress",
    "ENABLE_BITCODE" => "NO"
  }
  s.user_target_xcconfig = {
      "ENABLE_BITCODE" => "NO"
  }

  s.dependency "CocoaLumberjack", "~> 3.4"
  s.requires_arc = true
  s.default_subspec = "SDK"

end
