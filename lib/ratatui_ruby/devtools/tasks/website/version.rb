# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rubygems"
require "fileutils"

# A documentation version for multi-version websites.
#
# Documentation websites need to serve multiple versions. Users browse docs
# for their installed release. Maintainers preview trunk changes. Manually
# tracking git tags and branches is tedious.
#
# This class discovers versions from git tags. It extracts source files at
# each ref. It provides metadata for version menus.
#
# Use it to build multi-version documentation portals.
class Version
  # Discovers all available versions.
  #
  # Returns Edge (trunk) plus the latest patch for each minor version,
  # sorted newest first.
  def self.all
    tags = `git tag`.split.grep(/^v\d/)
    sorted_versions = tags.map { |t| Tagged.new(t) }
      .sort_by(&:semver)
      .reverse

    # Keep only the latest patch for each minor version
    # e.g., if we have v0.6.0, v0.6.1, v0.6.2, only keep v0.6.2
    latest_per_minor = sorted_versions
      .group_by { |v| v.semver.segments[0..1] } # group by [major, minor]
      .values
      .map(&:first) # take the first (highest patch) from each group

    [Edge.new] + latest_per_minor
  end

  # URL-safe identifier for this version.
  def slug
    raise NotImplementedError
  end

  # Human-readable name for version menus.
  def name
    raise NotImplementedError
  end

  # Version type: <tt>:edge</tt> or <tt>:version</tt>.
  def type
    raise NotImplementedError
  end

  # Git ref (branch or tag) for checkout.
  def ref
    raise NotImplementedError
  end

  # Yields a temporary directory containing this version's source.
  #
  # Exports the git archive at the specified ref. Removes the native
  # extension directory to avoid compilation issues.
  #
  # [globs] File patterns (unused, for API compatibility).
  def checkout(globs:, &block)
    Dir.mktmpdir do |path|
      # Use git archive to export the version at the specified ref
      # Pipe to tar to extract into the temporary directory
      system("git archive #{ref} | tar -x -C #{path}")

      # Remove the native extension directory as we don't need it for builds
      # and it can cause issues if not meant to be compiled in this context
      FileUtils.rm_rf("#{path}/ext")

      yield path
    end
  end

  # Returns <tt>true</tt> if this is the latest stable release.
  def latest?
    false
  end

  # Returns <tt>true</tt> if this is the edge (trunk) version.
  def edge?
    false
  end
end

# The trunk branch version for unreleased changes.
#
# Developers preview upcoming features before release. The edge version
# builds documentation from trunk.
class Edge < Version
  # Stable URL path for bookmarks. Trunk docs live at <tt>/trunk/</tt>.
  def slug
    "trunk"
  end

  # Appears in version menus as-is, without version numbering.
  def name
    "trunk"
  end

  # Distinguishes unreleased docs from tagged releases in conditionals.
  def type
    :edge
  end

  # Git branch name for archive extraction.
  def ref
    "origin/trunk"
  end

  # Identifies this as unreleased for "(dev)" labels in menus.
  def edge?
    true
  end
end

# A Git release tag version.
#
# Each release gets a tag like <tt>v0.6.0</tt>. The documentation website
# shows only the latest patch for each minor version.
class Tagged < Version
  # The raw Git tag for archive extraction.
  attr_reader :tag

  # Creates a Tagged version.
  #
  # [tag] Git tag string.
  def initialize(tag)
    @tag = tag
  end

  # Groups patch releases under one URL. Docs for <tt>v0.6.0</tt> and
  # <tt>v0.6.1</tt> both live at <tt>/v0.6/</tt>.
  def slug
    segments = semver.segments
    "v#{segments[0]}.#{segments[1]}"
  end

  # Shows exact version in menus. Users know which patch they're viewing.
  def name
    @tag
  end

  # Distinguishes released docs from trunk in conditionals.
  def type
    :version
  end

  # Git tag for archive extraction.
  def ref
    @tag
  end

  # Enables sorting and grouping by semantic version rules.
  def semver
    Gem::Version.new(@tag.sub(/^v/, ""))
  end

  # Set by IndexPage to enable "(latest)" label in menus.
  attr_accessor :is_latest

  # Identifies this for "(latest)" labels in menus.
  def latest?
    @is_latest
  end
end
