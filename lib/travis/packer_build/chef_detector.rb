require_relative 'chef_cookbooks'
require_relative 'chef_packer_templates'

module Travis
  module PackerBuild
    class ChefDetector
      def initialize(cookbooks_path, packer_templates_path, log)
        @cookbooks_path = cookbooks_path
        @packer_templates_path = packer_templates_path
        @log = log
      end

      def detect(git_paths)
        return [] if git_paths.empty?
        filenames = git_paths.map(&:namespaced_path)
        to_trigger = []

        packer_templates.each do |template, run_list_cookbooks|
          log.info "Detecting type=chef template=#{template.name}"
          to_trigger << template if filenames.include?(template.filename)

          run_list_cookbooks.each do |cb|
            cb_files = Array(cookbooks.files(cb)).map(&:namespaced_path)
            next if cb_files.empty?
            to_trigger << template unless (filenames & cb_files).empty?
          end
        end

        to_trigger.sort_by(&:name).uniq(&:name)
      end

      private

      attr_reader :cookbooks_path, :packer_templates_path, :log

      def packer_templates
        @packer_templates ||= Travis::PackerBuild::ChefPackerTemplates.new(
          cookbooks_path, packer_templates_path
        )
      end

      def cookbooks
        @cookbooks ||= Travis::PackerBuild::ChefCookbooks.new(cookbooks_path)
      end
    end
  end
end
