require_relative 'packer_templates'

module Travis
  module PackerBuild
    class PostProcessorDetector
      def initialize(packer_templates_path, log)
        @packer_templates_path = packer_templates_path
        @log = log
      end

      def detect(git_paths)
        return [] if git_paths.empty?
        filenames = git_paths.map(&:namespaced_path)
        to_trigger = []

        packer_templates.each do |_, template|
          log.info "Detecting type=post-processor template=#{template.name}"
          to_trigger << template if filenames.include?(template.filename)
          intersection = post_processor_files(
            (template.parsed['post-processors'] || []).flatten
          ) & filenames
          to_trigger << template unless intersection.empty?
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

      def post_processor_files(post_processors)
        shell_local_post_processors = post_processors.select do |p|
          p['type'] == 'shell-local'
        end

        script_files = shell_local_post_processors.map do |p|
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
