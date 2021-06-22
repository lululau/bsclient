require 'delegate'
require 'yaml'
require 'ostruct'

module BSClient
  class Config < SimpleDelegator
    class << self
      def create(env, file = nil)
        file ||= File.expand_path('~/.bsclient.yml')
        yaml = YAML.load(File.read(file)) || {}
        conf = yaml[env] || {}
        new(OpenStruct.new(conf))
      end
    end
  end
end
