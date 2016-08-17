require_relative './helper/spec_helper'

describe RoutificApi::Solution do
  describe "valid parameters" do
    subject(:solution) {
      RoutificApi::Solution.new(vehicle_id, visits)
    }

    it "has vehicle_id" do
      expect(solution.vehicle_id).to eq(vehicle_id)
    end

    it "has visits" do
      expect(solution.visits).to eq(visits)
    end
  end

  describe ".valid_solutions" do
    subject(:driver_ids) { %w(1 2 3) }
    subject(:solutions) do
      [
        RoutificApi::Solution.new('1', %w(a b)),
        RoutificApi::Solution.new('2', %w(d e)),
        RoutificApi::Solution.new('4', %w(f g))
      ]
    end

    it "returns a hash of solutions with the given driver ids" do
      valid_solution = RoutificApi::Solution.valid_solutions(driver_ids, solutions)
      expect(valid_solution).to eq('1' => %w(a b), '2' => %w(d e))
    end
  end

  describe "provided invalid parameters" do
    subject(:solution) do
      RoutificApi::Solution.new("12", "12")
    end

    it "raises an ArgumentError" do
      expect { solution }.to raise_error(ArgumentError)
    end
  end

  def vehicle_id
    '123'
  end

  def visits
    %w(order_1 order_id)
  end
end
