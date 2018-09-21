platform :ios, '9.0'
#use_modular_headers!
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'

def all_pods
    pod 'AFNetworking', '~> 3.0'
    #pod 'NinchatLowLevel', '~> 0'
    pod 'NinchatLowLevel', :path => '.'
end

target 'NinchatSDK' do
  all_pods
end

target 'NinchatSDKTests' do
  all_pods
end
