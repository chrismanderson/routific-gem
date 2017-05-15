module RoutificApi
  # This class represents the resulting schedule returned by the Routific API
  class Schedule
    attr_reader :status, :unserved, :solution, :total_travel_time, :total_idle_time, :total_working_time, :polyline_precision, :total_distance

    # Constructor
    def initialize(status:, solution: {}, unserved: {}, total_travel_time: 0, total_idle_time: 0, total_distance: 0, total_working_time: 0, pl_precision: nil, polylines: {}, **_)
      @status = status
      @unserved = unserved
      @total_idle_time = total_idle_time
      @total_travel_time = total_travel_time
      @total_working_time = total_working_time
      @polyline_precision = pl_precision
      @polylines = polylines
      @total_distance = total_distance

      add_solution(solution)
    end

    def add_solution(solution)
      @solution = {}

      solution.each do |vehicle_name, way_points|
        # Get all way points for this vehicle
        way_points.each do |waypoint_info|
          # Get all information for this way point
          way_point = RoutificApi::WayPoint.new(waypoint_info)
          add_way_point(vehicle_name, way_point)
        end
      end
    end

    # Adds a new way point for the specified vehicle
    def add_way_point(vehicle_name, way_point)
      if @solution[vehicle_name].nil?
        # No previous way point was added for the specified vehicle, so create a new array
        @solution[vehicle_name] = []
      end
      # Adds the provided way point for the specified vehicle
      @solution[vehicle_name] << way_point
    end

    def number_of_unserved
      @number_of_unserved ||= unserved.count
    end

    class << self
      # Parse the JSON representation of a route, and return it as a Route object
      def parse(data)
        data = process_data(data)
        RoutificApi::Schedule.new(data)
      end

      def process_data(hash)
        hash.keys.each do |key|
          hash[(key.to_sym rescue key) || key] = hash.delete(key)
        end

        hash.delete(:num_unserved)
        hash.delete(:unserved) if hash[:unserved].nil?

        hash
      end
    end
  end
end
