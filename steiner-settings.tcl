proc safesetudef {name} { if {[catch {renudef flag $name temp ;renudef flag temp $name}]} { setudef flag $name } }
safesetudef steiner

namespace eval steiner {
	namespace eval settings {
		set prefix			"."
		set useragent			"Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:25.0) Gecko/20100101 Firefox/25.0"
		namespace eval bitly {
			set apiKey      	"";					# Insert yours.  Can be found at http://bit.ly/a/your_api_key
			set domain      	"j.mp";					# Can be either bit.ly or j.mp
			set login       	"";					# Insert yours.  Can be found at http://bit.ly/a/your_api_key
			set timeout     	60;					# Don't set this too low or else you might not get all the data
		}
		namespace eval dice {
			# Rolls greater than or equal to this number will be considered a success
			set success		9
		}
		namespace eval exec {
			# [0/1] Enables Public/Private output of command, respectively
			set enablepublic	1
			set enablemsg		1
			# User flag for users who can use the commands.  Helps with flooding and attacks
			set flag		"S"
			#Time zone listings can be found at https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
			set times {
					"Los Angeles" "America/Los_Angeles"
					"New York" "America/New_York"
					"London" "Europe/London"
					"Berlin" "Europe/Berlin"
					"Tokyo" "Asia/Tokyo"
			}
		}
		namespace eval fortune {
			# Command for fortune programs
			set path		"/usr/games/fortune"
			# Set your fortune files with this.  Separated by a space
			set options		"fortunes"
		}
		namespace eval opall {
			# Delay in seconds before we voice someone:
			# x:y random delay; minimum x sec, maximum y sec
			set delay		3:10
		}
		namespace eval weather {
			namespace eval binds {
				set forecast	[list forecast wzf]
				set location	[list location setloc wzloc]
				set time	[list time]
				set weather	[list w weather we wz]
			}
			# Bold is \002, Color is \003, Reverse is \026, Underline is \037
			# Valid tokens for are:
			# %alert%, %city%, %current%, %heat_index%, %humidity%, %latitude%, %local_time%, %location%, %longitude%
			# %state_name%, %temp_c%, %temp_f%, %windchill%, %wind_direction%, %wind_kph%, %wind_mph%, %zipcode%
			variable output_format	"%location% \002Current\002: %current% \002Temp\002: %temp_f%/%temp_c% \002Wind\002: %wind_mph%/%wind_kph% (%wind_direction%)%heat_index%%wind_chill% \002Humidity\002: %humidity%%alert%"
			# Valid token is: %warnings%
			variable alert_format	" \002\00301,08Advisory\002: \00304\002%warnings%\002 \00312\037%alert_website%\037\003"
			# Valid tokens are: %location%, %local_time%.
			variable time_format	"%location% \002\Current Date and Time\002: %local_time%."

			# Time, in minutes, weather results should be cached.  This will reduce bandwidth and prevent you from abusing the API. Default: 60 (1 hour)
			set cachetime		60
			# Time, in seconds, to wait for reply.  Default: 60 (1 minute)
			set timeout		60
			# IP Address to remove the need to DNS api.wunderground.com
			set ipaddress		38.102.136.138
		}
		namespace eval wikipedia
			namespace eval binds {
				set wikipedia [list wiki wikipedia]
			}
			set timeout 5
		}
		namespace eval youtube {
			# Time, in minutes, youtube results should be cached.	This will reduce bandwidth and prevent you from abusing the API. Default: 1440 (1 day)
			set cachetime		1440
			set timeout		5
			set retries		12

			# Maximum length for the title and description.	Most IRC servers cut off at ~300 characters, so keep it well below that.
			set max_length		256
			# Valid tokens are %bitly% %botnick% %commentCount% %description% %duration% %ratingCount%
			# %rating% %title% %triggerNick% %uploadedDate% %uploader% %viewCount% %youtubeURI%
			# Most of these should be self explanatory, but here are some that may not be:
			# %botnick%		Nickname of the bot
			# %triggerNick%		Nickname of the person who sent the link
			# %youtube_shorten%	http://youtu.be/VIDEOID
			set output_format	"\002\00301,00You\00300,04Tube\003\002 \"%title%\" (%duration%) By: %uploader%. %viewCount% views since %uploadedDate%. %commentCount% comments. %rating% (%ratingCount% ratings) - \037%youtube_shorten%\037"
		}
	}
}
