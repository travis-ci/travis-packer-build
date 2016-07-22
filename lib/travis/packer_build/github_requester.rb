require 'json'

require 'gh'

module Travis
  module PackerBuild
    class GithubRequester
      def initialize(github_api_token: '', repo_slug: '')
        @github_api_token = github_api_token
        @repo_slug = repo_slug
      end

      def perform(request)
        commit_sha = base_commit(request.branch)
        return false if commit_sha.empty?

        blob_sha = create_blob(request.config)
        blob_tree = create_tree(fetch_tree(commit_sha), blob_sha)
        blob_commit_sha = create_commit(
          blob_tree, commit_sha, request.message
        )

        update_ref(request.branch, blob_commit_sha)
        true
      end

      private

      attr_reader :github_api_token, :repo_slug

      def update_ref(name, sha)
        gh.patch(
          "#{repos_path}/git/refs/heads/#{name}",
          { sha: sha }.to_json
        )
      end

      def create_commit(tree_sha, parent_sha, message)
        gh.post(
          "#{repos_path}/git/commits",
          {
            tree: tree_sha,
            parents: [
              parent_sha
            ],
            message: message
          }.to_json
        )['sha']
      end

      def create_tree(tree_sha, blob_sha)
        gh.post(
          "#{repos_path}/git/trees",
          {
            base_tree: tree_sha,
            tree: [
              {
                type: 'blob',
                path: '.travis.yml',
                mode: '100644',
                sha: blob_sha
              }
            ]
          }.to_json
        )['sha']
      end

      def create_blob(config)
        gh.post(
          "#{repos_path}/git/blobs",
          { content: YAML.dump(config) }.to_json
        )['sha']
      end

      def fetch_tree(commit_sha)
        gh["#{repos_path}/git/commits/#{commit_sha}"]['tree']['sha']
      end

      def base_commit(branch)
        gh["#{repos_path}/git/refs/heads/#{branch}"]['object']['sha']
      rescue
        return ''
      end

      def repos_path
        @repos_path ||= URI(
          gh["repos/#{repo_slug}"]['_links']['self']['href']
        ).path
      end

      def gh
        @gh ||= GH::DefaultStack.build(token: github_api_token)
      end
    end
  end
end
