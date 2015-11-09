Pod::Spec.new do |s|
  s.name         = "AppLord"
  s.version      = "0.0.1"
  s.summary      = "The load of iOS app"

  s.description  = <<-DESC

                   * Module: module management 
                   * Service Between modules 
                   * event between modules 
                   DESC

  s.homepage     = "http://gitlab.cnbluebox.com/bluebox/AppLord"

  s.license      = "MIT (example)"

  s.author             = { "念纪" => "765409243@qq.com" }
  s.platform     = :ios, "6.0"

  s.source       = { :git => "http://EXAMPLE/AppLord.git", :tag => "0.0.1" }
  s.source_files  = "AppLord/**/*.{h,m}"

  s.requires_arc = true

end
