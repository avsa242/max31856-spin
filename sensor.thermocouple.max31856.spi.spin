{
    --------------------------------------------
    Filename: sensor.thermocouple.max31856.spi.spin
    Author: Jesse Burt
    Description: Driver object for Maxim's MAX31856 thermocouple amplifier (4W SPI)
    Copyright (c) 2018
    Created: Sep 30, 2018
    Updated: Mar 16, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    CMODE_OFF   = 0
    CMODE_AUTO  = 1

VAR

    byte _cs, _mosi, _miso, _sck

OBJ

    core    : "core.con.max31856"
    spi     : "SPI_Asm"
    types   : "system.types"

PUB Null
''This is not a top-level object

PUB Start (CS_PIN, SDI_PIN, SDO_PIN, SCK_PIN): okay

    if okay := spi.start (core#CLK_DELAY, core#CPOL)
        _cs := CS_PIN
        _mosi := SDI_PIN
        _miso := SDO_PIN
        _sck := SCK_PIN
        dira[_cs] := 1
    else
        return FALSE

PUB Stop

    spi.stop

PUB ColdJuncTemp
' Read the Cold-Junction temperature sensor
    readRegX (core#CJTH, 2, @result)
    result := (result & $FFFF) >> 2

PUB ThermoCoupleTemp
' Read the Thermocouple temperature
    readRegX (core#LTCBH, 3, @result)
    result := result >> 5

PUB ConversionMode(mode) | tmp
' Enable automatic conversion mode
'   Valid values: CMODE_OFF (0): Normally Off (default), CMODE_AUTO (1): Automatic Conversion Mode
'   Any other value polls the chip and returns the current value
'   NOTE: In Automatic mode, conversions occur continuously approx. every 100ms
    readRegX (core#CR0, 1, @tmp)
    case mode
        CMODE_OFF, CMODE_AUTO:
            mode := (mode << core#FLD_CMODE)
        OTHER:
            return result := (tmp >> core#FLD_CMODE) & %1

    tmp &= core#MASK_CMODE
    tmp := (tmp | mode) & core#CR0_MASK
    writeRegX (core#CR0, 1, @tmp)

PUB CJOffset(offset) | tmp  'XXX Make param units degrees
' Set Cold-Junction temperature sensor offset
    readRegX (core#CJTO, 2, @tmp)
    case offset
        -128..127:
            offset := types.s8 (offset)
        OTHER:
            return tmp

    writeRegX (core#CJTO, 1, @tmp)

PUB FaultTestTime(time_ms) | tmp 'XXX Note recommendations based on circuit design
' Sets open-circuit fault detection test time, in ms
'   Valid values: 0 (disable fault detection), 10, 32, 100
    readRegX (core#CR0, 1, @tmp)
    case time_ms
        0, 10, 32, 100:
            time_ms := lookdownz(time_ms: 0, 10, 32, 100) << core#FLD_OCFAULT
        OTHER:
            return result := ((tmp >> core#FLD_OCFAULT) & core#BITS_OCFAULT)

    tmp &= core#MASK_OCFAULT
    tmp := (tmp | time_ms) & core#CR0_MASK
    writeRegX (core#CR0, 1, @tmp)

PUB OneShot | tmp
' Perform single cold-junction and thermocouple conversion
' NOTE: Single conversion is performed only if ConversionMode is set to CMODE_OFF (Normally Off)
' Approximate conversion times:
'   Filter Setting      Time
'   60Hz                143ms
'   50Hz                169ms
    readRegX (core#CR0, 1, @tmp)
    tmp &= core#MASK_ONESHOT
    tmp := (tmp | (1 << core#FLD_ONESHOT)) & core#CR0_MASK
    writeRegX (core#CR0, 1, @tmp)

PUB writeRegX(reg, nr_bytes, buf_addr) | tmp
' Write reg to MOSI
    outa[_CS] := 0
    case nr_bytes
        1..4:
            spi.SHIFTOUT (_mosi, _sck, core#MOSI_BITORDER, 8, reg | core#WRITE_REG)     'Command w/nr_bytes data bytes following
            repeat tmp from 0 to nr_bytes-1
                spi.SHIFTOUT (_mosi, _sck, core#MOSI_BITORDER, 8, byte[buf_addr][tmp])
        OTHER:
            result := FALSE
            buf_addr := 0
    outa[_CS] := 1

PUB readRegX(reg, nr_bytes, buf_addr) | tmp
' Read reg from MISO
    outa[_CS] := 0
    spi.SHIFTOUT (_mosi, _sck, core#MOSI_BITORDER, 8, reg)              'Which register to query

    case nr_bytes
        1..4:
            repeat tmp from 0 to nr_bytes-1
                byte[buf_addr][tmp] := spi.SHIFTIN (_miso, _sck, core#MISO_BITORDER, 8)
        OTHER:
            result := FALSE
            buf_addr := 0
    outa[_CS] := 1

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
