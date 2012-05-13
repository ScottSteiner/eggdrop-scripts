#########################################################################################
# Name			steiner:youtube
# Description		Grabs YouTube info for your eggdrop bot.  Uses YouTube's JSON API
# Version		1.2 (2012-04-23)
# Contact		ScottSteiner@irc.rizon.net
# Website		https://github.com/ScottSteiner/eggdrop-scripts
# Copyright		2010-2012, ScottSteiner <nothingfinerthanscottsteiner@gmail.com>
# License		GPL version 3 or any later version; http://www.gnu.org/copyleft/gpl.html
#########################################################################################
# Author's notes
# Commify proc courtesy of Jeff Hobbs via Andreas Kupries http://j.mp/aqgSa1
#
# Requirements: The json and http packages for tcl (tcllib in Debian or Ubuntu)
if {[catch {source scripts/steiner-settings.tcl} err]} {
	putlog "Error: Could not load 'scripts/steiner-settings.tcl' file.";
}

namespace eval steiner {
   namespace eval youtube {
	package require http;package require json
	safesetudef youtube
	bind pubm - * steiner::youtube::public
	variable cache [dict create]
	variable regex {(?:http(?:s|).{3}|)(?:www.|)(?:youtube.com\/watch\?.*v=|youtu.be\/)([\w-]{11})}
	variable version "1.2"
	::http::config -useragent $steiner::settings::useragent
	proc public {nick uhost hand chan text} {
		if {[channel get $chan steiner] && [channel get $chan youtube] && [regexp -nocase -- $steiner::youtube::regex $text url id]} {
			if {([regexp .*c.* [getchanmode $chan] match] == 1) && (![botisop $chan]) && (![botishalfop $chan]) && (![botisvoice $chan])} {
				puthelp "PRIVMSG $chan :[stripcodes bcru [getinfo $nick $id]]" }\
			else {	puthelp "PRIVMSG $chan :[getinfo $nick $id]" }
		}
	}

	proc getinfo {nick id} {
	        if { [catch {
			global botnick
			if {([dict exists $steiner::youtube::cache $id time]) && ([expr [unixtime] - [dict get $steiner::youtube::cache $id time]] <= [expr $steiner::settings::youtube::cachetime * 60])} {
				return "[dict get $steiner::youtube::cache $id output] - Cached from [clock format [dict get $steiner::youtube::cache $id time] -format %Y-%m-%d\ %H:%M:%S]"
			}
			for { set i 1 } { $i <= $steiner::settings::youtube::retries } { incr i } {
				set xml [::http::data [::http::geturl "http://gdata.youtube.com/feeds/api/videos/$id\?v=2&alt=jsonc" -timeout [expr $steiner::settings::youtube::timeout * 1000]]]
				if {[string length $xml] > 0} { break }
			}
			if {[string length $xml] == 0} { error "YouTube returned no data" }
			if { [dict exists [json::json2dict $xml] "error"] } { error [dict get [json::json2dict $xml] "error" "message"] }
			set data [dict get [json::json2dict $xml] "data"]
			if { [regexp -nocase {%bitly%} $steiner::settings::youtube::output_format] } { set bitly [make_bitly "http://youtu.be/$id"]} else { set bitly "http://youtu.be/$id" }
			foreach json {commentCount description duration rating ratingCount title uploaded uploader viewCount}\
				{if { [catch { set $json [dict get $data $json] } ] } { set $json "n/a" } }
			set description [string range $description 0 $steiner::settings::youtube::max_length]
			if {[string is integer -strict $duration]} {
				if {$duration >= 3600} { set duration [clock format $duration -format %H:%M:%S -gmt true] }\
				else { set duration [clock format $duration -format %M:%S] }
			}
			if {$ratingCount == "n/a"} { set ratingCount "0" } elseif {[string is double -strict $rating]} { set rating "[roundnum $rating 2]/5" }
			set title [string range $title 0 $steiner::settings::youtube::max_length]
			set uploaded [string range $uploaded 0 9]
			foreach commify {commentCount ratingCount viewCount} { set $commify [commify [expr \$$commify]] }
			set tokens [list %bitly% $bitly %botnick% $botnick %commentCount% $commentCount\
				%description% $description %duration% $duration %ratingCount% $ratingCount\
				%rating% "$rating" %title% $title %triggerNick% $nick\
				%uploadedDate% $uploaded %uploader% $uploader %viewCount% $viewCount\
				%youtube_shorten% "http://youtu.be/$id" %youtubeURI% "http://www.youtube.com/watch?v=$id"]

			dict set steiner::youtube::cache $id output [string map $tokens $steiner::settings::youtube::output_format]
			dict set steiner::youtube::cache $id time [unixtime]
			return [dict get $steiner::youtube::cache $id output]
		} catch] == 1} { putlog "steiner:youtube Failed to get YouTube data for $id: $catch"; return "steiner:youtube Failed to get \002YouTube\002 data for $id: $catch" }\
	        else { return $catch }
	}
	proc make_bitly {url} {
		if { [catch {
			if {[info exists url] && [string length $url]} {
				set data [::http::geturl "http://api.bit.ly/v3/shorten?login=$steiner::settings::bitly::login&apiKey=$steiner::settings::bitly::apiKey&domain=$steiner::settings::bitly::domain&format=json&longURL=$url" -timeout [expr $steiner::settings::settings::bitly::timeout * 1000]]
				return [dict get [json::json2dict [::http::data $data]] "data" "url"]
			} else { return $url }
		} catch] == 1} { putlog "steiner:youtube $steiner::youtube::version: Failed to shorten url for $url: $catch." } else { return $catch }
	}
	proc commify {num {sep ,}} {
		while {[regsub {^([-+]?\d+)(\d\d\d)} $num "\\1$sep\\2" num]} {}
		return $num
	}
	proc roundnum {num precision} { return [expr { double(round($num * pow(10,$precision))) / pow(10,$precision) }] }
   }
}
putlog "steiner:youtube $steiner::youtube::version loaded"

