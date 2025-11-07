###############################################################################
#
# tclshrc.tcl --
#
# Extensible Adaptable Generalized Logic Engine (Eagle)
# Tcl/Tk & Eagle Shell Startup Script
#
# Copyright (c) 2007-2012 by Joe Mistachkin.  All rights reserved.
#
# See the file "license.terms" for information on usage and redistribution of
# this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# RCS: @(#) $Id: $
#
###############################################################################

#
# NOTE: This script is designed to be evaluated in the global namespace only.
#       Native Tcl does this by default (?); however, Eagle does not.
#
namespace eval :: {
  if {[info exists ::eagle_platform]} then {; # are we running in Eagle?
    if {![info exists ::eagle_debugger(startup)]} then {; # already done?
      apply [list [list script {quiet ""}] {
        #
        # NOTE: Attempt to load all the interactive startup files,
        #       e.g. the extra stuff that is useful for interactive
        #       use, etc.
        #
        set path [file normalize [file dirname $script]]

        #
        # HACK: Should be quiet for things like the Demo test suite.
        #       Since the "$::argv" script variable can be modified
        #       by the shell command line processing, use the (new)
        #       [info argv] sub-command to fetch the full, original
        #       command line argument list.
        #
        if {[string length $quiet] == 0} then {; # auto-detect?
          #
          # WARNING: This snippet blatantly stolen from the script
          #          file "startup-compat.eagle", which resides in
          #          the same directory as this script file.  Both
          #          of these should be kept synchronized.
          #
          if {[catch {info argv} fullArgv] || \
              [llength $fullArgv] == 0} then {
            set quiet false
          } else {
            set quiet true
          }
        }

        if {!$quiet} then {
          host result Ok [appendArgs "Starting from \"" $path "\"...\n\t"]
        }

        foreach fileName [source [file join $path startup-lister.eagle]] {
          if {[file exists $fileName]} then {
            if {!$quiet} then {
              host result Return [appendArgs " " [file tail $fileName]]
            }

            uplevel #0 [list source $fileName]
          }
        }

        if {!$quiet} then {
          host result Ok " DONE\n"
        }
      }] [info script]
    } else {
      apply [list [list] {; # log startup command line
        #
        # HACK: Make sure the "effective" command line arguments, as they
        #       appear to the interactive loop, are (eventually) emitted
        #       into the test log file, if any.
        #
        tqlog [appendArgs "---- startup command line: " [expr {
          [info exists ::argv] && \
              [string length $::argv] > 0 ? $::argv : "<none>"
        }] \n]
      }]
    }

    #
    # HACK: This is primarily for the benefit of being able to run some
    #       previous releases of Eagle.  The script file being evaluated
    #       contains various (backward) compatibility shims and/or other
    #       code that prevents errors when running the test suite, etc.
    #       This script file must be evaluated outside the "already done"
    #       script block (above) because it needs to be evaluated twice,
    #       once during interpreter creation and then again when entering
    #       the interactive loop.
    #
    apply [list [list script] {
      set path [file dirname $script]
      set fileName [file join $path startup-compat.eagle]

      if {[file exists $fileName]} then {
        uplevel #0 [list source $fileName]
      }
    }] [info script]
  } else {
    #
    # HACK: Forcibly enable support for tracking the current test name
    #       for native Tcl (i.e. via the [tcltest::test] procedure) for
    #       use by the [getTestName] Eagle test suite helper procedure.
    #
    set ::eagle_debugger(TclTestCurrentName) ""
  }
}
