# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Configuration for RDoc documentation generation.
#
# RDoc generates API documentation from source files. Configuring which files
# to include requires glob patterns. Large files slow generation. Verification
# examples clutter the output.
#
# This module defines the file list, size limits, and main page. Use it to
# configure RDoc::Task consistently across ecosystem gems.
module RDocConfig
  # Maximum file size to include in documentation. Files larger than this are
  # skipped to avoid performance issues. 100KB handles most source files while
  # excluding chat logs and similar large artifacts.
  MAX_FILE_SIZE = 100_000

  # Files to include in RDoc generation.
  #
  # Includes markdown docs, readme files, library source, and executables.
  # Excludes large files and verification examples.
  RDOC_FILES = Dir.glob(%w[
    doc/**/*.md
    examples/**/*.md
    *.md
    *.rdoc
    lib/**/*.rb
    exe/**/*
  ]).reject { |f|
    # Skip large files
    if File.size(f) > MAX_FILE_SIZE
      warn "RDoc: skipping #{f} (#{File.size(f) / 1024}KB > #{MAX_FILE_SIZE / 1024}KB limit)"
      next true
    end
    # Skip verification examples (internal testing, not user-facing)
    f.start_with?("examples/verify_")
  }.freeze

  # The main page for RDoc output.
  MAIN = "README.md"
end
