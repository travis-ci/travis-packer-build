require_relative 'chef_dependency_finder'
require_relative 'packer_templates'

module Travis
  module PackerBuild
    class ChefPackerTemplates
      def initialize(cookbook_path, packer_templates_path)
        @cookbook_path = cookbook_path
        @packer_templates_path = packer_templates_path
      end

      def each(&block)
        cookbooks_by_template.each(&block)
      end

      private

      attr_reader :cookbook_path, :packer_templates_path

      def cookbooks_by_template
        @cookbooks_by_template ||= load_cookbooks_by_template
      end

      def load_cookbooks_by_template
        loaded = {}

        packer_templates.each do |_, t|
          Array(t.parsed['provisioners']).each do |provisioner|
            next unless provisioner['type'] =~ /chef/
            next if Array(provisioner.fetch('run_list', [])).empty?
            loaded[t] = find_dependencies(
              provisioner['run_list'], cookbook_path
            )
          end
        end

        loaded
      end

      def packer_templates
        @packer_templates ||= Travis::PackerBuild::PackerTemplates.new(
          packer_templates_path
        )
      end

      def find_dependencies(run_list, cookbook_path)
        Travis::PackerBuild::ChefDependencyFinder.new(
          run_list, cookbook_path
        ).find
      end
    end
  end
end
