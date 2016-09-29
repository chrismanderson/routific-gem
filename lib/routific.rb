require 'faraday'
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
  def add_visit(id, params = {})
    visits[id] = RoutificApi::Visit.new(id, params)
  end

  # Sets a vehicle with the specified ID and parameters
  # id: vehicle ID
  # params: parameters for this vehicle
  def add_vehicle(id, params)
    fleet[id] = RoutificApi::Vehicle.new(id, params)
  end

  # Sets options with the specified params
  # params: parameters for these options
  def add_options(params)
    @options = RoutificApi::Options.new(params)
  end

  # Sets optional solution to allow for routing unserved orders
  # params: a hash with vehicle id as the key, and an ordered array
  # of visits as the value
  # { vehicle_id => [visit_1, visit_2] }
  def add_solution(id, visits)
    @solutions << RoutificApi::Solution.new(id, visits)
  end

  # Sets optional array of unserved orders
  def set_unserved(unserved)
    @unserved = unserved
  end

  # Returns the route using the previously provided visits and fleet information
  def get_route
    data = {
      visits: visits,
      fleet: fleet
    }

    data[:options] = options if options
    Routific.get_route(data, token)
  end

  # Returns the fixed route using the previously provided visits and fleet information
  def fix_route
    data = {
      visits: visits,
      fleet: fleet
    }

    data[:solution] = valid_solutions
    data[:options] = options if options
    data[:unserved] = valid_unserved

    if data[:solution].empty?
      raise ArgumentError, 'must include a set of solutions to fix'
    end

    if data[:unserved].empty?
      raise ArgumentError, 'must include unserved visits'
    end

    Routific.fix_route(data, token)
  end

  def valid_solutions
    RoutificApi::Solution.valid_solutions(fleet.keys, solutions)
  end

  def valid_unserved
    unserved.select { |u| visits.keys.include? u }
  end

  class << self
    # Sets the default access token to use
    def token=(new_token)
      @@token = new_token
    end

    def token
      @@token
    end

    # Returns the route using the specified access token, visits and fleet information
    # If no access token is provided, the default access token previously set is used
    # If the default access token either is nil or has not been set, an ArgumentError is raised
    def get_route(data, token = @@token)
      fetch_data(data, 'https://api.routific.com/v1/vrp', token)
    end

    # Returns the route using the specified access token, visits, fleet, and solution information
    # If no access token is provided, the default access token previously set is used
    # If the default access token either is nil or has not been set, an ArgumentError is raised
    def fix_route(data, token = @@token)
      fetch_data(data, 'https://api.routific.com/v1/fix', token)
    end

    def fetch_data(data, url, token)
      validate_token(token)

      begin
        response = post_request(data, token, url)
        construct_route_from_response(response)
      rescue Faraday::ClientError => error
        response = error.response # hash of response
        message = JSON.parse(response[:body])["error"]
        puts "Received HTTP #{response[:status]}: #{message}"

        OpenStruct.new(
          status: response[:status],
          headers: response[:headers],
          error: message
        )
      end
    end

    def post_request(data, base_token, url = 'https://api.routific.com/v1/vrp')
      conn = Faraday.new(url: url) do |c|
        c.use Faraday::Response::RaiseError
        c.use Faraday::Adapter::NetHttp
      end

      conn.headers['Content-Type'] = 'application/json'
      conn.headers['Authorization'] = prefixed_token(base_token)

      conn.post do |req|
        req.body = data.to_json
      end
    end

    def validate_token(token)
      raise ArgumentError, 'access token must be set' if token.nil?
    end

    def construct_route_from_response(response)
      # Parse the HTTP request response to JSON
      json = JSON.parse(response.body)

      # Parse the JSON representation into a RoutificApi::Route object
      RoutificApi::Route.parse(json)
    end

    def prefixed_token(token)
      /bearer /.match(token).nil? ? "bearer #{token}" : token
    end
  end
end
