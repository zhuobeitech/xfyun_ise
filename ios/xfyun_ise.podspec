#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'xfyun_ise'
  s.version          = '0.0.1'
  s.summary          = '科大讯飞语音评测插件'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://91ddedu.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Deng Deng PTE' => 'info@ptecourse.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.frameworks = 'AVFoundation', 'SystemConfiguration', 'Foundation', 'CoreTelephony', 'AudioToolbox', 'UIKit', 'CoreLocation', 'QuartzCore', 'CoreGraphics', 'CoreTelephony', 'CoreTelephony', 'CoreTelephony', 'CoreTelephony'
  s.libraries = 'c++', 'z'
  s.vendored_frameworks = 'Frameworks/iflyMSC.framework'
  
  s.ios.deployment_target = '8.0'
end

