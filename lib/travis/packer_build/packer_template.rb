# frozen_string_literal: true

require_relative 'yaml_loader'

module Travis
  module PackerBuild
    class PackerTemplate
      def initialize(filename, string)
        @name = File.basename(filename.sub(/.*::/, '')).sub(/\.(yml|json)/, '')
        @filename = filename
        @parsed = Travis::PackerBuild::YamlLoader.load_string(string)
      end

      attr_reader :name, :filename, :parsed
    end
  end
end
