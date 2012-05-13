#########################################################################################
# Name                  steiner:dice
# Description           Dice roller script with rerolls
# Version               1.1 (2012-04-23)
# Contact               ScottSteiner@irc.rizon.net
# Website		https://github.com/ScottSteiner/eggdrop-scripts
# Copyright		2010-2012 ScottSteiner <nothingfinerthanscottsteiner@gmail.com>
# License               GPL version 3 or any later version; http://www.gnu.org/copyleft/gpl.html
#########################################################################################
# Author's notes
# Original dice rolling by Spacexplosion <spacexplosion@gmail.com>: http://j.mp/gYJsa5
if {[catch {source scripts/steiner-settings.tcl} err]} {
	putlog "Error: Could not load 'scripts/steiner-settings.tcl' file.";
}

namespace eval steiner {
   namespace eval dice {
	safesetudef dice
	bind pub -|- ${steiner::settings::prefix}roll steiner::dice::public
	bind msg -|- roll steiner::dice::private

	# Process dice roll for public channel
	proc public {nick userhost hand chan text} {
		if {![channel get $chan dice]} { return }
		roll $chan "-> \002$nick\002 rolls" $text
	}

	# Process dice roll for private message
	proc private {nick userhost hand text} {
		roll $nick "You roll" $text
	}

	# Parse command and sends response message
	proc roll {recipient msgPrefix text} {
		set msg $msgPrefix
		if {[regexp {([0-9]+)(?: |)(.*|)} $text match num action]} {
			set mod 0; set sides 10;
			if {$action != ""} { append msg " to $action" }
			if {$num > 50} { append msg " too many dice (maximum of 50)" } else { append msg " [diceCalc $num $sides $mod $steiner::settings::dice::success]" }
		} else { append msg " incorrectly. Try !roll <n>: where <n> is number of dice" }
		puthelp "PRIVMSG $recipient :$msg."
	}

	# Do the random generation and arithmetic
	# Returns final total
	proc diceCalc {num sides mod success} {
		set roll_string ""
		set roll_critfail 0;set roll_reroll 0;set roll_success 0
		for {set i 0} {$i < $num} {incr i} {
			set roll_new [expr [rand $sides]+1]
			if {$roll_new == 10} { incr i -1; incr roll_success; incr roll_reroll; set roll_new "\002\00309$roll_new\003\002" } \
			elseif {$roll_new >= $steiner::settings::dice::success} { incr roll_success; set roll_new "\00309$roll_new\003" } \
			elseif {$roll_new == 1} { incr roll_critfail; set roll_new "\002\00304$roll_new\003\002" }
			if {$roll_string == ""} {set roll_string "$roll_new"} else { set roll_string "$roll_string, $roll_new" }
		}
		if {$roll_reroll == 0} {set roll_reroll ""}\
			elseif {$roll_reroll == 1} {set roll_reroll " (+$roll_reroll reroll)"}\
			else {set roll_reroll " (+$roll_reroll rerolls)"}
		if {$roll_success == 0} { set roll_success "" }\
			elseif {$roll_success == 1} {set roll_success " (\00309\002$roll_success\002 success\003)"}\
			else {set roll_success " (\00309\002$roll_success\002 successes\003)"}
		if {$roll_critfail == 0 || $roll_success != ""} {set roll_critfail ""}\
			elseif {$roll_critfail == 1} {set roll_critfail " (\00304\002$roll_critfail\002 critical failure\003)"}\
			else {set roll_critfail " (\00304\002$roll_critfail\002 critical failures\003)"}
		if {$num == 1} { set num "$num roll" } else { set num "$num rolls" }
		return "$roll_string on $num$roll_success$roll_critfail$roll_reroll"
	}
   }
}
