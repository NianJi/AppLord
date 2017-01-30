Pod::Spec.new do |s|
  s.name         = "AppLord"
  s.version      = "1.2.1"
  s.summary      = "The lord of iOS app modules"

  s.description  = <<-DESC

                   * Module: module management 
                   * Service Between modules 
                   * Task manage global tasks
                   DESC

  s.platform     = :ios
  s.ios.deployment_target = '6.0'

  s.homepage     = "https://github.com/NianJi/AppLord"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = { "fengnianji" => "765409243@qq.com" }

  s.source       = { :git => "https://github.com/NianJi/AppLord.git", :tag => "1.2.1" }
  s.source_files  = "AppLord/**/*.{h,m}"

  s.frameworks = 'Foundation', 'UIKit'
  s.requires_arc = true

end
