require 'rest-client'
require 'json'

require_relative './routific/location'
require_relative './routific/visit'
require_relative './routific/vehicle'
require_relative './routific/route'
require_relative './routific/way_point'
require_relative './routific/options'
require_relative './routific/solution'

# Main class of this gem
class Routific
  attr_reader :token, :visits, :fleet, :options, :solutions, :unserved

  # Constructor
  # token: Access token for Routific API
  def initialize(token)
    @token = token
    @visits = {}
    @fleet = {}
    @options = {}
    @solutions = []
    @unserved = []
  end

  # Sets a visit for the specified location using the specified parameters
  # id: ID of location to visit
  # params: parameters for this visit
  def setVisit(id, params={})
    visits[id] = RoutificApi::Visit.new(id, params)
  end

  # Sets a vehicle with the specified ID and parameters
  # id: vehicle ID
  # params: parameters for this vehicle
  def setVehicle(id, params)
    fleet[id] = RoutificApi::Vehicle.new(id, params)
  end

  # Sets options with the specified params
  # params: parameters for these options
  def setOptions(params)
    @options = RoutificApi::Options.new(params)
  end

  # Sets optional solution to allow for routing unserved orders
  # params: a hash with vehicle id as the key, and an ordered array
  # of visits as the value
  # { vehicle_id => [visit_1, visit_2] }
  def setSolution(id, visits)
    @solutions << RoutificApi::Solution.new(id, visits)
  end

  # Sets optional array of unserved orders
  def setUnserved(unserved)
    @unserved = unserved
  end

  # Returns the route using the previously provided visits and fleet information
  def getRoute
    data = {
      visits: visits,
      fleet: fleet
    }

    data[:options] = options if options
    Routific.getRoute(data, token)
  end

  def fixRoute
    data = {
      visits: visits,
      fleet: fleet
    }

    data[:solution] = valid_solutions
    data[:options] = options if options
    data[:unserved] = valid_unserved

    if data[:solution].empty?
      raise ArgumentError, "must include a set of solutions to fix"
    end

    if data[:unserved].empty?
      raise ArgumentError, "must include unserved visits"
    end

    Routific.fixRoute(data, token)
  end

  def valid_solutions
    RoutificApi::Solution.valid_solutions(fleet.keys, solutions)
  end

  def valid_unserved
    unserved.select { |u| visits.keys.include? u }
  end

  class << self
    # Sets the default access token to use
    def setToken(token)
      @@token = token
    end

    def token
      @@token
    end

    # Returns the route using the specified access token, visits and fleet information
    # If no access token is provided, the default access token previously set is used
    # If the default access token either is nil or has not been set, an ArgumentError is raised
    def getRoute(data, token = @@token)
      validate_token(token)

      begin
        response = post_request(data, token)
        construct_route_from_response(response)
      rescue => e
        error_response = JSON.parse e.response.body
        puts "Received HTTP #{e.message}: #{error_response["error"]}"
        nil
      end
    end

    def fixRoute(data, token = @@token)
      validate_token(token)

      begin
        # Sends HTTP request to Routific API server
        response = post_request(data, token, 'https://api.routific.com/v1/fix')
        construct_route_from_response(response)
      rescue => e
        error_response = JSON.parse e.response.body
        puts "Received HTTP #{e.message}: #{error_response["error"]}"
        nil
      end
    end

    def post_request(data, base_token, url = 'https://api.routific.com/v1/vrp')
      RestClient.post(
        url,
        data.to_json,
        Authorization: prefixed_token(base_token),
        content_type: :json,
        accept: :json
      )
    end

    def validate_token(token)
      raise ArgumentError, "access token must be set" if token.nil?
    end

    def construct_route_from_response(response)
      # Parse the HTTP request response to JSON
      jsonResponse = JSON.parse(response)

      # Parse the JSON representation into a RoutificApi::Route object
      RoutificApi::Route.parse(jsonResponse)
    end

    def prefixed_token(token)
      /bearer /.match(token).nil? ? "bearer #{token}" : token
    end
  end
end
