module Travis
  module PackerBuild
    class Options
      attr_accessor :chef_cookbook_path, :packer_templates_path
      attr_accessor :root_repo, :root_repo_dir, :target_repo_slug
      attr_accessor :github_api_token, :branch, :commit_range
      attr_accessor :clone_tmp, :default_builders, :body_tmpl
      attr_accessor :noop, :quiet
    end
  end
end
