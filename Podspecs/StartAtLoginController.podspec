Pod::Spec.new do |s|
  s.name         =  'StartAtLoginController'
  s.version      =  '0.0.1'
  s.summary      =  'A class that uses the new ServiceManagement api to allow apps to run at login.'
  s.homepage     =  'http://www.alexzielenski.com'
  s.author       =  { 'Alex Zielenski' => 'alex@alexzielenski.com' }
  s.source       =  { :git => 'https://github.com/alexzielenski/StartAtLoginController.git' }
  s.license      =  'MIT'

  s.source_files =  %w(StartAtLoginController.h StartAtLoginController.m)
end
