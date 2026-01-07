# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Manages the header section of a changelog.
#
# Changelogs start with a header: title, description, format reference. During
# updates, this section stays unchanged. Extracting it ensures safe rewrites.
#
# This class parses the header from changelog markdown. It preserves it
# during modifications.
class Header
  # Regex to match everything before the Unreleased section.
  PATTERN = /^(.*?)(?=## \[Unreleased\])/m

  # Parses the header from changelog content.
  #
  # [content] The full changelog text.
  def self.parse(content)
    match = content.match(PATTERN)
    new(match[1]) if match
  end

  # Creates a new Header.
  #
  # [content] The raw header text.
  def initialize(content)
    @content = content.dup
  end

  # Returns the byte length of the header.
  def length
    @content.length
  end

  # Returns the header as a string.
  def to_s
    @content
  end
end
