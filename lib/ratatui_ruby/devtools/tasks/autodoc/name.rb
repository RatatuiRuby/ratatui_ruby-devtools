# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

module Autodoc
  # Wraps a name string with case conversion utilities.
  #
  # Ruby uses snake_case. Constants use PascalCase. Converting between them
  # by hand invites typos. This class handles the conversion.
  #
  # [string] The name string.
  class Name < Data.define(:string)
    # Converts the name to snake_case.
    #
    # === Example
    #
    #   Autodoc::Name.new("BarChart").snake  # => "bar_chart"
    def snake
      string.to_s
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
    end

    # Returns the original string.
    def to_s
      string.to_s
    end
  end
end
