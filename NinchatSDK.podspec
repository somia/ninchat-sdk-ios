# coding: utf-8

Pod::Spec.new do |s|
  s.name         = "NinchatSDK"
  s.version      = "0.0.9"
  s.summary      = "iOS SDK for Ninchat."
  s.description  = "For building iOS applications using Ninchat messaging."
  s.homepage     = "https://ninchat.com/"
  s.license      = { :type => "Ninchat", :file => "LICENSE.md" }
  s.author       = { "Matti Dahlbom" => "matti.dahlbom@qvik.fi" }
  s.source       = { :git => "https://github.com/somia/ninchat-sdk-ios.git", :tag => "#{s.version}" }

  s.ios.deployment_target = "9.0"

  # Handle the Go library as a subspec
  #s.subspec "Client" do |cl|
  #  cl.vendored_frameworks = "Frameworks/Client.framework"
  #  cl.source_files = "Frameworks/Client.framework/Headers/*.h"
    #cl.module_name = "Client"
    #end

  # Handle libjingle_peerconnection as a subspec
  s.subspec "Libjingle" do |lj|
    lj.vendored_frameworks = "Frameworks/Libjingle.framework"
    lj.frameworks = "VideoToolbox", "AVFoundation", "CoreMedia", "AudioToolbox", "GLKit"
    lj.libraries = "stdc++"
  end

  # Handle the SDK itself as a subspec with dependencies to the frameworks
  s.subspec "SDK" do |ss|
      #ss.dependency "#{s.name}/Client"
    ss.dependency "#{s.name}/Libjingle"

    ss.source_files  = "NinchatSDK/**/*.{h,m}"
    ss.public_header_files = "NinchatSDK/*.h"
    #ss.prefix_header_file = "NinchatSDK/PrefixHeader.pch"
    ss.resource_bundles = {
        "NinchatSDKUI" => ["NinchatSDK/**/*.{storyboard,xib,xcassets}"],
    }
 end

 # The SDK is our main spec
 s.default_subspec = "SDK"

  # Provide our Go library Client.framework and Libjingle as vendored frameworks
  #s.vendored_frameworks = "Frameworks/Client.framework", "Frameworks/Libjingle.framework"

#s.dependency "#{s.name}/Client"
#  s.dependency "#{s.name}/Libjingle"

  # Frameworks / libraries required by our vendored frameworks
  #s.frameworks = "VideoToolbox"
  #s.libraries = "stdc++"

  # SDK sources / resources
  #s.source_files = "NinchatSDK/**/*.{h,m}"
  #s.public_header_files = "NinchatSDK/*.h"
  #s.resource_bundles = {
  #  "NinchatSDKUI" => ["NinchatSDK/**/*.{storyboard,xib,xcassets}"],
  #}

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

  # Cocoapods dependencies
  s.dependency "AFNetworking", "~> 3.0"
  s.dependency "NinchatLowLevel", "~> 0"

  s.module_name = "NinchatSDK"
  s.requires_arc = true
end
