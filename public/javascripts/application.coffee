jsTimeToSeconds = (jsTime) ->
  return jsTime * .001

jsTimeToMinutes = (jsTime) ->
  return jsTimeToSeconds(jsTime) / 60

jsTimeToHours = (jsTime) ->
  return jsTimeToMinutes(jsTime) / 60

jsTimeToDays = (jsTime) ->
  return jsTimeToHours(jsTime) / 24

relativeTime = (timeInPast) ->
  now = Date.now()
  minutes = jsTimeToMinutes(now - timeInPast)
  hours   = jsTimeToHours(now - timeInPast)
  days    = jsTimeToDays(now - timeInPast)

  return "less than a minute ago"  if Math.round(minutes) is 0
  return "a minute ago"  if Math.round(minutes) is 1
  return "#{Math.round(minutes)} min ago"  if minutes < 45
  return "about 1 hr ago"  if minutes < 90
  return "about #{Math.round(hours)} hrs ago"  if minutes < 1440
  return "1 day ago"  if minutes < 2880
  return "#{Math.round(days)} days ago" if minutes < 43200
  #return "about 1 month ago"  if distance_in_minutes < 86400
  #return (distance_in_minutes / 43200).floor() + " months ago"  if distance_in_minutes < 525960
  #return "about 1 year ago"  if distance_in_minutes < 1051199
  "over " + jsTimeToHours(timeInPast) + " years ago"

$(document).ready( ->

  $("time").each( ->
    time = $(this).text()
    $(this).text( relativeTime(time) )
  )
  @
)
