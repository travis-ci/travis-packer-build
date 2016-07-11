module Travis
  module PackerBuild
    class Options
      attr_accessor :chef_cookbook_path, :packer_templates_path
      attr_accessor :root_repo, :root_repo_dir, :target_repo_slug
      attr_accessor :travis_api_url, :travis_api_token, :branch
      attr_accessor :request_interval, :commit_range, :clone_tmp, :builders
      attr_accessor :noop, :quiet
    end
  end
end
