module Travis
  module PackerBuild
    autoload :ChefCookbooks, 'travis/packer_build/chef_cookbooks'
    autoload :ChefDependencyFinder, 'travis/packer_build/chef_dependency_finder'
    autoload :ChefDetector, 'travis/packer_build/chef_detector'
    autoload :ChefFakeRecipeMethods, 'travis/packer_build/chef_fake_recipe_methods'
    autoload :ChefPackerTemplates, 'travis/packer_build/chef_packer_templates'
    autoload :FileDetector, 'travis/packer_build/file_detector'
    autoload :GitPath, 'travis/packer_build/git_path'
    autoload :PackerTemplate, 'travis/packer_build/packer_template'
    autoload :PackerTemplates, 'travis/packer_build/packer_templates'
    autoload :ShellDetector, 'travis/packer_build/shell_detector'
    autoload :Trigger, 'travis/packer_build/trigger'
    autoload :VERSION, 'travis/packer_build/version'
    autoload :YamlLoader, 'travis/packer_build/yaml_loader'
  end
end
