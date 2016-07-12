require 'uri'
require 'json'

require_relative 'request'

module Travis
  module PackerBuild
    class RequestBuilder
      def initialize(travis_api_token: '', target_repo_slug: '',
                     builders: %w(), commit_range: %w(@ @),
                     branch: '', body_json_tmpl: '{}')
        @travis_api_token = travis_api_token
        @target_repo_slug = target_repo_slug
        @builders = builders
        @commit_range = commit_range
        @branch = branch
        @body_json_tmpl = load_body_json_tmpl(body_json_tmpl)
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
      attr_reader :commit_range, :branch, :body_json_tmpl

      def body(template)
        ret = Marshal.load(Marshal.dump(body_json_tmpl || {}))
        ret['message'] = interpolated_value(
          ret['message'], ':bomb: commit-range=%{commit_range_string}',
          template
        )
        ret['branch'] = interpolated_value(ret['branch'], template, template)
        ret['config'] ||= {}
        ret['config']['language'] = interpolated_value(
          ret['config']['language'], 'generic',
          template
        )
        ret['config']['dist'] = interpolated_value(
          ret['config']['dist'], 'trusty',
          template
        )
        ret['config']['group'] = interpolated_value(
          ret['config']['group'], 'edge',
          template
        )
        ret['config']['sudo'] =
          ret['config'].key?('sudo') ? ret['config']['sudo'] : true

        ret['config']['env'] ||= {}

        if ret['config']['env'].key?('matrix')
          ret['config']['env']['matrix'].each_with_index do |v, i|
            ret['config']['env']['matrix'][i] = v % body_vars
          end
        else
          ret['config']['env']['matrix'] = builders.map { |b| "BUILDER=#{b}" }
        end

        ret['config']['install'] = Array(ret['config']['install'])
        if ret['config']['install'].empty?
          ret['config']['install'] = [
            'git clone --branch=%{branch} ' \
            'https://github.com/travis-ci/packer-templates.git',
            'pushd packer-templates && ' \
            'git checkout -qf %{commit_range_last} ; ' \
            'popd',
            './packer-templates/bin/packer-build-install'
          ]
        end

        ret['config']['install'].each_with_index do |v, i|
          ret['config']['install'][i] = v % body_vars(template)
        end

        ret['config']['script'] = Array(ret['config']['script'])
        if ret['config']['script'].empty?
          ret['config']['script'] = [
            './packer-templates/bin/packer-build-script %{template}'
          ]
        end

        ret['config']['script'].each_with_index do |v, i|
          ret['config']['script'][i] = v % body_vars(template)
        end

        ret
      end

      def interpolated_value(value, default, template)
        (value || default) % body_vars(template)
      end

      def body_vars(template)
        {
          commit_range: commit_range,
          commit_range_string: commit_range.join('...'),
          commit_range_first: commit_range.first,
          commit_range_last: commit_range.last,
          branch: branch,
          template: template
        }
      end

      def load_body_json_tmpl(hashstring)
        return hashstring if hashstring.respond_to?(:key)
        return JSON.parse(File.read(hashstring)) if File.exist?(hashstring)
        JSON.parse(hashstring)
      end
    end
  end
end
