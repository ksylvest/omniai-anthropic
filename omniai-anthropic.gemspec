# frozen_string_literal: true

require_relative "lib/omniai/anthropic/version"

Gem::Specification.new do |spec|
  spec.name = "omniai-anthropic"
  spec.version = OmniAI::Anthropic::VERSION
  spec.license = "MIT"
  spec.authors = ["Kevin Sylvestre"]
  spec.email = ["kevin@ksylvest.com"]

  spec.summary = "A generalized framework for interacting with Anthropic"
  spec.description = "An implementation of OmniAI for Anthropic"
  spec.homepage = "https://github.com/ksylvest/omniai-anthropic"

  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("{lib}/**/*") + %w[README.md Gemfile]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]

  spec.add_dependency "event_stream_parser"
  spec.add_dependency "omniai", "~> 2.0"
  spec.add_dependency "zeitwerk"
end
