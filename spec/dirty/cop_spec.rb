# encoding: utf-8

require 'spec_helper'

class RubocopTest
  include DirtyCop
end

describe DirtyCop do
  describe '#mask_array' do
    it 'returns an array, containing line numbers that have changed' do
      git_diff_output = File.open('spec/git_diff')
      result = RubocopTest.new.mask_array(git_diff_output)
      expected = [4, 6, 7, 8, 9, 12]
      expect(result.sort).to eq(expected)
    end
  end
end
