<!--
  SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Added

- Initial release of `ratatui_ruby-devtools`
- Rake tasks: `lint`, `lint:fix`, `reuse`, `license`, `bump`
- Executables: `agent_rake`, `consolidate_md`, `hbs`, `announce`
- Templates for scaffolding new ecosystem gems
- Auto-discovery of gem configuration from `*.gemspec`
- Conditional Cargo/Rust task support for gems with native extensions