{
    --------------------------------------------
    Filename: MAX31856-Demo.spin
    Author: Jesse Burt
    Description: MAX31856 driver demo
        * Temp data output
    Copyright (c) 2022
    Started Sep 30, 2018
    Updated Jul 22, 2022
    See end of file for terms of use.
    --------------------------------------------

    Build-time symbols supported by driver:
        -DMAX31856_SPI (default if none specified)
        -DMAX31856_SPI_BC
}
#define HAS_THERMCPL
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

    { SPI configuration }
    CS_PIN      = 0
    SCK_PIN     = 1
    MOSI_PIN    = 2                             ' SDI
    MISO_PIN    = 3                             ' SDO
' --

OBJ

    cfg:    "core.con.boardcfg.flip"
    sensr:  "sensor.thermocouple.max31856"
    ser:    "com.serial.terminal.ansi"
    time:   "time"

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(10)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if (sensr.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN))
        ser.strln(string("MAX31856 driver started"))
    else
        ser.strln(string("MAX31856 driver failed to start - halting"))
        repeat

    sensr.tempscale(sensr#C)                    ' C, F, K
    sensr.tc_type(sensr#TYPE_K)
    ' TYPE_B (0), TYPE_E (1), TYPE_J (2), TYPE_K (3)
    ' TYPE_N (4), TYPE_R (5), TYPE_S (6), TYPE_T (7)

    sensr.cj_bias(0)                            ' -8_0000..7_9375 (= x.xxxx C)
    sensr.notchfilter(60)                       ' 50, 60 (Hz)
    sensr.opmode(sensr.CONT)
    demo{}

#include "tempdemo.common.spinh"                ' code common to all temp demos

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

