#########################################################################################
# Name			steiner:fortune
# Description		Gives a fortune cookie
# Version		1.1 (2012-04-23)
# Contact		ScottSteiner@irc.rizon.net
# Website		https://github.com/ScottSteiner/eggdrop-scripts
# Copyright		2011-2012, ScottSteiner <nothingfinerthanscottsteiner@gmail.com>
# License		GPL version 3 or any later version; http://www.gnu.org/copyleft/gpl.html
#########################################################################################
if {[catch {source scripts/steiner-settings.tcl} err]} {
	putlog "Error: Could not load 'scripts/steiner-settings.tcl' file.";
}

namespace eval steiner {
   namespace eval fortune {
	package require json
	safesetudef fortune
	bind pub -|- ${steiner::settings::prefix}fortune steiner::fortune::public
	variable cache [dict create]

	proc public {nick uhost hand chan arg} {
		if {[string tolower [lindex [split $arg] 0]] == "-p"} { set targ "$nick";set arg "[lindex [split $arg] 1]"; } else { set targ "$chan" }
		if {$arg == ""} { set fnick $nick } else { set fnick $arg }
		if {[channel get $chan steiner] && [channel get $chan fortune]} { puthelp "PRIVMSG $targ :[fortune $targ $fnick]" }
	}

	proc fortune { targ nick } {
		if { [catch {
			if {([dict exists $steiner::fortune::cache $nick time]) && ([clock format [clock seconds] -format "%Y-%m-%d"] == [dict get $steiner::fortune::cache $nick time])} {
				return "[dict get $steiner::fortune::cache $nick output]"
			}
			catch { exec $steiner::settings::fortune::path {*}$steiner::settings::fortune::options | tr {\n\t} { } } output
			set output "$nick's fortune for today is: $output"
			dict set steiner::fortune::cache $nick output $output
			dict set steiner::fortune::cache $nick time [clock format [clock seconds] -format "%Y-%m-%d"]
			return $output
		} catch] == 1} { putlog "steiner:fortune Failed to get fortune for $nick: $catch"; return "steiner:fortune Failed to get fortune for $nick: $catch" }\
                else { return $catch }
	}
   }
}
