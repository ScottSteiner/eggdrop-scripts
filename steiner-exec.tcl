#########################################################################################
# Name			steiner:exec
# Description		Executes a command on your system's shell.  Only works for people with the correct flags
# Version		1.2 (2014-02-24)
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
	set flag $steiner::settings::exec::flag
	if {$steiner::settings::exec::enablepublic} { foreach cmd {date stats sysinfo times uname uptime} { bind pub ${flag}|${flag} ${steiner::settings::prefix}$cmd steiner::exec::public } }

	proc public {nick uhost hand chan arg} {
		if {[string tolower [lindex [split $arg] 0]] == "-p"} { set targ "$nick" } else { set targ "$chan" }
		set cmd [string range [lindex $::lastbind 0] 1 end]
		execute $targ $cmd
	}

	proc execute { targ cmd } {
		if {$cmd == "date"}	{ set cmd "date +%F\\ %T%:::z" }
		if {$cmd == "stats"}	{ puthelp "PRIVMSG $targ :Channel stats can be found at http://scottsteiner.github.io"; return 1 }
		if {$cmd == "sysinfo"}	{ set cmd "/usr/local/bin/sysinfo" }

		#Time zone listings can be found at https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
		if {$cmd == "times"}	{ puthelp "PRIVMSG $targ :[clock format [clock seconds] -format {Los Angeles %I:%M %p %Z} -timezone America/Los_Angeles] | [clock format [clock seconds] -format {New York %I:%M %p %Z} -timezone America/New_York] |\
								[clock format [clock seconds] -format {London %I:%M %p %Z} -timezone Europe/London] | [clock format [clock seconds] -format {Berlin %I:%M %p %Z} -timezone Europe/Berlin] | [clock format [clock seconds] -format {Tokyo %I:%M %p %Z} -timezone Asia/Tokyo]"; return 1 }
		if {$cmd == "uname"}	{ set cmd "uname -a" }
		catch { eval exec $cmd } output
		puthelp "PRIVMSG $targ :$output"
	}
   }
}
