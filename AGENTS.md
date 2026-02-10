# Eagle Extra Repository — Agent Specification

## 1. Purpose

This document is a formal specification of the Eagle `extra` repository,
located at `https://github.com/mistachkin/extra`. It is intended for
autonomous agents, language model tool-use implementations, and other
programmatic clients that need to understand, use, or extend the startup
scripts, packages, interactive extension commands, test infrastructure,
security artifacts, and ruleset files contained in this repository.

The `extra` repository provides add-on startup scripts, integration packages,
and interactive tools for the Eagle scripting language. Eagle is a
Tcl-compatible scripting language implemented in managed code. The official
Eagle source code repository is at `https://urn.to/r/code`; the official
documentation repository is at `https://urn.to/r/docs`.

A separate agent specification for the ruleset files in the `ruleSets/`
directory is available at `ruleSets/AGENTS.md`. This document covers the
repository as a whole, including the startup chain, packages, interactive
extension commands, test infrastructure, and security artifacts. It
cross-references the ruleset specification where appropriate.

## 2. License and Attribution

The repository is licensed under the BSD 3-Clause License. The copyright
holder is Joe Mistachkin. All files carry the Tcl-style license as described
in the Eagle `license.terms` file.

```
Copyright (c) 2007-2025 Joe Mistachkin.  All rights reserved.
```

## 3. Repository Structure

The repository contains 143 files organized as follows:

```
AGENTS.md                                 — This document.
README.md                                 — Human-readable overview.
LICENSE                                   — BSD 3-Clause License.
.gitattributes                            — GitHub linguist config (*.eagle → Tcl).
.gitignore                                — Excludes private/site-specific directories.

startup.eagle                             — Stage 1: Core startup entry point.
tclshrc.tcl                               — Stage 2: Startup driver script.
startup-lister.eagle                      — Stage 3: Ordered file list builder.
startup-compat.eagle                      — Stage 4: Compatibility shims.
worker.eagle                              — Background worker initialization.
shellWorker.eagle                         — Shell worker initialization.
testPrologue.eagle                        — Test suite setup.
testEpilogue.eagle                        — Test suite cleanup.

Certificates/
  Script/
    Plugin1.0/
      pkgIndex.eagle.harpy                — Script certificate for Plugin1.0.

Configurations/
  InteractiveLoop/
    interactive_loop.eagle                — Signed interactive loop entry point.
    interactive_loop.eagle.b64sig         — Base64-encoded script signature.

KeyRings/
  Personal/
    keyRing.personal.eagle                — Personal signing key ring.
    keyRing.personal.eagle.harpy          — Script certificate for key ring.

LoadOnStartup/
  Public/
    backcompat.eagle                      — Backward compatibility shims.
    chat.eagle                            — Fossil chat polling package.
    checkUpdateZeusHook.eagle             — Zeus update hook integration.
    execPipes.eagle                       — Execute-with-pipes package.
    helpers.eagle                         — Detection utilities and test runners.
    history.eagle                         — Interactive command history.
    intExtCmds.eagle                      — Interactive extension commands (public).
    intExtCmds_licensing.eagle            — Interactive extension commands (licensing).
    licensing.eagle                       — Harpy licensing package.
    licensing_test.eagle                  — Licensing test helper.
    mathematica.eagle                     — Wolfram Mathematica bridge.
    releaseTestingHelper.eagle            — Release testing helper.
    secrets.eagle                         — Secrets search and clipboard utilities.
    sms.eagle                             — Twilio SMS integration.
    pkgIndex_9e27cfa54b4b427e.eagle       — Package index file.
    Settings/
      secrets-patterns.eagle              — Regular expression patterns for secrets.
    *.harpy                               — Script certificates (one per script).

Scripts/
  Public/
    badgeTest.eagle                       — Badge plugin test suite runner.
    WatchCat/
      watchCat.tool.eagle                 — Log file monitoring tool.
      watchCron.eagle                     — Cron job watcher and reporter.
      *.harpy                             — Script certificates.

Settings/
  startup-settings-files.eagle            — Startup phase and file list definitions.
  startup-settings.eagle                  — Startup configuration settings.
  *.harpy                                 — Script certificates.

ruleSets/
  AGENTS.md                               — Ruleset agent specification.
  *.ruleSet                               — 37 ruleset definition files.
  *.ruleSet.harpy                         — Script certificates (one per ruleset).
  tcl84-wiki.txt                          — Tcl 8.4 command reference.
```

### 3.1. File Types

| Extension | Count | Description |
|---|---|---|
| `.eagle` | 30 | Eagle script files (Tcl-compatible). |
| `.tcl` | 1 | Tcl script file (`tclshrc.tcl`). |
| `.ruleSet` | 37 | Ruleset definition files (see `ruleSets/AGENTS.md`). |
| `.harpy` | 68 | Harpy script certificate files (XML format). |
| `.b64sig` | 1 | Base64-encoded script signature file. |
| `.txt` | 1 | Plain-text reference file (`tcl84-wiki.txt`). |
| `.md` | 2 | Markdown documentation files. |

### 3.2. The `.gitignore` Exclusions

The `.gitignore` file excludes the following directories, which exist in
the author's local working environment but are not part of the public
repository:

- `Certificates/License/` — License certificate files.
- `Data/` — Local data files.
- `Drafts/` — Draft scripts.
- `KeyRings/Auxiliary/` — Additional key rings.
- `Killer/` — Process termination utilities.
- `LoadOnStartup/Private/` — Site-specific authentication scripts.
- `LoadOnStartup/Public/WatchCat/` — WatchCat library package.
- `Scripts/Private/` — Private scripts.
- `Tools/` — Local tool binaries.
- `cmd/` and `cmds/` — Command history files.

**Guidance for agents:** The excluded directories may be referenced by scripts
in the repository (e.g., `LoadOnStartup/Private/auth.eagle`). If a script
references a file from an excluded directory, the file is site-specific and
will not be present in a fresh clone. The scripts are designed to handle
missing files gracefully, typically by skipping the missing functionality.

## 4. Quick Start

To activate the startup chain, set the `XDG_STARTUP_HOME` environment variable
to the path of the repository checkout and then start an Eagle interpreter:

```tcl
set ::env(XDG_STARTUP_HOME) /path/to/extra
```

Upon startup of an Eagle interpreter (beta 46 or later), the startup chain
(section 5) will execute automatically.

## 5. Startup Chain

The startup chain is a sequence of scripts that execute automatically when an
Eagle interpreter is created. The chain initializes the interactive
environment, loads packages, applies compatibility shims, and optionally
installs licensing hooks and background workers.

### 5.1. Startup Sequence

| Stage | Script | Function |
|---|---|---|
| 1 | `startup.eagle` | The core entry point. Evaluated by all created interpreters in Eagle beta 46 and later, even if the interactive loop will not be entered. Optionally sources `tclshrc.tcl` and installs the Harpy licensing hook. |
| 2 | `tclshrc.tcl` | The startup driver. Iterates through the ordered file list (stage 3), sources each file, and then sources `startup-compat.eagle`. |
| 3 | `startup-lister.eagle` | The file list builder. Consults `Settings/startup-settings-files.eagle` to build the ordered list of files to source during startup. |
| 4 | `startup-compat.eagle` | The compatibility layer. Applies version-specific shims and prints the "Interactive startup complete." message for interactive sessions. |
| 5 | `worker.eagle` | The background worker. Runs on a thread pool thread. Waits for the `::tcl_interactive` variable and then emits a greeting message in interactive mode. |
| 6 | `shellWorker.eagle` | The shell worker. Runs on a thread pool thread. Emits a diagnostic message identifying the current thread. |
| 7 | `testPrologue.eagle` | The test suite prologue. Configures test timeouts, verbosity, runtime options, and WatchCat integration. Evaluated only during test suite runs. |
| 8 | `testEpilogue.eagle` | The test suite epilogue. Dumps complaint information to a file at the end of a test suite run. Evaluated only during test suite runs. |

### 5.2. Stage 1: `startup.eagle`

The entry point script performs three operations in sequence:

1. **Source `tclshrc.tcl`** — Unless the `NoStartupRunCommands` flag is set
   (in `::no(...)` or as an environment variable), the script sources
   `tclshrc.tcl` in the global context via `uplevel #0`.

2. **Load the licensing package** — Unless the `NoLicensingPackage` flag is
   set, the script sources `LoadOnStartup/Public/licensing.eagle` if the file
   exists.

3. **Install the licensing hook** — Unless the `NoLicensing` flag is set, the
   script installs the Harpy `[package unknown]` handler via
   `::Licensing::installPackageUnknown`. This enables dynamic license
   certificate resolution when packages are requested.

The entire script is guarded by `[interp issafe]` and `[interp issdk]` — it
does not execute in `'safe'` interpreters or SDK interpreters.

### 5.3. Stage 2: `tclshrc.tcl`

The startup driver operates in the `::` (global) namespace. It detects whether
it is running inside Eagle (via `::eagle_platform`) and whether startup has
already been completed (via `::eagle_debugger(startup)`).

On first execution:

1. Optionally adds `LoadOnStartup/Public` to the `auto_path` (unless
   `NoLoadOnStartupPublicAutoPath` is set).
2. Auto-detects quiet mode based on the command-line argument list. Batch
   runs are quiet; interactive sessions produce progress output.
3. Sources the file list from `startup-lister.eagle`.
4. Sources each file in the list, skipping files that do not exist.
5. Sources `startup-compat.eagle` (always, even on subsequent evaluations).

On subsequent executions (when `::eagle_debugger(startup)` exists), the script
logs the effective command line to the test log file.

### 5.4. Stage 3: `startup-lister.eagle`

The file lister reads `Settings/startup-settings-files.eagle` and builds an
ordered list of script file paths. The settings file defines four startup
phases:

| Phase | Directory | Files |
|---|---|---|
| `public` | `LoadOnStartup/Public` | `backcompat.eagle`, `chat.eagle`, `helpers.eagle`, `history.eagle`, `intExtCmds.eagle`, `intExtCmds_licensing.eagle`, `secrets.eagle`, `sms.eagle` |
| `watchCat` | `LoadOnStartup/Public/WatchCat` | `watchCat.eagle` |
| `private` | `LoadOnStartup/Private` | `auth.eagle` |
| `settings` | `Settings` | `startup-settings.eagle` |

The files are sourced in phase order, and within each phase, in the order
listed. The `private` phase references `auth.eagle`, which is site-specific
and excluded from the public repository (see section 3.2).

### 5.5. Stage 4: `startup-compat.eagle`

The compatibility layer runs a series of version-check procedures that install
shims for missing functionality in older Eagle releases:

| Procedure | Minimum Version | Shim |
|---|---|---|
| `checkIsWindows` | pre-beta 29 | Defines `isWindows` if not present. |
| `checkEagleBeta28` | beta 28 | Wraps `[interp]` to add `readylimit` sub-command. |
| `checkEagleBeta41` | beta 41 | Defines `isNonNullObjectHandle` if not present. |
| `checkEagleBeta42` | beta 42 | Defines `isDotNetCore` and `doesCompileCSharpWork` if not present. |
| `checkEagleBeta46` | beta 46 | Defines `getShellExecutableName` if not present. |
| `checkEagleBeta47` | beta 47 | Defines `vwaitLocked` if not present. |
| `checkEagleBeta49` | beta 49 | Defines `checkForUnicodeCategory` if not present. |
| `checkEagleBeta51` | beta 51 | Sets network timeout via `SetOrUnsetTimeout`. |
| `checkEagleBeta53` | beta 53 | Defines `checkForOfflineMode` and related if not present. |
| `checkEagleBeta55` | beta 55 | Adds `+Count` to `PromptFlags`. |
| `checkEagleBeta56` | beta 56 | Adds `+CommandCount` and `+ActiveLoops` to `PromptFlags`; sets up prompt script and shell unknown. |

For interactive sessions, the script also:

- Enables command history recording (beta 36+).
- Displays the history help message.
- Prints "Interactive startup complete."

### 5.6. Workers

The `worker.eagle` and `shellWorker.eagle` scripts are evaluated on thread
pool threads, not on the main interpreter thread. They are guarded by the
`NoWorkerThread` flag.

- **`worker.eagle`** — Waits for the `::tcl_interactive` variable to be set
  (indicating the interactive loop has started), then emits "'Hello World' from
  the thread pool." in interactive mode.

- **`shellWorker.eagle`** — Emits a diagnostic message identifying the
  current thread ID. Runs only on non-main threads.

**Guidance for agents:** The worker scripts are demonstration and diagnostic
tools. They do not provide functionality that agents need to interact with
directly. They are relevant only for understanding the threading model of the
Eagle shell.

## 6. Configuration

### 6.1. The `::no(...)` Flag Array

The `::no(...)` array is the primary mechanism for controlling optional
behavior throughout the startup chain and test infrastructure. Each flag is a
key in the array; its presence (regardless of value) disables the
corresponding behavior.

| Flag | Effect |
|---|---|
| `NoStartupRunCommands` | Skip sourcing `tclshrc.tcl` in stage 1. |
| `NoLicensingPackage` | Skip loading the Harpy licensing package in stage 1. |
| `NoLicensing` | Skip installing the Harpy `[package unknown]` hook in stage 1. |
| `NoLoadOnStartupPublicAutoPath` | Skip adding `LoadOnStartup/Public` to the auto-path. |
| `NoWorkerThread` | Prevent worker scripts from executing on thread pool threads. |
| `NoAutoRecord` | Disable automatic recording of interactively entered commands. |
| `NoPromptCommandCount` | Disable command count display in the prompt. |
| `NoPromptActiveLoops` | Disable active loop count display in the prompt. |
| `NoTclPrompt1` | Disable the custom Eagle shell prompt. |
| `NoShellUnknown` | Disable seamless Eagle-to-operating-system shell integration. |
| `NoAddCommandToTextFile` | Skip writing command history to `cmds-*.eagle` text files. |
| `NoRecordPerTestStatistics` | Disable per-test resource leak checking. |
| `NoHookTestLogForWatchCat` | Skip WatchCat integration in the test prologue. |
| `NoForceTraceStack` | Skip enabling managed call stack traces in complaints. |
| `NoStringBuilderCache` | Skip enabling the StringBuilder cache. |

Each flag can also be set as an environment variable with the same name.

### 6.2. Environment Variables

| Variable | Purpose |
|---|---|
| `XDG_STARTUP_HOME` | The root path of this repository checkout. Required for startup chain activation. |
| `EAGLE` | The root path of the Eagle source tree. Required by test runners and licensing commands. |
| `SCRATCH_ROOT` | The root path of the scratch/working directory. Required by Harpy/Zeus configuration commands. |
| `EAGLE_USER_CMDS_DIR` / `XDG_STATE_HOME` | The directory where command history files (`cmds-*.eagle`, `cmds.db`) are stored. |
| `KEYS_DIR` | The directory containing secret files. Required by the secrets package. |
| `NETCFG_API_KEY` | The API key used by the `#netcfg` interactive command. |
| `KAPOK_SETUP_PORT` / `localNetCfgBaseUri` | Configuration for local network variable endpoints. |
| `TRIAL_CERTIFICATES` | The directory containing trial license certificate files. |
| `XDG_WATCHCAT_HOME` | Override path for the WatchCat library. |
| `BATCH_ID` | The batch identifier used by `watchCron.eagle` for remote logging. |

### 6.3. Settings Files

#### 6.3.1. `Settings/startup-settings-files.eagle`

Defines the four startup phases, their directories, and the ordered file lists
within each phase (see section 5.4). This file is sourced by
`startup-lister.eagle` and uses `upvar` to set the `phases`,
`fileNamesOnly(...)`, and `directories(...)` variables in the caller's scope.

#### 6.3.2. `Settings/startup-settings.eagle`

Applies runtime configuration settings during the final phase of startup:

- Disables the keep-alive thread (`::no(keepAliveThreadStart)`).
- Disables the run-update-and-exit prompt (`::no(runUpdateAndExit)`).
- Disables writing command history to text files
  (`::no(NoAddCommandToTextFile)`).
- Configures maximum command history length for add and search operations (300
  characters each).
- Enables automatic saving of command history files.
- Sets the `::eagle_debugger(startup)` indicator variable, marking startup as
  complete.

#### 6.3.3. `LoadOnStartup/Public/Settings/secrets-patterns.eagle`

Defines regular expression patterns used by the secrets package to extract
passwords and credentials from files in the `KEYS_DIR` directory. The patterns
match lines containing `password:`, `pass:`, and `fossil pass:` prefixes.

## 7. Packages

The repository provides eight Eagle packages, registered via the package index
file `LoadOnStartup/Public/pkgIndex_9e27cfa54b4b427e.eagle`. All packages use
version `1.0`.

### 7.1. `Eagle.History` — Command History

**Source:** `LoadOnStartup/Public/history.eagle`

Provides an interactive command history system with search, staging, and
database-backed storage. Command history is stored in rotating
`cmds-*.eagle` text files or a SQLite database file (`cmds.db`).

**Interactive commands:**

| Command | Purpose |
|---|---|
| `#!` | Find and stage the latest command matching any of the given search terms. |
| `#!!` | Find and stage the latest command matching all of the given search terms. |
| `#@` | Evaluate the currently staged command. |
| `#@@` | Clear the currently staged command. |
| `##!` | Find and return all matching commands. |
| `##0` | Import commands from text files into the SQLite database. |

**Example:**

```tcl
#! eval expr            ;# Stage the last command containing "eval" or "expr".
#@                      ;# Execute the staged command.
##! set                 ;# List all historical commands containing "set".
##0                     ;# Import text-file history into the database.
```

### 7.2. `Eagle.Secrets` — Secrets Management

**Source:** `LoadOnStartup/Public/secrets.eagle`

**Namespace:** `::Secrets`

Provides interactive secret search and clipboard copy utilities. Searches the
directory specified by the `KEYS_DIR` environment variable for files matching
a user-provided pattern, then extracts passwords from matching files using the
patterns defined in `Settings/secrets-patterns.eagle`.

**Key procedures:**

| Procedure | Description |
|---|---|
| `promptForAndCopySecret` | Prompts the user for a file name pattern, searches for matching secrets, copies the result to the clipboard, and clears the clipboard after a configurable timeout (default: 30 seconds). |
| `findAndCopySecret` | Programmatic variant — searches without prompting. |
| `copySecretToClipboard` | Copies a secret value to the Windows clipboard. |
| `removeSecretFromClipboard` | Clears the clipboard contents. |

**Dependencies:** Requires the HotKey plugin and WinForms (`System.Windows.Forms`).

**Example:**

```tcl
set ::env(KEYS_DIR) "/path/to/secrets"
::Secrets::promptForAndCopySecret
```

### 7.3. `Eagle.Sms` — Twilio SMS Integration

**Source:** `LoadOnStartup/Public/sms.eagle`

**Namespace:** `::Eagle`

Provides SMS message sending via the Twilio REST API.

**Procedures:**

| Procedure | Description |
|---|---|
| `isValidShortMessage msg ?type?` | Validates message content and length (1-160 characters). The `type` parameter controls the permitted character set: `limited` (alphanumeric and space), `typical` (adds `-` and `:`), `full` (adds all GSM printable characters). |
| `sendViaShortMessageService sid token from to msg` | Sends an SMS message using `curl` and the Twilio REST API. Validates the account SID, auth token, and phone number formats before sending. |

**Example:**

```tcl
package require Eagle.Sms

if {[isValidShortMessage "Build 42 passed."]} then {
    sendViaShortMessageService \
        ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \
        YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY \
        +15551234567 +15557654321 \
        "Build 42 passed."
}
```

### 7.4. `Eagle.Chat` — Fossil Chat Polling

**Source:** `LoadOnStartup/Public/chat.eagle`

**Namespace:** `::Eagle`

Provides integration with Fossil-SCM chat endpoints. Configures the HotKey
plugin, secrets package, and downloader package for polling Fossil chat
servers.

**Key procedures:**

| Procedure | Description |
|---|---|
| `setupForChat force` | Initializes all dependencies (WinForms, Package Client Toolset, HotKey plugin, secrets package) and configures the chat polling environment. |
| `getDateTimeFormatForChat` | Returns the date-time format string used for chat message timestamps. |

**Dependencies:** Requires the HotKey plugin, WinForms, and the Package Client
Toolset.

### 7.5. `Eagle.Licensing` — Enterprise Licensing

**Source:** `LoadOnStartup/Public/licensing.eagle`

**Namespace:** `::Licensing`

Provides the Harpy Enterprise Edition licensing package. This package manages
dynamic license certificate resolution via a `[package unknown]` handler. When
a package is requested that requires a license certificate, this handler
searches for and installs the appropriate certificate.

**Key procedures:**

| Procedure | Description |
|---|---|
| `getPrimaryPackageNames ?basicOnly?` | Returns the list of primary Harpy package names (Security.Core, Licensing.Core, etc.). |
| `getAllPackageNames ?includePrimary?` | Returns the full list of package names that this module can handle. |
| `installPackageUnknown interpreter` | Installs the `[package unknown]` handler for dynamic license certificate resolution. |
| `personalLicenses` | Enables or disables personal license certificates. |
| `developmentLicenses` | Enables or disables development license certificates. |
| `encryptedDevelopmentLicenses` | Enables or disables encrypted development license certificates. |
| `trialLicenses` | Enables or disables trial license certificates. |
| `legacyLicenses` | Enables or disables legacy license certificate environment variables. |

### 7.6. `Eagle.Execute.Pipes` — Execute with Pipes

**Source:** `LoadOnStartup/Public/execPipes.eagle`

**Namespace:** `::Eagle`

Provides enhanced process execution support with pipe-based I/O redirection.
Extends the built-in `exec` command with support for sub-command construction,
tagged options, and piped command chains.

### 7.7. `Eagle.Mathematica` — Wolfram Mathematica Bridge

**Source:** `LoadOnStartup/Public/mathematica.eagle`

**Namespace:** `::Eagle`

Provides a bridge to Wolfram Mathematica via the NETLink managed assembly.
On Windows, automatically discovers the Mathematica installation via the
Windows registry.

**Key procedures:**

| Procedure | Description |
|---|---|
| `mathematica expr` | Evaluates a Mathematica expression and returns the result. Creates a MathKernel link, evaluates the expression, and returns the output form. |

**Example:**

```tcl
package require Eagle.Mathematica
set result [mathematica "Integrate[x^2, x]"]
```

**Platform note:** On Windows, the procedure locates the `Wolfram.NETLink.dll`
assembly via the Windows registry. On other platforms, it attempts to load the
`Wolfram.NETLink` assembly by name.

### 7.8. `Zeus.Update` — Zeus Update Hook

**Source:** `LoadOnStartup/Public/checkUpdateZeusHook.eagle`

**Namespace:** `::Eagle`

Provides integration testing support for encrypted updates via the Zeus
plugin. The package hooks the `getUpdateScriptData` procedure from the core
script library to transparently decrypt update scripts before evaluation.

**Key procedures:**

| Procedure | Description |
|---|---|
| `setupEncryptionPasswordAndSalt setup` | Initializes or cleans up encryption password and salt global variables. |
| `setupEncryptionParameters setup` | Initializes or cleans up encoding, iteration count, and hash algorithm global variables. |
| `hookGetUpdateScriptData` | Hooks the `getUpdateScriptData` procedure to add transparent decryption. |
| `unhookGetUpdateScriptData` | Unhooks the procedure, restoring the original behavior. |
| `enableZeusUpdateHook ?enable?` | High-level toggle. With a boolean argument, enables or disables the hook. Without an argument, returns the current hook status. |
| `cleanupZeusUpdateHook` | Removes all procedures added by this package. |

**Dependencies:** Requires the `Zeus.Enterprise` and `Zeus.Cryptography`
packages.

## 8. Interactive Extension Commands

### 8.1. Overview

The interactive extension commands are procedures defined in the global
namespace with names beginning with `#`. They are designed for use in the
Eagle interactive shell (REPL). These commands are loaded during the `public`
phase of the startup chain via `intExtCmds.eagle` and
`intExtCmds_licensing.eagle`.

### 8.2. General Commands

| Command | Description |
|---|---|
| `#morecmds enable ?all? ?interp?` | Adds or removes extra (e.g., test-only) script commands from the interpreter. |
| `#env ?enable? ?includeExisting?` | Shows or sets environment variables. Without arguments, displays the current environment. |
| `#zeus ?enable?` | Toggles the Zeus update hook (see section 7.8). |
| `#histset enable ?lock?` | Enables or disables command history recording. |
| `#cfgharpy` | Enters the Harpy interactive configuration loop. Requires the `SCRATCH_ROOT` environment variable. |
| `#unlockvar varName` | Unlocks a locked variable. |
| `#kthreads` | Disposes all live `Thread` objects. |
| `#showd` | Displays the current directory stack. |
| `#pushd ?directory?` | Pushes the current directory onto the stack and changes to the specified directory. |
| `#popd` | Pops a directory from the stack and changes to it. |
| `#news` | Displays a summary of the Eagle ChangeLog. |
| `#netcfg enable ?apiKey?` | Links or unlinks the remote network variable endpoint. Requires the `NETCFG_API_KEY` environment variable. |
| `#localnetcfg enable` | Links or unlinks the local network variable endpoint. |

### 8.3. Licensing Commands

| Command | Description |
|---|---|
| `#usedevcerts enable ?quiet?` | Enables or disables development license certificates from the `EAGLE` directory. |
| `#usetrialcerts enable ?quiet?` | Enables or disables trial license certificates from the `TRIAL_CERTIFICATES` directory. |
| `#useenccerts enable ?quiet?` | Enables or disables encrypted development license certificates from the `EAGLE` directory. |
| `#usemycerts enable ?quiet?` | Enables or disables personal license certificates from the `XDG_STARTUP_HOME` directory. |
| `#legacycerts enable ?quiet?` | Enables or disables legacy certificate environment variables. |

### 8.4. History Commands

The history commands are documented in section 7.1.

### 8.5. Examples

```tcl
#env                              ;# Display all environment variables.
#env true                         ;# Enable environment variable display.

#pushd ~/projects/eagle           ;# Push current directory and change.
#showd                            ;# Show the directory stack.
#popd                             ;# Pop and return to the previous directory.

#zeus true                        ;# Enable the Zeus update hook.
#zeus false                       ;# Disable the Zeus update hook.

#usedevcerts true                 ;# Enable development license certificates.
#usedevcerts false                ;# Disable development license certificates.

#morecmds true                    ;# Add extra test commands.
#morecmds true true               ;# Add all test commands.
#morecmds false                   ;# Remove extra test commands.
```

## 9. Test Infrastructure

### 9.1. Test Prologue (`testPrologue.eagle`)

The test prologue is evaluated at the beginning of a test suite run. It is
specific to the author's development environment (machine name
`LACHRYMOSE`). It performs the following configuration:

1. **Clears cached process-owner information** from the
   `::eagle_debugger` array.
2. **Disables command history** during test runs to avoid interference.
3. **Configures native Tcl shell verbosity** (level 3 for development
   builds, level 0 for official release builds).
4. **Sets the test timeout** to 20,000 milliseconds.
5. **Disables expensive operations** during tests: process queries,
   temporary file queries, per-test leak checking, TLS 1.3 host file, and
   process owner lookups.
6. **Marks remote server endpoints as unavailable** (time server, library
   server, certificate request server, certificate provision server).
7. **Disables the custom shell prompt** and shell unknown integration
   during tests.
8. **Adds runtime options** for extra test result logging, fail-fast
   behavior for exec stress tests, and data capture.
9. **Enables managed call stack traces** in the complaint subsystem.
10. **Hooks test log file operations** for WatchCat integration.

**Guidance for agents:** The test prologue contains machine-specific
configuration. Agents should not evaluate this script directly. It is
documented here to provide context for understanding the test infrastructure.

### 9.2. Test Epilogue (`testEpilogue.eagle`)

The test epilogue is evaluated at the end of a test suite run. It inspects the
complaint subsystem for any internal errors recorded during the run. If
complaints exist, it dumps them to a `.complaints` file and optionally logs
them to the remote logging server.

### 9.3. Badge Test Script (`Scripts/Public/badgeTest.eagle`)

The badge test script is a comprehensive test runner for the Eagle Enterprise
Edition plugin suite. It supports the following test suites:

| Suite | Description |
|---|---|
| Harpy | Script certificate and security policy tests. |
| Badge | Badge plugin tests. |
| Kapok | Kapok server tests. |
| Zeus | Zeus update management tests. |
| Demo | Demonstration and example tests. |
| HotKey | HotKey plugin tests. |
| AlphaCipher | AlphaCipher encryption tests. |
| KeyPair | KeyPair management tests. |
| Featherlight | Featherlight environment tests. |
| Version | Plugin version information display. |

The script is invoked via the `runBadgeTestScript` helper procedure from
`helpers.eagle`, which requires the `XDG_STARTUP_HOME` environment variable.

**Example:**

```tcl
runBadgeTestScript false false    ;# Run all badge tests (no IIS, not local).
runBadgeTestScript true true      ;# Run all badge tests (IIS, local).
```

### 9.4. WatchCat Tool (`Scripts/Public/WatchCat/watchCat.tool.eagle`)

The WatchCat tool is a log file monitoring utility that watches a test suite
log file and kills the test process if it appears to be hung. It is designed
to run as an external monitor process alongside a test suite run.

**Usage:**

```
EagleShell.exe watchCat.tool.eagle <logFileName> <pid>
```

**Behavior:**

1. Monitors the specified log file for changes.
2. If the file has not been modified for longer than the configured limit
   (default: 1 hour, or 8 hours on the author's development machines), the
   tool considers the target process to be hung.
3. Logs the hung state to both the local log file and the remote logging
   server.
4. Forcibly kills the target process.
5. Periodically pings the remote logging server with status updates.
6. After the target process exits, verifies that the log file is complete
   (contains an "OVERALL RESULT:" line and remote logging confirmation).

**Configurable variables:**

| Variable | Default | Description |
|---|---|---|
| `limit` | 3600 (seconds) | The duration after which a process is considered hung. |
| `ping` | 1200 (seconds) | The interval between remote server status pings. |
| `aggressive` | false | When true, ensures the target process is killed at exit. |
| `verbose` | false | When true, enables detailed tracing output. |
| `quiet` | true | When true, suppresses non-error output. |

### 9.5. WatchCron (`Scripts/Public/WatchCat/watchCron.eagle`)

The WatchCron tool analyzes a batch test run log file and reports aggregate
results to the remote logging server. It counts the number of test runs by
outcome (SUCCESS, FAILURE, STOP-ON-FAILURE, STOP-ON-LEAK, NONE, UNKNOWN),
extracts unique test run identifiers, and logs the totals remotely.

**Usage:**

```
EagleShell.exe watchCron.eagle <logFileName>
```

### 9.6. Release Testing Helper

**Source:** `LoadOnStartup/Public/releaseTestingHelper.eagle`

Provides the `setupForReleaseTesting` procedure, which configures the
command-line argument list for official release testing. It:

- Loads the Eagle test package.
- Optionally excludes specific test files.
- Excludes performance tests for non-default builds.
- Excludes extremely time-consuming tests during official stable releases.

## 10. Harpy Security Artifacts

### 10.1. Script Certificate Files (`.harpy`)

Every script file in the repository has a corresponding `.harpy` file
containing a Harpy script certificate. The `.harpy` files are XML documents
conforming to the `https://eagle.to/2011/harpy` XML namespace. Each
certificate contains:

| Field | Description |
|---|---|
| `Protocol` | The certificate protocol (typically `None`). |
| `Vendor` | The certificate vendor (`Mistachkin Systems`). |
| `Id` | A unique GUID identifier for the certificate. |
| `HashAlgorithm` | The hash algorithm used (typically `SHA512`). |
| `EntityType` | The entity type (`Script`). |
| `TimeStamp` | The UTC timestamp when the certificate was generated. |
| `Duration` | The certificate validity duration (typically `-1.00:00:00`, meaning no expiration). |

**Guidance for agents:** The `.harpy` files are consumed by the Harpy security
subsystem for script authenticity verification. They are not directly relevant
to agents unless the agent is operating within an Eagle interpreter where
Harpy script certificate enforcement is enabled. Agents should never modify
`.harpy` files — doing so will invalidate the certificate and may prevent the
associated script from executing.

### 10.2. Script Signature Files (`.b64sig`)

The `Configurations/InteractiveLoop/interactive_loop.eagle.b64sig` file is a
base64-encoded script signature. This is an alternative signature format used
by the Harpy security subsystem. The same guidance as for `.harpy` files
applies: do not modify.

### 10.3. Key Ring Files

**Source:** `KeyRings/Personal/keyRing.personal.eagle`

The key ring file contains the bytes of the `MistachkinPublic.snk` strong name
key (public key only). It also contains metadata (kind, ID, name, group,
description) and usage flags (`IDSZGE`). This key is used to sign key rings
and scripts.

**Guidance for agents:** Key ring files are consumed by the Harpy security
subsystem. They establish the cryptographic trust root for script certificate
verification. Agents should not modify key ring files.

### 10.4. Configuration Files

**Source:** `Configurations/InteractiveLoop/interactive_loop.eagle`

A signed script that enters the Eagle interactive loop with configuration
commands available. The script calls `requireVersion 0.0.0.0` (accepting any
version) and then `interactiveLoop`. This file is used when the interpreter
needs to enter interactive mode from a controlled configuration entry point.

## 11. Ruleset Files

The `ruleSets/` directory contains 37 ruleset definition files (`.ruleSet`)
with corresponding Harpy script certificates (`.ruleSet.harpy`). A
comprehensive agent specification for these files is available at
`ruleSets/AGENTS.md`.

The ruleset files control which script commands are available within the script
evaluation interpreter when a ruleset is applied. They are used with the Kapok
Server API (see the Kapok Server API agent specification at `api/AGENTS.md` in
the Thorium repository, if available) and can be composed via the
`includeRuleSet` directive.

**Key categories:**

| Category | Rulesets | Description |
|---|---|---|
| Foundation | `common`, `configuration` | Minimal baselines for the most restricted use cases. |
| Functional | `expr`, `string`, `list`, `variable`, `control`, `safeControl`, `unsafeControl`, `proc`, `procCaller`, `procManager`, `namespace`, `io`, `event`, `introspection` | Script commands grouped by functional domain. |
| Security-Sensitive | `fileSystem`, `network`, `critical`, `unsafe`, `meta` | Script commands that access system resources or bypass security boundaries. |
| Domain-Specific | `entity`, `licenseSdk`, `securitySdk`, `loader0`, `loader1` | Tailored for specific applications or SDK integrations. |
| Tcl Compatibility | `tcl84`, `tcl85`, `tcl86`, `missing` | Mirror the script command sets of specific Tcl versions. |
| Comprehensive | `full` | Every script command available in a standard Eagle interpreter. |
| Instructional | `example`, `test1`–`test5` | Demonstrate ruleset features and composition patterns. |

For detailed information about individual rulesets, their script commands,
security characteristics, and composability, consult `ruleSets/AGENTS.md`.

## 12. Coding Conventions

### 12.1. Script Structure

All Eagle scripts in the repository follow a consistent structure:

1. **Copyright header** — A multi-line comment block containing the file
   name, project name, copyright notice, and RCS identifier.

2. **Namespace declaration** — Scripts evaluated in the global namespace
   use `namespace eval :: { ... }`. Scripts providing packages use their own
   namespace (e.g., `namespace eval ::Eagle { ... }`).

3. **Procedure definitions** — Procedures include `# <help>` comment
   blocks that are extractable by the Eagle help subsystem.

4. **Package provision** — Package scripts end with a `package provide`
   statement that uses the Eagle engine patch level as the version number
   when running in Eagle, or `"1.0"` when running in Tcl.

### 12.2. Cross-Platform Compatibility

Scripts are designed to be compatible with:

- Windows, macOS, and Linux.
- .NET Framework, Mono, and .NET (Core).
- Multiple Eagle beta releases (backward compatibility shims in
  `backcompat.eagle` support versions as far back as beta 28).

### 12.3. Flag Convention

The `::no(...)` and `::env(...)` flag convention is used throughout:

```tcl
if {![info exists ::no(SomeFlag)] && \
    ![info exists ::env(SomeFlag)]} then {
    # ... code that runs unless the flag is set ...
}
```

This pattern allows behavior to be disabled either programmatically (via the
`::no(...)` array) or externally (via an environment variable).

### 12.4. The `apply` Pattern

Most scripts wrap their top-level logic in an `apply` block to avoid
polluting the global namespace with temporary variables:

```tcl
apply [list [list] {
    # ... script logic here ...
}]
```

This creates an anonymous procedure that is immediately invoked and then
discarded, confining any local variables to the block's scope.

### 12.5. The `appendArgs` Idiom

String concatenation uses the `appendArgs` procedure rather than Tcl string
interpolation. This is an Eagle convention that avoids issues with the
Eagle interpreter's handling of string interpolation:

```tcl
host result Ok [appendArgs "File: " $fileName " loaded.\n"]
```

## 13. Common Tasks for Agents

### 13.1. Activating the Startup Chain

```tcl
set ::env(XDG_STARTUP_HOME) /path/to/extra
source /path/to/extra/startup.eagle
```

### 13.2. Loading a Specific Package

```tcl
package require Eagle.Sms
package require Eagle.Licensing
package require Zeus.Update
```

### 13.3. Using Interactive Commands Programmatically

Interactive commands can be called from scripts by escaping the `#` with a
backslash:

```tcl
\#env true                        ;# Enable environment display.
\#pushd /tmp                      ;# Push directory.
\#usedevcerts true                ;# Enable dev certificates.
```

### 13.4. Running the Badge Test Suite

```tcl
set ::env(XDG_STARTUP_HOME) /path/to/extra
set ::env(EAGLE) /path/to/eagle
runBadgeTestScript false false
```

### 13.5. Sending an SMS Notification

```tcl
package require Eagle.Sms

if {[isValidShortMessage "Deploy complete" typical]} then {
    sendViaShortMessageService \
        ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \
        YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY \
        +15551234567 +15557654321 \
        "Deploy complete"
}
```

### 13.6. Searching for Secrets

```tcl
set ::env(KEYS_DIR) /path/to/secrets
::Secrets::promptForAndCopySecret
```

### 13.7. Enabling the Zeus Update Hook

```tcl
package require Zeus.Update
enableZeusUpdateHook true
```

### 13.8. Evaluating a Mathematica Expression

```tcl
package require Eagle.Mathematica
set result [mathematica "Series[Exp[x], {x, 0, 5}]"]
```

### 13.9. Skipping Optional Startup Features

```tcl
set ::no(NoLicensing) 1           ;# Skip Harpy licensing hook.
set ::no(NoWorkerThread) 1        ;# Skip background workers.
set ::no(NoShellUnknown) 1        ;# Skip OS shell integration.
source /path/to/extra/startup.eagle
```

## 14. Dependencies and Requirements

### 14.1. Eagle Interpreter

The startup chain requires Eagle beta 46 or later. Individual compatibility
shims support versions as far back as beta 28, but the full startup chain is
designed for beta 46+.

### 14.2. Optional Dependencies

| Dependency | Required By | Purpose |
|---|---|---|
| Harpy plugin | `licensing.eagle`, `intExtCmds_licensing.eagle` | Script certificate enforcement and license management. |
| Badge plugin | `badgeTest.eagle` | Plugin test suite execution. |
| Zeus plugin | `checkUpdateZeusHook.eagle` | Encrypted update management. |
| HotKey plugin | `secrets.eagle`, `chat.eagle` | Interactive secret prompting and chat alerts. |
| WinForms (`System.Windows.Forms`) | `secrets.eagle`, `chat.eagle` | Clipboard access. |
| SQLite | `history.eagle` | Database-backed command history. |
| Wolfram Mathematica + NETLink | `mathematica.eagle` | Mathematica expression evaluation. |
| `curl` | `sms.eagle` | HTTP requests to the Twilio REST API. |
| Package Client Toolset | `chat.eagle` | Fossil repository login. |

### 14.3. Platform-Specific Notes

- **Secrets and Chat packages:** Require Windows with WinForms support.
  They will not function on Mono or .NET Core without WinForms availability.
- **Mathematica package:** Requires a Wolfram Mathematica installation.
  On Windows, the installation is discovered via the Windows registry.
- **WatchCat tool:** Requires an external `kill` tool (provided by the
  operating system) for process termination.

## 15. Versioning

This document describes the `extra` repository as it exists at the time of
writing. The repository at `https://github.com/mistachkin/extra` is the
authoritative source for the current state of all files. In the event of any
discrepancy between this document and the repository contents, the repository
takes precedence.

The repository does not use semantic versioning. Changes are tracked via Git
commits. Agents should clone or fetch the latest revision to ensure they are
working with the current state of the repository.
