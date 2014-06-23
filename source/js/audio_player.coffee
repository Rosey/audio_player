class @AudioPlayer
  @States:
    Ready: 0
    Playing: 1
    Loading: 2
    Error: 3

  audioPlayerEvents: [
    "abort"
    "error"
    "play"
    "playing"
    "seeked"
    "pause"
    "ended"
    "canplay"
    "loadstart"
    "loadeddata"
    "canplaythrough"
    "seeking"
    "stalled"
    "waiting"
    "progress"
  ]

  constructor: (options) ->
    @setOptions(options)

  setOptions: (options = {}) ->
    for key, value of options
      this[key] = value

    @setEl(options.el) if options.el

  setEl: (el) ->
    @_unbindEvents() if @el
    @el = el
    @_bindEvents()

  updateState:  (e) ->
    state = if @isErrored()
      AudioPlayer.States.Error
    else if @isLoading()
      AudioPlayer.States.Loading
    else if @isPlaying()
      AudioPlayer.States.Playing
    else
      AudioPlayer.States.Ready

    if @state != state
      @state = state
      @ui?.AudioPlayerUpdateState(state)

  isPlaying: ->
    @el && !@el.paused

  isPaused: ->
    @el && @el.paused

  isLoading: ->
    return false if !@state && @isEmpty()
    @el.networkState == @el.NETWORK_LOADING && @el.readyState < @el.HAVE_FUTURE_DATA

  isErrored: ->
    @el.error || @el.networkState == @el.NETWORK_NO_SOURCE

  isEmpty: ->
    @el.readyState == @el.HAVE_NOTHING

  isEnded: ->
    @el.ended

  play: ->
    if @isEmpty()
      @ui?.AudioPlayerUpdateState(AudioPlayer.States.Loading)
    @el.play()

  pause: ->
    @el.pause()

  load: ->
    @el.load()

  duration: ->
    @el.duration

  seekTo: (time) ->
    @el.currentTime = parseInt(time, 10)

  percentComplete: ->
    number = ~~((@el.currentTime / @el.duration)*10000)
    number/10000

  handleEvent: (event) ->
    if event.type in @audioPlayerEvents
      @updateState(event)
    else if event.type == "timeupdate"
      @_timeUpdate(event)

  destroy: ->
    @ui = null
    @_unbindEvents()

  #
  # Private
  #

  _bindEvents: ->
    @el.addEventListener(eventName, this) for eventName in @audioPlayerEvents
    @el.addEventListener("timeupdate", this)

  _unbindEvents: ->
    @el.removeEventListener(eventName, this) for eventName in @audioPlayerEvents
    @el.removeEventListener("timeupdate", this)

  _timeUpdate: (e) ->
    unless @isLoading()
      @ui?.AudioPlayerTimeUpdated?(@percentComplete())
