require_relative 'packer_template'
require_relative 'yaml_loader'

module Travis
  module PackerBuild
    class PackerTemplates
      def initialize(packer_templates_path)
        @packer_templates_path = packer_templates_path
      end

      def each(&block)
        templates_by_name.each(&block)
      end

      private

      attr_reader :packer_templates_path

      def templates_by_name
        @templates_by_name ||= load_templates_by_name
      end

      def load_templates_by_name
        loaded = {}

        packer_template_files.each do |filename, string|
          template = Travis::PackerBuild::PackerTemplate.new(filename, string)
          loaded[template.name] = template
        end

        loaded
      end

      def packer_template_files
        files = packer_templates_path.map do |entry|
          entry.files(/.*\.(yml|json)$/).select do |p|
            packer_template?(p.show)
          end
        end

        files.flatten.compact.sort_by(&:namespaced_path).map do |p|
          [p.namespaced_path, p.show]
        end
      end

      def packer_template?(file_contents)
        parsed = Travis::PackerBuild::YamlLoader.load_string(file_contents)
        %w[variables builders provisioners].all? { |k| parsed.include?(k) }
      rescue => e
        $stderr.puts "ERROR: #{e}\n#{e.backtrace.join("\n")}" if ENV['DEBUG']
        false
      end
    end
  end
end
