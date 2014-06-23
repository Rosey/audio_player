class @AudioPlayerUI
  transitionEvents: [
    "transitionend"
    "webkitTransitionEnd"
    "MSTransitionEnd"
    "oTransitionEnd"
  ]

  constructor: (options = {}) ->
    @setOptions(options)
    @audioPlayer = new AudioPlayer({ui: this})
    @_createAudioEl()
    @_createImageEl()
    @setEl(options.el) if options.el
    @goToSong(0)

  setOptions: (options) ->
    for key, value of options
      this[key] = value

  setEl: (el) ->
    @_unbindEvents()
    @el = el
    @$el = $(@el)
    @$el.append(@audioEl)
    @$imageContainer = @$el.find(".audio-player-image")
    @$imageContainer.append(@image)
    @$progressContainer = @$el.find(".audio-player-progress")
    @$progressBar = @$el.find(".audio-player-progress-bar")
    @$button = @$el.find(".audio-player-place-pause-button")
    @$backButton = @$el.find(".icon-backward")
    @$nextButton = @$el.find(".icon-forward")
    @$name = @$el.find(".audio-player-song-name")
    @_bindEvents()

  togglePlayPause: ->
    if @audioPlayer.isPlaying()
      @audioPlayer.pause()
    else
      @audioPlayer.play()

  goToSong: (index) ->
    @currentSong = index
    wasPlaying = @audioPlayer.isPlaying()
    @_updateSourceAttributes(index)
    @_updateImageAttributes(index)
    @$name[0].innerHTML = @songs[index].name
    @audioPlayer.setEl(@audioEl)
    @$progressBar.css({width: 0})
    @audioPlayer.load()
    @audioPlayer.play() if wasPlaying

  nextSong: ->
    if @currentSong == @songs.length - 1
      @goToSong(0)
    else
      @goToSong(@currentSong + 1)

  previousSong: ->
    if @currentSong == 0
      @goToSong(@songs.length - 1)
    else
      @goToSong(@currentSong - 1)

  seek: (e) ->
    if offset = e.offsetX || e.originalEvent?.layerX
      percent = (offset / @$progressContainer.width())
      duration = @audioPlayer.duration()
      seekTo = duration * percent
      @audioPlayer.seekTo(seekTo)

  #
  # Audio Player UI Functions
  #

  AudioPlayerUpdateState: ->
    @$el.toggleClass("error", @audioPlayer.isErrored())
    @$progressContainer.toggleClass("loading", @audioPlayer.isLoading())

    if @audioPlayer.isPlaying()
      @$button.removeClass("icon-play").addClass("icon-pause")
    else
      @$button.removeClass("icon-pause").addClass("icon-play")

    if @audioPlayer.isEnded() && @currentSong != @songs.length - 1
      @nextSong()
      @audioPlayer.play()

  AudioPlayerTimeUpdated: (percentComplete) ->
    @$progressBar.css({width: "#{percentComplete*100}%"})

  #
  # Private
  #

  _createImageEl: ->
    @image = document.createElement("img")

  _createAudioEl: ->
    @audioEl = document.createElement("audio")

  _updateSourceAttributes: (index) ->
    @audioEl.removeChild(@audioEl.firstChild) while @audioEl.firstChild

    for source in @songs[index].srcs
      sourceEl = document.createElement("source")
      sourceEl.setAttribute("src", source.src)
      sourceEl.setAttribute("type", source.type)
      @audioEl.appendChild(sourceEl)

  _updateImageAttributes: (index) ->
    callback = =>
      @image.removeAttribute("class")
      $(@image).off(@transitionEvents.join(" "))
      @image.setAttribute("src", @songs[index].image)
      setTimeout(=>
        @$imageContainer[0].removeChild(secondImage) if secondImage
      , 500)

    if Modernizr.csstransitions && @$imageContainer && @image.getAttribute("src")
      secondImage = document.createElement("img")
      secondImage.setAttribute("src", @songs[index].image)
      @image.setAttribute("class", "fading")
      @$imageContainer.append(secondImage)
      $(@image).on(@transitionEvents.join(" "), callback)
    else
      callback()

  _bindEvents: ->
    @$button.on("click", $.proxy(this, "togglePlayPause"))
    @$backButton.on("click",$.proxy(this, "previousSong"))
    @$nextButton.on("click",$.proxy(this, "nextSong"))
    @$progressContainer.on("mouseup", $.proxy(this, "seek"))

  _unbindEvents: ->
    @$button?.off("click", @togglePlayPause)
    @$backButton?.off("click", @previousSong)
    @$nextButton?.off("click", @nextSong)
    @$progressContainer?.off("mouseup", @seek)

@audioPlayer = new AudioPlayerUI({
  el: document.getElementById("audio-player")
  songs: [
    {
      image: "images/sunhawk-small@2x.jpg"
      name: "Sunhawk - She Snake Shuffle"
      srcs: [
        {
          src:"SheSnake.mp3"
          type: "audio/mp3"
        }
      ]
    }
    {
      image: "images/sunhawk-small-2@2x.jpg"
      name: "Sunhawk - Shotgun Love"
      srcs: [
        {
          src:"ShotgunLove.mp3"
          type: "audio/mp3"
        }
        {
          src:"ShotgunLove.m4a"
          type: "audio/mp4"
        }
        {
          src:"ShotgunLove.ogg"
          type: "audio/ogg"
        }
      ]
    }
  ]
})
