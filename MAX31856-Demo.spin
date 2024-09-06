{
----------------------------------------------------------------------------------------------------
    Filename:       MAX31856-Demo.spin
    Description:    MAX31856 driver demo
        * Temperature data output
    Author:         Jesse Burt
    Started:        Sep 30, 2018
    Updated:        Sep 6, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

' Uncomment the two lines below to use the bytecode-based SPI engine
'#define MAX31856_SPI_BC
'#pragma exportdef(MAX31856_SPI_BC)

#define HAS_THERMCPL
CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    sensor: "sensor.thermocouple.max31856" | CS=0, SCK=1, MOSI=2, MISO=3
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_2000
    time:   "time"


PUB main() | tscl, cj_temp, tc_temp

    setup()

    sensor.temp_scale(sensor.C)                 ' C, F, K
    sensor.tc_type(sensor.TYPE_K)               ' TYPE_B (0), TYPE_E (1), TYPE_J (2), TYPE_K (3)
                                                ' TYPE_N (4), TYPE_R (5), TYPE_S (6), TYPE_T (7)

    sensor.cj_bias(0)                           ' -8_0000..7_9375 (= x.xxxx C)
    sensor.notch_filt_freq(60)                  ' 50, 60 (Hz) mains power frequency
    sensor.opmode(sensor.CONT)

    repeat
        tscl := lookupz(sensor.temp_scale(-2): "C", "F", "K")
        cj_temp := sensor.cj_temp()
        tc_temp := sensor.tc_temp()
        ser.printf1(@"Temp (deg %c):\n\r", tscl)

        ' scale the temperature measurements down (from hundredths of a degree) for display:
        ser.printf2(@"Cold junction: %3.3d.%02.2d\n\r", (cj_temp / 100), ...    ' whole
                                                        ||(cj_temp // 100))     ' fractional
        ser.printf2(@"Thermocouple: %3.3d.%02.2d\n\r",  (tc_temp / 100), ...
                                                        ||(tc_temp // 100))


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"MAX31856 driver started")
    else
        ser.strln(@"MAX31856 driver failed to start - halting")
        repeat


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

