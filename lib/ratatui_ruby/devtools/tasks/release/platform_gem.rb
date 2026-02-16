# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rubygems"
require "rubygems/package"
require "fileutils"

require_relative "versioned_binary"

# A platform-specific gem assembled from pre-compiled versioned binaries.
#
# CI builds produce one compiled binary per Ruby version per OS.
# A PlatformGem collects those binaries and packages them into a single
# installable gem that serves all supported Ruby versions.
class PlatformGem
  # Loads the gemspec and scans for compiled binaries.
  def initialize(
    spec = Gem::Specification.load(RatatuiRuby::Devtools.gemspec_file),
    lib_dir = "lib/#{RatatuiRuby::Devtools.gem_name.tr('-', '_')}"
  )
    @spec = spec
    @lib_dir = lib_dir
    @binaries = VersionedBinary.scan(lib_dir, RatatuiRuby::Devtools.gem_name)
  end

  # Packages the platform gem into +pkg/+.
  def build
    abort "No versioned binaries found in #{@lib_dir}/*/" if @binaries.empty?

    @spec.platform = Gem::Platform.local
    @spec.extensions.clear
    @spec.files += @binaries.map(&:path)

    #--
    # SPDX-SnippetBegin
    # SPDX-SnippetCopyrightText: rake-compiler contributors
    # SPDX-License-Identifier: MIT
    #
    # Version constraint pattern derived from rake-compiler's
    # ExtensionTask#define_native_tasks (lib/rake/extensiontask.rb).
    #++
    @spec.required_ruby_version = [
      ">= #{@binaries.first.api_version}",
      "< #{@binaries.last.api_version.succ}.dev",
    ]
    #--
    # SPDX-SnippetEnd
    #++

    FileUtils.mkdir_p("pkg")
    gem_file = Gem::Package.build(@spec)
    FileUtils.mv(gem_file, "pkg")
    puts "Built pkg/#{File.basename(gem_file)}"
  end
end

if $PROGRAM_NAME == __FILE__
  PlatformGem.new.build
end
