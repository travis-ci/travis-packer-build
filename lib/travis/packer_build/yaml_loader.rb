require 'yaml'
require 'erb'

module Travis
  module PackerBuild
    class YamlLoader
      def self.load_string(string)
        YAML.load(ERB.new(string).result)
      end
    end
  end
end
