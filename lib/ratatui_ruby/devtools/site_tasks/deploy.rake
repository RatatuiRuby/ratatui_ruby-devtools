# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Uses PUBLIC_DOCS_DIR from build.rake

desc "Deploy to production (builds first, validates docs)"
task deploy: :build do
  trunk_dir = File.join(PUBLIC_DOCS_DIR, "trunk")
  unless File.directory?(trunk_dir)
    abort "ERROR: #{trunk_dir} does not exist. Run `rake build:docs` first."
  end

  sh "kamal deploy"
end
