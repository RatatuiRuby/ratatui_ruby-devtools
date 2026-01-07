# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

desc "Generate SourceHut build manifests from template"
task sourcehut: "sourcehut:build"

namespace :sourcehut do
  desc "Build SourceHut manifests"
  task build: "sourcehut:build:manifest"

  namespace :build do
    desc "Generate SourceHut build manifests from template"
    task :manifest do
      require "erb"
      require "yaml"

      gem_name = RatatuiRuby::Devtools.gem_name
      gemspec_file = RatatuiRuby::Devtools.gemspec_file
      version_file = RatatuiRuby::Devtools.version_file

      # Detect if this is a Rust extension gem
      has_rust = File.exist?("ext/#{gem_name}/Cargo.toml") ||
        File.exist?("ext/#{gem_name.tr('-', '_')}/Cargo.toml")

      spec = Gem::Specification.load(gemspec_file)

      # Read version directly from file to ensure we get the latest version
      # even if it was just bumped in the same Rake execution
      version_content = File.read(version_file)
      version = version_content.match(/VERSION = "(.+?)"/)[1]

      gem_filename = "#{spec.name}-#{version}.gem"

      rubies = YAML.load_file("tasks/resources/rubies.yml")

      bundler_version = File.read("Gemfile.lock").match(/BUNDLED WITH\n\s+([\d.]+)/)[1]

      template = File.read("tasks/resources/build.yml.erb")
      erb = ERB.new(template, trim_mode: "-")

      FileUtils.mkdir_p ".builds"

      # Remove old generated files to ensure a clean state
      Dir.glob(".builds/*.yml").each { |f| File.delete(f) }

      rubies.each do |ruby_version|
        filename = ".builds/ruby-#{ruby_version}.yml"
        puts "Generating #{filename}..."
        content = erb.result_with_hash(gem_name:, has_rust:, ruby_version:, gem_filename:, bundler_version:)
        File.write(filename, content)
      end
    end
  end

  desc "Update stable branch to match release and set as default"
  task :update_stable do
    version_file = RatatuiRuby::Devtools.version_file

    # Read version to determine tag
    version_content = File.read(version_file)
    version = version_content.match(/VERSION = "(.+?)"/)[1]
    tag_name = "v#{version}"

    # Verify that the version file matches the actual git tag
    # This prevents updating stable to the wrong version if the release failed
    latest_tag = `git describe --tags --abbrev=0`.strip
    if latest_tag != tag_name
      abort "Fatal: Version mismatch! '#{version_file}' says #{tag_name}, " \
        "but the latest git tag is #{latest_tag}."
    end

    puts "Updating stable branch to point to #{tag_name}..."
    # Resolve the tag to a commit hash (peel annotated tags)
    # This renders a commit SHA that can be pushed to a branch head
    commit_sha = `git rev-parse #{tag_name}^{}`.strip

    # Update local stable branch to match
    sh "git branch -f stable #{commit_sha}"

    # Push the commit to remote stable branch
    # This creates 'stable' if it doesn't exist, or fast-forwards it.
    sh "git push origin #{commit_sha}:stable"
  end
end

if Rake::Task.task_defined?("release")
  Rake::Task["release"].enhance do
    Rake::Task["sourcehut:update_stable"].invoke
  end
end
