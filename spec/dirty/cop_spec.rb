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
        rubocop_allowed_files = ['dont_care']
        result = rubocop.files_to_inspect(rubocop_allowed_files, files)
        expect(result).to eq(files)
      end
    end

    context 'no files passed in' do
      it 'returns all files that have changes' do
        changed_files = ['company', 'user']
        rubocop_allowed_files = changed_files
        rubocop.stub(:changed_files) { changed_files }

        result = rubocop.files_to_inspect(rubocop_allowed_files, [])
        expect(result).to eq(changed_files)
      end

      it 'returns files that have changes that are okayed by rubocop' do
        changed_files = ['company', 'user', 'project']
        rubocop_allowed_files = ['app', 'company', 'user']
        rubocop.stub(:changed_files) { changed_files }

        result = rubocop.files_to_inspect(rubocop_allowed_files, [])
        expect(result).to eq(['company', 'user'])
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

  describe '#report_offense_at?' do
    it 'should respond if a line was changed at past file and line' do
      changed_files_and_lines = {
        'company' => [4, 6, 7, 8, 9, 12],
        'user' => [2, 3, 6]
      }
      rubocop.stub(:changed_files_and_lines) { changed_files_and_lines }
      expect(rubocop.report_offense_at?('company', 6)).to be_truthy
      expect(rubocop.report_offense_at?('company', 1)).to be_falsy
      expect(rubocop.report_offense_at?('other_file', 6)).to be_falsy
    end

    it 'should not blow up if no files were changed' do
      changed_files_and_lines = {}
      rubocop.stub(:changed_files_and_lines) { changed_files_and_lines }
      expect(rubocop.report_offense_at?('company', 1)).to be_falsy
    end
  end

  describe '#changed_files_and_lines' do
    it 'should return a hash with filenames and changed lines' do
      rubocop.stub(:changed_files) { %w(company user) }
      rubocop.stub(:git_diff).with('company', 'HEAD') { File.open('spec/diff_mocks/company') }
      rubocop.stub(:git_diff).with('user', 'HEAD') { File.open('spec/diff_mocks/user') }
      expected = {
        'company' => [4, 6, 7, 8, 9, 12],
        'user' => [2, 3, 6]
      }
      result = rubocop.changed_files_and_lines(ref)
      expect(result.keys).to eq(expected.keys)
      result.keys.each do |key|
        expect(result[key].sort).to eq(expected[key].sort)
      end
    end
  end
end
