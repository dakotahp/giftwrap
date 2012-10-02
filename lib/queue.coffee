# Statuses: queued, started, finished, error

class Queue
  constructor: ->
    @q = []
    @autoIncrement = 0

  add: (filename) ->
    timestamp = Math.round(Date.now() * .001)
    @q[@autoIncrement] = 
      file: filename
      created_at: timestamp
      processing_started: null
      processing_ended: null
      status: 'queued'

    @autoIncrement++

  delete: (id) ->
    delete @q[id]

  in: (filename) ->
    for current in @q
      return true if current.file is filename

    false

  dump: ->
    return @q

exports.class = Queue
