# frozen_string_literal: true

require File.expand_path "#{File.dirname(__FILE__)}/lib/issue/version"

Gem::Specification.new do |s|
  s.name = "issue"
  s.version = Issue::VERSION
  s.platform = Gem::Platform::RUBY
  s.date = Time.now.strftime('%Y-%m-%d')
  s.authors = ["Juanjo Bazán"]
  s.homepage = 'http://github.com/xuanxu/issue'
  s.license = "MIT"
  s.summary = "Manage webhook payload for issue events"
  s.description = "Receive, parse and manage GitHub webhook events for issues, PRs and issue's comments"
  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/xuanxu/issue/issues",
    "changelog_uri"     => "https://github.com/xuanxu/issue/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://www.rubydoc.info/gems/issue",
    "homepage_uri"      => s.homepage,
    "source_code_uri"   => s.homepage
  }
  s.files = %w(LICENSE README.md CHANGELOG.md) + Dir.glob("{spec,lib/**/*}") & `git ls-files -z`.split("\0")
  s.require_paths = ["lib"]
  s.rdoc_options = ['--main', 'README.md', '--charset=UTF-8']

  s.add_dependency "openssl", "~> 3.2"
  s.add_dependency "rack", "~> 3.1"

  s.add_development_dependency "rake", "~> 13.2"
  s.add_development_dependency "rspec", "~> 3.13"
end
