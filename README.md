# Add-ons for the Eagle Scripting Language

This repository contains **startup scripts, integration packages, and interactive tools** for the [Eagle](https://urn.to/r/eagle) scripting language.

Originally, the contents of this repository were primarily designed for my personal use.

They provide optional convenience commands, hooks, and integrations with **Harpy**, **Zeus**, **Badge**, **Twilio SMS**, **Fossil-SCM chat**, etc.

---

## Table of Contents

* [Repository layout](#repository-layout)
* [Quick start](#quick-start)
* [Startup chain overview](#startup-chain-overview)
* [Configuration flags](#configuration-flags)
* [Directory phases](#directory-phases-from-settingsstartup-settings-fileseagle)
* [Root scripts](#root-scripts)
* [Configurations scripts](#configurations-scripts)
* [KeyRing scripts](#keyring-scripts)
* [LoadOnStartup/Public scripts](#loadonstartuppublic-scripts)
* [LoadOnStartup/Private (site-specific)](#loadonstartupprivate-site-specific)
* [RuleSet files](#ruleset-files)
* [Settings](#settings)
* [Scripts/Public/badgeTest.eagle](#scriptspublicbadgetesteagle)
* [checkUpdateZeusHook.eagle](#checkupdatezeushookeagle)
* [Environment variables](#environment-variables)
* [Examples](#examples)
* [Script certificates](#script-certificates)
* [License](#license)
* [Contributing](#contributing)
* [Credits](#credits)

---

## Repository layout

```
Certificates/
  Script/
    Plugin1.0/

Configurations/
  InteractiveLoop/

KeyRings/
  Personal/

LoadOnStartup/
  Public/
    Settings/

Scripts/
  Public/

Settings/

shellWorker.eagle
startup.eagle
startup-compat.eagle
startup-lister.eagle
tclshrc.tcl
testPrologue.eagle
worker.eagle

*.harpy (script certificates)
```

---

## Quick start

```
Set the environment variable XDG_STARTUP_HOME to the path of this checkout.
```

Upon startup of an Eagle interpreter, that will trigger loading of the chain-of-scripts described below.

---

## Startup chain overview

| Stage | Script                              | Function                                                                                         |
| ----- | ----------------------------------- | ------------------------------------------------------------------------------------------------ |
| 1     | `startup.eagle`                     | Core library entry point; optionally wires in Harpy licensing hooks, then sources `tclshrc.tcl`. |
| 2     | `tclshrc.tcl`                       | Loads and sources each startup file listed by `startup-lister.eagle`.                            |
| 3     | `startup-lister.eagle`              | Builds the ordered file list from `Settings/startup-settings-files.eagle`.                       |
| 4     | `startup-compat.eagle`              | Applies compatibility shims and prints “Interactive startup complete.”                           |
| 5     | `worker.eagle`, `shellWorker.eagle` | Background worker and shell worker initialization (optional).                                    |
| 6     | `testPrologue.eagle`                | Test-suite setup and WatchCat integration.                                                       |
| 7     | `testEpilogue.eagle`                | Test-suite cleanup and diagnostic reporting.                                                     |

---

## Configuration flags

All flags may be defined either in the `::no(...)` array or as environment variables before sourcing `startup.eagle`.

| Flag                                     | Description                                   |
| ---------------------------------------- | --------------------------------------------- |
| `NoStartupRunCommands`                   | Skip sourcing `tclshrc.tcl`.                  |
| `NoLicensingPackage` / `NoLicensing`     | Skip setting up Harpy licensing hook.         |
| `NoLoadOnStartupPublicAutoPath`          | Skip adding public packages to auto-path.     |
| `NoWorkerThread`                         | Disable threaded startup messages.            |
| `NETCFG_API_KEY`                         | API key used by `#netcfg`.                    |
| `SCRATCH_ROOT`                           | Required by `#zeus` and `#cfgharpy`.          |
| `KAPOK_SETUP_PORT`, `localNetCfgBaseUri` | Configure local network variable endpoints.   |
| Various `No...` test flags               | Control test suite verbosity and performance. |

---

## Directory phases (from `Settings/startup-settings-files.eagle`)

| Phase      | Directory               | Typical contents                                                                                                                                   |
| ---------- | ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `public`   | `LoadOnStartup/Public`  | `backcompat.eagle`, `helpers.eagle`, `history.eagle`, `intExtCmds.eagle`, `intExtCmds_licensing.eagle`, `secrets.eagle`, `sms.eagle`, `chat.eagle` |
| `watchCat` | `WatchCat`              | `watchCat.eagle`                                                                                                                                   |
| `private`  | `LoadOnStartup/Private` | `auth.eagle` (site-specific)                                                                                                                       |
| `settings` | `Settings`              | `startup-settings.eagle`                                                                                                                           |

---

## Root scripts

### `startup.eagle`

Core library entry point for newly created interpreters. Sets up environment flags, optionally installs the Harpy licensing hook, and sources `tclshrc.tcl`.

### `tclshrc.tcl`

Iterates through the startup list (quiet for batch runs, verbose for interactive), then sources `startup-compat.eagle`.

### `startup-lister.eagle`

Builds the ordered file list by consulting `Settings/startup-settings-files.eagle`.

### `startup-compat.eagle`

Adds version checks (`checkEagleBetaNN`) and prints “Interactive startup complete” for user feedback.

### `worker.eagle`

Background library worker, typically run on a thread-pool thread. For demonstration purposes.

### `shellWorker.eagle`

Background shell worker, typically run on a thread-pool thread. For demonstration purposes.

### `testPrologue.eagle`

Configures the Eagle test environment:

* Sets up timeouts, test verbosity, and platform-specific optimizations, etc.
* Defines multiple `::no(...)` toggles to accelerate testing.
* Integrates with WatchCat.

### `testEpilogue.eagle`

* Logs any internal errors (i.e. complaints) encountered by the test suite.

---

## Configurations scripts

Contains (various) signed Harpy configuration (script) files.

---

## KeyRing scripts

Contains (various) signed Harpy keyring (script) files.

---

## LoadOnStartup/Public scripts

### backcompat.eagle - compatibility shims

Adds cross-version helper procedures such as `checkEagleBetaNN`, `isWindows`, and minor defaults for recorder/prompt handling.

### helpers.eagle - generic helpers

Defines detection utilities and test-suite runners:

* `checkIsEagle`, `checkEaglePatchLevel`
* `runBadgeTestScript`, `runHarpyTestScript`
* `maybeCreateBackupPath`, `forceUseLatestTestPackage`

### history.eagle - command history

Adds miniature shell commands:

| Command | Purpose                                |
| ------- | -------------------------------------- |
| `#!`    | Stage last command matching any term.  |
| `#!!`   | Stage last command matching all terms. |
| `#@`    | Execute staged command.                |
| `#@@`   | Clear staged command.                  |
| `##!`   | Return all matches.                    |
| `##0`   | Import into history database.          |

Stores history in rotating `cmds-*.eagle` files or a SQLite database (`cmds.db`).

### intExtCmds.eagle - interactive extension commands

Adds numerous diagnostic and convenience commands:

| Command                           | Description                                   |
| --------------------------------- | --------------------------------------------- |
| `#morecmds enable ?all? ?interp?` | Add/remove test commands.                     |
| `#env ?enable? ?includeExisting?` | Show or set environment variables.            |
| `#zeus ?enable?`                  | Toggle Zeus update hook.                      |
| `#histset enable ?lock?`          | Enable/disable command history.               |
| `#cfgharpy`                       | Enter Harpy interactive configuration loop.   |
| `#unlockvar varName`              | Unlock a variable.                            |
| `#kthreads`                       | Dispose live `Thread` objects.                |
| `#showd`, `#pushd`, `#popd`       | Directory stack utilities.                    |
| `#news`                           | Show Eagle ChangeLog summary.                 |
| `#netcfg enable ?apiKey?`         | Link/unlink remote network variable endpoint. |
| `#localnetcfg enable`             | Link/unlink local network variable endpoint.  |

### secrets.eagle - search & clipboard utilities

Interactive secret finder and copier:

* Searches `KEYS_DIR` for matching patterns.
* Uses `HotKey` and WinForms clipboard.
* Patterns loaded from `settings/secrets-patterns.eagle`.

**Procedures:**
`promptForAndCopySecret`, `findAndCopySecret`, `copySecretFromData`, `copySecretToClipboard`, `removeSecretFromClipboard`.

### sms.eagle - Twilio SMS integration

Implements `package provide Eagle.Sms`.

| Command                                                     | Description                                 |
| ----------------------------------------------------------- | ------------------------------------------- |
| `isValidShortMessage msg ?type?`                            | Validates message content & length.         |
| `sendViaShortMessageService sid token from to msg`          | Sends SMS using `curl` and Twilio REST API. |

Requires Twilio credentials and network access.

### chat.eagle - Fossil chat setup

Provides `setupForChat` and `getDateTimeFormatForChat`; configures HotKey, Secrets, and Downloader packages for polling Fossil chat endpoints.

---

## LoadOnStartup/Private (site-specific)

* `auth.eagle` - authentication credentials.

(These are referenced but not part of this public repo.)

---

### RuleSet files

Various ruleset files that may be used to configure an interpreter.

---

## Settings

### `Settings/startup-settings-files.eagle`

Defines startup phases, directories, and file lists.

### `Settings/startup-settings.eagle`

Caps command history length, controls autosave, disables certain background threads, etc.

---

## Scripts/Public/badgeTest.eagle

Runs test suites for Harpy, Badge, Zeus, Kapok, etc.
Options are parsed from `::argv`; automatically initializes certificates and policies.

---

## checkUpdateZeusHook.eagle

Implements integration testing support for obfuscated updates via Zeus.

| Proc                                                          | Function                               |
| ------------------------------------------------------------- | -------------------------------------- |
| `setupEncryptionPasswordAndSalt`, `setupEncryptionParameters` | Initialize encryption globals.         |
| `hookGetUpdateScriptData`, `unhookGetUpdateScriptData`        | Wrap core function to decrypt updates. |
| `enableZeusUpdateHook ?enable?`                               | High-level toggle (returns status).    |
| `cleanupZeusUpdateHook`                                       | Remove all hook procedures.            |

Requires `Zeus.Enterprise` and `Zeus.Cryptography`.

---

## Environment variables

| Variable                                 | Purpose                                        |
| ---------------------------------------- | ---------------------------------------------- |
| `EAGLE_USER_CMDS_DIR` / `XDG_STATE_HOME` | Where `cmds-*.eagle` and `cmds.db` are stored. |
| `KEYS_DIR`                               | Directory containing secret files.             |
| `XDG_STARTUP_HOME`, `EAGLE`              | Used by Badge/Harpy test runners.              |
| `SCRATCH_ROOT`                           | Required for Harpy/Zeus configuration.         |
| `NETCFG_API_KEY`                         | API key for `#netcfg`.                         |

---

## Examples

### Basic startup

```tcl
source ./extra/startup.eagle
```

### Using helper commands

```tcl
# Show and enable env vars
#env
#env true

# Push and pop directories
#pushd ~/projects/eagle
#showd
#popd

# Run Zeus update hook
#zeus true
```

### Sending an SMS

```tcl
package require Eagle.Sms
if {[isValidShortMessage "Build complete"]} {
  sendViaShortMessageService \
      ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \
      YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY \
      +15551234567 +15557654321 \
      "Build complete"
}
```

### Searching secrets

```tcl
set ::env(KEYS_DIR) "C:/keys"
::Secrets::promptForAndCopySecret
```

---

## Script certificates

All scripts include an associated `.harpy` file - which contains a certificate that allows the associated script to be verified by the Harpy script policy subsystem.
These are not required (for normal operation) unless the Harpy plugin is loaded and its script certificate enforcement policy is enabled.

---

## License

All files carry the Tcl-style license as described in the Eagle `license.terms` file.

---

## Contributing

Contributions should follow the Eagle project conventions:

* Preserve existing indentation and conditional compilation style.
* Preserve cross-platform compatibility (Windows, macOS, Linux).
* Preserve cross-runtime compatibility (.NET Framework, Mono, .NET).
* Preserve backward compatibility with (relatively recent) Eagle releases.

---

## Credits

Copyright © 2007–2025 **Joe Mistachkin**.  All rights reserved.