#########################################################################################
# Name			steiner:exec
# Description		Executes a command on your system's shell.  Only works for people with the correct flags
# Version		1.2.1 (2014-03-05)
# Contact		ScottSteiner@irc.rizon.net
# Website		https://github.com/ScottSteiner/eggdrop-scripts
# Copyright		2010-2014, ScottSteiner <nothingfinerthanscottsteiner@gmail.com>
# License		GPL version 3 or any later version; http://www.gnu.org/copyleft/gpl.html
#########################################################################################
if {[catch {source scripts/steiner-settings.tcl} err]} {
	putlog "Error: Could not load 'scripts/steiner-settings.tcl' file.";
}

namespace eval steiner {
   namespace eval exec {
	# Protected functions
	set flag $steiner::settings::exec::flag
	if {$steiner::settings::exec::enablepublic} { foreach cmd {date sysinfo uname uptime} { bind pub ${flag}|${flag} ${steiner::settings::prefix}$cmd steiner::exec::public } }
	# Public functions
	if {$steiner::settings::exec::enablepublic} { foreach cmd {stats times} { bind pub -|- ${steiner::settings::prefix}$cmd steiner::exec::public } }
	proc public {nick uhost hand chan arg} {
		if {[string tolower [lindex [split $arg] 0]] == "-p"} { set targ "$nick" } else { set targ "$chan" }
		set cmd [string range [lindex $::lastbind 0] 1 end]
		puthelp "PRIVMSG $targ :[execute $cmd]"
	}

	proc execute { cmd } {
		if {$cmd == "sysinfo"}	{ set cmd "/usr/local/bin/sysinfo" }
		if {$cmd == "uname"}	{ set cmd "uname -a" }

		if {$cmd == "date"}     { return [clock format [clock seconds] -format {%Y-%m-%d %T %Z}] }
		if {$cmd == "stats"}	{ return "Channel stats can be found at http://scottsteiner.github.io" }
		if {$cmd == "times"}	{
			foreach city [dict keys $steiner::settings::exec::times] {
				set timezone [dict get $steiner::settings::exec::times $city]
				lappend info "$city [clock format [clock seconds] -format {%I:%M %p %Z} -timezone $timezone]"
			}
			set output [join $info " | "]
			return "$output"
		}
		catch { eval exec $cmd } output
		return "$output"
	}
   }
}
