require 'uri'
require 'json'
require 'yaml'

require_relative 'request'

module Travis
  module PackerBuild
    class RequestBuilder
      def initialize(travis_api_token: '', target_repo_slug: '',
                     builders: %w(), commit_range: %w(@ @),
                     branch: '', body_tmpl: '{}')
        @travis_api_token = travis_api_token
        @target_repo_slug = target_repo_slug
        @builders = builders
        @commit_range = commit_range
        @branch = branch
        @body_tmpl = load_body_tmpl(body_tmpl)
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
      attr_reader :commit_range, :branch, :body_tmpl

      def body(template)
        ret = Marshal.load(Marshal.dump(body_tmpl || {}))
        ret['message'] = interpolated_value(
          ret['message'], ':bomb: commit-range=%{commit_range_string}',
          template
        )
        ret['branch'] = interpolated_value(
          ret['branch'], template.name, template
        )
        ret['config'] ||= {}
        ret['config']['language'] = interpolated_value(
          ret['config']['language'], 'generic', template
        )
        ret['config']['dist'] = interpolated_value(
          ret['config']['dist'], 'trusty', template
        )
        ret['config']['group'] = interpolated_value(
          ret['config']['group'], 'edge', template
        )
        ret['config']['sudo'] =
          ret['config'].key?('sudo') ? ret['config']['sudo'] : true

        ret['config']['env'] ||= {}

        if ret['config']['env'].key?('matrix')
          ret['config']['env']['matrix'].each_with_index do |v, i|
            ret['config']['env']['matrix'][i] = v % body_vars(template)
          end
        else
          ret['config']['env']['matrix'] = builders.map { |b| "BUILDER=#{b}" }
        end

        ret['config']['install'] = Array(ret['config']['install'])
        if ret['config']['install'].empty?
          ret['config']['install'] = ['echo ohai']
        end

        ret['config']['install'].each_with_index do |v, i|
          ret['config']['install'][i] = v % body_vars(template)
        end

        ret['config']['script'] = Array(ret['config']['script'])
        if ret['config']['script'].empty?
          ret['config']['script'] = [
            <<-EOF.gsub(/^\s+> ?/, '').split("\n").map(&:strip).join(' ')
            > if [[ %{template_filename} =~ yml ]] ; then
            >   packer build -only=${BUILDER} <(
            >     ruby -rjson -ryaml -rerb -e "
            >       puts JSON.pretty_generate(
            >         YAML.load(ERB.new(STDIN.read).result)
            >       )
            >     " < %{template_filename}
            >   ) ;
            > else
            >   packer build -only=${BUILDER} %{template_filename} ;
            > fi
            EOF
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
          template_name: template.name,
          template_filename: template.filename
        }
      end

      def load_body_tmpl(hashstring)
        return hashstring if hashstring.respond_to?(:key)
        return YAML.load_file(hashstring) if File.exist?(hashstring)
        YAML.load(hashstring)
      end
    end
  end
end
