# coding: utf-8

Pod::Spec.new do |s|
  s.name         = "NinchatSDK"
  s.version      = "0.0.1"
  s.summary      = "iOS SDK for Ninchat."
  s.description  = "iOS SDK for Ninchat."
  s.homepage     = "https://ninchat.com/"
  s.license      = "MIT"
  s.author       = { "Matti Dahlbom" => "matti.dahlbom@qvik.fi" }
  s.source       = { :git => "https://github.com/somia/ninchat-sdk-ios", :tag => "#{s.version}" }

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
    ss.dependency 'CocoaLumberjack', '~> 3.4'
  end
  
  s.requires_arc = true
  s.default_subspec = "SDK"
end
