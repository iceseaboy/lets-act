#!/usr/bin/env python3
"""Generate a dependency-free Xcode project and shared test scheme deterministically."""
from pathlib import Path
import hashlib

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "ios"
PROJECT = IOS / "LetsAct.xcodeproj"
PROJECT.mkdir(exist_ok=True)
objects = {}

def uid(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()

def add(name, value):
    key = uid(name)
    objects[key] = value
    return key

def quote(value):
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"') + '"'

def array(values):
    return '(' + ', '.join(values) + (',' if values else '') + ')'

def settings(values):
    return '{' + ' '.join(f'{key} = {quote(value)};' for key, value in values.items()) + '}'

app_sources = sorted((IOS / "LetsAct").rglob("*.swift"))
test_sources = sorted((IOS / "LetsActUITests").rglob("*.swift"))
groups = []
for kind, sources in [("app", app_sources), ("tests", test_sources)]:
    refs, builds = [], []
    for source in sources:
        path = str(source.relative_to(IOS))
        ref = add(path, f'{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quote(path)}; sourceTree = SOURCE_ROOT;}}')
        refs.append(ref)
        builds.append(add("build:" + path, f'{{isa = PBXBuildFile; fileRef = {ref};}}'))
    groups.append(add(kind + "group", f'{{isa = PBXGroup; children = {array(refs)}; name = {quote("LetsAct" if kind == "app" else "LetsActUITests")}; sourceTree = "<group>";}}'))
    add(kind + "sources", f'{{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {array(builds)}; runOnlyForDeploymentPostprocessing = 0;}}')
    add(kind + "frameworks", '{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;}')
    resources = []
    if kind == "app":
        for path, filetype in [("LetsAct/Resources/Assets.xcassets", "folder.assetcatalog"), ("LetsAct/Resources/PrivacyInfo.xcprivacy", "text.xml")]:
            ref = add(path, f'{{isa = PBXFileReference; lastKnownFileType = {filetype}; path = {quote(path)}; sourceTree = SOURCE_ROOT;}}')
            resources.append(add("build:" + path, f'{{isa = PBXBuildFile; fileRef = {ref};}}'))
            groups.append(ref)
    add(kind + "resources", f'{{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {array(resources)}; runOnlyForDeploymentPostprocessing = 0;}}')

app_product = add("appProduct", '{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = LetsAct.app; sourceTree = BUILT_PRODUCTS_DIR;}')
test_product = add("testProduct", '{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = LetsActUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;}')
products = add("products", f'{{isa = PBXGroup; children = {array([app_product, test_product])}; name = Products; sourceTree = "<group>";}}')
root_group = add("rootGroup", f'{{isa = PBXGroup; children = {array(groups + [products])}; sourceTree = "<group>";}}')

for kind in ["project", "app", "tests"]:
    configs = []
    for configuration in ["Debug", "Release"]:
        values = {}
        if kind == "project":
            values = {"IPHONEOS_DEPLOYMENT_TARGET": "17.0", "SDKROOT": "iphoneos", "SWIFT_VERSION": "5.0", "CLANG_ENABLE_MODULES": "YES", "CLANG_ENABLE_OBJC_ARC": "YES", "SWIFT_STRICT_CONCURRENCY": "targeted", "ENABLE_USER_SCRIPT_SANDBOXING": "YES", "DEBUG_INFORMATION_FORMAT": "dwarf" if configuration == "Debug" else "dwarf-with-dsym", "SWIFT_OPTIMIZATION_LEVEL": "-Onone" if configuration == "Debug" else "-O", "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG" if configuration == "Debug" else "", "ENABLE_TESTABILITY": "YES" if configuration == "Debug" else "NO"}
        elif kind == "app":
            values = {"PRODUCT_BUNDLE_IDENTIFIER": "com.letsact.app", "PRODUCT_NAME": "$(TARGET_NAME)", "INFOPLIST_FILE": "LetsAct/Resources/Info.plist", "GENERATE_INFOPLIST_FILE": "NO", "TARGETED_DEVICE_FAMILY": "1,2", "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator", "SUPPORTS_MACCATALYST": "NO", "CODE_SIGN_STYLE": "Automatic", "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon", "CURRENT_PROJECT_VERSION": "1", "MARKETING_VERSION": "0.1.0", "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks"}
        else:
            values = {"PRODUCT_BUNDLE_IDENTIFIER": "com.letsact.app.uitests", "PRODUCT_NAME": "$(TARGET_NAME)", "GENERATE_INFOPLIST_FILE": "YES", "TARGETED_DEVICE_FAMILY": "1,2", "TEST_TARGET_NAME": "LetsAct", "CODE_SIGN_STYLE": "Automatic"}
        configs.append(add(kind + configuration, f'{{isa = XCBuildConfiguration; buildSettings = {settings(values)}; name = {configuration};}}'))
    add(kind + "config", f'{{isa = XCConfigurationList; buildConfigurations = {array(configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;}}')

proxy = add("proxy", f'{{isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("appTarget")}; remoteInfo = LetsAct;}}')
dependency = add("dependency", f'{{isa = PBXTargetDependency; target = {uid("appTarget")}; targetProxy = {proxy};}}')
for kind, name, product, product_type in [("app", "LetsAct", app_product, "com.apple.product-type.application"), ("tests", "LetsActUITests", test_product, "com.apple.product-type.bundle.ui-testing")]:
    phases = [uid(kind + suffix) for suffix in ["sources", "frameworks", "resources"]]
    add(kind + "Target", f'{{isa = PBXNativeTarget; buildConfigurationList = {uid(kind + "config")}; buildPhases = {array(phases)}; buildRules = (); dependencies = {array([dependency] if kind == "tests" else [])}; name = {name}; productName = {name}; productReference = {product}; productType = {quote(product_type)};}}')
add("project", f'{{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; TargetAttributes = {{{uid("appTarget")} = {{CreatedOnToolsVersion = 16.0;}}; {uid("testsTarget")} = {{CreatedOnToolsVersion = 16.0; TestTargetID = {uid("appTarget")};}};}};}}; buildConfigurationList = {uid("projectconfig")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {root_group}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = {array([uid("appTarget"), uid("testsTarget")])};}}')

content = '// !$*UTF8*$!\n{\n archiveVersion = 1;\n classes = {};\n objectVersion = 56;\n objects = {\n'
content += '\n'.join(f'  {key} = {value};' for key, value in objects.items())
content += f'\n }};\n rootObject = {uid("project")};\n}}\n'
(PROJECT / "project.pbxproj").write_text(content)

def buildable(target, name):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid(target)}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:LetsAct.xcodeproj"/>'

scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
    <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{buildable('appTarget', 'LetsAct.app')}</BuildActionEntry>
  </BuildActionEntries></BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{buildable('testsTarget', 'LetsActUITests.xctest')}</TestableReference></Testables></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildable('appTarget', 'LetsAct.app')}</BuildableProductRunnable></LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildable('appTarget', 'LetsAct.app')}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
scheme_dir = PROJECT / "xcshareddata/xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
(scheme_dir / "LetsAct.xcscheme").write_text(scheme)
print(f"Generated {len(app_sources)} app sources and {len(test_sources)} UI test sources")
