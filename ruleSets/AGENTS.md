# Eagle Ruleset Files — Agent Specification

## 1. Purpose

This document is a formal specification of the Eagle ruleset definition files
available in the official `extra` repository at `https://urn.to/r/code` (under
the `extra/ruleSets/` directory). It is intended for autonomous agents, language
model tool-use implementations, and other programmatic clients that need to
understand, select, or compose rulesets for use with the Kapok Server API's
`ruleSetType` and `ruleSetFileName` request fields.

The authoritative API contract for the Kapok Server is defined in
`api/openapi.json` (OpenAPI 3.2.0). The corresponding agent specification is in
`api/AGENTS.md`. This document supplements those references with detailed
guidance on individual ruleset files, their security characteristics, and their
composability.

Each ruleset file defines a set of rules that control which script commands are
available within the script evaluation interpreter. When a ruleset is applied,
only the script commands explicitly permitted by its rules are available for use
by the evaluated script. All other script commands are denied by default.

## 2. File Format

### 2.1. Structure

Each `.ruleSet` file consists of a standard copyright header followed by one or
more `rule { ... }` blocks and optional `includeRuleSet` directives. Each rule
block contains the following fields:

| Field | Description |
|---|---|
| `id` | The optional numeric identifier for ordering and precedence. |
| `type` | The rule type: `Include` to permit, or `Exclude` to deny. |
| `kind` | The entity type the rule applies to (typically `Command`). |
| `mode` | The matching strategy: `{Include Exact}` for exact name match, `{Exclude Glob}` for glob-based exclusion, `{Hide Exact}` to include but hide, or `{Show Exact}` to include and show. |
| `patterns` | The script command name or glob pattern to match. |

### 2.2. Composition via `includeRuleSet`

The `includeRuleSet <name>` directive includes another ruleset by name (without
the `.ruleSet` file extension). This enables modular composition: a ruleset can
build upon one or more other rulesets without duplicating their rules.

### 2.3. Harpy Signature Files

Each `.ruleSet` file has a corresponding `.ruleSet.harpy` file that contains a
cryptographic signature for authenticity verification purposes. The `.harpy`
files are consumed by the Harpy security subsystem and are not directly relevant
to ruleset selection or composition.

## 3. Ruleset Inventory

The following sections describe each ruleset file, organized by functional
category. For each ruleset, the document provides:

- The script commands it permits.
- Its intended purpose.
- Its security implications.
- The types of scripts it is ideally suited for.

### 3.1. Foundation Rulesets

These rulesets provide minimal baselines for the most restricted use cases.

#### 3.1.1. `common.ruleSet`

**Script commands:** `nop`

The most restrictive ruleset available. It permits only the `nop` script
command, which does nothing and returns nothing. This script command is `'safe'`.

**Use cases:** Serves as a baseline for composition. A script evaluated under
this ruleset alone cannot perform any meaningful work. This ruleset is useful as
a starting point when building a custom ruleset via `includeRuleSet`, or for
testing that the ruleset enforcement mechanism itself is functioning correctly.

**Limitations:** A script evaluated under this ruleset cannot compute, store,
compare, or output anything.

#### 3.1.2. `configuration.ruleSet`

**Script commands:** `set`, `unset`

Permits only variable assignment and removal. This ruleset is designed for "pure
settings files" — scripts whose sole purpose is to define or clear configuration
variables.

**Use cases:** Loading configuration files that consist entirely of `set` and
`unset` statements. This is the appropriate ruleset when the script is a
declarative list of key-value assignments and nothing more.

**Limitations:** The script cannot perform any computation, conditional logic,
looping, string manipulation, or output. It can only set and unset variables.

### 3.2. Functional Rulesets

These rulesets group script commands by their functional domain. They are
designed to be composed together to build a tailored evaluation sandbox.

#### 3.2.1. `expr.ruleSet`

**Script commands:** `expr`, `fpclassify`

Permits mathematical expression evaluation and floating-point classification.

**Ideal scripts:** Pure computation — arithmetic, mathematical functions,
numeric comparisons. Compose with `variable.ruleSet` to store intermediate
results, or with `control.ruleSet` to use expressions in conditional logic.

#### 3.2.2. `string.ruleSet`

**Script commands:** `append`, `base64`, `concat`, `encoding`, `format`,
`hash`, `join`, `regexp`, `regsub`, `split`, `string`

Permits string manipulation, encoding conversion, regular expressions, hashing,
and base64 encoding/decoding.

**Ideal scripts:** Text processing, data transformation, format conversion,
template rendering. Compose with `list.ruleSet` for scripts that manipulate
both strings and lists, or with `variable.ruleSet` and `control.ruleSet` for
general-purpose text processing workflows.

#### 3.2.3. `list.ruleSet`

**Script commands:** `lappend`, `lassign`, `lget`, `lindex`, `linsert`, `list`,
`llength`, `lrange`, `lremove`, `lrepeat`, `lreplace`, `lreverse`, `lsearch`,
`lset`, `lsort`

Permits list construction, indexing, searching, sorting, and manipulation.

**Ideal scripts:** Data structure manipulation — building lists, extracting
elements, sorting datasets, filtering collections. Compose with `string.ruleSet`
for scripts that transform between string and list representations.

#### 3.2.4. `variable.ruleSet`

**Script commands:** `array`, `getf`, `global`, `incr`, `scope`, `set`, `setf`,
`unset`, `unsetf`, `upvar`, `vwait`, `variable`, `namespace`

Permits variable assignment, array manipulation, scoping, and namespace-scoped
variable access. Most script commands in this ruleset are `'safe'`; the exceptions
are `getf`, `setf`, and `unsetf`, which access script evaluation interpreter
flags.

**Ideal scripts:** Any script that needs to store intermediate state, work with
arrays or associative data, or manage variables across scopes. This is a
fundamental building block for nearly all non-trivial compositions.

**Potential problems:** The inclusion of `vwait` enables event-loop-based
waiting, which can cause a script to block indefinitely if no event arrives.
The `getf`/`setf`/`unsetf` script commands access interpreter flags and should
be treated as sensitive.

#### 3.2.5. `control.ruleSet`

**Script commands:** `apply`, `break`, `catch`, `continue`, `do`, `downlevel`,
`error`, `eval`, `exit`, `for`, `foreach`, `if`, `invoke`, `lmap`, `napply`,
`return`, `scope`, `source`, `subst`, `switch`, `throw`, `time`, `try`,
`uplevel`, `while`

Permits all script control flow: conditionals, loops, error handling, procedure
application, and dynamic evaluation.

**Ideal scripts:** Any script that requires conditional logic, iteration, or
error handling. This is the essential companion to the data-manipulation
rulesets (`expr`, `string`, `list`, `variable`).

**Potential problems:** The inclusion of `eval` and `uplevel` permits dynamic
script construction and execution, which can be used to circumvent the intent
of other restrictions if combined with string-building script commands. The
`source` command permits loading external script files, which may introduce
unreviewed code. The `exit` command can terminate the interpreter.

**Partitioning:** This ruleset is partitioned into `safeControl.ruleSet` (18
script commands, section 3.2.6) and `unsafeControl.ruleSet` (7 script commands,
section 3.2.7), which together illustrate the dual-use nature of ruleset files
(see section 4.4).

#### 3.2.6. `safeControl.ruleSet`

**Script commands:** `apply`, `break`, `catch`, `continue`, `do`, `error`,
`eval`, `for`, `foreach`, `if`, `lmap`, `napply`, `return`, `subst`, `switch`,
`throw`, `try`, `while`

The subset of `control.ruleSet` containing only the script commands that do not
change the active variable scope, modify non-local variable state, modify
interpreter state, or access external files or side-channels (e.g. timing
information). Together with `unsafeControl.ruleSet`, this forms a complete
partition of `control.ruleSet` (18 + 7 = 25 script commands).

**Ideal scripts:** Scripts that require conditional logic, iteration, error
handling, and dynamic evaluation but must not escape the current variable scope,
terminate the interpreter, load external files, or access timing information.
This is the preferred control-flow ruleset for sandboxed environments where
scope isolation is a requirement.

**Relationship to `control.ruleSet`:** This ruleset demonstrates the dual-use
nature of ruleset files (see section 4.4). While `control.ruleSet` groups
script commands by functional category (all control-flow script commands),
`safeControl.ruleSet` draws a security boundary within that same category —
permitting only the script commands that are `'safe'` within a scope-isolated
evaluation sandbox.

#### 3.2.7. `unsafeControl.ruleSet`

**Script commands:** `downlevel`, `exit`, `invoke`, `scope`, `source`, `time`,
`uplevel`

The complement of `safeControl.ruleSet` within `control.ruleSet`. These are the
control-flow script commands that can change the active variable scope
(`downlevel`, `invoke`, `scope`, `uplevel`), modify interpreter state (`exit`),
or access external files or side-channels (`source`, `time`).

**Ideal scripts:** Scripts that require scope traversal, external file loading,
timing measurement, or the ability to modify interpreter state. These
capabilities are necessary for certain administrative and infrastructure scripts
but are inappropriate for untrusted script evaluation.

**Potential problems:** The `exit` command can terminate the interpreter. The
`source` command can load external script files, which may introduce unreviewed
code. The `uplevel`, `downlevel`, and `invoke` commands can modify variables in
ancestor call frames, potentially bypassing scope-based security assumptions.
The `time` command exposes a timing side-channel.

#### 3.2.8. `proc.ruleSet`

**Script commands:** `apply`, `namespace`, `napply`, `nproc`, `proc`, `rename`

Permits procedure definition, anonymous procedure application, and command
renaming.

**Ideal scripts:** Scripts that define reusable procedures or need to organize
code into named routines. Compose with `control.ruleSet` for scripts that
define and call procedures with control flow.

**Partitioning:** This ruleset is partitioned into `procCaller.ruleSet` (2
script commands, section 3.2.9) and `procManager.ruleSet` (4 script commands,
section 3.2.10), which together illustrate the dual-use nature of ruleset files
(see section 4.4). This partition is valuable because defining procedures and
calling procedures represent fundamentally different levels of trust. A script
that only defines (or redefines) procedures is purely declarative — it is not
executing arbitrary script code, it is merely establishing procedure definitions
that may be called later. Conversely, a script that only calls procedures
consumes those definitions without the ability to create or modify them.

#### 3.2.9. `procCaller.ruleSet`

**Script commands:** `apply`, `napply`

The subset of `proc.ruleSet` containing only the script commands that call
procedures. These script commands apply anonymous procedures but cannot define,
rename, or otherwise modify the set of available procedures. Together with
`procManager.ruleSet`, this forms a complete partition of `proc.ruleSet`
(2 + 4 = 6 script commands).

**Ideal scripts:** Scripts that need to call pre-defined anonymous procedures
but should not be permitted to (re-)define procedures, rename script commands,
or manipulate namespaces. This is the preferred procedure-related ruleset for
environments where procedure definitions are managed externally and the
evaluated script is a consumer of those definitions.

**Relationship to `proc.ruleSet`:** This ruleset demonstrates the dual-use
nature of ruleset files (see section 4.4). While `proc.ruleSet` groups script
commands by functional category (all procedure-related script commands),
`procCaller.ruleSet` draws a role boundary within that same category —
permitting only the script commands that consume procedures without the ability
to create or modify them.

#### 3.2.10. `procManager.ruleSet`

**Script commands:** `namespace`, `nproc`, `proc`, `rename`

The complement of `procCaller.ruleSet` within `proc.ruleSet`. These are the
procedure-related script commands that (re-)define procedures (`nproc`, `proc`),
rename or delete script commands (`rename`), or manage namespaces (`namespace`).

**Ideal scripts:** Setup and initialization scripts that define procedures for
later use by other scripts, or administrative scripts that manage the set of
available procedures and their organization within namespaces. These capabilities
are appropriate for scripts that configure the interpreter prior to evaluating
untrusted consumer scripts.

**Potential problems:** The `rename` command can rename or delete any script
command, which can alter the effective script command set in ways that affect
subsequent evaluations. The `proc` and `nproc` commands can redefine existing
procedures, potentially changing their behavior.

#### 3.2.11. `namespace.ruleSet`

**Script commands:** `namespace`

Permits namespace creation and manipulation.

**Ideal scripts:** Scripts that organize script commands and variables into
namespaces. This is a single-command ruleset, typically composed with
`proc.ruleSet` and `variable.ruleSet`.

#### 3.2.12. `io.ruleSet`

**Script commands:** `close`, `eof`, `fblocked`, `fconfigure`, `fcopy`,
`flush`, `gets`, `puts`, `read`, `seek`, `tell`, `truncate`

Permits input/output operations on channels (files, network streams, console).

**Ideal scripts:** Scripts that read from or write to channels. This ruleset
permits I/O operations on channels that are already open, but does not include
`open` — opening new channels requires the `fileSystem.ruleSet` or
`full.ruleSet`.

**Potential problems:** The `truncate` command can destructively modify file
contents. The `fconfigure` command can change channel properties in ways that
affect other consumers of the same channel.

#### 3.2.13. `event.ruleSet`

**Script commands:** `after`, `bgerror`, `callback`, `update`, `vwait`

Permits event loop management: scheduling delayed script commands, handling
background errors, processing pending events, and waiting for variable changes.

**Ideal scripts:** Scripts that need timer-based execution, asynchronous
callbacks, or event-driven processing. Compose with `io.ruleSet` for scripts
that process asynchronous I/O events.

**Potential problems:** The `after` command can schedule deferred execution,
and `vwait` can cause a script to block indefinitely. These script commands
should be used with care in server-side evaluation contexts where execution time
is bounded.

#### 3.2.14. `introspection.ruleSet`

**Script commands:** `clock`, `info`, `pid`, `version`

Permits read-only inspection of the interpreter and system state: querying the
current time, examining script command and variable metadata, retrieving the
process ID, and checking the interpreter version.

**Ideal scripts:** Diagnostic scripts, version checks, capability detection.
This is a `'safe'`, read-only ruleset with no side effects.

### 3.3. Security-Sensitive Rulesets

These rulesets contain script commands that access system resources, bypass
security boundaries, or interact with the host environment. They should only be
composed into rulesets intended for trusted scripts or scripts evaluated under
API keys with administrator access.

#### 3.3.1. `fileSystem.ruleSet`

**Script commands:** `cd`, `file`, `glob`, `hash`, `load`, `open`, `pwd`,
`source`, `unload`

Permits interaction with the host file system: changing directories, querying
file metadata, loading native libraries, opening files, and sourcing external
scripts. All script commands in this ruleset are considered `'unsafe'`.

**Ideal scripts:** Maintenance scripts, file processing workflows, plugin
loading. This ruleset should only be used when the evaluated script is trusted
and the API key has appropriate access.

**Potential problems:** The `load` and `unload` commands can load and unload
native shared libraries, which can execute arbitrary native code. The `source`
command can load external script files, which may introduce unreviewed code.
The `cd` command changes the working directory globally.

#### 3.3.2. `network.ruleSet`

**Script commands:** `socket`, `source`, `uri`

Permits network access: opening network sockets, sourcing scripts from network
locations, and URI manipulation. All script commands in this ruleset are
considered `'unsafe'`.

**Ideal scripts:** Scripts that need to make network connections, fetch remote
resources, or interact with web services. This ruleset should only be used in
trusted contexts.

**Potential problems:** The `socket` command can open arbitrary network
connections. The `source` command, when given a URI, can load and execute
scripts from remote servers.

#### 3.3.3. `critical.ruleSet`

**Script commands:** `debug`, `file`, `host`, `library`, `load`, `object`,
`tcl`, `unload`

Contains the most security-sensitive script commands in the Eagle command set.
If any of these script commands are available, they can be used to bypass other
safety and security features of the interpreter.

**Ideal scripts:** None in a sandboxed context. This ruleset exists to
explicitly enumerate the script commands that should almost never be included in
a sandbox-facing ruleset. It may be useful for reference or for composing
explicitly permissive rulesets intended for fully trusted environments.

**Potential problems:** The `debug` command exposes interpreter internals. The
`object` command enables arbitrary managed code invocation. The `host` command
accesses the host application. The `tcl` command bridges to a native Tcl
interpreter. Any one of these can be used to bypass the evaluation sandbox.

#### 3.3.4. `unsafe.ruleSet`

**Script commands:** `debug`, `exec`, `host`, `interp`, `library`, `object`,
`sql`, `tcl`, `xml`

Contains script commands that are considered `'unsafe'` but excludes script commands
that have one or more `'safe'` script sub-commands (such as `clock`, `file`, `info`,
`interp`, `object`, `package`, `source`, and `uri`). Note that `interp` and
`object` appear in this ruleset because the top-level script commands themselves
are `'unsafe'`, even though certain script sub-commands may be `'safe'`.

**Ideal scripts:** Administrative scripts in fully trusted environments. This
ruleset is effectively the inverse of `'safe'` mode — it enumerates the script
commands that `'safe'` mode would deny.

**Potential problems:** The `exec` command can execute arbitrary external
processes. The `sql` command can execute arbitrary database queries. The `xml`
command can parse and manipulate XML with full access. All script commands in
this ruleset can be used to interact with or modify system state beyond the
evaluation sandbox.

#### 3.3.5. `meta.ruleSet`

**Script commands:** `debug`, `guid`, `host`, `interp`, `library`, `object`,
`package`, `sql`, `tcl`, `time`, `xml`

Permits script commands that manipulate the script environment, the managed
environment, or the native environment. This ruleset is a superset of
`unsafe.ruleSet` with the addition of `guid`, `package`, and `time`.

**Ideal scripts:** Infrastructure management scripts that need to inspect and
modify the interpreter environment, manage packages, interact with databases,
or invoke managed code.

### 3.4. Domain-Specific Rulesets

These rulesets are tailored for specific applications or SDK integrations.

#### 3.4.1. `entity.ruleSet`

**Script commands:** `Organization`, `Account`, `Category`, `Validation`,
`Notes`, `Id`, `ParentId`, `Name`, `Description`, `Number`, `Submitted`,
`Effective`, `Created`, `OrganizationId`, `AccountId`, `ParentOrganization`,
`ParentOrganizationId`, `ParentAccount`, `ParentAccountId`, `Status`,
`StatusId`, `Type`, `TypeId`, `CategoryId`, `Currency`, `CurrencyId`

Permits ledger entity type and attribute script commands. These are not standard
Eagle script commands but domain-specific script commands registered by a ledger
application.

**Ideal scripts:** Ledger data definition scripts that declare organizations,
accounts, categories, and their attributes. This ruleset is specific to
applications that register these script commands and is not useful in a generic
Eagle evaluation context.

#### 3.4.2. `licenseSdk.ruleSet`

**Script commands:** `load`, `package`

Permits the minimal set of script commands required by the Harpy License SDK:
loading native libraries and managing packages.

**Ideal scripts:** Scripts that need to load and initialize the Harpy License
SDK. This is a narrow, purpose-built ruleset.

**Potential problems:** The `load` command can load arbitrary native libraries.
This ruleset should only be used when the script is trusted to load specifically
identified libraries.

#### 3.4.3. `securitySdk.ruleSet`

**Script commands:** `apply`, `file`, `foreach`, `if`, `list`, `load`,
`package`, `rename`, `string`

Permits the script commands required by the Harpy Security SDK: file operations,
control flow, list and string manipulation, library loading, and package
management.

**Ideal scripts:** Scripts that need to load and initialize the Harpy Security
SDK. This ruleset includes `file` and `load`, which are `'unsafe'`, so it should
only be used in contexts where the script is trusted to interact with the
security subsystem.

#### 3.4.4. `loader0.ruleSet`

**Script commands:** `maybeCreatePackageIfNeededCommand`, `sourceWithInfo`

Permits the special script commands provided by the Eagle plugin loader
subsystem. These are internal script commands not available in standard Eagle
interpreters.

**Ideal scripts:** Plugin loader initialization scripts. Not useful for
general-purpose script evaluation.

#### 3.4.5. `loader1.ruleSet`

**Script commands:** `apply`, `try`

Permits the Eagle script commands that are not present in Tcl 8.4 and that are
required by the plugin loader subsystem.

**Ideal scripts:** Plugin loader scripts that need anonymous procedure
application and structured exception handling.

### 3.5. Tcl Compatibility Rulesets

These rulesets mirror the script command sets of specific Tcl versions, enabling
version-specific compatibility testing and migration.

#### 3.5.1. `tcl84.ruleSet`

**Script commands:** 85 script commands — the full Tcl 8.4 core script command
set, including `'unsafe'` script commands.

Permits all script commands available in Tcl 8.4, including file system access,
networking, process execution, and interpreter manipulation. This is a
comprehensive ruleset intended for scripts that need full Tcl 8.4 compatibility.

**Ideal scripts:** Legacy Tcl 8.4 scripts being evaluated in an Eagle
interpreter for compatibility testing or migration.

**Potential problems:** This ruleset includes all `'unsafe'` Tcl 8.4 script commands
and should only be used in trusted environments.

#### 3.5.2. `tcl85.ruleSet`

**Script commands:** `dict`, `apply`, `chan`, `namespace`, `try`

Permits only the script commands that were added in Tcl 8.5. This is a delta
ruleset, not a standalone compatibility set.

**Ideal scripts:** Compose with `tcl84.ruleSet` to produce a full Tcl 8.5
compatible script command set. Useful for testing Tcl 8.5-specific features in
isolation.

#### 3.5.3. `tcl86.ruleSet`

**Script commands:** `coroutine`, `yield`, `yieldto`, `zlib`

Permits only the script commands that were added in Tcl 8.6. This is a delta
ruleset, not a standalone compatibility set.

**Ideal scripts:** Compose with `tcl84.ruleSet` and `tcl85.ruleSet` to produce
a full Tcl 8.6 compatible script command set. Useful for testing coroutine
support or zlib compression in isolation.

#### 3.5.4. `missing.ruleSet`

**Script commands:** `binary`, `case`, `dde`, `fileevent`, `history`, `memory`,
`pkg::create`, `pkg_mkIndex`, `registry`, `scan`, `tcl_findLibrary`, `trace`

Enumerates Tcl 8.4 script commands that are missing from the Eagle core library.
This ruleset does not make these script commands available — it declares them
for reference and for use by compatibility shim layers.

**Ideal scripts:** Not useful for direct script evaluation. Serves as a
reference for identifying Tcl script commands that require special handling or
alternative implementations in Eagle.

### 3.6. Comprehensive Rulesets

#### 3.6.1. `full.ruleSet`

**Script commands:** 107 script commands — every script command available in a
standard Eagle interpreter.

The most permissive ruleset available. It permits all Eagle script commands,
including all `'safe'` and `'unsafe'` script commands. This is the ruleset equivalent of
running with no script command restrictions.

**Ideal scripts:** Fully trusted scripts that need unrestricted access to the
script evaluation interpreter. Suitable for administrative scripts, development
and debugging, and environments where the script author is trusted.

**Potential problems:** This ruleset provides no protection. A script running
under this ruleset can access the file system, the network, the host
environment, native code, databases, and interpreter internals.

### 3.7. Instructional and Test Rulesets

These rulesets demonstrate ruleset features and composition patterns. They are
not intended for production use.

#### 3.7.1. `example.ruleSet`

**Rules:**
1. `id 1` — Include all script commands matching glob pattern `o*` (exclude
   mode).
2. `id 2` — Exclude the `open` script command specifically.

Demonstrates mixed allow/disallow rule construction. The first rule includes
all script commands whose names start with `o` (such as `object` and `open`).
The second rule then explicitly excludes `open`. The net effect is that script
commands like `object` are permitted, but `open` is denied.

**Key lesson:** Rules can use glob patterns for broad matching, and specific
`Exclude` rules can carve out exceptions. The `id` field controls evaluation
order.

#### 3.7.2. `test1.ruleSet` through `test3.ruleSet`

Demonstrates composition chaining via `includeRuleSet`:

- `test1.ruleSet` — Includes `nop`, then includes `test2`.
- `test2.ruleSet` — Includes `namespace.ruleSet`, then includes `test3`.
- `test3.ruleSet` — Includes `securitySdk.ruleSet`.

The effective ruleset for `test1` is: `nop` + `namespace` + `securitySdk`
script commands (`apply`, `file`, `foreach`, `if`, `list`, `load`, `package`,
`rename`, `string`).

**Key lesson:** Rulesets can be composed into arbitrarily deep inclusion chains.

#### 3.7.3. `test4.ruleSet`

**Rules:**
1. Include `apply` with mode `{Include Exact}`.
2. Include `apply` with mode `{Hide Exact}`.

Demonstrates the `Hide` mode: the `apply` script command is included in the
interpreter but hidden from script command enumeration. The script command can
still be invoked by name.

**Key lesson:** The `Hide` mode allows script commands to be available but not
discoverable, which is useful for internal infrastructure script commands that
should not appear in help or introspection output.

#### 3.7.4. `test5.ruleSet`

**Rules:**
1. Include `uri` with mode `{Include Exact}`.
2. Include `uri` with mode `{Show Exact}`.

Demonstrates the `Show` mode: the `uri` script command is explicitly included
and marked as visible in script command enumeration.

**Key lesson:** The `Show` mode is the complement of `Hide`. It can be used to
explicitly ensure that a script command appears in introspection output.

## 4. Composability Guide

### 4.1. Composition Principles

Rulesets are designed to be composed. The functional rulesets (sections 3.2.1
through 3.2.14) each cover a single domain and can be combined to build an
evaluation sandbox tailored to the specific needs of the evaluated script. The
following principles apply:

1. **Start minimal.** Begin with only the rulesets required for the script's
   functionality. Add rulesets incrementally rather than starting with
   `full.ruleSet` and attempting to restrict.

2. **Compose via `includeRuleSet`.** Create a custom `.ruleSet` file that uses
   `includeRuleSet` directives to include the desired functional rulesets.
   This avoids duplicating rules and makes the composition auditable.

3. **Layer security-sensitive rulesets deliberately.** The rulesets in section
   3.3 should only be added when the script genuinely requires their script
   commands, and only for API keys with appropriate access levels.

4. **Use `Exclude` rules for exceptions.** When a composed ruleset includes a
   script command that should be denied in a specific context, add an explicit
   `Exclude` rule rather than restructuring the composition.

5. **Prefer `'safe'` subsets when available.** When a functional ruleset has a
   subset that matches the specific need (e.g. `safeControl.ruleSet` for
   `control.ruleSet`, or `procCaller.ruleSet` for `proc.ruleSet`), prefer the
   subset unless the script specifically requires the excluded script commands.
   This reduces the attack surface without sacrificing the core functionality
   of the domain.

### 4.2. Common Compositions

The following compositions are recommended for typical use cases:

#### Safe General-Purpose Scripting

```
includeRuleSet safeControl
includeRuleSet expr
includeRuleSet string
includeRuleSet list
includeRuleSet variable
includeRuleSet proc
includeRuleSet io
includeRuleSet introspection
```

This composition provides a rich scripting environment with control flow,
mathematical expressions, string and list manipulation, variable management,
procedure definitions, basic I/O, and read-only introspection. By using
`safeControl` instead of `control`, this composition excludes scope-traversal
script commands (`downlevel`, `uplevel`), interpreter-modifying script commands
(`exit`, `invoke`), external file loading (`source`), and timing side-channels
(`time`), providing stronger scope isolation guarantees. It also excludes file
system access, network access, and all other `'unsafe'` script commands.

**Ideal for:** Customer-authored business logic, AI agent scripts, educational
submissions, data transformation pipelines.

#### Minimal Computation

```
includeRuleSet expr
includeRuleSet variable
```

Permits only mathematical expressions and variable storage. No control flow,
no I/O, no string manipulation beyond what `expr` provides.

**Ideal for:** Calculator-style scripts, single-expression evaluations, formula
evaluation engines.

#### Configuration Loading

```
includeRuleSet configuration
```

Permits only `set` and `unset`. The absolute minimum for loading key-value
configuration files.

#### Tcl 8.6 Full Compatibility

```
includeRuleSet tcl84
includeRuleSet tcl85
includeRuleSet tcl86
```

Produces the full Tcl 8.4 + 8.5 + 8.6 script command set. Includes all `'unsafe'`
script commands. Suitable only for trusted environments.

#### SDK Integration

```
includeRuleSet securitySdk
includeRuleSet licenseSdk
includeRuleSet loader0
includeRuleSet loader1
```

Permits the script commands required for Harpy Security SDK and License SDK
integration, including plugin loader support. Includes `'unsafe'` script commands
(`file`, `load`) — suitable only for trusted SDK initialization scripts.

### 4.3. Composition Limitations

1. **No subtraction from included rulesets.** The `includeRuleSet` directive
   is purely additive. If a composed ruleset includes a script command that is
   undesirable, the only recourse is to add an `Exclude` rule at the
   composition level.

2. **Order sensitivity with `id` fields.** When rules have explicit `id`
   values, the evaluation order is determined by those IDs. When composing
   rulesets that use `id` values, be aware that IDs from different included
   rulesets may conflict or produce unexpected ordering.

3. **No conditional inclusion.** The `includeRuleSet` directive does not
   support conditional logic. A ruleset either includes another ruleset or it
   does not.

4. **Overlap between rulesets.** Several rulesets include the same script
   commands (e.g., `source` appears in `control.ruleSet`, `fileSystem.ruleSet`,
   and `network.ruleSet`; `namespace` appears in `variable.ruleSet`,
   `proc.ruleSet`, `procManager.ruleSet`, and `namespace.ruleSet`). Duplicate
   inclusions are harmless but should be understood when reasoning about the
   effective script command set.

### 4.4. Dual-Use Classification

Ruleset files serve two distinct but complementary purposes:

1. **Functional categorization.** A ruleset can group script commands that
   share a common functional domain or set of idioms. For example,
   `control.ruleSet` groups all script commands that implement script control
   flow, regardless of their individual security characteristics.

2. **Security or conceptual boundary.** A ruleset can represent a security or
   other conceptual boundary, selecting only the script commands within a
   domain that satisfy a particular criterion. For example,
   `safeControl.ruleSet` selects only the control-flow script commands that do
   not change the active variable scope, modify non-local variable state,
   modify interpreter state, or access external files or side-channels.

Two pairs of rulesets illustrate this dual-use nature:

**Security boundary (`control.ruleSet`):** The `safeControl.ruleSet` and
`unsafeControl.ruleSet` pair partitions `control.ruleSet` along a security
boundary (18 + 7 = 25 script commands). One groups the script commands that are
`'safe'` within a scope-isolated evaluation sandbox; the other groups the script
commands that can change scope, modify interpreter state, or access external
resources. The functional category remains the same; the security boundary
differs.

**Role boundary (`proc.ruleSet`):** The `procCaller.ruleSet` and
`procManager.ruleSet` pair partitions `proc.ruleSet` along a role boundary
(2 + 4 = 6 script commands). One groups the script commands that consume
procedures (anonymous procedure application); the other groups the script
commands that produce procedures (definition, renaming, namespace management).
The functional category remains the same; the operational role differs.

This pattern can be applied to any functional ruleset. When the full script
command set of a functional ruleset includes script commands with differing
security profiles or operational roles, splitting it into complementary subsets
provides the granularity needed to satisfy both functional requirements (which
script commands are needed) and boundary requirements (which script commands are
appropriate for the given context) simultaneously.

**Guidance for agents:** When composing rulesets, consider whether the
composition is driven by functional requirements, security requirements, role
requirements, or a combination thereof. When a subset is available for a
functional ruleset, prefer the subset that most closely matches the needs of the
evaluated script.

## 5. Security Considerations

### 5.1. Script Command Safety Classification

The rulesets implicitly define a three-tier safety classification:

| Tier | Description | Rulesets |
|---|---|---|
| Safe | Script commands with no side effects beyond modifying the implicit interpreter state (e.g. number of commands executed, etc). | `common`, `configuration`, `expr`, `string`, `list`, `safeControl`, `procCaller`, `introspection` |
| Sensitive | Script commands with potential side effects that require care. | `variable`, `control`, `unsafeControl`, `proc`, `procManager`, `io`, `event`, `namespace` |
| Unsafe | Script commands that access system resources or bypass security. | `fileSystem`, `network`, `critical`, `unsafe`, `meta` |

The placement of `safeControl` in the Safe tier and `unsafeControl` in the
Sensitive tier reflects their role as a security partition of `control.ruleSet`:
the script commands in `unsafeControl` are precisely the script commands that
elevate `control.ruleSet` from the Safe tier to the Sensitive tier.

Similarly, the placement of `procCaller` in the Safe tier and `procManager` in
the Sensitive tier reflects their role as a role partition of `proc.ruleSet`.
The script commands in `procCaller` (`apply`, `napply`) are purely functional —
they apply anonymous procedures without side effects beyond modifying the
implicit interpreter state (e.g. number of commands executed, etc), which
places them squarely in the Safe tier. The script commands in `procManager`
(`namespace`, `nproc`, `proc`, `rename`) can (re-)define procedures, rename or
delete script commands, and manage namespaces, which are operations that modify
the interpreter's script command set and require care.

However, `procManager` operations are notably declarative: they establish
procedure definitions for later use rather than executing arbitrary script
code. This declarative character distinguishes them from the Unsafe tier — the
script commands in `procManager` configure the interpreter's available
procedures but do not, by themselves, access system resources or bypass the
evaluation sandbox.

### 5.2. Script Commands That Span Tiers

Several script commands have both `'safe'` and `'unsafe'` script sub-commands. The
rulesets handle this in different ways:

- `unsafe.ruleSet` explicitly excludes script commands with `'safe'` script
  sub-commands (`clock`, `file`, `info`, `interp`, `object`, `package`,
  `source`, `uri`) even though the top-level script command is `'unsafe'`. This is
  noted in the file's header comment.
- `fileSystem.ruleSet` includes `file` and `source` because the file-system
  functionality requires the `'unsafe'` script sub-commands.
- `control.ruleSet` includes `source` for script loading, even though `source`
  can access the file system or network. The `'safe'`/`'unsafe'` split of
  `control.ruleSet` places `source` in `unsafeControl.ruleSet`, reflecting
  this cross-tier concern.

**Guidance for agents:** Agents composing rulesets should be aware that
including a script command with mixed `'safe'`/`'unsafe'` script sub-commands may grant
access to both. The server's security policies may impose additional
restrictions at the script sub-command level, if applicable and available.

### 5.3. The `critical.ruleSet` as a Deny Reference

The `critical.ruleSet` is best understood not as a ruleset to be included, but
as a reference enumeration of the script commands that should almost never be
permitted in a sandbox-facing configuration. When reviewing a composed ruleset
for security, verify that none of the `critical.ruleSet` script commands are
present unless the script is fully trusted.

## 6. Reference: `tcl84-wiki.txt`

The file `tcl84-wiki.txt` is a plain-text reference listing of all Tcl 8.4
script commands as documented on the Tcl wiki. It contains 93 script command
names grouped alphabetically. This list includes script commands not present in
`tcl84.ruleSet` (such as the `auto_*` family and `http`) because those script
commands are implemented as library procedures rather than core script commands.
Conversely, `tcl84.ruleSet` includes `tclLog` and `case`, which do not appear
in the wiki listing.

This file is a reference artifact and is not consumed by the ruleset processing
engine.

## 7. Versioning

This document describes the ruleset files as they exist in the official `extra`
repository. The repository is the authoritative source for the current state of
each file. In the event of any discrepancy between this document and the
repository contents, the repository takes precedence.
