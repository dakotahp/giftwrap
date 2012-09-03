var watch = require("watch")
var ffmpeg = require("fluent-ffmpeg")
var Metalib = require("fluent-ffmpeg").Metadata;

var watchFileExt = ['mkv', '2t', 'm2ts'],
    _videoMetadata = {},
    _lastEventTime = 0

var _getFfmpegProfile = function(file, callback)
{
  ffmpeg.call([
        "-i " + file
      ],
      function(params, params2) {
        console.log(params, params2)
        if( typeof callback == 'function' )
          callback()
      }
  )
}


var _getAudioCodec = function(metadata)
{
  if( metadata == undefined )
    metadata = _videoMetadata

  // Transmux audio if it's already AAC
  if( metadata.audio.codec == 'aac' )
    return 'copy'
  else
    return 'aac'
}

var _getVideoCodec = function(metadata)
{
  if( metadata == undefined )
    metadata = _videoMetadata

  // Transmux video if it's already h264
  if( metadata.video.codec == 'h264' )
    return 'copy'
  else
    return 'libx264'
}


var _processVideo = function(options) {
  options.outputExt = 'mp4',
  options.audioBitrate = '384k'

  outputFilename = options.source.replace(/\.[a-z0-9]+$/i, '.'+options.outputExt)
  // remove path from beginning
  outputFilename = 'output/' + outputFilename.replace(/^[a-z]+\//i, '')

  var proc = new ffmpeg({source: options.source, timeout: 60 * 60})
    .withVideoCodec(options.videoCodec)
    .withAudioCodec(options.audioCodec)
    .withAudioBitrate(options.audioBitrate)
    //.addOption('-sameq')
    .addOption('-strict', '-2')
    .onProgress(function(progress) {
      console.log('Progress: ' + progress)
    })
    .toFormat(options.outputExt)
    .saveToFile(outputFilename, function(retcode, error) {
      console.log("SUCCESS: File processed to " + outputFilename + "\n")
    })
}

var _validFiletype = function(file) {
  for( var i in watchFileExt )
  {
    var regex = new RegExp('\.' + watchFileExt[i] + '$', 'i')
    if( file.match(regex) ) {
      return true
    }
  }
  return false
}

var _notDuplicateEvent = function() {
  return new Date().getTime() - _lastEventTime < 20
}


watch.createMonitor('./process', function (monitor) {
    monitor.on("created", function (file, stat) {
      // if file is a video file and event happended more than 20 milliseconds ago
      //   since last event
      if( !_validFiletype(file) || _notDuplicateEvent() )
        return

      var metaObject = new Metalib(file)
      metaObject.get(function(metadata,err) {
        _videoMetadata = metadata

        //console.log(require('util').inspect(metadata, false, null));

        console.log("########", "Starting to process " + file)
        _processVideo({
          source: file,
          audioCodec: _getAudioCodec(metadata),
          videoCodec: _getVideoCodec(metadata)
        })
      })
      _lastEventTime = new Date().getTime()
    })


    monitor.on("changed", function (file, curr, prev) {
      for( var i in watchFileExt ) {
        var re = new RegExp('\.' + watchFileExt[i] + '$', 'i')
        if( file.match(re) ) {
          var metaObject = new Metalib(file)
          metaObject.get(function(metadata,err) {
            //_videoMetadata = metadata
          })
        }
      }
    })


    monitor.on("removed", function (file, stat) {
    })
})

