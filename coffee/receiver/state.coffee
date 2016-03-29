class StateHandler
  sendMessage: (message) ->
    console.debug 'StateHandler message:', message, @current
    @current.onMessage(message)

  resetState: (state) ->
    console.debug 'resetState', state, @initialState
    if state?
      @current = new state()
      @initialState = state
    else
      @current = new @initialState()

  setState: (@current) ->

class StateDefinition
  constructor: ({@handler = window.stateHandler} = {}) ->

  onMessage: (message) ->
    @handler.resetState()

class SplashState extends StateDefinition
  constructor: ({@handler = window.stateHandler} = {}) ->
    @splash = document.createElement('div')
    @splash.id = 'splash'
    @splash.innerHTML = '<img src="/static/images/logo.png" /><audio autoplay id="splash-sound" src="/static/sounds/wheel.mp3"></audio>'

    document.body.appendChild(@splash)

    super

  onMessage: ->
    ($ @splash).fadeOut(400)
    ($ '#splash-sound').animate volume: 0, 5000
    setTimeout =>
      ($ @splash).remove()
      @handler.resetState(RootState)
    , 5000

class RootState extends StateDefinition
  strength_messages: ['Did you do something?', 'LOOSER!', 'Ah..', "Well..It's something", 'Better', 'OK', "Now we're talking!", 'You are the MAN (or woman!)', 'Great!', 'Awesome!', 'You must be really good in the sack!', 'WOW!', 'You must be cheating...' , "IT'S OVER 9000!!!" ,'Is it Chuck Norris?']

  onMessage: (message) ->
    if 'spinWheel' of message and not wheelSpinning
      wheel.spin(message.spinWheel)
      @setMarker(message.spinWheel)

  setMarker: (velocity) ->
    y = Math.abs(velocity) / 15 * 100
    $('#marker').css bottom: (y / 2) + 'vh'
    style = if 15 > y
      'blue'
    else if 15 < y < 50
      'green'
    else if 50 < y < 80
      'yellow'
    else
      'red'
    $('#marker-line').removeClass 'blue green yellow red'
    $('#marker-line').addClass style
    $('#strength-message').text @strength_messages[parseInt(velocity)]

    setTimeout ->
      $('#marker-line').removeClass 'blue green yellow red'
      $('#marker-line').addClass 'blue'
      $('#marker').css bottom: '0vh'
      $('#strength-message').text ''
    , 4000

class DialogState extends StateDefinition
  id: null
  constructor: ({@content = '', @size = 'md', @classes = '', @data = {}} = {}) ->
    throw Error "Must provide id in prototype" unless @id?
    displayText JSON.stringify {@content, @size, @classes}
    super
    modal = document.createElement('div')
    modal.className = 'modal fade in'
    modal.id = @id
    modal.setAttribute 'role', 'dialog'
    modalDialog = document.createElement('div')
    modalDialog.className = "modal-dialog modal-#{@size} #{@classes}"
    modalContent = document.createElement('div')
    modalContent.className = 'modal-content'
    modal.setAttribute 'role', 'document'
    modalContent.innerHTML = "<h1>#{@_getContent()}</h1>"

    modalDialog.appendChild(modalContent)
    modal.appendChild(modalDialog)
    document.body.appendChild(modal)

    @modal = $("##{@id}")

    @modal.modal('show')

  _getContent: ->
    if typeof @content is 'function'
      @content = @content()
    @content

  _refreshContent: ->
    @modal.find('.modal-content').html @_getContent()

  _setSize: (@size) ->
    @modal
      .find('.modal-dialog')
      .removeClass('modal-xs modal-sm modal-md modal-lg modal-xl')
      .addClass("modal-#{@size}")

  onMessage: ->
    @_closeModal()
    super

  _closeModal: ->
    @modal.modal('hide')
    setTimeout =>
      @modal.remove()
    , 1000

class DrinkState extends DialogState
  id: 'drink-modal'

class YouTubeState extends DialogState
  id: 'youtube-modal'

  constructor: ->
    super
    @playing = no
    @_setSize('lg')

  _getContent: ->
    i = Math.floor(Math.random() * @data.videos.length)
    """
      <h2>#{@content}</h2>
      <iframe id="ytplayer-#{@id}" type="text/html" width="640" height="390"
      src="http://www.youtube.com/embed/#{@data.videos[i]}"
      frameborder="0"/>
    """

  onMessage: ->
    if not @playing
      $("#ytplayer-#{@id}")[0].src += "?autoplay=1"
      @playing = yes
    else
      $("#ytplayer-#{@id}")[0].src = ''
      super

class TimeoutState extends DialogState
  id: 'timeout'
  step: 0

  constructor: (options) ->
    super

  _getContent: ->
    switch @step
      when 0
        """
        <h1>#{@_competitorsImages()}</h1>
        <h2>You have #{@data.seconds} seconds to drink as much beer as you can!</h2>
        """
      when 1
        """
        <h2>#{@_competitorsImages()}</h2>
        <h1>#{@_toTimeStr(@data.seconds)}</h1>
        """
      else
        "<h1>Time's up!</h1>"

  _randomizeCompetitors: ->
    amount = Math.round(Math.random())
    names = 'Amit Avihad Chen Dor Eran Lior Michael Tom Zeevi'.split(' ')
    return _.shuffle(names).slice(0, amount + 2)

  _competitorsImages: ->
    @data.competitors = @_randomizeCompetitors() unless @data.competitors?
    @data.competitors
      .map (c) -> "<img src=\"/static/images/#{c.toLowerCase()}.png\" />"
      .join(' vs ')

  _startTimeout: ->
    @interval = window.setInterval =>
      @data.seconds -= 1
      @_refreshContent()
      if @data.seconds < 0
        clearInterval @interval
        @step++
        @_refreshContent()
    , 1000

  onMessage: ->
    return if @step is 1

    switch @step
      when 0
        @_startTimeout()
        @step++
      when 2
        super
        return

  _contentTemplate: (competitors, time) ->

  _toTimeStr: (secs) ->
    hours = Math.floor secs / 3600
    minutes = Math.floor (secs - (hours * 3600)) / 60
    seconds = secs - (hours * 3600) - (minutes * 60)

    # hours = "0#{hours}" if hours < 10
    minutes = "0#{minutes}" if minutes < 10
    seconds = "0#{seconds}" if seconds < 10

    "#{minutes}:#{seconds}"
