require_relative './helper/spec_helper'

describe Routific do
  describe "instance objects" do
    subject(:routific) { Routific.new(ENV["API_KEY"]) }

    it "has token" do
      expect(routific.token).to eq(ENV["API_KEY"])
    end

    describe "#visits" do
      it "is instance of a Hash" do
        expect(routific.visits).to be_instance_of(Hash)
      end
    end

    describe "#fleet" do
      it "is instance of a Hash" do
        expect(routific.fleet).to be_instance_of(Hash)
      end
    end

    describe "#options" do
      it "is instance of a Routific::Options" do
        routific.add_options(Factory::ROUTE_OPTIONS_PARAMS)
        expect(routific.options).to be_instance_of(RoutificApi::Options)
      end
    end

    describe "#add_visit" do
      let(:id) { Faker::Lorem.word }
      before do
        routific.add_visit(id, Factory::VISIT_PARAMS)
      end

      it "adds location 1 into visits" do
        expect(routific.visits).to include(id)
      end

      it "location 1 in visits is instances of Visit" do
        expect(routific.visits[id]).to be_instance_of(RoutificApi::Visit)
      end
    end

    describe "#add_vehicle" do
      let(:id) { Faker::Lorem.word }

      before do
        routific.add_vehicle(id, Factory::VEHICLE_PARAMS)
      end

      it "adds vehicle into fleet" do
        expect(routific.fleet).to include(id)
      end

      it "vehicle in fleet is instances of Vehicle" do
        expect(routific.fleet[id]).to be_instance_of(RoutificApi::Vehicle)
      end
    end

    describe "#add_options" do
      before do
        routific.add_options(Factory::ROUTE_OPTIONS_PARAMS)
      end

      it "adds an options hash into options" do
        expect(routific.options.traffic).to eq(Factory::ROUTE_OPTIONS_TRAFFIC)
        expect(routific.options.min_visits_per_vehicle).to eq(Factory::ROUTE_OPTIONS_MIN_VISITS_PER_VEHICLE)
        expect(routific.options.balance).to eq(Factory::ROUTE_OPTIONS_BALANCE)
        expect(routific.options.min_vehicles).to eq(Factory::ROUTE_OPTIONS_MIN_VEHICLES)
        expect(routific.options.shortest_distance).to eq(Factory::ROUTE_OPTIONS_SHORTEST_DISTANCE)
      end

      it "options is instance of RoutificApi::Options" do
        expect(routific.options).to be_instance_of(RoutificApi::Options)
      end
    end

    describe "#get_route" do
      before do
        routific.add_visit(
          "order_1",
          "start" => "9:00",
          "end" => "10:00",
          "duration" => 15,
          "location" => {
            "name" => "6800 Cambie",
            "lat" => 49.227107,
            "lng" => -123.1163085
          }
        )

        routific.add_visit(
          "order_2",
          "start" => "12:00",
          "end" => "13:00",
          "duration" => 15,
          "location" => {
            "name" => "6800 Cambie",
            "lat" => 49.227107,
            "lng" => -123.1163085
          }
        )

        routific.add_vehicle(
          "vehicle_1",
          "start_location" => {
            "name" => "800 Kingsway",
            "lat" => 49.2553636,
            "lng" => -123.0873365
          },
          "end_location" => {
            "name" => "800 Kingsway",
            "lat" => 49.2553636,
            "lng" => -123.0873365
          },
          "shift_start" => "8:00",
          "shift_end" => "13:00"
        )
      end

      it "returns a Route instance" do
        VCR.use_cassette 'routific/api_response/get_route' do
          route = routific.get_route
          expect(route).to be_instance_of(RoutificApi::Schedule)
        end
      end

      it "attaches optional data hash" do
        routific.add_options(
          "traffic" => "slow",
          "polylines" => "true"
        )

        VCR.use_cassette 'routific/api_response/with_data_hash' do
          route = routific.get_route
          expect(route).to be_instance_of(RoutificApi::Schedule)
          expect(route.polyline_precision).to eq(6)
        end
      end
    end
  end

  describe "class methods" do
    describe ".token" do
      before do
        Routific.token = ENV["API_KEY"]
      end

      it "sets default Routific API token" do
        expect(Routific.token).to eq(ENV["API_KEY"])
      end
    end

    describe ".get_route" do
      describe "access token is nil" do
        it "throws an ArgumentError" do
          expect { Routific.get_route({}, nil) }.to raise_error(ArgumentError)
        end
      end

      describe "valid access token" do
        before do
          visits = {
            "order_1" => {
              "start" => "9:00",
              "end" => "12:00",
              "duration" => 10,
              "location" => {
                "name" => "6800 Cambie",
                "lat" => 49.227107,
                "lng" => -123.1163085
              }
            }
          }
          fleet = {
            "vehicle_1" => {
              "start_location" => {
                "name" => "800 Kingsway",
                "lat" => 49.2553636,
                "lng" => -123.0873365
              },
              "end_location" => {
                "name" => "800 Kingsway",
                "lat" => 49.2553636,
                "lng" => -123.0873365
              },
              "shift_start" => "8:00",
              "shift_end" => "12:00"
            }
          }
          @data = {
            visits: visits,
            fleet: fleet
          }
        end

        describe "access token is set" do
          before do
            Routific.token = ENV["API_KEY"]
          end

          it "returns a Route instance" do
            VCR.use_cassette 'routific/api_response' do
              expect(Routific.get_route(@data)).to be_instance_of(RoutificApi::Schedule)
            end
          end
        end

        describe "access token is provided" do
          before do
            Routific.token = nil
          end

          it "returns a Route instance" do
            VCR.use_cassette 'routific/api_response' do
              expect(Routific.get_route(@data, ENV["API_KEY"])).to be_instance_of(RoutificApi::Schedule)
            end
          end

          it "still successful even if missing prefix 'bearer ' in key" do
            key = ENV["API_KEY"].sub(/bearer /, '')
            expect(/bearer /.match(key).nil?).to be true
            VCR.use_cassette 'routific/api_response' do
              expect(Routific.get_route(@data, key)).to be_instance_of(RoutificApi::Schedule)
            end
          end
        end
      end
    end

    describe ".fix_route" do
      describe "access token is nil" do
        it "throws an ArgumentError" do
          expect { Routific.get_route({}, nil) }.to raise_error(ArgumentError)
        end
      end

      describe "valid access token" do
        before do
          visits = {
            "order_1" => {
              "start" => "9:00",
              "end" => "12:00",
              "duration" => 10,
              "location" => {
                "name" => "6800 Cambie",
                "lat" => 49.227107,
                "lng" => -123.1163085
              }
            },
            "order_2" => {
              "start" => "9:00",
              "end" => "12:00",
              "duration" => 10,
              "location" => {
                "name" => "6800 Cambie",
                "lat" => 49.227107,
                "lng" => -123.1163085
              }
            }
          }
          fleet = {
            "vehicle_1" => {
              "start_location" => {
                "name" => "800 Kingsway",
                "lat" => 49.2553636,
                "lng" => -123.0873365
              },
              "end_location" => {
                "name" => "800 Kingsway",
                "lat" => 49.2553636,
                "lng" => -123.0873365
              },
              "shift_start" => "8:00",
              "shift_end" => "12:00"
            },
            "vehicle_2" => {
              "start_location" => {
                "name" => "800 Kingsway",
                "lat" => 49.2553636,
                "lng" => -123.0873365
              },
              "end_location" => {
                "name" => "800 Kingsway",
                "lat" => 49.2553636,
                "lng" => -123.0873365
              },
              "shift_start" => "8:00",
              "shift_end" => "12:00"
            }
          }
          @data = {
            visits: visits,
            fleet: fleet,
            solution: {
              "vehicle_1" => ["order_1"]
            },
            unserved: ["order_2"]
          }
        end

        describe "access token is set" do
          before do
            Routific.token = ENV["API_KEY"]
          end

          it "returns a Route instance" do
            VCR.use_cassette 'routific/api_response/fix' do
              expect(Routific.fix_route(@data)).to be_instance_of(RoutificApi::Schedule)
            end
          end
        end

        describe "access token is provided" do
          before do
            # clear out the token
            Routific.token = nil
          end

          it "returns a Route instance" do
            VCR.use_cassette 'routific/api_response/fix' do
              expect(Routific.fix_route(@data, ENV["API_KEY"])).to be_instance_of(RoutificApi::Schedule)
            end
          end

          it "still successful even if missing prefix 'bearer ' in key" do
            key = ENV["API_KEY"].sub(/bearer /, '')
            expect(/bearer /.match(key).nil?).to be true
            VCR.use_cassette 'routific/api_response/fix' do
              expect(Routific.fix_route(@data, key)).to be_instance_of(RoutificApi::Schedule)
            end
          end
        end
      end
    end
  end
end
