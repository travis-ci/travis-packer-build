# frozen_string_literal: true

require_relative 'packer_templates'

module Travis
  module PackerBuild
    class ShellDetector
      def initialize(packer_templates_path, log)
        @packer_templates_path = packer_templates_path
        @log = log
      end

      def detect(git_paths)
        return [] if git_paths.empty?
        filenames = git_paths.map(&:namespaced_path)
        to_trigger = []

        packer_templates.each_value do |template|
          log.info "Detecting type=shell template=#{template.name}"
          to_trigger << template if filenames.include?(template.filename)
          intersection = provisioner_files(
            template.parsed['provisioners'] || []
          ) & filenames
          unless intersection.empty?
            to_trigger << template
            log.info "Detected type=shell template=#{template.name}"
          end
        end

        to_trigger.sort_by(&:name).uniq(&:name)
      end

      private

      attr_reader :packer_templates_path, :log

      def packer_templates
        @packer_templates ||= Travis::PackerBuild::PackerTemplates.new(
          packer_templates_path
        )
      end

      def provisioner_files(provisioners)
        shell_provisioners = provisioners.select do |p|
          p['type'] == 'shell' && (p.key?('scripts') || p.key?('script'))
        end

        script_files = shell_provisioners.map do |p|
          Array(p['scripts']) + Array(p['script'])
        end

        script_files.flatten!
        script_files.map! do |f|
          packer_templates_path.map do |entry|
            matching_files = entry.files(/#{f}/)
            matching_files.empty? ? nil : matching_files
          end
        end

        script_files.flatten.compact.map(&:namespaced_path).sort.uniq
      end
    end
  end
end
