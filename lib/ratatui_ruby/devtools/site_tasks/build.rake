# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "fileutils"
require "digest/md5"

# Website build tasks for ecosystem documentation sites.
#
# These tasks sync documentation from a source gem repository, update
# HTML metadata, and manage deployments.

SOURCE_GEM_DIR = RatatuiRuby::Devtools.source_gem_dir
PUBLIC_DOCS_DIR = File.expand_path("public/docs", Dir.pwd)
INDEX_HTML = File.expand_path("public/index.html", Dir.pwd)
BUILT_SHA_FILE = File.join(PUBLIC_DOCS_DIR, ".built_sha")

# Shared helper to load version metadata from source gem
def load_source_gem_metadata
  # Derive full_version from the highest git tag, not version.rb.
  # Patch releases live on release branches; trunk stays at the
  # minor baseline (e.g. 1.4.0) until the next minor ships.
  full_version = Dir.chdir(SOURCE_GEM_DIR) do
    tags = `git tag`.split.grep(/^v\d/)
    latest = tags.map { |t| Gem::Version.new(t.sub(/^v/, "")) }
      .max
    raise "No version tags found in #{SOURCE_GEM_DIR}" unless latest
    latest.to_s
  end

  # Get gem_name from gemspec for other metadata
  gemspec_files = Dir.glob(File.join(SOURCE_GEM_DIR, "*.gemspec"))
  raise "No gemspec found in #{SOURCE_GEM_DIR}" if gemspec_files.empty?

  gem_name = File.basename(gemspec_files.first, ".gemspec")

  # Compute docs version (major.minor only) using Gem::Version
  segments = Gem::Version.new(full_version).segments
  docs_version = segments.first(2).join(".")

  # Read summary from gemspec
  gemspec_file = gemspec_files.first
  gemspec_content = File.read(gemspec_file)
  summary = gemspec_content[/spec\.summary\s*=\s*"([^"]+)"/, 1]
  raise "Could not parse summary from #{gemspec_file}" unless summary

  # Get datePublished from git tag's tagger date
  tag_date = Dir.chdir(SOURCE_GEM_DIR) do
    `git tag -l --format='%(creatordate:short)' v#{full_version} 2>/dev/null`.strip
  end
  tag_date = nil if tag_date.empty?

  # Get copyrightYear from this version's release (each version is its own work)
  copyright_year = tag_date&.split("-")&.first

  { full_version:, docs_version:, summary:, tag_date:, copyright_year:, gem_name: }
end

def current_source_sha
  Dir.chdir(SOURCE_GEM_DIR) { `git rev-parse origin/trunk`.strip }
end

def docs_content_hash
  return nil unless File.directory?(PUBLIC_DOCS_DIR)

  trunk_dir = File.join(PUBLIC_DOCS_DIR, "trunk")
  return nil unless File.directory?(trunk_dir)

  digest = Digest::MD5.new
  Dir.glob("#{PUBLIC_DOCS_DIR}/**/*", File::FNM_DOTMATCH).sort.each do |path|
    next if File.directory?(path)
    next if path == BUILT_SHA_FILE
    digest.update(path)
    digest.update(File.binread(path))
  end
  digest.hexdigest
end

def docs_up_to_date?
  return false unless File.exist?(BUILT_SHA_FILE)

  stored = File.read(BUILT_SHA_FILE).strip.split("\n")
  stored_sha = stored[0]
  stored_hash = stored[1]

  return false unless stored_sha == current_source_sha
  return false unless stored_hash == docs_content_hash

  true
end

def write_build_stamp
  File.write(BUILT_SHA_FILE, "#{current_source_sha}\n#{docs_content_hash}")
end

namespace :build do
  desc "Build RDoc from source gem and copy to public/docs/ (FORCE=1 to rebuild)"
  task :docs do
    if docs_up_to_date? && !ENV["FORCE"]
      puts "Docs already built for #{current_source_sha[0, 8]}, skipping (use FORCE=1 to rebuild)"
      next
    end

    Bundler.with_unbundled_env do
      Dir.chdir(SOURCE_GEM_DIR) do
        sh "bundle install --quiet"
        sh "bundle exec rake website:build"
      end
    end

    www_source = File.join(SOURCE_GEM_DIR, "www")

    FileUtils.rm_rf(PUBLIC_DOCS_DIR)
    FileUtils.mkdir_p(PUBLIC_DOCS_DIR)

    # Copy contents, not the directory itself, to avoid cp_r's quirky behavior
    Dir.glob("#{www_source}/*", File::FNM_DOTMATCH).each do |entry|
      next if entry.end_with?("/.", "/..")
      FileUtils.cp_r(entry, PUBLIC_DOCS_DIR)
    end

    # Failsafe: if files ended up in public/docs/www/, move them up
    nested_www = File.join(PUBLIC_DOCS_DIR, "www")
    if File.directory?(nested_www)
      warn "WARNING: Detected nested www/ directory, moving contents up..."
      Dir.glob("#{nested_www}/*", File::FNM_DOTMATCH).each do |entry|
        next if entry.end_with?("/.", "/..")
        FileUtils.mv(entry, PUBLIC_DOCS_DIR)
      end
      FileUtils.rmdir(nested_www)
    end

    # Write SHA + content hash after successful build
    write_build_stamp

    puts "Copied docs to #{PUBLIC_DOCS_DIR} (#{current_source_sha[0, 8]})"
  end

  desc "Update index.html with version metadata from source gem"
  task :html do
    meta = load_source_gem_metadata

    html = File.read(INDEX_HTML)

    if html =~ /"softwareVersion":\s*"([^"]+)"/
      old_version = $1
      old_docs = old_version.split(".").first(2).join(".")

      # Plain string replacement for all occurrences
      # Bare version catches both "v1.1.0" and "gem_name-1.1.0.gem"
      html.gsub!(old_version, meta[:full_version])
      html.gsub!("v#{old_docs}/", "v#{meta[:docs_version]}/")

      # Update description from gemspec summary
      html.gsub!(/"description":\s*"[^"]+"/, %{"description": "#{meta[:summary]}"})

      # Update datePublished from git tag date
      if meta[:tag_date]
        html.gsub!(/"datePublished":\s*"[^"]+"/, %{"datePublished": "#{meta[:tag_date]}"})
      end

      # Update copyrightYear from first release
      if meta[:copyright_year]
        html.gsub!(/"copyrightYear":\s*\d+/, %{"copyrightYear": #{meta[:copyright_year]}})
      end

      File.write(INDEX_HTML, html)
    else
      warn "WARNING: No softwareVersion found in index.html JSON-LD, skipping version update"
    end

    puts "Updated index.html to version v#{meta[:full_version]} (docs: v#{meta[:docs_version]})"
  end
end

desc "Build docs and update index.html"
task build: ["build:docs", "build:html"]
