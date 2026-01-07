# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Synchronizes code snippets with documentation.
#
# Documentation contains code examples. Source files change. Copy-pasting
# leads to stale examples. Tests pass but the README lies.
#
# This module scans markdown files for SYNC markers and replaces content
# with live source. The documentation stays accurate. No manual updates.
#
# Use it to keep README examples in sync with working code.
module Autodoc
  # Synchronizes code snippets from source files into markdown.
  #
  # Markdown files contain embedded code examples. Maintaining them manually
  # drifts from the source. This class scans for SYNC markers and injects
  # live code from the referenced files.
  #
  # Use it to sync README.md examples with your actual implementation.
  #
  # === Example
  #
  # In your README.md:
  #   <!-- SYNC:START:examples/hello/app.rb:main -->
  #   ```ruby
  #   # This content gets replaced
  #   ```
  #   <!-- SYNC:END -->
  #
  # Then run:
  #   Autodoc::Examples.sync
  #
  class Examples
    # Synchronize all README files in the repository.
    def self.sync
      new.sync
    end

    # Synchronize all README files.
    #
    # Scans for SYNC markers in markdown files and replaces content with
    # source file snippets.
    def sync
      Dir.glob("{README.md,doc/**/*.md,examples/*/README.md}").each do |readme_path|
        sync_readme(readme_path)
      end
    end

    private def sync_readme(readme_path)
      content = File.read(readme_path)
      dir = File.dirname(readme_path)

      new_content = content.gsub(/<!-- SYNC:START:([^ ]+) -->.*?<!-- SYNC:END -->/m) do
        marker_info = $1
        source_rel_path, segment_id = marker_info.split(":")

        # Support both repo-root-relative paths (no leading ./) and file-relative paths
        source_path = if source_rel_path.start_with?("./", "../")
          File.join(dir, source_rel_path)
        else
          source_rel_path # Already relative to repo root
        end

        unless File.exist?(source_path)
          warn "Warning: Source file not found: #{source_path}"
          next $&
        end

        source_content = File.read(source_path)
        extracted_content = if segment_id
          extract_segment(source_content, segment_id, source_path)
        else
          source_content
        end

        # Detect language from extension
        ext = File.extname(source_path).delete(".")
        lang = (ext == "rb") ? "ruby" : ext

        # Build replacement
        "<!-- SYNC:START:#{marker_info} -->\n```#{lang}\n#{extracted_content}```\n<!-- SYNC:END -->"
      end

      if new_content != content
        puts "Syncing #{readme_path}..."
        File.write(readme_path, new_content)
      end
    end

    # Extracts a named segment from source content.
    #
    # Source files contain segment markers like <tt>[SYNC:START:main]</tt>.
    # This method extracts the content between matching markers.
    #
    # [content] The source file content.
    # [segment_id] The segment name to extract.
    # [source_path] The source file path (for error messages).
    def extract_segment(content, segment_id, source_path)
      start_marker = /#\s*\[SYNC:START:#{segment_id}\]/
      end_marker = /#\s*\[SYNC:END:#{segment_id}\]/

      lines = content.lines
      start_idx = lines.find_index { |l| l =~ start_marker }
      end_idx = lines.find_index { |l| l =~ end_marker }

      if start_idx && end_idx
        "#{unindent(lines[(start_idx + 1)...end_idx].join).strip}\n"
      else
        warn "Warning: Segment '#{segment_id}' not found in #{source_path}"
        content
      end
    end

    # Removes common leading indentation from text.
    #
    # Code segments often have indentation from their context. This method
    # strips the common prefix so the output looks clean.
    #
    # [text] The text to unindent.
    def unindent(text)
      lines = text.lines
      return text if lines.empty?

      indentation = lines.grep(/\S/).map { |l| l[/^\s*/].length }.min || 0
      lines.map { |l| (l.length > indentation) ? l[indentation..-1] : "#{l.strip}\n" }.join
    end
  end
end
