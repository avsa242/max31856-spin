{
    --------------------------------------------
    Filename: sensor.thermocouple.max31856.spi.spin
    Author: Jesse Burt
    Description: Driver object for Maxim's MAX31856 thermocouple amplifier (4W SPI)
    Copyright (c) 2018
    Created: Sep 30, 2018
    Updated: Sep 30, 2018
    See end of file for terms of use.
    --------------------------------------------
}

CON

    CMODE_OFF   = max31856#CMODE_OFF
    CMODE_AUTO  = max31856#CMODE_AUTO
    
VAR

    byte _cs, _sdi, _sdo, _sck

OBJ

    max31856    : "core.con.max31856"
    spi         : "SPI_Asm"

PUB null
''This is not a top-level object

PUB Start (CS_PIN, SDI_PIN, SDO_PIN, SCK_PIN): okay

    if okay := spi.start (10, max31856#CPOL)
        _cs := CS_PIN
        _sdi := SDI_PIN
        _sdo := SDO_PIN
        _sck := SCK_PIN
    else
        Stop

PUB Stop

    spi.stop

PUB readTC(ptr_tcdata)

    ptr_tcdata := readX($0C, 3)

PUB readth

    result := readX(max31856#LTCBH, 3) >> 5

PUB ReadConfig

PUB ConversionMode(mode) | cmd_packet

    case mode
        CMODE_OFF, CMODE_AUTO:
        OTHER: return

    cmd_packet.byte[1] := max31856#REG_CR0_W
    cmd_packet.byte[0] := mode

    writeX(cmd_packet, 16)

PUB writeX(data, nr_bits)
'' Write nr_bits of data
    Low (_cs)
    spi.SHIFTOUT (_sdi, _sck, spi#MSBFIRST, nr_bits, data)
    High (_cs)

PUB readX(reg, nr_bytes): read
'' Read nr_bytes of data from register 'reg'
    Low (_cs)
    spi.SHIFTOUT (_sdi, _sck, spi#MSBFIRST, 8, reg)
    read := spi.SHIFTIN (_sdo, _sck, SPI#MSBPOST, nr_bytes * 8)
    High (_cs)

PRI High(pin)
'' Abbreviated way to bring an output pin high
   dira[pin] := 0
   outa[pin] := 0

PRI Low(pin)
'' Abbreviated way to bring an output pin low
   dira[pin] := 1
   outa[pin] := 0

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
