# MAJOR THANKS TO http://codepen.io/zadvorsky/pen/xzhBw

TWO_PI = Math.PI * 2
HALF_PI = Math.PI * 0.5
# canvas settings
viewWidth = 1200
viewHeight = 1200
viewCenterX = viewWidth * 0.5
viewCenterY = viewHeight * 0.5
drawingCanvas = undefined
ctx = undefined
timeStep = 1 / 60
time = 0
ppm = 54
physicsWidth = viewWidth / ppm
physicsHeight = viewHeight / ppm
physicsCenterX = physicsWidth * 0.5
physicsCenterY = physicsHeight * 0.5
world = undefined
wheel = undefined
arrow = undefined
mouseBody = undefined
mouseConstraint = undefined
arrowMaterial = undefined
pinMaterial = undefined
contactMaterial = undefined
wheelSpinning = false
wheelStopped = true
particles = []
statusLabel = document.getElementById('status_label')
segConfig = [
  {
    text: 'Drink with Zeevi'
    winState: YouTubeState
    stateOptions:
      content: 'dQw4w9WgXcQ'
      size: 'lg'
  }
  {
    text: 'Beer Match!'
    winState: TimeoutState
    stateOptions:
      data:
        competitorsFunc: ->
          amount = Math.round(Math.random())
          names = 'Amit Avihad Chen Dor Eran Lior Michael Tom Zeevi'.split(' ')
          _.shuffle(names)[0...amount + 2]
  }
  {
    text: 'Drink with Chen'
    winState: DrinkState
    stateOptions:
      content: 'Drink with Chen'
  }
  {
    text: 'Drink with Dor'
    winState: DrinkState
    stateOptions:
      content: 'Drink with Dor'
  }
  {
    text: 'Drink with Amit'
    winState: DrinkState
    stateOptions:
      content: 'Drink with Amit'
  }
  {
    text: 'Drink with Alon'
    winState: DrinkState
    stateOptions:
      content: 'Drink with Alon'
  }
  {
    text: 'Drink with Eran'
    winState: DrinkState
    stateOptions:
      content: 'Drink with Eran'
  }
  {
    text: 'Drink with Lior'
    winState: DrinkState
    stateOptions:
      content: 'Drink with Lior'
  }
]

initDrawingCanvas = ->
  drawingCanvas = document.getElementById('drawing_canvas')
  drawingCanvas.width = viewWidth
  drawingCanvas.height = viewHeight
  ctx = drawingCanvas.getContext('2d')
  drawingCanvas.addEventListener 'mousemove', updateMouseBodyPosition
  drawingCanvas.addEventListener 'mousedown', checkStartDrag
  drawingCanvas.addEventListener 'mouseup', checkEndDrag
  drawingCanvas.addEventListener 'mouseout', checkEndDrag

updateMouseBodyPosition = (e) ->
  p = getPhysicsCoord(e)
  mouseBody.position[0] = p.x
  mouseBody.position[1] = p.y

checkStartDrag = (e) ->
  if world.hitTest(mouseBody.position, [ wheel.body ])[0]
    mouseConstraint = new (p2.RevoluteConstraint)(mouseBody, wheel.body,
      worldPivot: mouseBody.position
      collideConnected: false)
    world.addConstraint mouseConstraint
  # if wheelSpinning == true
  #   wheelSpinning = false
  #   wheelStopped = true
  #   statusLabel.innerHTML = 'Impatience will not be rewarded.'

checkEndDrag = (e) ->
  if mouseConstraint
    world.removeConstraint mouseConstraint
    mouseConstraint = null
    if wheelSpinning == false and wheelStopped == true
      if Math.abs(wheel.body.angularVelocity) > 4.5
        wheelSpinning = true
        wheelStopped = false
        console.log 'good spin'
        statusLabel.innerHTML = '...clack clack clack clack clack clack...'
      else
        console.log 'sissy'
        statusLabel.innerHTML = 'Come on, you can spin harder than that.'

getPhysicsCoord = (e) ->
  rect = drawingCanvas.getBoundingClientRect()
  x = (e.clientX - (rect.left)) / ppm
  y = physicsHeight - ((e.clientY - (rect.top)) / ppm)
  {
    x: x
    y: y
  }

initPhysics = ->
  world = new (p2.World)
  world.solver.iterations = 100
  world.solver.tolerance = 0
  arrowMaterial = new (p2.Material)
  pinMaterial = new (p2.Material)
  contactMaterial = new (p2.ContactMaterial)(arrowMaterial, pinMaterial,
    friction: 0.0
    restitution: 0.1)
  world.addContactMaterial contactMaterial
  wheelRadius = 8
  wheelX = physicsCenterX
  wheelY = wheelRadius + 4
  arrowX = wheelX
  arrowY = wheelY + wheelRadius + 0.625
  wheel = new Wheel(wheelX, wheelY, wheelRadius, segConfig.length, (seg.text for seg in segConfig), 0.25, 7.5)
  wheel.body.angle = Math.PI / 32.5
  wheel.body.angularVelocity = 0.2
  arrow = new Arrow(arrowX, arrowY, 0.5, 1.5)
  mouseBody = new (p2.Body)
  world.addBody mouseBody

spawnPartices = ->
  i = 0
  while i < 200
    p0 = new Point(viewCenterX, viewCenterY - 64)
    p1 = new Point(viewCenterX, 0)
    p2 = new Point(Math.random() * viewWidth, Math.random() * viewCenterY)
    p3 = new Point(Math.random() * viewWidth, viewHeight + 64)
    particles.push new Particle(p0, p1, p2, p3)
    i++

update = ->
  particles.forEach (p) ->
    p.update()
    if p.complete
      particles.splice particles.indexOf(p), 1
  # p2 does not support continuous collision detection :(
  # but stepping twice seems to help
  # considering there are only a few bodies, this is ok for now.
  world.step timeStep * 0.5
  world.step timeStep * 0.5
  # console.debug 'update', {wheelSpinning, wheelStopped, angularVelocity: wheel.body.angularVelocity, arrowHasStopped: arrow.hasStopped()}
  if wheelSpinning and not wheelStopped and wheel.body.angularVelocity < 0.5 and arrow.hasStopped()
    currentSeg = wheel.currentSegment()
    wheelStopped = true
    wheelSpinning = false
    seg = segConfig[currentSeg]
    if seg.winState
      stateHandler.setState new seg.winState seg.stateOptions

draw = ->
  # ctx.fillStyle = '#fff';
  ctx.clearRect 0, 0, viewWidth, viewHeight
  wheel.draw()
  arrow.draw()
  particles.forEach (p) ->
    p.draw()

do_loop = ->
  update()
  draw()
  requestAnimationFrame do_loop

#///////////////////////////
# wheel of fortune
#///////////////////////////

class Wheel
  constructor: (@x, @y, @radius, @segments, @segmentTexts, @pinRadius, @pinDistance) ->
    @pX = @x * ppm
    @pY = (physicsHeight - (@y)) * ppm
    @pRadius = @radius * ppm
    @pPinRadius = @pinRadius * ppm
    @pPinPositions = []
    @deltaPI = TWO_PI / @segments
    @createBody()
    @createPins()

  createBody: ->
    @body = new (p2.Body)(
      mass: 1
      position: [
        @x
        @y
      ])
    @body.angularDamping = 0.0
    @body.addShape new (p2.Circle)(@radius)
    @body.shapes[0].sensor = true
    #TODO use collision bits instead
    axis = new (p2.Body)(position: [
      @x
      @y
    ])
    constraint = new (p2.LockConstraint)(@body, axis)
    constraint.collideConnected = false
    world.addBody @body
    world.addBody axis
    world.addConstraint constraint

  createPins: ->
    l = @segments
    pin = new (p2.Circle)(@pinRadius)
    pin.material = pinMaterial
    i = 0
    while i < l
      x = Math.cos(i / l * TWO_PI) * @pinDistance
      y = Math.sin(i / l * TWO_PI) * @pinDistance
      @body.addShape pin, [
        x
        y
      ]
      @pPinPositions[i] = [
        x * ppm
        -y * ppm
      ]
      i++

  gotLucky: ->
    @currentSegment() % 2 == 0

  currentSegment: ->
    currentRotation = wheel.body.angle % TWO_PI
    segNum = currentRotation / @deltaPI
    (@segments + Math.floor(segNum)) % @segments

  spin: (velocity) ->
    wheel.body.angularVelocity = velocity
    wheelSpinning = true
    wheelStopped = false

  draw: ->
    # TODO this should be cached in a canvas, and drawn as an image
    # also, more doodads
    ctx.save()
    ctx.translate @pX, @pY
    ctx.beginPath()
    ctx.fillStyle = '#DB9E36'
    ctx.arc 0, 0, @pRadius + 24, 0, TWO_PI
    ctx.fill()
    # ctx.fillRect -12, 0, 24, 400
    # drawing usually starts at 90 deg. so we reduced it from the rotation
    # so that the 0 deg segment is the 0 index and not the 90 deg one
    ctx.rotate -@body.angle - (@deltaPI * (@segments / 4))
    i = 0
    while i < @segments
      ctx.save()
      ctx.fillStyle = if i % 2 == 0 then '#BD4932' else '#FFFAD5'
      ctx.beginPath()
      ctx.arc 0, 0, @pRadius, i * @deltaPI, (i + 1) * @deltaPI
      ctx.lineTo 0, 0
      ctx.closePath()
      ctx.fill()

      if @segmentTexts[i].length
        ctx.rotate (i + (3/5)) * @deltaPI
        ctx.font = '30px sans-serif'
        ctx.fillStyle = '#000000'
        ctx.fillText(@segmentTexts[i], 70, 3, 280)

      ctx.restore()
      i++
    ctx.fillStyle = '#401911'
    @pPinPositions.forEach (p) =>
      ctx.beginPath()
      ctx.arc p[0], p[1], @pPinRadius, 0, TWO_PI
      ctx.fill()
    ctx.restore()


#///////////////////////////
# arrow on top of the wheel of fortune
#///////////////////////////

class Arrow
  constructor: (@x, @y, @w, @h) ->
    @verts = []
    @pX = @x * ppm
    @pY = (physicsHeight - (@y)) * ppm
    @pVerts = []
    @createBody()

  createBody: ->
    @body = new (p2.Body)(
      mass: 1
      position: [
        @x
        @y
      ])
    @body.addShape @createArrowShape()
    axis = new (p2.Body)(position: [
      @x
      @y
    ])
    constraint = new (p2.RevoluteConstraint)(@body, axis, worldPivot: [
      @x
      @y
    ])
    constraint.collideConnected = false
    left = new (p2.Body)(position: [
      @x - 2
      @y
    ])
    right = new (p2.Body)(position: [
      @x + 2
      @y
    ])
    leftConstraint = new (p2.DistanceConstraint)(@body, left,
      localAnchorA: [
        -@w * 2
        @h * 0.25
      ]
      collideConnected: false)
    rightConstraint = new (p2.DistanceConstraint)(@body, right,
      localAnchorA: [
        @w * 2
        @h * 0.25
      ]
      collideConnected: false)
    s = 32
    r = 4
    leftConstraint.setStiffness s
    leftConstraint.setRelaxation r
    rightConstraint.setStiffness s
    rightConstraint.setRelaxation r
    world.addBody @body
    world.addBody axis
    world.addConstraint constraint
    world.addConstraint leftConstraint
    world.addConstraint rightConstraint

  createArrowShape: ->
    @verts[0] = [
      0
      @h * 0.25
    ]
    @verts[1] = [
      -@w * 0.5
      0
    ]
    @verts[2] = [
      0
      -@h * 0.75
    ]
    @verts[3] = [
      @w * 0.5
      0
    ]
    @pVerts[0] = [
      @verts[0][0] * ppm
      -@verts[0][1] * ppm
    ]
    @pVerts[1] = [
      @verts[1][0] * ppm
      -@verts[1][1] * ppm
    ]
    @pVerts[2] = [
      @verts[2][0] * ppm
      -@verts[2][1] * ppm
    ]
    @pVerts[3] = [
      @verts[3][0] * ppm
      -@verts[3][1] * ppm
    ]
    shape = new (p2.Convex)(@verts)
    shape.material = arrowMaterial
    shape

  hasStopped: ->
    angle = Math.abs(@body.angle % TWO_PI)
    angle < 1e-3 or TWO_PI - angle < 1e-3

  update: ->

  draw: ->
    ctx.save()
    ctx.translate @pX, @pY
    ctx.rotate -@body.angle
    ctx.fillStyle = '#401911'
    ctx.beginPath()
    ctx.moveTo @pVerts[0][0], @pVerts[0][1]
    ctx.lineTo @pVerts[1][0], @pVerts[1][1]
    ctx.lineTo @pVerts[2][0], @pVerts[2][1]
    ctx.lineTo @pVerts[3][0], @pVerts[3][1]
    ctx.closePath()
    ctx.fill()
    ctx.restore()

cubeBezier = (p0, c0, c1, p1, t) ->
  p = new Point
  nt = 1 - t
  p.x = nt * nt * nt * p0.x + 3 * nt * nt * t * c0.x + 3 * nt * t * t * c1.x + t * t * t * p1.x
  p.y = nt * nt * nt * p0.y + 3 * nt * nt * t * c0.y + 3 * nt * t * t * c1.y + t * t * t * p1.y
  p

#///////////////////////////
# math
#///////////////////////////

###*
# easing equations from http://gizma.com/easing/
# t = current time
# b = start value
# c = delta value
# d = duration
###

Ease =
  inCubic: (t, b, c, d) ->
    t /= d
    c * t * t * t + b
  outCubic: (t, b, c, d) ->
    t /= d
    t--
    c * (t * t * t + 1) + b
  inOutCubic: (t, b, c, d) ->
    t /= d / 2
    if t < 1
      return c / 2 * t * t * t + b
    t -= 2
    c / 2 * (t * t * t + 2) + b
  inBack: (t, b, c, d, s) ->
    s = s or 1.70158
    c * (t /= d) * t * ((s + 1) * t - s) + b

window.addEventListener 'load', ->
  console.debug 'window load wheel'
  initDrawingCanvas()
  initPhysics()
  requestAnimationFrame do_loop
  statusLabel.innerHTML = 'Give it a good spin!'
  return

#///////////////////////////
# your reward
#///////////////////////////

class Particle
  constructor: (@p0, @p1, @p2, @p3) ->
    @time = 0
    @duration = 3 + Math.random() * 2
    @color = 'hsl(' + Math.floor(Math.random() * 360) + ',100%,50%)'
    @w = 10
    @h = 7
    @complete = false

  update: ->
    @time = Math.min(@duration, @time + timeStep)
    f = Ease.outCubic(@time, 0, 1, @duration)
    p = cubeBezier(@p0, @p1, @p2, @p3, f)
    dx = p.x - (@x)
    dy = p.y - (@y)
    @r = Math.atan2(dy, dx) + HALF_PI
    @sy = Math.sin(Math.PI * f * 10)
    @x = p.x
    @y = p.y
    @complete = @time == @duration

  draw: ->
    ctx.save()
    ctx.translate @x, @y
    ctx.rotate @r
    ctx.scale 1, @sy
    ctx.fillStyle = @color
    ctx.fillRect -@w * 0.5, -@h * 0.5, @w, @h
    ctx.restore()

class Point
  constructor: (@x = 0, @y = 0) ->
