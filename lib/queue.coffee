class Queue
  constructor: ->
    @q = []

  add: (filename) ->
    console.log "Q: adding "+filename
    @q.push filename

  delete: (filename) ->
    @q[filename]

  in: (filename) ->
    for currentFilename in @q
      return true if currentFilename is filename

    false

  dump: ->
    return @q

exports.class = Queue
