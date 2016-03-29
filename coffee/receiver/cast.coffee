# utility function to display the text message in the input field

displayText = (text) ->
  console.log text
  document.getElementById('message').innerHTML = text
  window.castReceiverManager.setApplicationState text

window.addEventListener 'load', ->
  cast.receiver.logger.setLevelValue 0
  window.castReceiverManager = cast.receiver.CastReceiverManager.getInstance()
  console.log 'Starting Receiver Manager'
  # handler for the 'ready' event

  castReceiverManager.onReady = (event) ->
    console.log 'Received Ready event: ' + JSON.stringify(event.data)
    window.castReceiverManager.setApplicationState 'Application status is ready...'

  # handler for 'senderconnected' event

  castReceiverManager.onSenderConnected = (event) ->
    console.log 'Received Sender Connected event: ' + event.data
    console.log window.castReceiverManager.getSender(event.data).userAgent

  # handler for 'senderdisconnected' event

  castReceiverManager.onSenderDisconnected = (event) ->
    console.log 'Received Sender Disconnected event: ' + event.data
    if window.castReceiverManager.getSenders().length == 0
      window.close()

  # handler for 'systemvolumechanged' event

  castReceiverManager.onSystemVolumeChanged = (event) ->
    console.log 'Received System Volume Changed event: ' + event.data['level'] + ' ' + event.data['muted']

  # create a CastMessageBus to handle messages for a custom namespace
  window.messageBus = window.castReceiverManager.getCastMessageBus('urn:x-cast:com.castroulette')
  # handler for the CastMessageBus message event

  window.messageBus.onMessage = (event) ->
    data = if typeof event.data is 'object' then event.data else (JSON.parse(event.data) ? null)
    console.log 'Message [' + event.senderId + ']: ', data
    # display the message from the sender
    displayText JSON.stringify(data)

    if 'spinWheel' of data
      spinWheel(data.spinWheel)
    # inform all senders on the CastMessageBus of the incoming message event
    # sender message listener will be invoked
    window.messageBus.send event.senderId, event.data

  window.spinWheel = (velocity) ->
    console.debug 'spinWheel', {wheelSpinning, wheelStopped}
    wheel.spin(velocity)

  # initialize the CastReceiverManager with an application status message
  window.castReceiverManager.start statusText: 'Application is starting'
  console.log 'Receiver Manager started'
  return
