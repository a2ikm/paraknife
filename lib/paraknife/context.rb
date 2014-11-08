require "logger"
require "open3"
require "term/ansicolor"

module Paraknife
  class Context
    attr_reader :logger, :backend, :subcommand, :node, :options

    def initialize(backend, subcommand, node, options)
      @backend = backend
      @subcommand = subcommand
      @node = node
      @options = options

      setup_logger
    end

    def run
      logger.info command
      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        begin
          loop do
            IO.select([stdout, stderr]).flatten.compact.each do |io|
              io.each do |line|
                next if line.nil? || line.empty?

                if io == stdout
                  logger.info line
                elsif io == stderr
                  logger.warn line
                end
              end
            end
            break if stdout.closed? && stderr.closed?
          end
        rescue EOFError
        end
      end
    end

    def command
      [
        "knife",
        backend,
        subcommand,
        node,
        options,
      ].flatten.compact.join(" ")
    end

    private

      def setup_logger
        color = rand(0..255)
        colored_node = Term::ANSIColor.color(color, node)

        @logger = Logger.new(STDOUT)
        @logger.formatter = proc { |severity, datetime, progname, msg| "[#{colored_node}] #{msg.chomp}\n" }
      end
  end
end
