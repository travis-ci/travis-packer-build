# frozen_string_literal: true

require_relative 'packer_templates'

module Travis
  module PackerBuild
    class FileDetector
      def initialize(packer_templates_path, log)
        @packer_templates_path = packer_templates_path
        @log = log
      end

      def detect(git_paths)
        return [] if git_paths.empty?
        filenames = git_paths.map(&:namespaced_path)
        to_trigger = []

        packer_templates.each_value do |template|
          log.info "Detecting type=file template=#{template.name}"
          to_trigger << template if filenames.include?(template.filename)
          intersection = provisioner_files(
            template.parsed['provisioners'] || []
          ) & filenames
          unless intersection.empty?
            to_trigger << template
            log.info "Detected type=file template=#{template.name}"
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
        files = provisioners.select { |p| p['type'] == 'file' }.map do |p|
          packer_templates_path.map do |entry|
            matching_files = entry.files(/#{p['source']}/)
            matching_files.empty? ? nil : matching_files
          end
        end
        files.flatten.compact.map(&:namespaced_path).sort.uniq
      end
    end
  end
end
