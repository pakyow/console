module Pakyow
  module Console
    class RobotsTxt
      def initialize
        @agents = []
      end
      
      def agent(name)
        agent = RobotsAgent.new(name)
        @agents << agent
        yield agent
      end
      
      def to_s
        @agents.map(&:to_s).join("\n")
      end
    end
    
    class RobotsAgent
      def initialize(name)
        @name = name
        @rules = []
      end
      
      def allow(path)
        @rules << [:allow, path]
      end
      
      def disallow(path)
        @rules << [:disallow, path]
      end
      
      def to_s
        "User-agent: #{@name}\n" + @rules.map { |rule|
          "#{rule[0].capitalize}: #{rule[1]}"
        }.join("\n")
      end
    end
  end
end
