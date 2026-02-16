# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# GitHubCli wraps availability and authentication checks for the `gh` CLI.
class GitHubCli
  # Whether the +gh+ binary is on PATH.
  def available?
    system("command", "-v", "gh", out: File::NULL, err: File::NULL)
  end

  # Whether +gh auth status+ reports a valid session.
  def authenticated?
    system("gh", "auth", "status", out: File::NULL, err: File::NULL)
  end

  # Whether the CLI is both installed and authenticated.
  def ready?
    available? && authenticated?
  end

  # Prints advisory when the +gh+ binary cannot be found.
  def warn_unavailable
    warn "\n⚠  'gh' CLI not found — skipping native gem push."
    warn "   Install: https://cli.github.com\n\n"
  end

  # Prints advisory when +gh+ is installed but not logged in.
  def warn_unauthenticated
    warn "\n⚠  'gh' is not authenticated — skipping native gem push."
    warn "   Run: gh auth login\n\n"
  end
end
