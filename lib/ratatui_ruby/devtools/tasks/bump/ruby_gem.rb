# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Coordinates version bumping across multiple manifests.
#
# Ruby gems have versions in multiple files: version.rb, Cargo.toml, lockfiles.
# Bumping manually leads to mismatches. Forgetting the changelog produces
# incomplete releases.
#
# This class orchestrates the bump. It updates all manifests, refreshes
# lockfiles, and updates the changelog. One command. Consistent versions.
#
# Use it in rake tasks to bump major, minor, or patch versions.
class RubyGem
  # Creates a new RubyGem coordinator.
  #
  # [manifests] Array of Manifest objects. Exactly one must be primary.
  # [lockfile] A lockfile object that responds to <tt>refresh</tt>.
  # [changelog] A Changelog object for updating release notes.
  def initialize(manifests:, lockfile:, changelog:)
    raise ArgumentError, "Must have exactly one primary manifest" unless manifests.count(&:primary) == 1
    @manifests = manifests
    @lockfile = lockfile
    @changelog = changelog
  end

  # Returns the current version from the primary manifest.
  def version
    @manifests.find(&:primary).version
  end

  # Bumps the version by the given segment.
  #
  # Updates all manifests, refreshes lockfiles, and updates the changelog.
  # Prints a suggested commit message.
  #
  # [segment] One of <tt>:major</tt>, <tt>:minor</tt>, or <tt>:patch</tt>.
  def bump(segment)
    target = version.next(segment)
    commit_message = @changelog.commit_message(target)

    puts "Bumping #{segment}: #{version} -> #{target}"
    @changelog.release(target)
    @manifests.each { |manifest| manifest.write(target) }
    @lockfile.refresh

    puts_commit_message(commit_message)
  end

  # Sets the version to an exact value.
  #
  # Updates all manifests, refreshes lockfiles, and updates the changelog.
  # Prints a suggested commit message.
  #
  # [version_string] A version string like <tt>"1.2.3"</tt>.
  def set(version_string)
    target = SemVer.parse(version_string)
    commit_message = @changelog.commit_message(target)

    puts "Setting version: #{version} -> #{target}"
    @changelog.release(target)
    @manifests.each { |manifest| manifest.write(target) }
    @lockfile.refresh

    puts_commit_message(commit_message)
  end

  private def puts_commit_message(message)
    puts "=" * 80
    puts message
    puts "=" * 80
  end
end
