#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ruby - "$PROJECT_ROOT" <<'RUBY'
require "json"

root = ARGV.fetch(0)
targets = [
  {
    name: "App",
    source_root: File.join(root, "App"),
    helper: "AppLocalization",
    catalog: File.join(root, "App/Resources/Localizable.xcstrings")
  },
  {
    name: "Core",
    source_root: File.join(root, "Sources/Core"),
    helper: "CoreLocalization",
    catalog: File.join(root, "Sources/Core/Resources/Localizable.xcstrings")
  }
]

targets.each do |target|
  catalog = JSON.parse(File.read(target.fetch(:catalog)))
  abort "#{target[:name]} catalog sourceLanguage must be vi" unless catalog["sourceLanguage"] == "vi"

  strings = catalog.fetch("strings")
  strings.each do |key, entry|
    unit = entry.dig("localizations", "vi", "stringUnit")
    unless unit && unit["state"] == "translated" && !unit["value"].to_s.empty?
      abort "#{target[:name]} missing translated Vietnamese value for #{key}"
    end
  end

  source = Dir.glob(File.join(target.fetch(:source_root), "**/*.swift"))
    .sort
    .map { |path| File.read(path) }
    .join("\n")
  helper = Regexp.escape(target.fetch(:helper))
  used_keys = source.scan(/#{helper}\.(?:text|format)\(\s*"([^"]+)"/m).flatten.uniq.sort
  catalog_keys = strings.keys.sort

  missing = used_keys - catalog_keys
  unused = catalog_keys - used_keys
  abort "#{target[:name]} catalog missing keys: #{missing.join(', ')}" unless missing.empty?
  abort "#{target[:name]} catalog has unused keys: #{unused.join(', ')}" unless unused.empty?

  puts "#{target[:name]} localization catalog: #{catalog_keys.length} keys OK"
end

app_source = Dir.glob(File.join(root, "App/**/*.swift"))
  .sort
  .map { |path| File.read(path) }
  .join("\n")
direct_literals = app_source.scan(
  /(?:Text|Button|Toggle|Picker|Section|GroupBox|LabeledContent)\(\s*"([^"]+)"/
).flatten.reject { |value| value == "VietLunar" }
abort "Direct user-visible literals remain: #{direct_literals.uniq.sort.join(', ')}" unless direct_literals.empty?
RUBY
