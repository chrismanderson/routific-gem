module RoutificApi
  # This class represents a precomposed solution
  class Solution
    attr_reader :vehicle_id, :visits

    # Constructor
    def initialize(id, visits)
      validate(visits)
      @vehicle_id = id
      @visits     = visits
    end

    private

    # Validates the parameters being provided
    # Raises an ArgumentError if any of the required parameters is not provided.
    # Required parameters are: vehicle_id, visits
    def validate(visits)
      unless visits.is_a?(Array)
        raise ArgumentError, "'visits' parameter must an array"
      end
    end

    class << self
      def valid_solutions(vehicle_ids, solutions)
        data = vehicle_ids.map do |vehicle_id|
          solution = solutions.detect { |s| s.vehicle_id == vehicle_id }

          next unless solution

          { vehicle_id => solution.visits }
        end.compact

        return if data.empty?

        data.reduce({}, :merge)
      end
    end
  end
end
