##
# CONFIGURATION START
##

# File types to watch for
watchFileExt = ["mkv", "ts", "m2ts", "avi"]

# Move source video files to trash after processing
cleanup = true

# Automatically moves finished file to iTunes' watched folder (~/Music/iTunes/iTunes Media/Automatically Add to iTunes/) and added to iTunes library
automaticallyAddToItunes = true

# Enable web interface at http://localhost:5000 - requires redis to be installed or Redis To Go cloud service credentials
web_interface = false

redistogo_url = "" # replace with Redis To Go URL if you don't install redis locally

# Watch folder for incoming video files
#   (If you change this folder to a different drive as your boot drive it may cause issues because of the way Node copies files. Submit a GitHub issue if you run into problems.)
watchFolder = "./process"

##
# CONFIGURATION END
##


fs              = require("fs")
watch           = require("watch")
ffmpeg          = require("fluent-ffmpeg")
Metalib         = require("fluent-ffmpeg").Metadata
ProgressBar     = require('progress')
startStopDaemon = require("start-stop-daemon")

bar = new ProgressBar('Processing [:bar] :percent :etas', { total: 100 })

_videoMetadata = {}
_lastEventTime = 0
_conversionProgress = 0
_home = process.env.HOME

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
  # Video output type
  options.outputExt    = "mp4"
  # Audio output bitrate
  options.audioBitrate = "384k"

  # Swap original filename with new format
  pieces = options.source.split("/")
  sourceFilename = options.source.replace(/^[a-z]+\//i, "")
  outputFilename = options.source.replace(/\.[a-z0-9]+$/i, "." + options.outputExt).replace(/^[a-z]+\//i, "")

  # Remove path from beginning
  outputFile = "output/" + outputFilename

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
  ).toFormat(options.outputExt).saveToFile(outputFile, (retcode, error) ->
    console.log "- File successfully processed to #{outputFile}"

    # Clean up old file
    _trashSourceFile(options.source, sourceFilename) if cleanup

    # Move to iTunes inbox folder
    _moveToItunes(outputFile, outputFilename) if automaticallyAddToItunes
  )

_moveToItunes = (source, destination) ->
  destinationFile = _home + "/Music/iTunes/iTunes Media/Automatically Add to iTunes/#{destination}"
  fs.rename(source, destinationFile, (error) ->
    if error
      console.error(error)
    else
      console.log "- Moved output file to iTunes library folder"
  )

_trashSourceFile = (source, destination) ->
    destinationFile = _home + "/.Trash/#{destination}"
    fs.rename(source, destinationFile, (error) ->
      if error
        console.error(error)
      else
        console.log "- Moved source file to trash"
    )

_copyFileSync = (srcFile, destFile) ->
  BUF_LENGTH = 64*1024
  buff = new Buffer(BUF_LENGTH)
  fdr = fs.openSync(srcFile, 'r')
  fdw = fs.openSync(destFile, 'w')
  bytesRead = 1
  pos = 0
  while bytesRead > 0
    bytesRead = fs.readSync(fdr, buff, 0, BUF_LENGTH, pos)
    fs.writeSync(fdw,buff,0,bytesRead)
    pos += bytesRead
  fs.closeSync(fdr)
  fs.closeSync(fdw)


_validFiletype = (file) ->
  for i of watchFileExt
    regex = new RegExp("." + watchFileExt[i] + "$", "i")
    return true  if file.match(regex)
  false

_notDuplicateEvent = ->
  new Date().getTime() - _lastEventTime < 20

startStopDaemon({}, () ->
  watch.createMonitor watchFolder, (monitor) ->
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
