require 'forwardable'

module Travis
  module PackerBuild
    class PackerTemplate
      extend Forwardable

      def initialize(filename, string)
        @name = File.basename(filename.sub(/.*::/, ''), '.yml')
        @filename = filename
        @parsed = Travis::PackerBuild::YamlLoader.load_string(string)
      end

      attr_reader :name, :filename, :parsed

      def_delegators :@parsed, :[], :each
    end
  end
end
