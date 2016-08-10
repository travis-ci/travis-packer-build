require 'English'

require 'json'
require 'logger'
require 'optparse'
require 'uri'

require 'faraday'

require_relative 'chef_detector'
require_relative 'file_detector'
require_relative 'git_change_finder'
require_relative 'git_remote_path_parser'
require_relative 'git_root'
require_relative 'github_requester'
require_relative 'options'
require_relative 'post_processor_detector'
require_relative 'request_builder'
require_relative 'shell_detector'

module Travis
  module PackerBuild
    class Cli
      def self.run!(argv: ARGV)
        new.run(argv: argv)
      end

      def run(argv: ARGV)
        setup(argv)

        ret = 0
        triggered = 0
        errored = 0

        build_requests.each do |template, request|
          if options.noop
            log.info "Not triggering template=#{template.name} " \
                     "repo=#{options.target_repo_slug}"
            next
          end

          log.info "Performing request=#{request}"

          if github_requester.perform(request)
            log.info "Triggered template=#{template.name} " \
                     "repo=#{options.target_repo_slug}"
            triggered += 1
            next
          end

          errored += 1
          ret = 1
        end

        log.info "All done! triggered=#{triggered} errored=#{errored}"
        ret
      end

      private

      def build_requests
        request_builder.build(triggerable_templates)
      end

      def setup(argv)
        return if @setup
        parse_args(argv)
        options.packer_templates_path ||= git_remote_path_parser.parse(
          default_packer_templates_path_string
        )
        options.chef_cookbook_path ||= git_remote_path_parser.parse(
          default_chef_cookbook_path_string
        )

        if options.root_repo.nil? || options.root_repo.empty?
          options.root_repo_dir =
            options.packer_templates_path.first.repo.repo.path
        end
        @setup = true
      end

      def parse_args(argv)
        OptionParser.new do |opts|
          opts.on('-r GIT_REMOTE', '--root-repo GIT_REMOTE',
                  'Git remote of root repository to check commit range. ' \
                  'defaults to the first entry of --packer-templates-path') do |v|
            options.root_repo = v.strip
          end

          opts.on('-R GIT_DIR', '--root-repo-dir GIT_DIR',
                  'Git dir of root repository to check commit range. ' \
                  'defaults to the first entry of --packer-templates-path') do |v|
            options.root_repo_dir = File.expand_path(v.strip)
          end

          opts.on('-P GITFUL_PATH', '--packer-templates-path GITFUL_PATH',
                  'Packer templates path. ' \
                  "default=#{default_packer_templates_path_string}") do |v|
            options.packer_templates_path = git_remote_path_parser.parse(v)
          end

          opts.on('-C COMMIT_RANGE', '--commit-range COMMIT_RANGE',
                  'Commit range to check for changed paths. ' \
                  "default=#{options.commit_range}") do |v|
            options.commit_range = v.strip.split('...').map(&:strip)
          end

          opts.on('-B BRANCH', '--branch BRANCH',
                  'Branch name to clone of root repository in triggered build. ' \
                  "default=#{options.branch}") do |v|
            options.branch = v.strip
          end

          opts.on('-D CLONE_TMP', '--clone-tmp CLONE_TMP',
                  'Temporary directory for git clones. ' \
                  "default=#{options.clone_tmp}") do |v|
            options.clone_tmp = v.strip
          end

          opts.on('-c GITFUL_PATH', '--chef-cookbook-path GITFUL_PATH',
                  'Cookbook path. ' \
                  "default=#{default_chef_cookbook_path_string}") do |v|
            options.chef_cookbook_path = git_remote_path_parser.parse(v)
          end

          opts.on('-t REPO', '--target-repo-slug REPO',
                  'Target repo slug to which triggered builds should be sent. ' \
                  "default=#{options.target_repo_slug}") do |v|
            options.target_repo_slug = v.strip
          end

          opts.on('-T TOKEN', '--github-api-token TOKEN',
                  'API token for use with GitHub API.') do |v|
            options.github_api_token = v.strip
          end

          opts.on('-b BUILDERS', '--default-builders BUILDERS',
                  'Default packer builder names for which Travis jobs ' \
                  'should be triggered (","-delimited), otherwise read ' \
                  'from the given packer template. ' \
                  "default=#{options.default_builders}") do |v|
            options.default_builders = v.split(',').map(&:strip)
          end

          opts.on('-S STRING_OR_FILENAME', '--body-tmpl STRING_OR_FILENAME',
                  'YAML/JSON literal or filename to load as request body ' \
                  "template.  default=#{options.body_tmpl}") do |v|
            options.body_tmpl = v.strip
          end

          opts.separator 'Usual Suspects'

          opts.on('-n', '--noop', 'Do not do') do
            options.noop = true
          end

          opts.on('-q', '--quiet', 'Simmer down the logging') do
            options.quiet = true
          end

          opts.on_tail('-h', '--help', 'Show this message') do
            puts opts unless ENV['QUIET']
            puts "\n\n" unless ENV['QUIET']
            puts <<-EOF.gsub(/^\s+> ?/, '') unless ENV['QUIET']
              > Options that accept a `GITFUL_PATH` type expect the string
              > arguments to contain whitespace-separated tokens of the format:
              >
              >     <git-repo-remote>::[prefix[@ref]],[prefix...]
              >
              > e.g.:
              >
              >     https://github.com/repo/remote.git::cookbooks@master,ci_environment@precise-stable
              >     git@github.com:other/remote.git::
              >
              > This allows for arguments like packer templates paths and cookbook
              > paths to contain multiple entries for a given git repository,
              > while retaining a prefix "namespace" for purposes of matching file
              > paths.
              >
              > Leading '/' characters are automatically stripped from repository
              > prefixes, as git lists files without leading slashes.
            EOF
            exit 0
          end
        end.parse!(argv)
      end

      def options
        @options ||= Travis::PackerBuild::Options.new.tap do |opts|
          opts.root_repo = ENV.fetch('ROOT_REPO', '')
          opts.target_repo_slug = ENV.fetch(
            'TARGET_REPO_SLUG', 'dev/null'
          )
          opts.github_api_token = ENV.fetch('GITHUB_API_TOKEN', '')

          opts.commit_range = ENV.fetch(
            'COMMIT_RANGE',
            ENV.fetch(
              'TRAVIS_COMMIT_RANGE',
              '@...@' # <--- the empty range
            )
          ).split('...').map(&:strip)

          opts.branch = ENV.fetch(
            'BRANCH', ENV.fetch('TRAVIS_BRANCH', 'master')
          )
          opts.clone_tmp = ENV.fetch(
            'CLONE_TMP', File.join(Dir.tmpdir, 'travis-packer-build')
          )

          opts.default_builders = ENV.fetch(
            'BUILDERS', 'amazon-ebs,googlecompute,docker'
          ).split(',').map(&:strip)

          opts.body_tmpl = ENV.fetch('BODY_TMPL', '{}')

          opts.noop = ENV['NOOP'] == '1'
          opts.quiet = ENV['QUIET'] == '1'
        end
      end

      def github_requester
        @github_requester ||= Travis::PackerBuild::GithubRequester.new(
          github_api_token: options.github_api_token,
          repo_slug: options.target_repo_slug
        )
      end

      def git_remote_path_parser
        @git_remote_path_parser ||=
          Travis::PackerBuild::GitRemotePathParser.new(
            clone_tmp: options.clone_tmp
          )
      end

      def default_packer_templates_path_string
        ENV.fetch('PACKER_TEMPLATES_PATH', "#{Dir.getwd}::")
      end

      def default_chef_cookbook_path_string
        ENV.fetch('CHEF_COOKBOOK_PATH', "#{Dir.getwd}::cookbooks")
      end

      def detectors
        @detectors ||= [
          Travis::PackerBuild::ChefDetector.new(
            options.chef_cookbook_path,
            options.packer_templates_path,
            log
          ),
          Travis::PackerBuild::FileDetector.new(
            options.packer_templates_path, log
          ),
          Travis::PackerBuild::ShellDetector.new(
            options.packer_templates_path, log
          ),
          Travis::PackerBuild::PostProcessorDetector.new(
            options.packer_templates_path, log
          )
        ]
      end

      def request_builder
        @request_builder ||= Travis::PackerBuild::RequestBuilder.new(
          default_builders: options.default_builders,
          branch: options.branch,
          body_tmpl: options.body_tmpl,
          body_vars: {
            commit_range: commit_range,
            commit_range_string: commit_range.join('...'),
            commit_range_first: commit_range.first,
            commit_range_last: commit_range.last,
            source_commit: commit_range.last,
            source_commit_message: commit_message(commit_range.last)
          }
        )
      end

      def triggerable_templates
        detectors.map { |d| d.detect(changed_files) }
                 .flatten.sort_by(&:name).uniq(&:name)
      end

      def changed_files
        git_change_finder.find
      end

      def git_change_finder
        @git_change_finder ||= Travis::PackerBuild::GitChangeFinder.new(
          root: root_repo_git,
          packer_templates_path: options.packer_templates_path,
          clone_tmp: options.clone_tmp
        )
      end

      def root_repo_git
        @root_repo_git ||= Travis::PackerBuild::GitRoot.new(
          commit_range: commit_range,
          branch: options.branch,
          dir: options.root_repo_dir,
          remote: options.root_repo
        )
      end

      def commit_message(treeish)
        Git.bare(options.root_repo_dir)
           .gcommit(treeish)
           .message
           .sub(/.*END PGP SIGNATURE-+/m, '')
           .strip
      end

      def commit_range
        @commit_range ||= begin
                            [
                              options.commit_range.first,
                              options.commit_range.last
                            ].map { |v| v.nil? || v.to_s.empty? ? '@' : v }
                          end
      end

      def log
        @log ||= Logger.new($stdout).tap do |l|
          l.level = Logger::FATAL if options.quiet
          l.progname = File.basename($PROGRAM_NAME)
          l.formatter = proc do |_, _, progname, msg|
            "#{progname}: #{msg}\n"
          end
        end
      end
    end
  end
end
