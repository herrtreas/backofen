$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Backofen
  VERSION = '0.0.1'

  autoload :Prototype, 'backofen/prototype'
end
