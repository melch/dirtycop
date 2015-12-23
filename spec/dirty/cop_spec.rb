# encoding: utf-8

require 'spec_helper'

class RubocopTest
  include DirtyCop
end

describe DirtyCop do
  let(:rubocop) { RubocopTest.new }
  let(:ref) { 'HEAD' }

  describe '#files_to_inspect' do
    context 'files passed in' do
      it 'returns files passed into rubocop that have changes' do
        files = ['company', 'user']
        result = rubocop.files_to_inspect(files)
        expect(result).to eq(files)
      end
    end

    context 'no files passed in' do
      it 'returns all files that have changes' do
        files = ['company', 'user']
        rubocop.stub(:changed_files) { files }

        result = rubocop.files_to_inspect([])
        expect(result).to eq(files)
      end
    end
  end

  describe '#changed_files' do
    it 'returns an array of full path of files changed' do
      rubocop.stub(:git_diff_name_only) { File.open('spec/diff_mocks/name_only') }
      expected = [
        "#{Dir.pwd}/lib/dirty/cop.rb",
        "#{Dir.pwd}/spec/dirty/cop_spec.rb"
      ]
      expect(rubocop.changed_files(ref)).to eq(expected)
    end
  end

  describe '#changed_lines' do
    let(:file) { 'company' }

    it 'returns an array, containing line numbers that have changed' do
      rubocop.stub(:git_diff) { File.open('spec/diff_mocks/company') }
      result = rubocop.changed_lines(file, ref)
      expected = [4, 6, 7, 8, 9, 12]
      expect(result.sort).to eq(expected)
    end
  end

  describe '#inspect_file' do
    it 'should only respond with offenses on lines that were changed'
  end

  # TODO:
  # describe '#changed_files_and_lines' do
  #   it 'should return a hash where keys are filenames and values are an array of line numbers that changed' do
  #     expected = {
  #       "company" => [4, 6, 7, 8, 9, 12],
  #       "user" => [2, 4, 5]
  #     }
  #     result = RubocopTest.new.changed_files_and_lines(ref)
  #     expect(result.sort).to eq(expected)
  #   end
  # end
end
