require 'uri'
require 'json'

module Travis
  module PackerBuild
    class RequestBuilder
      def initialize(travis_api_token: '', target_repo_slug: '',
                     builders: %w(), commit_range: %w(@ @),
                     branch: '')
        @travis_api_token = travis_api_token
        @target_repo_slug = target_repo_slug
        @builders = builders
        @commit_range = commit_range
        @branch = branch
      end

      def build(triggerable_templates)
        requests = []
        triggerable_templates.each do |template|
          request = Travis::PackerBuild::Request.new.tap do |req|
            req.url = File.join(
              '/repo', URI.escape(target_repo_slug, '/'), 'requests'
            )
            req.body = JSON.dump(body(template))
            req.headers = {
              'Content-Type' => 'application/json',
              'Accept' => 'application/json',
              'Travis-API-Version' => '3',
              'Authorization' => "token #{travis_api_token}"
            }
          end
          requests << [template, request]
        end
        requests
      end

      private

      attr_reader :travis_api_token, :target_repo_slug, :builders
      attr_reader :commit_range, :branch

      def body(template)
        {
          message: ':lemon: :bomb: ' \
            "commit-range=#{commit_range.join('...')}",
          branch: template,
          config: {
            language: 'generic',
            dist: 'trusty',
            group: 'edge',
            sudo: true,
            env: {
              matrix: builders.map { |b| "BUILDER=#{b}" }
            },
            # TODO: Make most/all of this config-injectable
            install: [
              "git clone --branch=#{branch} " \
              'https://github.com/travis-ci/packer-templates.git',
              'pushd packer-templates && ' \
              "git checkout -qf #{commit_range.last} ; " \
              'popd',
              './packer-templates/bin/packer-build-install'
            ],
            script: "./packer-templates/bin/packer-build-script #{template}"
          }
        }
      end
    end
  end
end
