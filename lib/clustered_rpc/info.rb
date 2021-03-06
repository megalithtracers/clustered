require 'clustered_rpc/methods'
require 'open3'

module ClusteredRpc
  class Info
    include ClusteredRpc::Methods

    def self.stats(detailed_memory_stats = false)
      require 'objspace'
      r = 
      { instance_id: ClusteredRpc.instance_id, 
        transport_class: ClusteredRpc.transport_class.name.to_s, 
        options: ClusteredRpc.options,
        process_id: Process.pid,
        uptime: get_uptime,
        used_mb: memory_used,
        startup_command: startup_command,
        process_type: lookup_process_type(startup_command),
        count_nodes: ObjectSpace.count_nodes,
      }
      if detailed_memory_stats
        r[:count_objects_size] = ObjectSpace.count_objects_size
        r[:gc] = GC.stat
      end
      r
    end

    def self.startup_command
      "#{$0} #{$*}"
    end

    def self.memory_used
      (((100.0 * (`ps -o rss -p #{$$}`.strip.split.last.to_f / 1024.0)).to_i) / 100.0)
    end

    def self.get_uptime 
      Open3.capture3("ps", "-p", Process.pid.to_s, "-o", "etime=").first.split("\n").first
    end

    def self.lookup_process_type(sc = startup_command)
      process_type = if (sc == "script/rails []") || (sc == "bin/rails []") || ( sc =~ /spring app/)
        "Rails Console"
      elsif (sc =~ /sidekiq/) 
        "Sidekiq"
      elsif (sc =~ /puma/) 
        "Web Server"
      elsif (sc =~ /rspec/)
        "Rspec"
      elsif sc =~ /scheduler/
        "Resque Scheduler"
      elsif sc =~ /resque:work/
        "Resque Worker"
      elsif sc =~ /rules:redis/
        "Rules Engine"
      else
        sc
      end
      process_type
    end

  end
end