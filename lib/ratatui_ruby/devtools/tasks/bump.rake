# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rubygems"

require_relative "bump/sem_ver"
require_relative "bump/manifest"
require_relative "bump/cargo_lockfile"
require_relative "bump/ruby_gem"
require_relative "bump/changelog"

# Null lockfile for gems without Rust
class NullLockfile
  def refresh
    # No-op
  end
end

namespace :bump do
  # Auto-discover gem configuration
  def devtools_gem
    @devtools_gem ||= begin
      version_file = RatatuiRuby::Devtools.version_file
      gem_name = RatatuiRuby::Devtools.gem_name

      manifests = [
        Manifest.new(
          path: version_file,
          pattern: /(?<=VERSION = ")[^"]+(?=")/,
          primary: true
        ),
      ]

      # Optionally add Cargo.toml if this gem has Rust extensions
      cargo_toml = "ext/#{gem_name}/Cargo.toml"
      if File.exist?(cargo_toml)
        manifests << Manifest.new(
          path: cargo_toml,
          pattern: /(?<=^version = ")[^"]+(?=")/,
          primary: false
        )
      end

      # Optionally use Cargo lockfile if it exists
      cargo_lock = "ext/#{gem_name}/Cargo.lock"
      lockfile = if File.exist?(cargo_lock)
        CargoLockfile.new(
          path: cargo_lock,
          dir: "ext/#{gem_name}",
          name: gem_name
        )
      else
        # No-op lockfile for pure Ruby gems
        NullLockfile.new
      end

      RubyGem.new(
        manifests:,
        lockfile:,
        changelog: Changelog.new
      )
    end
  end

  SemVer::SEGMENTS.each do |segment|
    desc "Bump #{segment} version"
    task segment do
      devtools_gem.bump(segment)
    end
  end

  desc "Set exact version (e.g. rake bump:exact[0.1.0])"
  task :exact, [:version] do |_, args|
    devtools_gem.set(args[:version])
  end
end
