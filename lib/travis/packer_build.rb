module Travis
  module PackerBuild
    def self.libfile(basename)
      "travis/packer_build/#{basename}"
    end

    autoload :ChefCookbooks, libfile('chef_cookbooks')
    autoload :ChefDependencyFinder, libfile('chef_dependency_finder')
    autoload :ChefDetector, libfile('chef_detector')
    autoload :ChefFakeRecipeMethods, libfile('chef_fake_recipe_methods')
    autoload :ChefPackerTemplates, libfile('chef_packer_templates')
    autoload :Cli, libfile('cli')
    autoload :FileDetector, libfile('file_detector')
    autoload :GitChangeFinder, libfile('git_change_finder')
    autoload :GitPath, libfile('git_path')
    autoload :GitRemotePathParser, libfile('git_remote_path_parser')
    autoload :Options, libfile('options')
    autoload :PackerTemplate, libfile('packer_template')
    autoload :PackerTemplates, libfile('packer_templates')
    autoload :Request, libfile('request')
    autoload :RequestBuilder, libfile('request_builder')
    autoload :ShellDetector, libfile('shell_detector')
    autoload :VERSION, libfile('version')
    autoload :YamlLoader, libfile('yaml_loader')
  end
end
