module RoutificApi
  # This class represents the resulting route returned by the Routific API
  class Route
    attr_reader :status, :unserved, :vehicleRoutes, :total_travel_time, :total_idle_time

    # Constructor
    def initialize(status:, unserved: {}, total_travel_time: 0, total_idle_time: 0)
      @status = status
      @unserved = unserved
      @total_idle_time = total_idle_time
      @total_travel_time = total_travel_time
      @vehicleRoutes = {}
    end

    def number_of_unserved
      unserved.count
    end

    # Adds a new way point for the specified vehicle
    def addWayPoint(vehicle_name, way_point)
      if @vehicleRoutes[vehicle_name].nil?
        # No previous way point was added for the specified vehicle, so create a new array
        @vehicleRoutes[vehicle_name] = []
      end
      # Adds the provided way point for the specified vehicle
      @vehicleRoutes[vehicle_name] << way_point
    end

    class << self
      # Parse the JSON representation of a route, and return it as a Route object
      def parse(routeJson)
        status = routeJson["status"]
        unserved = routeJson["unserved"]
        route = RoutificApi::Route.new(status: status, unserved: unserved)

        # Get way points for each vehicles
        routeJson["solution"].each do |vehicle_name, way_points|
          # Get all way points for this vehicle
          way_points.each do |waypoint_info|
            # Get all information for this way point
            way_point = RoutificApi::WayPoint.new(waypoint_info)
            route.addWayPoint(vehicle_name, way_point)
          end
        end

        # Return the resulting Route object
        route
      end
    end
  end
end
