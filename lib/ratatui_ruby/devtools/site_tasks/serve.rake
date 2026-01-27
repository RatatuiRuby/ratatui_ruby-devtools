# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

desc "Serve public/ locally on http://localhost:8000"
task :serve do
  require "webrick"
  server = WEBrick::HTTPServer.new(Port: 8000, DocumentRoot: File.expand_path("public", Dir.pwd))
  trap("INT") { server.shutdown }
  server.start
end
