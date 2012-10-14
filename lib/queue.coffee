# Statuses: queued, started, finished, error

class Queue
  constructor: ->
    @q = []
    @current = 0
    @running = false

  add: (options) ->
    @q.push 
      file: options.filename
      priority: 0
      progress: 0
      status: 'queued'
      processing_started: 0
      processing_ended: 0
      created_at: Date.now()
      x_audio_codec: options.x_audio_codec
      x_video_codec: options.x_video_codec

    @current = @q.length - 1
    @current

  next: ->
    for current in @q
      if current.status is 'queued'
        @current = _i
        return current
    false

  delete: (id) ->
    delete @q[id]

  in: (filename) ->
    for current in @q
      return true if current.file is filename
    false

  dump: ->
    return @q

  updateProgress: (progress) ->
    @q[@current].progress = progress

  updateStatus: (status) ->
    @q[@current].status = status

  setStart: ->
    @q[@current].processing_started = Date.now()
    @q[@current].status = "started"
    @running = true

  setEnd: ->
    @q[@current].processing_ended = Date.now()
    @q[@current].status = "finished"
    @running = false

exports.class = Queue
