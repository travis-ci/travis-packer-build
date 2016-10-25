module Travis
  module PackerBuild
    class Options
      attr_accessor :chef_cookbook_path, :packer_templates_path
      attr_accessor :root_repo, :root_repo_dir, :target_repo_slug
      attr_accessor :github_api_token, :branch, :pull_request
      attr_accessor :commit_range, :clone_tmp, :default_builders
      attr_accessor :included_templates, :body_tmpl, :noop, :quiet
    end
  end
end
