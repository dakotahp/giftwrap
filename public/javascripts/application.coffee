Queue:
  getStatusClass: (status) ->
    return "label-success" if status is "finished"
    return "label-error"   if status is "error"
    return ""


createRefreshTimeout = ->
  setTimeout( ->
    window.location.reload(true)
  , 30000)  

refreshTimeout = createRefreshTimeout()
refreshTimeoutStatus = true

jsTimeToDateTime = (jsTime) ->
  

jsTimeToSeconds = (jsTime) ->
  return jsTime * .001

jsTimeToMinutes = (jsTime) ->
  return Math.round(jsTimeToSeconds(jsTime) / 60)

jsTimeToHours = (jsTime) ->
  return Math.round(jsTimeToMinutes(jsTime) / 60)

jsTimeToDays = (jsTime) ->
  return Math.round(jsTimeToHours(jsTime) / 24)

relativeTime = (timeInPast) ->
  now = Date.now()
  minutes = jsTimeToMinutes(now - timeInPast)
  hours   = jsTimeToHours(now - timeInPast)
  days    = jsTimeToDays(now - timeInPast)

  return "less than a minute ago"  if minutes is 0
  return "a minute ago"  if minutes is 1
  return "#{minutes} min ago"  if minutes < 45
  return "about 1 hr ago"  if minutes < 90
  return "about #{hours} hrs ago"  if minutes < 1440
  return "1 day ago" if minutes < 2880
  return "#{days} days ago" if minutes < 43200
  #return "about 1 month ago"  if distance_in_minutes < 86400
  #return (distance_in_minutes / 43200).floor() + " months ago"  if distance_in_minutes < 525960
  #return "about 1 year ago"  if distance_in_minutes < 1051199
  "over " + jsTimeToHours(timeInPast) + " years ago"

loadSettings = ->


$(document).ready( ->
  $("#auto-refresh").button('toggle')
  $("#auto-refresh").click( ->
    if refreshTimeoutStatus
      clearTimeout(refreshTimeout)
      refreshTimeoutStatus = false
    else
      refreshTimeout = createRefreshTimeout()
      refreshTimeoutStatus = true
    true
  )

  $("time.relative").each( ->
    time = $(this).text()
    $(this).text( relativeTime(time) )
  )
  $("time.elapsed").each( ->
    time = $(this).text()
    $(this).text( jsTimeToMinutes(time) + " min" )
  )
  @
)
