# Statuses: queued, started, finished, error

class Queue
  constructor: ->
    @q = []
    @current = 0

  add: (filename) ->
    timestamp = Date.now()
    @q.push 
      file: filename
      priority: 0
      progress: 0
      status: 'queued'
      processing_started: 0
      processing_ended: 0
      created_at: timestamp
    @current = @q.length - 1
    @current

  next: ->
    for current in @q
      if current.status is 'queued'
        @current = _i
        return current

  delete: (id) ->
    delete @q[id]

  in: (filename) ->
    for current in @q
      return true if current.file is filename
    false

  dump: ->
    return @q

  updateProgress: (progress, current) ->
    @q[current].progress = progress

  updateStatus: (status, current) ->
    @q[current].status = status

  setStart: (current) ->
    @q[current].processing_started = Date.now()
    @q[current].status = "started"

  setEnd: (current) ->
    @q[current].processing_ended = Date.now()
    @q[current].status = "finished"

exports.class = Queue
