watch = require("watch")
ffmpeg = require("fluent-ffmpeg")
Metalib = require("fluent-ffmpeg").Metadata
ProgressBar = require('progress')
startStopDaemon = require("start-stop-daemon")

bar = new ProgressBar('Processing [:bar] :percent :etas', { total: 100 })

watchFileExt = ["mkv", "ts", "m2ts", "avi"]
_videoMetadata = {}
_lastEventTime = 0
_conversionProgress = 0
_getFfmpegProfile = (file, callback) ->
  ffmpeg.call ["-i " + file], (params, params2) ->
    console.log params, params2
    callback()  if typeof callback is "function"


_getAudioCodec = (metadata) ->
  metadata = _videoMetadata  if metadata is `undefined`

  # Transmux audio if it's already AAC
  if metadata.audio.codec is "aac"
    "copy"
  else
    "aac"

_getVideoCodec = (metadata) ->
  metadata = _videoMetadata  if metadata is `undefined`

  # Transmux video if it's already h264
  if metadata.video.codec is "h264"
    "copy"
  else
    "libx264"

_processVideo = (options) ->
  options.outputExt = "mp4"
  options.audioBitrate = "384k"

  outputFilename = options.source.replace(/\.[a-z0-9]+$/i, "." + options.outputExt)

  # remove path from beginning
  outputFilename = "output/" + outputFilename.replace(/^[a-z]+\//i, "")

  #.addOption('-sameq')
  proc = new ffmpeg(
    source: options.source
    timeout: 60 * 60
  ).withVideoCodec(options.videoCodec).withAudioCodec(options.audioCodec).withAudioBitrate(options.audioBitrate).addOption("-strict", "-2").onProgress((progress) ->
    localProgress = Math.round progress.percent
    #console.log "Progress: " + localProgress.toString() + "%" if localProgress > _conversionProgress
    #bar.tick if localProgress > _conversionProgress
    #bar.tick progress.percent
    _conversionProgress = localProgress
  ).toFormat(options.outputExt).saveToFile(outputFilename, (retcode, error) ->
    console.log "SUCCESS: File processed to " + outputFilename + "\n"
  )

_validFiletype = (file) ->
  for i of watchFileExt
    regex = new RegExp("." + watchFileExt[i] + "$", "i")
    return true  if file.match(regex)
  false

_notDuplicateEvent = ->
  new Date().getTime() - _lastEventTime < 20


startStopDaemon({}, () ->
  watch.createMonitor "./process", (monitor) ->
    monitor.on "created", (file, stat) ->
      return if not _validFiletype(file) or _notDuplicateEvent()
      metaObject = new Metalib(file)
      metaObject.get (metadata, err) ->
        _videoMetadata = metadata

        #console.log(require('util').inspect(metadata, false, null));
        console.log "########", "Starting to process " + file
        _processVideo
          source: file
          audioCodec: _getAudioCodec(metadata)
          videoCodec: _getVideoCodec(metadata)


      _lastEventTime = new Date().getTime()

    monitor.on "changed", (file, curr, prev) ->
      for i of watchFileExt
        re = new RegExp("." + watchFileExt[i] + "$", "i")
        if file.match(re)
          metaObject = new Metalib(file)
          metaObject.get (metadata, err) ->
            #_videoMetadata = metadata
)
