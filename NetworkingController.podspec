Pod::Spec.new do |spec|
  spec.name         = 'NetworkingController'
  spec.version      = '1.5.2'
  spec.description  = 'Simple thread safe networking framework that works on OS X, iOS, tvOS, and watchOS.'
  spec.summary      = 'Simple thread safe networking framework.'
  spec.homepage     = 'https://github.com/Chandlerdea/NetworkingController'
  spec.author       = { 'Chandler De Angelis' => 'chandler.dea@me.com' }
  spec.source       = { :git => 'https://github.com/Chandlerdea/NetworkingController.git', :tag => "v#{spec.version}" }
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }

  spec.source_files = 'NetworkingController/Sources/*.{h,m,swift}'

  spec.frameworks = 'Foundation'

  spec.osx.deployment_target = '10.11'
  spec.ios.deployment_target = '10.0'
  spec.tvos.deployment_target = '10.0'
  spec.watchos.deployment_target = '3.0'
end



