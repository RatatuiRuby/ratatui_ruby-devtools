# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

module Autodoc
  # Member types for autodoc generation.
  #
  # Autodoc generates RBS types and RDoc comments for TUI factory methods.
  # Each method type (delegate, factory, helper) has different documentation
  # patterns. Writing these by hand is tedious and error-prone.
  #
  # These Data classes generate consistent RBS and RDoc output for each
  # member type. Feed them method names. Get documentation.
  module Member
    # A method that delegates to an identically-named module method.
    #
    # Some instance methods simply call a module-level method. This class
    # generates the RBS signature and RDoc comment for such methods.
    #
    # [name] The method name.
    class Delegate < Data.define(:name)
      # Generates an RBS type signature for this delegate.
      #
      # Autodoc writes .rbs files. Each method needs a signature. Delegates
      # forward all arguments, so they use a generic variadic signature.
      def rbs
        "    def #{name}: (*untyped args, **untyped kwargs) ?{ (*untyped) -> untyped } -> untyped"
      end

      # Generates RDoc comment lines for this delegate.
      #
      # Autodoc writes method documentation. Each method needs a comment.
      # Delegates describe forwarding to the module method. This returns
      # the correctly-formatted comment lines.
      def rdoc
        [
          "    # :method: #{name}",
          "    # :call-seq: #{name}(*args, **kwargs, &block)",
          "    #",
          "    # Delegates to RatatuiRuby.#{name}.",
          "    #",
        ]
      end
    end

    # A factory method that creates instances of a widget class.
    #
    # Factory methods like <tt>paragraph</tt> create <tt>Paragraph.new</tt>.
    # This class generates the RBS signature and RDoc comment.
    #
    # [name] The method name.
    # [const_name] The constant name (e.g., <tt>Paragraph</tt>).
    class Factory < Data.define(:name, :const_name)
      # Generates an RBS type signature for this factory.
      #
      # Autodoc writes .rbs files. Each method needs a signature. Factories
      # forward all arguments to constructors, so they use a generic variadic
      # signature.
      def rbs
        "    def #{name}: (*untyped args, **untyped kwargs) ?{ (*untyped) -> untyped } -> untyped"
      end

      # Generates RDoc comment lines for this factory.
      #
      # Autodoc writes method documentation. Each method needs a comment.
      # Factories describe creating a widget instance. This returns the
      # correctly-formatted comment lines.
      def rdoc
        [
          "    # :method: #{name}",
          "    # :call-seq: #{name}(*args, **kwargs, &block)",
          "    #",
          "    # Factory for RatatuiRuby::#{const_name}.new.",
          "    #",
        ]
      end
    end

    # A helper method that wraps a class method.
    #
    # Helper methods call class methods with simplified signatures. This
    # class generates the RBS signature and RDoc comment.
    #
    # [name] The method name.
    # [class_method] The class method being wrapped.
    # [const_name] The constant name.
    class Helper < Data.define(:name, :class_method, :const_name)
      # Generates an RBS type signature for this helper.
      #
      # Autodoc writes .rbs files. Each method needs a signature. Helpers
      # forward all arguments to class methods, so they use a generic variadic
      # signature.
      def rbs
        "    def #{name}: (*untyped args, **untyped kwargs) ?{ (*untyped) -> untyped } -> untyped"
      end

      # Generates RDoc comment lines for this helper.
      #
      # Autodoc writes method documentation. Each method needs a comment.
      # Helpers describe calling a class method. This returns the
      # correctly-formatted comment lines.
      def rdoc
        [
          "    # :method: #{name}",
          "    # :call-seq: #{name}(*args, **kwargs, &block)",
          "    #",
          "    # Helper for RatatuiRuby::#{const_name}.#{class_method}.",
          "    #",
        ]
      end
    end
  end
end
