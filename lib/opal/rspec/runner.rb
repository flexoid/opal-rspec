require 'shellwords'
require 'opal/rspec'
require 'tempfile'
require 'socket'

module Opal
  module RSpec
    class Runner
      attr_accessor :pattern, :exclude_pattern, :files, :default_path, :runner, :timeout, :arity_checking, :spec_opts, :cli_options

      def arity_checking?
        setting = @arity_checking || :enabled
        setting == :enabled
      end

      def runner
        @runner ||= ENV['RUNNER']
      end

      def spec_opts
        @spec_opts ||= ENV['SPEC_OPTS']
      end

      def get_load_asset_code(server)
        sprockets = server.sprockets
        name = server.main
        asset = sprockets[name]
        raise "Cannot find asset: #{name}" if asset.nil?
        Opal::Sprockets.load_asset name, sprockets
      end

      class LegacyServerProxy
        require 'set'
        def initialize
          @paths ||= Set.new
        end

        def append_path(path)
          @paths << path
        end

        # noop options
        attr_accessor :debug

        def to_cli_options
          options = []
          @paths.map do |path|
            options << "-r#{path.shellescape}"
          end
          options
        end
      end

      def initialize(&block)
        @legacy_server_proxy = LegacyServerProxy.new
        block.call(@legacy_server_proxy, self) if block_given? # for compatibility

        raise 'Cannot supply both a pattern and files!' if self.files and self.pattern

        pre_locator = RSpec::PreRackLocator.new self.pattern, self.exclude_pattern, self.files, self.default_path
        post_locator = RSpec::PostRackLocator.new pre_locator

        options = []
        options << '--arity-check' if arity_checking?
        options += ['--runner', runner] if runner
        options << '-ropal/platform'
        options << '-ropal-rspec'
        options += @legacy_server_proxy.to_cli_options
        (Opal.paths+pre_locator.get_spec_load_paths).each { |p| options << "-I#{p}" }
        post_locator.get_opal_spec_requires.each          { |p| options << "-r#{p}" }
        ::Opal::Config.stubbed_files.each                 { |p| options << "-s#{p}" }
        options += @cli_options if @cli_options
        tempfile_path = "/tmp/opal-rspec-runner-#{$$}.rb"

        File.write tempfile_path, [
          ::Opal::RSpec.spec_opts_code(spec_opts),
          '::RSpec::Core::Runner.autorun',
        ].join(';')

        @command = "opal #{options.map(&:shellescape).join ' '} #{tempfile_path.shellescape}"
      end

      def options
        {
          pattern: pattern,
          exclude_pattern: exclude_pattern,
          files: files,
          default_path: default_path,
          runner: runner,
          timeout: timeout,
          arity_checking: arity_checking,
          spec_opts: spec_opts,
        }
      end


      def command
        @command
      end

      def run
        system command
      end
    end
  end
end

