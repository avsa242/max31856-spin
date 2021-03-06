{
    --------------------------------------------
    Filename: MAX31856-Demo.spin
    Description: Demo for the MAX31856 driver
    Author: Jesse Burt
    Copyright (c) 2021
    Created Sep 30, 2018
    Updated May 16, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CS_PIN      = 0
    SCK_PIN     = 1
    SDI_PIN     = 2
    SDO_PIN     = 3

    SCALE       = F
' --

' Temperature scale readings
    C           = 0
    F           = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    max31856: "sensor.thermocouple.max31856.spi"
    int     : "string.integer"

PUB Main{} | cj_temp, tc_temp

    setup{}

    max31856.coldjuncbias(0)                    ' -128..127
    max31856.notchfilter(60)                    ' 50, 60 (Hz)
    max31856.opmode(max31856#CONT)
    max31856.tempscale(C)

    repeat
        cj_temp := max31856.coldjunctemp{}
        tc_temp := max31856.thermocoupletemp{}

        ser.position(0, 3)
        ser.str(string("Cold junction temp: "))
        decimal(cj_temp, 100)
        ser.char(lookupz(max31856.tempscale(-2): "C", "F"))
        ser.clearline{}
        ser.newline{}

        ser.str(string("Thermocouple temp: "))
        decimal(tc_temp, 100)
        ser.char(lookupz(max31856.tempscale(-2): "C", "F"))
        ser.clearline{}
        time.msleep(100)

PRI Decimal(scaled, divisor) | whole[4], part[4], places, tmp, sign
' Display a scaled up number as a decimal
'   Scale it back down by divisor (e.g., 10, 100, 1000, etc)
    whole := scaled / divisor
    tmp := divisor
    places := 0
    part := 0
    sign := 0
    if scaled < 0
        sign := "-"
    else
        sign := " "

    repeat
        tmp /= 10
        places++
    until tmp == 1
    scaled //= divisor
    part := int.deczeroed(||(scaled), places)

    ser.char(sign)
    ser.dec(||(whole))
    ser.char(".")
    ser.str(part)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if max31856.startx(CS_PIN, SCK_PIN, SDI_PIN, SDO_PIN)
        ser.strln(string("MAX31856 driver started"))
    else
        ser.strln(string("MAX31856 driver failed to start - halting"))
        max31856.stop{}
        time.msleep(5)
        ser.stop{}
        repeat

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
