require 'uri'
require 'json'
require 'yaml'

require_relative 'request'

module Travis
  module PackerBuild
    class RequestBuilder
      def initialize(default_builders: %w(), body_vars: {},
                     branch: '', body_tmpl: '{}')
        @default_builders = default_builders
        @body_vars = body_vars
        @branch = branch
        @body_tmpl = load_body_tmpl(body_tmpl)
      end

      def build(triggerable_templates)
        requests = []
        triggerable_templates.each do |template|
          request = Travis::PackerBuild::Request.new.tap do |req|
            rendered = body(template)
            req.message = rendered['message']
            req.config = rendered['config']
            req.branch = rendered['branch']
          end
          requests << [template, request]
        end
        requests
      end

      private

      attr_reader :default_builders, :body_vars, :branch, :body_tmpl

      def body(template)
        ret = Marshal.load(Marshal.dump(body_tmpl || {}))
        ret['message'] ||= ':bomb:'
        ret['branch'] ||= template.name
        ret['config'] ||= {}
        ret['config']['language'] ||= 'generic'
        ret['config']['dist'] ||= 'trusty'
        ret['config']['group'] ||= 'edge'

        ret['config']['sudo'] =
          ret['config'].key?('sudo') ? ret['config']['sudo'] : true

        ret['config']['env'] ||= {}

        unless ret['config']['env'].key?('matrix')
          builders = default_builders
          if template.parsed.key?('builders')
            builders = template.parsed['builders'].map do |builder|
              builder['name'] || builder['type']
            end
          end
          ret['config']['env']['matrix'] = builders.map { |b| "BUILDER=#{b}" }
        end

        ret['config']['install'] = Array(ret['config']['install'])
        if ret['config']['install'].empty?
          ret['config']['install'] = ['echo ohai']
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

        render_body_tmpl(ret, template)
      end

      def render_body_tmpl(modified_body_tmpl, template)
        redumped = YAML.dump(modified_body_tmpl) % body_vars.merge(
          branch: branch,
          template_name: template.name,
          template_filename: template.filename
        )
        YAML.load(redumped)
      end

      def load_body_tmpl(hashstring)
        return hashstring if hashstring.respond_to?(:key)
        return YAML.load_file(hashstring) if File.exist?(hashstring)
        YAML.load(hashstring)
      end
    end
  end
end
