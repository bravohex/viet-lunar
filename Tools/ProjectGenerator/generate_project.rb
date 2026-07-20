#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require "xcodeproj"

ROOT = Pathname.new(__dir__).join("../..").expand_path
PROJECT_PATH = ROOT.join("VietLunar.xcodeproj")

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH.to_s)
project.root_object.attributes["LastSwiftUpdateCheck"] = "2600"
project.root_object.attributes["LastUpgradeCheck"] = "2600"

def configure_target(target, bundle_identifier)
  target.build_configurations.each do |configuration|
    settings = configuration.build_settings
    settings["MACOSX_DEPLOYMENT_TARGET"] = "13.0"
    settings["SWIFT_VERSION"] = "6.0"
    settings["SWIFT_STRICT_CONCURRENCY"] = "complete"
    settings["SWIFT_TREAT_WARNINGS_AS_ERRORS"] = "YES"
    settings["CLANG_WARN_DOCUMENTATION_COMMENTS"] = "YES"
    settings["CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER"] = "YES"
    settings["ENABLE_USER_SCRIPT_SANDBOXING"] = "YES"
    settings["GENERATE_INFOPLIST_FILE"] = "YES"
    settings["PRODUCT_BUNDLE_IDENTIFIER"] = bundle_identifier
    settings["MARKETING_VERSION"] = "0.1.0"
    settings["CURRENT_PROJECT_VERSION"] = "1"
  end
end

def add_sources(project, target, group_name, directory, files)
  group = project.main_group.new_group(group_name, directory)
  files.each do |relative_path|
    reference = group.new_file(relative_path)
    target.source_build_phase.add_file_reference(reference)
  end
  group
end

def link_target(consumer, dependency)
  consumer.add_dependency(dependency)
  consumer.frameworks_build_phase.add_file_reference(dependency.product_reference)
end

core = project.new_target(:framework, "VietLunarCore", :osx, "13.0")
infrastructure = project.new_target(:framework, "VietLunarInfrastructure", :osx, "13.0")
app = project.new_target(:application, "VietLunar", :osx, "13.0")
core_tests = project.new_target(:unit_test_bundle, "VietLunarCoreTests", :osx, "13.0")
infrastructure_tests = project.new_target(:unit_test_bundle, "VietLunarInfrastructureTests", :osx, "13.0")
ui_tests = project.new_target(:ui_test_bundle, "VietLunarUITests", :osx, "13.0")

configure_target(core, "com.tuanlm.VietLunar.core")
configure_target(infrastructure, "com.tuanlm.VietLunar.infrastructure")
configure_target(app, "com.tuanlm.VietLunar")
configure_target(core_tests, "com.tuanlm.VietLunar.core-tests")
configure_target(infrastructure_tests, "com.tuanlm.VietLunar.infrastructure-tests")
configure_target(ui_tests, "com.tuanlm.VietLunar.ui-tests")

app.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings["ENABLE_APP_SANDBOX"] = "YES"
  settings["ENABLE_HARDENED_RUNTIME"] = "YES"
  settings["INFOPLIST_KEY_LSApplicationCategoryType"] = "public.app-category.utilities"
  settings["PRODUCT_NAME"] = "VietLunar"
end

ui_tests.build_configurations.each do |configuration|
  configuration.build_settings["TEST_TARGET_NAME"] = "VietLunar"
end

add_sources(project, core, "Core", "Sources/Core", ["VietLunarCore.swift"])
add_sources(project, infrastructure, "Infrastructure", "Sources/Infrastructure", ["VietLunarInfrastructure.swift"])
add_sources(project, app, "App", "App", ["VietLunarApp.swift"])
add_sources(project, core_tests, "CoreTests", "Tests/CoreTests", ["VietLunarCoreTests.swift"])
add_sources(project, infrastructure_tests, "InfrastructureTests", "Tests/InfrastructureTests", ["VietLunarInfrastructureTests.swift"])
add_sources(project, ui_tests, "UITests", "Tests/UITests", ["VietLunarUITests.swift"])

link_target(infrastructure, core)
link_target(app, core)
link_target(app, infrastructure)
link_target(core_tests, core)
link_target(infrastructure_tests, core)
link_target(infrastructure_tests, infrastructure)
ui_tests.add_dependency(app)

project.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings["MACOSX_DEPLOYMENT_TARGET"] = "13.0"
  settings["SWIFT_VERSION"] = "6.0"
  settings["SWIFT_STRICT_CONCURRENCY"] = "complete"
end

project.save

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_build_target(core)
scheme.add_build_target(infrastructure)
scheme.add_test_target(core_tests)
scheme.add_test_target(infrastructure_tests)
scheme.add_test_target(ui_tests)
scheme.set_launch_target(app)
scheme.save_as(PROJECT_PATH.to_s, "VietLunar", true)

puts "Generated #{PROJECT_PATH}"
