#########################################################################################
# Name			steiner:weather
# Description		Grabs weather info for your eggdrop bot.  Uses Weather Underground's API
# Version		1.2 (2012-04-23)
# Contact		ScottSteiner@irc.rizon.net
# Website		https://github.com/ScottSteiner/eggdrop-scripts
# Copyright		2010-2012, ScottSteiner <nothingfinerthanscottsteiner@gmail.com>
# License		GPL version 3 or any later version; http://www.gnu.org/copyleft/gpl.html
#########################################################################################
if {[catch {source scripts/steiner-settings.tcl} err]} {
	putlog "Error: Could not load 'scripts/steiner-settings.tcl' file.";
}

namespace eval steiner {
   namespace eval weather {
	package require http;package require json;package require tdom
	safesetudef weather
	foreach bind $steiner::settings::weather::binds::location { bind pub - ${steiner::settings::prefix}$bind steiner::weather::location }
	foreach bind $steiner::settings::weather::binds::time { bind pub - ${steiner::settings::prefix}$bind steiner::weather::public }
	foreach bind $steiner::settings::weather::binds::weather { bind pub - ${steiner::settings::prefix}$bind steiner::weather::public }

	variable version 1.2
	variable cache [dict create]

	::http::config -useragent $steiner::settings::useragent
	proc public {nick uhost hand chan text} {
		if {(![channel get $chan weather]) || (![channel get $chan steiner]) } {return 0}
		if {$text != ""} { set location $text } else { set location [getuser $hand XTRA weather.loc] }
		if {[string length $location] == 0 || [regexp {[^0-9a-zA-Z,. ]} $location match] == 1} { return }
		if  { [ lsearch $steiner::settings::weather::binds::forecast [string range [lindex $::lastbind 0] 1 end] ] >= 0 }   { putchan $chan "[forecast $location]"  }\
			elseif  { [ lsearch $steiner::settings::weather::binds::time [string range [lindex $::lastbind 0] 1 end] ] >= 0 }   { putchan $chan "[current time $location]"  }\
			elseif  { [ lsearch $steiner::settings::weather::binds::weather [string range [lindex $::lastbind 0] 1 end] ] >= 0 }   { putchan $chan "[current weather $location]"  }
	}

	proc current {action location} {
		if { [catch {
			regsub -all -- { } $location {%20} location
			if {([dict exists $steiner::weather::cache $location current time]) && ($action == "weather") && ([expr [unixtime] - [dict get $steiner::weather::cache $location current time]] <= [expr $steiner::settings::weather::cachetime * 60])} {
				return "[dict get $steiner::weather::cache $location current output] - Cached from [clock format [dict get $steiner::weather::cache $location current time] -format %Y-%m-%d\ %H:%M:%S]"
			}
			for { set i 1 } { $i <= 6 } { incr i } {
				set xml [::http::data [::http::geturl "http://$steiner::settings::weather::ipaddress/auto/wui/geo/WXCurrentObXML/index.xml?query=$location" -timeout [expr round($steiner::settings::weather::timeout * 1000)]]]
				if {[string length $xml] > 1} { break }
			}
			if {[string length $xml] == 0} { error "Weather Underground returned no data" }
			set nodeList [[dom parse $xml] documentElement]
			foreach nodeName {city latitude longitude state_name zip}\
				{if { [catch { set $nodeName [[lindex [$nodeList selectNodes /current_observation/display_location/$nodeName/text()] 0] data] } ]} { set $nodeName "No Report" } }
			foreach nodeName {heat_index_c heat_index_f local_time relative_humidity temp_c temp_f weather windchill_c windchill_f wind_mph wind_dir}\
				{if { [catch { set $nodeName [[lindex [$nodeList selectNodes /current_observation/$nodeName/text()] 0] data] } err] } { set $nodeName "No Report"; } }
			if {($city == "No Report") || ($latitude == "No Report") || ($longitude == "No Report") || ($temp_f == "No Report")} { error "Location not found"}
			set latitude [roundnum $latitude 2];set longitude [roundnum $longitude 2]
			if {$latitude < 0} { set latitude "[expr {abs($latitude)}]°S" } else { append latitude "°N" }
			if {$longitude < 0} { set longitude "[expr {abs($longitude)}]°W" } else { append longitude "°E" }
			if {$wind_mph < 0} { set wind_mph 0 }
			if {$zip > 0} { set zipcode " ($zip)" } else { set zipcode "" }

			if {$action == "weather"} {
				if {[isnumber $wind_mph]} { set wind_kph [expr round($wind_mph * 1.6)] }
				if {$heat_index_c == "NA"} { set heat_index "" } else { set heat_index " \002\Heat Index\002: $heat_index_f°F/$heat_index_c°C" }
				if {$windchill_c == "NA"} { set wind_chill "" } else { set wind_chill " \002\Wind Chill\002: $windchill_f°F/$windchill_c°C" }
				set current [subst [regsub -all {\w+} $weather {[string totitle \0]}]]
				set alert "";set warnings ""
				if {$zip > 0} {
					set nodeList [[dom parse [::http::data [::http::geturl "http://$steiner::settings::weather::ipaddress/auto/wui/geo/AlertsXML/index.xml?query=$zip" -timeout [expr round($steiner::settings::weather::timeout * 1000)]]]] documentElement]
					foreach nodeName [$nodeList selectNodes /alerts/alert/AlertItem/description/text()] { lappend warnings [$nodeName data] }
					if {[llength $warnings]} {
						set alerturl "http://www.accuweather.com/us/nothing/finer/$zip/watches-warnings.asp"
						set tokens [list %alert_website% [make_bitly $accuweather] %warnings% "[join [lsort -unique $warnings] ", "]"]
						set alert [string map $tokens $steiner::settings::weather::alert_format]
					} else { set alert "" }
				}

				set tokens [list %alert% "$alert" %city% "$city" %current% "$current" %heat_index% "$heat_index" %humidity% "$relative_humidity"\
					%latitude% "$latitude" %local_time% "$local_time" %location% "\002$city, $state_name$zipcode (\002$latitude $longitude\002)\002"\
					%longitude% "$longitude" %state_name% "$state_name" %temp_c% "$temp_c°C" %temp_f% "$temp_f°F" %wind_chill% "$wind_chill"\
					%wind_direction% "$wind_dir" %wind_kph% "$wind_kph\kph" %wind_mph% "$wind_mph\mph" %zipcode% "$zipcode" ]
				dict set steiner::weather::cache $location current output [string map $tokens $steiner::settings::weather::output_format]
				dict set steiner::weather::cache $location current time [unixtime]
				return [dict get $steiner::weather::cache $location current output]
			} elseif {$action == "time"} {
				set tokens [list %local_time% "$local_time" %location% "\002$city, $state_name$zipcode (\002$latitude $longitude\002)\002"]
				return [string map $tokens $steiner::settings::weather::time_format]
			}
		} catch] == 1} { putlog "weather: Failed to get $action data for $location: $catch.  String length of [string length $xml]\n$xml"; return "Failed to get \002$action\002 data for \002$location\002: $catch." }\
		else { return $catch }
	}
	proc location {nick uhost hand chan text} {
		if {![validuser $hand]} {
			adduser $nick $uhost
			chattr $nick -hp
			set lochand [nick2hand $nick]
			putchan $chan "fff [nick2hand $nick]"
		} else { set lochand $hand }
		putchan $chan "$nick $uhost $hand"
		setuser $hand XTRA weather.loc $text
		putchan $chan "Location for $nick set to $text."
	}
	proc isnumber {str} { return [string is integer -strict $str] }
	proc isdouble {str} { return [string is double -strict $str] }
	proc make_bitly {url} {
		if { [catch {
				if {[info exists url] && [string length $url]} {
						set data [::http::geturl "http://api.bit.ly/v3/shorten?login=$steiner::settings::bitly::login&apiKey=$steiner::settings::bitly::apiKey&domain=$steiner::settings::bitly::domain&format=json&longURL=$url" -timeout [expr $steiner::settings::bitly::timeout * 1000]]
						return [dict get [json::json2dict [::http::data $data]] "data" "url"]
				} else { return $url }
		} catch] == 1} { putlog "steiner:weather $steiner::weather::version: Failed to shorten url for $url: $catch." } else { return $catch }
	}

	proc putchan {chan text} {
		if {([regexp .*c.* [getchanmode $chan] match] == 1) && (![botisop $chan]) && (![botishalfop $chan]) && (![botisvoice $chan])} {
			puthelp "PRIVMSG $chan :[stripcodes abcgru $text]" }\
		else { puthelp "PRIVMSG $chan :$text" }
	}
	proc roundnum {num precision} { if {[isdouble $num]} { return [expr { double(round($num * pow(10,$precision))) / pow(10,$precision) }] } else { return $num } }
   }
}

putlog "steiner:weather $steiner::weather::version loaded"
