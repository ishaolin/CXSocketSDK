#
# Be sure to run `pod lib lint CXSocketSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do | s |
    s.name             = 'CXSocketSDK'
    s.version          = '1.0'
    s.summary          = 'CXSocketSDK'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = 'CXSocketSDK'
    
    s.homepage         = 'https://github.com/ishaolin/CXSocketSDK'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'wshaolin' => 'ishaolin@163.com' }
    s.source           = { :git => 'https://github.com/ishaolin/CXSocketSDK.git', :tag => s.version.to_s }
    
    s.ios.deployment_target = '9.0'
    
    s.subspec 'ProtoBuffer' do | sp |
        sp.public_header_files = 'CXSocketSDK/ProtoBuffer/**/*.h'
        sp.source_files = 'CXSocketSDK/ProtoBuffer/**/*'
        sp.requires_arc = false
    end
    
    s.public_header_files = 'CXSocketSDK/Classes/**/*.h'
    s.source_files = 'CXSocketSDK/Classes/**/*'
    
    s.dependency 'CocoaAsyncSocket', '7.6.5'
    s.dependency 'Protobuf', '3.17.0'
    s.dependency 'CXFoundation'
end
