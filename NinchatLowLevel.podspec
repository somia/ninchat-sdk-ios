# coding: utf-8

Pod::Spec.new do |s|
  s.name         = "NinchatLowLevel"
  s.version      = "0.0.9"
  s.summary      = "Low-level communications library for Ninchat messaging."
  s.description  = "For providing low-level communications using Ninchat messaging."
  s.homepage     = "https://ninchat.com/"
  s.license      = { :type => "Ninchat", :file => "LICENSE.md" }
  s.author       = { "Matti Dahlbom" => "matti.dahlbom@qvik.fi" }
  s.source       = { :git => "https://github.com/somia/ninchat-sdk-ios.git", :tag => "#{s.version}" }

  s.ios.deployment_target = "9.0"

  s.vendored_frameworks = "Frameworks/Client.framework"
# s.source_files = "Frameworks/Client.framework/Headers/*.h"

end

