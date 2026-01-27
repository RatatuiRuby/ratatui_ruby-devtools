# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "version"
require_relative "versioned_documentation"
require_relative "index_page"
require_relative "version_menu"
require "fileutils"

# Multi-version documentation website builder.
#
# Projects need documentation for multiple versions. Users on v0.5 read
# v0.5 docs. Users on trunk preview upcoming changes. Building this
# manually is tedious and error-prone.
#
# This class orchestrates the entire build: discovers versions, generates
# docs for each, creates the landing page, and injects version menus.
#
# Use it to build a complete documentation portal.
class Website
  # Creates a Website builder.
  #
  # [at] Output directory (default: <tt>www</tt>).
  # [project_name] Project name for page titles.
  # [globs] File patterns to document.
  # [assets] Optional directories to copy into each version's output.
  # [branding] Optional hash of branding overrides for the index template.
  def initialize(at: "www", project_name:, globs:, assets: [], branding: {})
    @destination = at
    @project_name = project_name
    @globs = globs
    @assets = assets
    @branding = branding
  end

  # Builds the complete documentation website.
  #
  # Cleans the output directory, generates docs for all versions,
  # creates the landing page, and injects version menus.
  def build
    clean

    versions.each do |version|
      VersionedDocumentation.new(version).publish_to(
        join(version.slug),
        project_name: @project_name,
        globs: @globs,
        assets: @assets
      )
    end

    IndexPage.new(versions, branding: @branding).publish_to(join("index.html"), project_name: @project_name)

    VersionMenu.new(root: @destination, versions:).run

    puts "Website built in #{@destination}/"
  end

  # Discovered versions for this build.
  #
  # Cached after first call. Includes Edge plus latest patch per minor.
  def versions
    @versions ||= Version.all
  end

  private def join(path)
    File.join(@destination, path)
  end

  private def clean
    FileUtils.rm_rf(@destination)
    FileUtils.mkdir_p(@destination)
  end
end
