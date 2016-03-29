castReveivers = {}
session = undefined
APP_ID = '6684D5DF'
namespace = 'urn:x-cast:chrome.cast'

window.__onGCastApiAvailable = (loaded, errorInfo) ->
  console.debug '__onGCastApiAvailable'
  if loaded
    console.debug 'initializing cast api'
    initializeCastApi()
  else
    console.error errorInfo

initializeCastApi = ->
  console.debug 'initializeCastApi'
  sessionRequest = new chrome.cast.SessionRequest(APP_ID)
  apiConfig = new chrome.cast.ApiConfig sessionRequest, sessionListener, receiveListener
  chrome.cast.initialize apiConfig, onInitSuccess, onError

sessionListener = (e) ->
  console.debug "New session ID: #{e.sessionId}"
  session = e
  session.addUpdateListener sessionUpdateListener
  session.addMessageListener namespace, receiverMessage

loggerMethod = (name) ->
  window[name] = (args...) ->
    console.debug name, args...

loggerMethod(name) for name in 'onInitSuccess onError receiverMessage receiveListener onRequestSessionSuccess onLaunchError'.split(' ')

requestSession = ->
  chrome.cast.requestSession onRequestSessionSuccess, onLaunchError
