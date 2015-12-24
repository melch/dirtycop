# Modified from skanev's https://gist.github.com/skanev/9d4bec97d5a6825eaaf6
#
# A sneaky wrapper around Rubocop that allows you to run it only against
# the recent changes, as opposed to the whole project. It lets you
# enforce the style guide for new/modified code only, as opposed to
# having to restyle everything or adding cops incrementally. It relies
# on git to figure out which files to check.
#
# Here are some options you can pass in addition to the ones in rubocop:
#
#   --local               Check only the changes you are about to push
#                         to the remote repository.
#
#   --uncommitted         Check only changes in files that have not been
#   --index               committed (i.e. either in working directory or
#                         staged).
#
#   --against REFSPEC     Check changes since REFSPEC. This can be
#                         anything that git will recognize.
#
#   --branch              Check only changes in the current branch.
#
#   --courage             Without this option, only the modified lines
#                         are inspected. When supplied, it will check
#                         the full contents of the file. You should have
#                         the courage to fix your style violations as
#                         you see them, you know.
#
# Caveat emptor:
#
# * Monkey patching ahead. This script relies on Rubocop internals and
#   has been tested against 0.25.0. Newer (or older) versions might
#   break it.
#
# * While it does try to check modified lines only, there might be some
#   quirks. It might not show offenses in modified code if they are
#   reported at unmodified lines. It might also show offenses in
#   unmodified code if they are reported in modified lines.

require 'rubocop'
# require 'pry'

module DirtyCop
  extend self # In your face, style guide!

  def bury_evidence?(file, line)
    !report_offense_at?(file, line)
  end

  def ref
    'HEAD'
  end

  def files_to_inspect(whitelisted_files, args)
    return @files ||= args unless args.empty?

    @files ||= (changed_files(ref) & whitelisted_files)
  end

  def cover_up_unmodified(ref, only_changed_lines = true)
    @line_filter ||= changed_files_and_lines(ref) if only_changed_lines
  end

  def process_bribe
    # leaving this unused method as a placeholder of flags that purportedly work
    # (potential feature set)
    only_changed_lines = true

    # I am specifying the ref above instead of getting it from args since
    # getting it from args seems to be broken
    # ref = nil
    # loop do
    #   arg = ARGV.shift
    #   case arg
    #   when '--local'
    #     ref = `git rev-parse --abbrev-ref --symbolic-full-name @{u}`.chomp
    #     exit 1 unless $?.success?
    #   when '--against'
    #     ref = ARGV.shift
    #   when '--uncommitted', '--index'
    #     ref = 'HEAD'
    #   when '--branch'
    #     ref = `git merge-base HEAD master`.chomp
    #   when '--courage'
    #     only_changed_lines = false
    #   else
    #     ARGV.unshift arg
    #     break
    #   end
    # end
    # return unless ref

    cover_up_unmodified ref, only_changed_lines
  end

  def report_offense_at?(file, line)
    changed_lines_for_file(file).include? line
  end

  def changed_lines_for_file(file)
    changed_files_and_lines(ref)[file] || []
  end

  def changed_files(ref)
    @changed_files ||= git_diff_name_only
      .lines
      .map(&:chomp)
      .grep(/\.rb$/)
      .map { |file| File.absolute_path(file) }
  end

  def git_diff_name_only
    `git diff --diff-filter=AM --name-only #{ref}`
  end

  def changed_files_and_lines(ref)
    result = {}

    changed_files(ref).each do |file|
      result[file] = changed_lines(file, ref)
    end

    result
  end

  def git_diff(file, ref)
    `git diff -p -U0 #{ref} #{file}`
  end

  def changed_lines(file, ref)
    ranges = git_diff(file, ref)
      .each_line
      .grep(/@@ -(\d+)(?:,)?(\d+)? \+(\d+)(?:,)?(\d+)? @@/) {
        [
          Regexp.last_match[3].to_i,
          (Regexp.last_match[4] || 1).to_i
        ]
      }.reverse

    mask = Set.new

    ranges.each do |changed_line_number, number_of_changed_lines|
      number_of_changed_lines.times do |line_delta|
        mask << changed_line_number + line_delta
      end
    end

    mask.to_a
  end

  def eat_a_donut
    puts "#{$PROGRAM_NAME}: The dirty cop Alex Murphy could have been"
    puts
    puts File.read(__FILE__)[/(?:^#(?:[^!].*)?\n)+/s].gsub(/^#/, '   ')
    exit
  end
end

module RuboCop
  class TargetFinder
    alias_method :find_unpatched, :find

    def find(args)
      DirtyCop.files_to_inspect(find_unpatched(args), args)
    end
  end

  class Runner
    alias_method :inspect_file_unpatched, :inspect_file

    def inspect_file(file)
      offenses, updated = inspect_file_unpatched(file)
      offenses = offenses.reject { |o| DirtyCop.bury_evidence?(file.path, o.line) }
      [offenses, updated]
    end
  end
end
