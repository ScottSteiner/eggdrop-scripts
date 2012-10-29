#########################################################################################
# Name			steiner:exec
# Description		Executes a command on your system's shell.  Only works for people with the correct flags
# Version		1.1 (2012-04-23)
# Contact		ScottSteiner@irc.rizon.net
# Website		https://github.com/ScottSteiner/eggdrop-scripts
# Copyright		2010-2012, ScottSteiner <nothingfinerthanscottsteiner@gmail.com>
# License		GPL version 3 or any later version; http://www.gnu.org/copyleft/gpl.html
#########################################################################################
if {[catch {source scripts/steiner-settings.tcl} err]} {
	putlog "Error: Could not load 'scripts/steiner-settings.tcl' file.";
}

namespace eval steiner {
   namespace eval exec {
	set flag $steiner::settings::exec::flag
	if {$steiner::settings::exec::enablepublic} { foreach cmd {date stats sysinfo uname uptime} { bind pub ${flag}|${flag} ${steiner::settings::prefix}$cmd steiner::exec::public } }

	proc public {nick uhost hand chan arg} {
		if {[string tolower [lindex [split $arg] 0]] == "-p"} { set targ "$nick" } else { set targ "$chan" }
		set cmd [string range [lindex $::lastbind 0] 1 end]
		execute $targ $cmd
	}

	proc execute { targ cmd } {
		if {$cmd == "date"}	{ set cmd "date +%F\\ %T%:::z" }
		if {$cmd == "sysinfo"}	{ set cmd "/usr/local/bin/sysinfo" }
		if {$cmd == "uname"}	{ set cmd "uname -a" }
		if {$cmd == "stats"}	{ puthelp "PRIVMSG $targ :Channel stats can be found at http://scottsteiner.is-great.org/stats.php"; return 1 }
		catch { eval exec $cmd } output
		puthelp "PRIVMSG $targ :$output"
	}
   }
}
