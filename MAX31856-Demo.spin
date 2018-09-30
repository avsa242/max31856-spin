{
    --------------------------------------------
    Filename:
    Author:
    Copyright (c) 20__
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    CS          = 0
    SDI         = 1
    SDO         = 2
    SCK         = 3

OBJ

    cfg     : "core.con.client.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    max31856: "sensor.thermocouple.max31856.spi"
    math    : "tiny.math.float"
    fs      : "string.float"

VAR

    long _max_cog, _ser_cog

PUB Main | i, r, tmp, tmpf, temp, f, scl

    Setup
    ser.Clear
'    f := 7 '.0078125
    f := 0.0078125
    scl := 1000

    i := max31856.readX ($01, 1)
    ser.Position (0, 0)
    ser.Str (string("Data: "))
    ser.Hex (i, 2)
    max31856.ConversionMode(max31856#CMODE_AUTO)

'Floating-point
    repeat
        ser.Position (0, 1)
        tmp := max31856.readth
        tmpf := math.FFloat (tmp)
        temp := ctof(math.FMul (tmpf, f))

        ser.Str (fs.FloatToString (temp))
        time.MSleep (250)

'Fixed-point
    repeat
        ser.Position (0, 5)
        tmp := max31856.readth
        ser.Hex (tmp, 8)
        temp := ((tmp * scl) * f) / scl
        ser.Char (" ")
        ser.Dec (ctof(temp))
        ser.Chars (32, 5)
        time.MSleep (100)

PUB ctof (c): f
'T(°F) = T(°C) × 9/5 + 32
' 9/5 = 1800 + 32
    f := math.FAdd (math.FMul (c, 1.8), 32.0)
'    f := c * 1800 + (32 * 1_000_000)
'    f := (c * 1800 + 32) / 1000


PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if _max_cog := max31856.start (CS, SDI, SDO, SCK)
        ser.Str(string("max31856 driver started", ser#NL))
    ser.Str (string("Press any key...", ser#NL))
    ser.CharIn

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
