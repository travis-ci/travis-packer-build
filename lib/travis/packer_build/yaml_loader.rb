require 'yaml'
require 'erb'

module Travis
  module PackerBuild
    class YamlLoader
      def self.load_string(string)
        YAML.load(ERB.new(string).result(binding))
      end

      def self.git_desc
        'fafafaf'
      end
    end
  end
end
