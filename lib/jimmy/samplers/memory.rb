# The design of the class is inspired by:
# https://github.com/newrelic/rpm/blob/master/lib/new_relic/agent/samplers/memory_sampler.rb

module Jimmy
  module Samplers
    class Memory
      def collect
        {
          rss: Memory.sampler.sample
        }
      end

      def self.sampler
        @sampler ||= determine_sampler
      end

      def self.determine_sampler
        case platform
        when  /linux/
          linux_sampler = ProcStatus.new
          linux_sampler.can_run? ? linux_sampler : ShellPS.new('ps -o rsz')
        when /darwin9/
          ShellPS.new('ps -o rsz')
        when /darwin1\d+/, /freebsd/
          ShellPS.new('ps -o rss')
        end
      end

      def self.platform
        if RUBY_PLATFORM =~ /java/
          `uname -s`.downcase
        else
          RUBY_PLATFORM.downcase
        end
      end

      class Base
        def can_run?
          return false if @broken
          memory = retrieve_memory_usage
          memory && memory > 0
        rescue
          false
        end

        def sample
          return nil if @broken
          memory = retrieve_memory_usage
          @broken = true if memory.nil?
          memory
        rescue
          @broken = true
          nil
        end
      end

      # ProcStatus
      #
      # A class that samples memory by reading the file /proc/$$/status, which is specific to linux
      #
      class ProcStatus < Base
        # Returns the amount of resident memory this process is using in MB
        #
        def retrieve_memory_usage
          proc_status = File.open(proc_status_file, 'r') { |f| f.read_nonblock(4096).strip }
          return Regexp.last_match(1).to_f / 1024.0 if proc_status =~ /RSS:\s*(\d+) kB/i
          fail "Unable to find RSS in #{proc_status_file}"
        end

        def proc_status_file
          @@proc_file ||= "/proc/#{Process.pid}/status"
        end

        def to_s
          "proc status file sampler: #{proc_status_file}"
        end
      end

      class ShellPS < Base
        def initialize(command)
          super()
          @command = command
        end

        # Returns the amount of resident memory this process is using in MB
        #
        def retrieve_memory_usage
          memory = begin
            `#{shell_command}`.split("\n")[1].to_f / 1024.0
          rescue
            nil
          end
          # if for some reason the ps command doesn't work on the resident os,
          # then don't execute it any more.
          fail "Faulty command: `#{@command} #{process}`" if memory.nil? || memory <= 0
          memory
        end

        def shell_command
          @@cached_shell_command ||= "#{@command} #{Process.pid}"
        end

        def to_s
          "shell command sampler: #{@command}"
        end
      end
    end
  end
end
