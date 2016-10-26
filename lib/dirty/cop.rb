# Modified from skanev's https://gist.github.com/skanev/9d4bec97d5a6825eaaf6
#
# A sneaky wrapper around Rubocop that allows you to run it only against
# the recent changes, as opposed to the whole project. It lets you
# enforce the style guide for new/modified code only, as opposed to
# having to restyle everything or adding cops incrementally. It relies
# on git to figure out which files to check.
#
# Caveat emptor:
#
# * Monkey patching ahead. This script relies on Rubocop internals and
#   has been tested against 0.44 Newer (or older) versions might
#   break it.
#
# * While it does try to check modified lines only, there might be some
#   quirks. It might not show offenses in modified code if they are
#   reported at unmodified lines. It might also show offenses in
#   unmodified code if they are reported in modified lines.

require 'rubocop'
# require 'pry'

class GitGitter
  attr_reader :diff_info

  def initialize
    @diff_info = Hash[
      changed_filenames.collect do |file|
        [file, line_change_info(file)]
      end
    ]
  end

  def changed_filenames
    `git diff --diff-filter=AM --name-only HEAD`
      .lines
      .map(&:chomp)
      .grep(/\.rb$/)
      .map { |file| File.absolute_path(file) }
  end

  def line_change_info(file)
    line_change_info = `git diff -p -U0 HEAD #{file}`
      .each_line
      .grep(/@@ -(\d+)(?:,)?(\d+)? \+(\d+)(?:,)?(\d+)? @@/) {
        [
          Regexp.last_match[3].to_i,
          (Regexp.last_match[4] || 1).to_i
        ]
      }.reverse
  end
end

class DirtyCop
  attr_reader :diff_info

  def initialize(diff_info:)
    @diff_info = diff_info
  end

  def changed_files_and_lines
    # TODO: Make this work with a relative path filename passed in :/
    @changes ||= Hash[
      diff_info.collect do |filename, line_change_info|
        mask = line_change_info.collect do |changed_line_number, number_of_changed_lines|
          Array(changed_line_number .. (changed_line_number + number_of_changed_lines))
        end.flatten

        [filename, mask]
      end
    ]
  end

  def bury_evidence?(offense)
    intersection = changed_files_and_lines[offense.location.source_buffer.name] & Array(offense.location.first_line..offense.location.last_line)
    intersection && intersection.empty?
  end

  def files_to_inspect(whitelisted_files, args)
    @files ||= args unless args.empty?

    @files ||= (diff_info.keys & whitelisted_files)
    @files
  end
end

module RuboCop
  class TargetFinder
    alias_method :find_unpatched, :find

    def find(args)
      # returns an array of full file paths that are the files to inspect.
      DirtyCop.new(diff_info: GitGitter.new.diff_info).files_to_inspect(find_unpatched(args), args)
    end
  end

  module Cop
    class Commissioner
      alias_method :straight_investigate, :investigate

      def investigate(processed_source)
        # returns an array of offenses (Offense objects)
        straight_investigate(processed_source).reject do |offense|
          DirtyCop.new(diff_info: GitGitter.new.diff_info).bury_evidence?(offense)
        end
      end
    end
  end
end
