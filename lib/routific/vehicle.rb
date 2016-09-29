module RoutificApi
  # This class represents a vehicle in the fleet
  class Vehicle
    attr_accessor :id, :start_location, :end_location, :shift_start, :shift_end, :capacity

    # Constructor
    #
    # Required arguments in params:
    # start_location: start location for this vehicle. Instance of Location
    #
    # Optional arguments in params:
    # end_location: end location for this vehicle. Instance of Location
    # shift_start: this vehicle's start shift time (e.g. '08:00'). Default value is 00:00, if not specified.
    # shift_end: this vehicle's end shift time (e.g. '17:00'). Default value is 23:59, if not specified.
    # capacity: the capacity that this vehicle can load
    def initialize(id, params)
      validate(params)

      @id = id
      @start_location = RoutificApi::Location.new(params["start_location"])
      if params["end_location"]
        @end_location = RoutificApi::Location.new(params["end_location"])
      end
      @shift_start = params["shift_start"]
      @shift_end = params["shift_end"]
      @capacity = params["capacity"]
    end

    def to_json(options=nil)
      as_json(options).to_json
    end

    # Returns the JSON representation of this object
    # def to_json(options = nil)
    def as_json(_options = nil)
      json = {}
      json["start_location"] = self.start_location.as_json
      json["end_location"] = self.end_location.as_json if self.end_location
      json["shift_start"] = self.shift_start if self.shift_start
      json["shift_end"] = self.shift_end if self.shift_end
      json["capacity"] = self.capacity if self.capacity

      json
    end

    private

    # Validates the parameters being provided
    # Raises an ArgumentError if any of the required parameters is not provided.
    # Required parameters are: location
    def validate(params)
      if params["start_location"].nil?
        raise ArgumentError, "'start-location' parameter must be provided"
      end
    end
  end
end
