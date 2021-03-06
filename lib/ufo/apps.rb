require 'text-table'

module Ufo
  class Apps
    autoload :CfnMap, "ufo/apps/cfn_map"
    autoload :Service, "ufo/apps/service"

    extend Memoist
    include Stack::Helper

    def initialize(options)
      @options = options
      @cluster = @options[:cluster] || default_cluster
    end

    def list
      begin
        resp = ecs.list_services(cluster: @cluster)
      rescue Aws::ECS::Errors::ClusterNotFoundException => e
        puts "ECS cluster #{@cluster.color(:green)} not found."
        exit 1
      end
      arns = resp.service_arns.sort

      puts "Listing ECS services in the #{@cluster.color(:green)} cluster."
      if arns.empty?
        puts "No ECS services found in the #{@cluster.color(:green)} cluster."
        return
      end

      resp = ecs.describe_services(services: arns, cluster: @cluster)
      display_info(resp)
    end

    def display_info(resp)
      table = Text::Table.new
      table.head = ["Service Name", "Task Definition", "Running", "Launch type", "Ufo?"]
      resp["services"].each do |s|
        table.rows << service_info(s)
      end
      puts table unless ENV['TEST']
    end

    # for specs
    def service_info(s)
      Service.new(s, @options).to_a
    end
  end
end
