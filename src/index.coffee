React = require 'preact'

CANVAS_WIDTH = 300
CANVAS_HEIGHT = 150
CANVAS_PADDING = 10
SLIDER_HEIGHT = 15

CANVAS_CURSOR_SIZE = 8
SLIDER_CURSOR_WIDTH = 6
SLIDER_CURSOR_HEIGHT = SLIDER_HEIGHT + 6

# Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
shortHex2Hex = (hex) ->
    shorthand_regex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i
    hex.replace(shorthand_regex, (m, r, g, b) ->
        r + r + g + g + b + b
    )

validHex = (hex) ->
    typeof hex == 'string' and
        /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)

rgb2hex = (r, g, b) ->
    return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)

hex2rgb = (hex) ->
    if matched = validHex shortHex2Hex hex
        r = parseInt(matched[1], 16)
        g = parseInt(matched[2], 16)
        b = parseInt(matched[3], 16)
    return [r, g, b]

rgb2hsv = (r, g, b) ->
    r /= 255
    g /= 255
    b /= 255
    max = Math.max(r, g, b)
    min = Math.min(r, g, b)
    h = undefined
    s = undefined
    l = (max + min) / 2
    if max == min
        h = s = 0
        # achromatic
    else
        d = max - min
        s = if l > 0.5 then d / (2 - max - min) else d / (max + min)
        switch max
            when r
                h = (g - b) / d + (if g < b then 6 else 0)
            when g
                h = (b - r) / d + 2
            when b
                h = (r - g) / d + 4
        h /= 6
    return [h, s, l]

hsv2rgb = (h, s, v) ->
    i = Math.floor(h * 6)
    f = h * 6 - i
    p = v * (1 - s)
    q = v * (1 - (f * s))
    t = v * (1 - ((1 - f) * s))
    switch i % 6
        when 0
            r = v; g = t; b = p
        when 1
            r = q; g = v; b = p
        when 2
            r = p; g = v; b = t
        when 3
            r = p; g = q; b = v
        when 4
            r = t; g = p; b = v
        when 5
            r = v; g = p; b = q
    [
        Math.round(r * 255)
        Math.round(g * 255)
        Math.round(b * 255)
    ]

class Picker extends React.Component
    constructor: (props) ->
        if validHex props.hex
            hex = props.hex
        else
            hex = '#888'
        rgb = hex2rgb hex
        hsv = rgb2hsv rgb...
        @state = {
            hex, rgb, hsv
        }

    componentDidMount: ->
        @renderCanvas()
        @renderSlider()

    setCanvas: (el) ->
        return if not el
        ctx = el.getContext '2d'
        @canvas = {el, ctx}

    setSlider: (el) ->
        return if not el
        ctx = el.getContext '2d'
        @slider = {el, ctx}

    clickCanvas: (e) ->
        {hsv} = @state
        hsv[1] = e.offsetX / CANVAS_WIDTH
        hsv[2] = 1 - (e.offsetY / CANVAS_HEIGHT)
        @setState {hsv}, =>
            @updateColorsFrom 'hsv'

    clickSlider: (e) ->
        window.last_e = e
        {hsv} = @state
        hsv[0] = e.offsetX / CANVAS_WIDTH
        @setState {hsv}, =>
            @updateColorsFrom 'hsv'

    updateColorsFrom: (key) ->
        update = {}
        if key == 'hsv'
            rgb = hsv2rgb @state.hsv...
            hex = rgb2hex rgb...
            update = {rgb, hex}
        @setState update, =>
            @props.onChange @state
            @renderCanvas()

    renderCanvas: ->
        h = @state.hsv[0]
        for y in [0..CANVAS_HEIGHT]
            for x in [0..CANVAS_WIDTH]
                s = x / CANVAS_WIDTH
                v = 1 - (y / CANVAS_HEIGHT)
                [r, g, b] = hsv2rgb(h, s, v)
                @canvas.ctx.fillStyle = "rgb(#{r},#{g},#{b})"
                @canvas.ctx.fillRect(x, y, 1, 1)

    renderSlider: ->
        s = 1
        v = 1
        for y in [0..CANVAS_HEIGHT]
            for x in [0..CANVAS_WIDTH]
                h = x / CANVAS_WIDTH
                [r, g, b] = hsv2rgb(h, s, v)
                @slider.ctx.fillStyle = "rgb(#{r},#{g},#{b})"
                @slider.ctx.fillRect(x, y + CANVAS_PADDING, 1, 1)

    render: ->
        canvas_cursor_style = {
            left: CANVAS_WIDTH * @state.hsv[1] - CANVAS_CURSOR_SIZE/2
            top: CANVAS_HEIGHT * (1 - @state.hsv[2]) - CANVAS_CURSOR_SIZE/2
            width: CANVAS_CURSOR_SIZE
            height: CANVAS_CURSOR_SIZE
        }
        slider_cursor_style = {
            left: CANVAS_WIDTH * @state.hsv[0] - SLIDER_CURSOR_WIDTH/2
            top: CANVAS_HEIGHT + CANVAS_PADDING - (SLIDER_CURSOR_HEIGHT - SLIDER_HEIGHT)/2
            width: SLIDER_CURSOR_WIDTH
            height: SLIDER_CURSOR_HEIGHT
        }
        <div className='picker'>
            <canvas ref={@setCanvas.bind(@)} width=CANVAS_WIDTH height=CANVAS_HEIGHT onClick={@clickCanvas.bind(@)} />
            <canvas ref={@setSlider.bind(@)} width=CANVAS_WIDTH height={SLIDER_HEIGHT + CANVAS_PADDING} onClick={@clickSlider.bind(@)} />
            <div className='canvas-cursor' style=canvas_cursor_style />
            <div className='slider-cursor' style=slider_cursor_style />
        </div>

module.exports = class ColorPicker extends React.Component
    constructor: (props) ->
        @state = {
            value: props.value
            picking: false
        }

    onChangeInput: (e) ->
        hex = e.target.value
        @setState {value: hex}
        @props.onChange hex

    onChangeColor: (color) ->
        {hex} = color
        @setState {value: hex}
        @props.onChange hex

    render: ->
        swatch_style = {backgroundColor: @state.value}
        <div className='color-picker'>
            <Picker hex={@state.value} onChange={@onChangeColor.bind(@)} />
            <div className='preview'>
                <div className='swatch' style=swatch_style />
                <input
                    type='text'
                    value={@state.value}
                    onChange={@onChangeInput.bind(@)}
                />
            </div>
        </div>

