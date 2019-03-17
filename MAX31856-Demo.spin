{
    --------------------------------------------
    Filename: MAX31856-Demo.spin
    Description: Demo for the MAX31856 driver
    Author: Jesse Burt
    Copyright (c) 2019
    Created Sep 30, 2018
    Updated Mar 16, 2019
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

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    max31856: "sensor.thermocouple.max31856.spi"
    math    : "tiny.math.float"
    fs      : "string.float"

VAR

    byte _ser_cog

PUB Main | i, r, tc, tc_tmp, tc_res, scl, cj, cj_tmp, cj_res

    Setup
    ser.Clear
'    f := 7 '.0078125
    tc_res := 0.0078125
    cj_res := 0.015625
    scl := 1000

    max31856.ConversionMode(max31856#CMODE_AUTO)

    repeat
        cj := math.FFloat (max31856.ColdJuncTemp)
        cj_tmp := ctof(math.FMul (cj, cj_res))
 '       cj_tmp := math.FMul (cj, cj_res)
        ser.Position (0, 0)
        ser.Str (string("Cold junction temp: "))
        ser.Str (fs.FloatToString (cj_tmp))


        tc := math.FFloat (max31856.ThermoCoupleTemp)
        tc_tmp := ctof(math.FMul (tc, tc_res))
'        tc_tmp := math.FMul (tc, tc_res)
        ser.Position (0, 2)
        ser.Str (string("Thermocouple temp: "))
        ser.Str (fs.FloatToString (tc_tmp))

        time.MSleep (250)

PUB CtoF (c): f
'T(°F) = T(°C) × 9/5 + 32
' 9/5 = 1800 + 32
    f := math.FAdd (math.FMul (c, 1.8), 32.0)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if max31856.start (CS, SDI, SDO, SCK)
        ser.Str(string("max31856 driver started", ser#NL))
    else
        ser.Str(string("max31856 driver failed to start - halting", ser#NL))
        max31856.Stop
        time.MSleep (500)
        ser.Stop
        repeat

PUB Flash(led_pin)

    dira[led_pin] := 1
    repeat
        !outa[led_pin]
        time.MSleep (100)

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
