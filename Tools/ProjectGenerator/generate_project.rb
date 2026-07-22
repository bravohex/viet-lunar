#!/usr/bin/env ruby

require "fileutils"
require "digest"
require "pathname"
require "xcodeproj"

# xcodeproj's UUID predictabilizer cannot distinguish structurally identical
# target dependencies when their initial proxy UUIDs are random. A stable
# creation sequence makes those inputs deterministic before final path hashing.
module DeterministicProjectUUIDs
  def generate_available_uuid_list(count = 100)
    @deterministic_uuid_sequence ||= 0
    candidates = Array.new(count + 1) do
      seed = "VietLunar-Xcodeproj-#{@deterministic_uuid_sequence}"
      @deterministic_uuid_sequence += 1
      Digest::SHA256.hexdigest(seed)[0, 24].upcase
    end
    unique_candidates = candidates - (@generated_uuids + uuids)
    @generated_uuids += unique_candidates
    @available_uuids += unique_candidates
  end
end

Xcodeproj::Project.prepend(DeterministicProjectUUIDs)

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
    settings["MARKETING_VERSION"] = "0.1.7"
    settings["CURRENT_PROJECT_VERSION"] = "7"
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

def add_resources(project, target, group_name, directory, files)
  group = project.main_group.new_group(group_name, directory)
  files.each do |relative_path|
    reference = group.new_file(relative_path)
    target.resources_build_phase.add_file_reference(reference)
  end
  group
end

def link_target(consumer, dependency)
  consumer.add_dependency(dependency)
  consumer.frameworks_build_phase.add_file_reference(dependency.product_reference)
end

core = project.new_target(:framework, "VietLunarCore", :osx, "13.0")
infrastructure = project.new_target(:static_library, "VietLunarInfrastructure", :osx, "13.0")
app = project.new_target(:application, "VietLunar", :osx, "13.0")
core_tests = project.new_target(:unit_test_bundle, "VietLunarCoreTests", :osx, "13.0")
infrastructure_tests = project.new_target(:unit_test_bundle, "VietLunarInfrastructureTests", :osx, "13.0")
ui_tests = project.new_target(:ui_test_bundle, "VietLunarUITests", :osx, "13.0")

configure_target(core, "com.bravohex.vietlunar.core")
configure_target(infrastructure, "com.bravohex.vietlunar.infrastructure")
configure_target(app, "com.bravohex.vietlunar")
configure_target(core_tests, "com.bravohex.vietlunar.core-tests")
configure_target(infrastructure_tests, "com.bravohex.vietlunar.infrastructure-tests")
configure_target(ui_tests, "com.bravohex.vietlunar.ui-tests")

app.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings["CODE_SIGN_ENTITLEMENTS"] = "App/VietLunar.entitlements"
  settings["ENABLE_APP_SANDBOX"] = "YES"
  settings["ENABLE_HARDENED_RUNTIME"] = "YES"
  settings["INFOPLIST_KEY_LSApplicationCategoryType"] = "public.app-category.utilities"
  settings["INFOPLIST_KEY_LSUIElement"] = "YES"
  settings["INFOPLIST_KEY_NSHumanReadableCopyright"] =
    "Copyright © 2026 bravohex"
  settings["PRODUCT_NAME"] = "VietLunar"
  settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  settings["ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"] = ""
  if configuration.name == "Release"
    settings["CODE_SIGN_INJECT_BASE_ENTITLEMENTS"] = "NO"
  end
end

ui_tests.build_configurations.each do |configuration|
  configuration.build_settings["TEST_TARGET_NAME"] = "VietLunar"
end

add_sources(
  project,
  core,
  "Core",
  "Sources/Core",
  [
    "VietLunarCore.swift",
    "DateTypes/DateValidationError.swift",
    "DateTypes/SolarDate.swift",
    "DateTypes/LunarDate.swift",
    "DateTypes/YearMonth.swift",
    "DateTypes/LocalTime.swift",
    "DateTypes/LocalDateTime.swift",
    "DateTypes/GregorianJDN.swift",
    "DateTypes/VietnamCalendarTime.swift",
    "CanChi/HeavenlyStem.swift",
    "CanChi/EarthlyBranch.swift",
    "CanChi/StemBranch.swift",
    "CanChi/CanChiDayBoundaryPolicy.swift",
    "CanChi/AuspiciousHour.swift",
    "CanChi/TraditionalDayClassification.swift",
    "CanChi/CanChiCalculator.swift",
    "Time/Clock.swift",
    "Snapshot/CalendarSnapshot.swift",
    "Snapshot/CalendarSnapshotFactory.swift",
    "MonthGrid/WeekStart.swift",
    "MonthGrid/MonthGridCell.swift",
    "MonthGrid/MonthGridBuilder.swift",
    "Formatting/CoreLocalization.swift",
    "Formatting/MenuBarTitleFormat.swift",
    "Formatting/MenuBarTitlePresentation.swift",
    "Formatting/VietnameseCalendarFormatter.swift",
    "Refresh/BoundaryCalculator.swift",
    "Preferences/AppPreferences.swift",
    "Lunar/EncodedLunarYearRecord.swift",
    "Lunar/LunarCalendarCalculating.swift",
    "Lunar/LunarCalendarEngine.swift",
    "Generated/LunarYearTable.generated.swift"
  ]
)
add_sources(
  project,
  infrastructure,
  "Infrastructure",
  "Sources/Infrastructure",
  [
    "VietLunarInfrastructure.swift",
    "Logging/AppLog.swift",
    "Time/OneShotBoundaryScheduler.swift",
    "Lifecycle/AppLifecycleEvent.swift",
    "Lifecycle/SystemLifecycleSource.swift",
    "Lifecycle/LifecycleEventCoordinator.swift",
    "Preferences/UserDefaultsPreferencesStore.swift",
    "LoginItem/SMLoginItemService.swift"
  ]
)
add_sources(
  project,
  app,
  "App",
  "App",
  [
    "VietLunarApp.swift",
    "IconAsset.swift",
    "AppState.swift",
    "Localization/AppLocalization.swift",
    "Views/MenuPopoverView.swift",
    "Views/CalendarHeaderView.swift",
    "Views/MonthGridView.swift",
    "Views/SelectedDayDetailView.swift",
    "Views/TraditionalDayStatusLabel.swift",
    "Views/PopoverFooterView.swift",
    "Views/SettingsView.swift"
  ]
)
add_resources(
  project,
  core,
  "CoreResources",
  "Sources/Core/Resources",
  ["Localizable.xcstrings"]
)
add_resources(
  project,
  app,
  "AppResources",
  "App/Resources",
  ["Localizable.xcstrings", "Assets.xcassets"]
)
add_sources(
  project,
  core_tests,
  "CoreTests",
  "Tests/CoreTests",
  [
    "VietLunarCoreTests.swift",
    "DateTypesTests.swift",
    "GregorianJDNTests.swift",
    "VietnamCalendarTimeTests.swift",
    "EncodedLunarYearRecordTests.swift",
    "LunarCalendarEngineTests.swift",
    "CanChiTypesTests.swift",
    "CanChiCalculatorTests.swift",
    "CanChiHourTests.swift",
    "AuspiciousHourCalculatorTests.swift",
    "TraditionalDayClassificationTests.swift",
    "CalendarSnapshotFactoryTests.swift",
    "MonthGridBuilderTests.swift",
    "VietnameseCalendarFormatterTests.swift",
    "BoundaryCalculatorTests.swift",
    "AppPreferencesTests.swift",
    "LunarExhaustiveRoundTripTests.swift"
  ]
)
add_sources(
  project,
  infrastructure_tests,
  "InfrastructureTests",
  "Tests/InfrastructureTests",
  [
    "VietLunarInfrastructureTests.swift",
    "OneShotBoundarySchedulerTests.swift",
    "LifecycleSourceTests.swift",
    "UserDefaultsPreferencesStoreTests.swift",
    "SMLoginItemServiceTests.swift"
  ]
)
add_sources(project, ui_tests, "UITests", "Tests/UITests", ["VietLunarUITests.swift"])

link_target(infrastructure, core)
link_target(app, core)
link_target(app, infrastructure)
link_target(core_tests, core)
link_target(infrastructure_tests, core)
link_target(infrastructure_tests, infrastructure)
ui_tests.add_dependency(app)

embed_frameworks = app.new_copy_files_build_phase("Embed Frameworks")
embed_frameworks.dst_subfolder_spec = "10"
[core].each do |framework_target|
  build_file = embed_frameworks.add_file_reference(framework_target.product_reference, true)
  build_file.settings = {
    "ATTRIBUTES" => ["CodeSignOnCopy", "RemoveHeadersOnCopy"]
  }
end

project.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings["MACOSX_DEPLOYMENT_TARGET"] = "13.0"
  settings["SWIFT_VERSION"] = "6.0"
  settings["SWIFT_STRICT_CONCURRENCY"] = "complete"
end

project.predictabilize_uuids
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
