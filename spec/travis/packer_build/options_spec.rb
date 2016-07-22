require 'travis/packer_build/options'

describe Travis::PackerBuild::Options do
  %w(
    body_tmpl
    branch
    chef_cookbook_path
    clone_tmp
    commit_range
    default_builders
    noop
    packer_templates_path
    quiet
    root_repo
    root_repo_dir
    target_repo_slug
    github_api_token
  ).each do |attr|
    it("has a #{attr} attr") { subject.public_send(attr) }
  end
end
