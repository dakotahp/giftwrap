SETTINGS = {}
##
# CONFIGURATION START
##

# File types to watch for
SETTINGS.watchFileExt = watchFileExt = ["mkv", "ts", "m2ts", "avi"]

# Move source video files to trash after processing
cleanup = false

# Automatically moves finished file to iTunes' watched folder (~/Music/iTunes/iTunes Media/Automatically Add to iTunes/) 
# and added to iTunes library
automaticallyAddToItunes = true
# By default output file is MOVED to iTunes. Set to true if you want to copy instead and leave file in output folder
copyToItunes = true

# Enable web interface at http://localhost:4000
SETTINGS.webInterface = true

# Watch folder for incoming video files
#   (If you change this folder to a different drive as your boot drive it may cause 
#    issues because of the way Node copies files. Submit a GitHub issue if you run into problems.)
SETTINGS.watchFolder = watchFolder = "./process"

##
# CONFIGURATION END
##


fs              = require 'fs'
http            = require 'http'
path            = require 'path'
watch           = require 'watch'
ffmpeg          = require 'fluent-ffmpeg'
express         = require 'express'
Metalib         = require('fluent-ffmpeg').Metadata
#ProgressBar     = require 'progress'
#bar = new ProgressBar('Processing [:bar] :percent :etas', { total: 100 })
startStopDaemon = require 'start-stop-daemon'


# Libraries

# Queueing mechanism for preventing duplicate system events and processing multiple files
Queue = require("./lib/queue")
queue = new Queue.class()

# Processing library
###
Process = require("./lib/process")
process = new Process.class({
  queue: queue
  ffmpeg: ffmpeg
  addToItunes: automaticallyAddToItunes
  copyToItunes: copyToItunes
})
###




_videoMetadata = {}

_home        = process.env.HOME
iTunesFolder = _home + "/Music/iTunes/iTunes Media/Automatically Add to iTunes/"
trashFolder  = _home + "/.Trash/"

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

_processVideo = () ->
  options = {}
  options.outputExt    = "mp4"
  options.audioBitrate = "384k"
  options.videoCodec = queue.q[queue.current].x_video_codec
  options.audioCodec = queue.q[queue.current].x_audio_codec
  options.source = queue.q[queue.current].file
  options.position = queue.current

  queue.setStart(options.position)

  # Swap original filename with new format
  sourcePath = watchFolder + "/" + options.source
  outputFilename = options.source.replace(/\.[a-z0-9]+$/i, "." + options.outputExt)

  # Remove path from beginning
  outputFile = "output/" + outputFilename

  #.addOption('-sameq')
  proc = new ffmpeg(
    source: sourcePath
    timeout: 60 * 60
  ).withVideoCodec(options.videoCodec)
  .withAudioCodec(options.audioCodec)
  .withAudioBitrate(options.audioBitrate)
  .addOption("-strict", "-2")
  .onProgress( (progress) ->
    console.log progress.percent
    queue.updateProgress(Math.round(progress.percent))
  )
  .toFormat(options.outputExt)
  .saveToFile(outputFile, (retcode, error) ->
    console.log "- File successfully processed to #{outputFile}"
    
    queue.setEnd options.position
    queue.updateStatus "finished", options.position
    
    # retcode, error params are useless
    #queue.updateStatus "error", options.position if error

    # Clean up old file
    console.log '_trashSourceFile', options.source, sourcePath
    _trashSourceFile(sourcePath, sourcePath) if cleanup

    # Move to iTunes inbox folder
    console.log '_moveToItunes', outputFile, outputFilename
    _moveToItunes(outputFile, outputFilename) if automaticallyAddToItunes

    _processVideo() if queue.next()
  )

_moveToItunes = (source, destination) ->
  destinationFile = iTunesFolder + destination
  fs.rename(source, destinationFile, (error) ->
    if error
      console.error(error)
    else
      console.log "- Moved output file to iTunes library folder"
  )

_trashSourceFile = (source, destination) ->
    destinationFile = trashFolder + destination
    fs.rename(source, destinationFile, (error) ->
      if error
        console.error(error)
      else
        console.log "- Moved source file to trash"
    )

_validFiletype = (file) ->
  for i of watchFileExt
    regex = new RegExp("." + watchFileExt[i] + "$", "i")
    return true if file.match(regex)
  false


startStopDaemon({}, () ->
  watch.createMonitor watchFolder, (monitor) ->
    monitor.on "created", (file, stat) ->
      pieces = file.split("/")
      filename = pieces[ pieces.length - 1 ]

      metaObject = new Metalib(file)
      metaObject.get (metadata, err) ->
        return if not _validFiletype(filename)
        _videoMetadata = metadata
        inQueueAlready = queue.in(filename)

        if not inQueueAlready
          queue.add(
            filename: filename
            x_audio_codec: _getAudioCodec(metadata)
            x_video_codec: _getVideoCodec(metadata)
          )
        
        #console.log(require('util').inspect(metadata, false, null))

        # Do not proceed if duplicate file system event
        return if inQueueAlready

        # Let's go!
        _processVideo() if not queue.running

    monitor.on "changed", (file, curr, prev) ->
      pieces = file.split("/")
      filename = pieces[ pieces.length - 1 ]

      metaObject = new Metalib(file)
      metaObject.get (metadata, err) ->
        return if not _validFiletype(filename)
        _videoMetadata = metadata
        inQueueAlready = queue.in(filename)

        if not inQueueAlready
          queue.add(
            filename: filename
            x_audio_codec: _getAudioCodec(metadata)
            x_video_codec: _getVideoCodec(metadata)
          )
        
        #console.log(require('util').inspect(metadata, false, null))

        # Do not proceed if duplicate file system event
        return if inQueueAlready

        # Let's go!
        _processVideo() if not queue.running      
)

app = express()
routes = require("./web/routes")
app.configure ->
  app.set "port", process.env.PORT or 4000
  app.set "views", __dirname + "/web/views"
  app.set "view engine", "ejs"
  app.use express.favicon()
  #app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  #app.use express.cookieParser("your secret here")
  app.use app.router
  app.use express.static(path.join(__dirname, "public"))

app.configure "development", ->
  app.use express.errorHandler()

app.get "/", (req, res) ->
  res.render 'index',
    queue: queue.dump()

app.get "/settings", (req, res) ->
  res.render 'settings',
    settings: SETTINGS

if SETTINGS.webInterface
  http.createServer(app).listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")
