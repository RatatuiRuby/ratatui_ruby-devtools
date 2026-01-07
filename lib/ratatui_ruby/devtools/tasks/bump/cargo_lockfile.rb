# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Refreshes Cargo.lock after version changes.
#
# Rust crates have lockfiles that pin dependency versions. After updating
# Cargo.toml, the lockfile becomes stale. Running cargo update fixes it.
#
# This class wraps the lockfile refresh operation. It runs cargo update
# in the crate directory. Use it after bumping Rust extension versions.
#
# [path] The path to the Cargo.lock file.
# [dir] The directory containing the Cargo.toml.
# [name] The crate name to update.
class CargoLockfile < Data.define(:path, :dir, :name)
  # Checks whether the lockfile exists on disk.
  #
  # Pure Ruby gems have no Cargo.lock. Refreshing a missing file fails. Check
  # this before calling refresh to avoid errors.
  def exists?
    File.exist?(path)
  end

  # Refreshes the lockfile by running cargo update.
  #
  # Runs <tt>cargo update -p {name} --offline</tt> in the crate directory.
  def refresh
    return unless exists?

    Dir.chdir(dir) do
      system("cargo update -p #{name} --offline")
    end
  end
end
