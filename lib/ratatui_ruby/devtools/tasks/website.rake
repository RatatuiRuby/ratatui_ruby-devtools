# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "erb"
require "fileutils"
require "tmpdir"
require_relative "rdoc_config"

namespace :website do
  desc "Build documentation for trunk (current dir) and all git tags"
  task :build do
    require_relative "website/website"

    spec = Gem::Specification.load(Dir["*.gemspec"].first)
    globs = RDocConfig::RDOC_FILES + ["*.gemspec", "doc/images/**/*", "examples/**/*"]

    # Allow projects to customize via website_config.rb in their tasks/ directory
    config = if File.exist?("tasks/website_config.rb")
      load File.expand_path("tasks/website_config.rb", Dir.pwd)
      WebsiteConfig::CONFIG
    else
      {}
    end

    Website.new(
      at: config[:output_dir] || "www",
      project_name: spec.name,
      globs:,
      assets: config[:assets] || ["doc/images"],
      branding: config[:branding] || {}
    ).build
  end
end
