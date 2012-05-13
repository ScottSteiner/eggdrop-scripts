#########################################################################################
# Name				steiner:opall
# Description			Automatically ops/voices people who join channels with the +opall/voiceall flags
# Version			1.1 (2012-04-23)
# Contact			ScottSteiner@irc.rizon.net
# Website			https://github.com/ScottSteiner/eggdrop-scripts
# Copyright			2010-2012, ScottSteiner <nothingfinerthanscottsteiner@gmail.com>
# License			GPL version 3 or any later version; http://www.gnu.org/copyleft/gpl.html
#########################################################################################
if {[catch {source scripts/steiner-settings.tcl} err]} {
	putlog "Error: Could not load 'scripts/steiner-settings.tcl' file.";
}

namespace eval steiner {
   namespace eval opall {
	bind join -|- * steiner::opall::join
	safesetudef voiceall
	safesetudef opall
	proc join {nick uhost hand chan} {
		global voice op
		if {[channel get $chan opall]} {
			if {[info exists op($chan)]} { lappend op($chan) $nick } else { set op($chan) $nick }
		}\
		elseif {[channel get $chan voiceall]} {
			if {[info exists voice($chan)]} { lappend voice($chan) $nick } else { set voice($chan) $nick }
		}
		utimer [expr [lindex [split $steiner::settings::opall::delay :] 0] + [rand [lindex [split $steiner::settings::opall::delay :] 1]]] [list steiner::opall::do $chan]
	}
	proc do {chan} {
		global op voice
		if {[info exists op($chan)]} { foreach nick [lsort -unique $op($chan)] { pmode $chan +o $nick; unset op($chan) } }
		if {[info exists voice($chan)]} { foreach nick [lsort -unique $voice($chan)] { pmode $chan +v $nick; unset voice($chan) } }
		return 0
	}
	proc pmode {chan mode nick} {if {(![isbotnick $nick]) && ([botisop $chan]) && (![isop $nick $chan])} { pushmode $chan $mode $nick } }
   }
}
