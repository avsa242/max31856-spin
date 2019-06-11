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

    CMODE_OFF       = 0
    CMODE_AUTO      = 1

    FAULTMODE_COMP  = 0
    FAULTMODE_INT   = 1

    TC_RES          = 78125 ' 0.0078125 * 10_000_000)
    CJ_RES          = 15625 ' 0.15625 * 100_000

VAR

    byte _CS, _MOSI, _MISO, _SCK

OBJ

    core    : "core.con.max31856"
    spi     : "com.spi.4w"
    types   : "system.types"
    umath   : "umath"

PUB Null
''This is not a top-level object

PUB Start (CS_PIN, SDI_PIN, SDO_PIN, SCK_PIN): okay

    if okay := spi.start (core#CLK_DELAY, core#CPOL)
        _CS := CS_PIN
        _MOSI := SDI_PIN
        _MISO := SDO_PIN
        _SCK := SCK_PIN
        dira[_CS] := 1
        outa[_CS] := 1
    else
        return FALSE

PUB Stop

    spi.stop

PUB ColdJuncOffset(offset) | tmp  'XXX Make param units degrees
' Set Cold-Junction temperature sensor offset
    readRegX (core#CJTO, 1, @tmp)
    case offset
        -128..127:
            offset := types.s8 (offset)
        OTHER:
            return tmp

    writeRegX (core#CJTO, 1, @tmp)

PUB ColdJuncSensor(enabled) | tmp
' Enable the on-chip Cold-Junction temperature sensor
'   Valid values: TRUE (-1 or 1), FALSE
'   Any other value polls the chip and returns the current setting
    readRegX (core#CR0, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_CJ
        OTHER:
            result := ((tmp >> core#FLD_CJ) & %1) * TRUE
            return

    tmp &= core#MASK_CJ
    tmp := (tmp | enabled) & core#CR0_MASK
    writeRegX (core#CR0, 1, @tmp)

PUB ColdJuncTemp
' Read the Cold-Junction temperature sensor
    readRegX (core#CJTH, 2, @result)
    result.byte[2] := result.byte[0]
    result.byte[0] := result.byte[1]
    result.byte[1] := result.byte[2]
    result.byte[2] := 0
    result >>=2
    return umath.multdiv (result, CJ_RES, 10_000)

PUB ConversionMode(mode) | tmp
' Enable automatic conversion mode
'   Valid values: CMODE_OFF (0): Normally Off (default), CMODE_AUTO (1): Automatic Conversion Mode
'   Any other value polls the chip and returns the current setting
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

PUB FaultClear | tmp
' Clear fault status
'   NOTE: This has no effect when FaultMode is set to FAULTMODE_COMP
    readRegX (core#CR0, 1, @tmp)
    tmp &= core#MASK_FAULTCLR
    tmp := (tmp | (1 << core#FLD_FAULTCLR)) & core#CR0_MASK
    writeRegX (core#CR0, 1, @tmp)

PUB FaultMode(mode) | tmp
' Defines behavior of fault flag
'   Valid values:
'       *FAULTMODE_COMP (0): Comparator mode - fault flag will be asserted when fault condition is true, and will clear
'           when the condition is no longer true, with a 2deg C hysteresis.
'       FAULTMODE_INT (1): Interrupt mode - fault flag will be asserted when fault condition is true, and will remain
'           asserted until fault status is explicitly cleared with FaultClear.
'           NOTE: If the fault condition is still true when the status is cleared, the flag will be asserted again immediately.
'   Any other value polls the chip and returns the current setting
    readRegX (core#CR0, 1, @tmp)
    case mode
        FAULTMODE_COMP, FAULTMODE_INT:
            mode := mode << core#FLD_FAULT
        OTHER:
            return result := ((tmp >> core#FLD_FAULT) & 1)

    tmp &= core#MASK_FAULT
    tmp := (tmp | mode) & core#CR0_MASK
    writeRegX (core#CR0, 1, @tmp)

PUB FaultTestTime(time_ms) | tmp 'XXX Note recommendations based on circuit design
' Sets open-circuit fault detection test time, in ms
'   Valid values: 0 (disable fault detection), 10, 32, 100
'   Any other value polls the chip and returns the current setting
    readRegX (core#CR0, 1, @tmp)
    case time_ms
        0, 10, 32, 100:
            time_ms := lookdownz(time_ms: 0, 10, 32, 100) << core#FLD_OCFAULT
        OTHER:
            return result := ((tmp >> core#FLD_OCFAULT) & core#BITS_OCFAULT)

    tmp &= core#MASK_OCFAULT
    tmp := (tmp | time_ms) & core#CR0_MASK
    writeRegX (core#CR0, 1, @tmp)

PUB Measure | tmp
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

PUB NotchFilter(Hz) | tmp, cmode_tmp
' Select noise rejection filter frequency, in Hz
'   Valid values: 50, 60*
'   Any other value polls the chip and returns the current setting
'   NOTE: The conversion mode will be temporarily set to Normally Off when changing notch filter settings
'       per MAX31856 datasheet, if it isn't already.
   if cmode_tmp := ConversionMode (-2)
        ConversionMode (CMODE_OFF)

    readRegX (core#CR0, 1, @tmp)
    case Hz
        50, 60:
            Hz := lookdownz(Hz: 60, 50)
        OTHER:
            result := tmp & core#BITS_OCFAULT
            return lookupz(tmp: 60, 50)

    tmp &= core#MASK_NOTCHFILT
    tmp := (tmp | Hz) & core#CR0_MASK
    writeRegX (core#CR0, 1, @tmp)

    if cmode_tmp
        ConversionMode (CMODE_AUTO)

PUB ThermoCoupleTemp
' Read the Thermocouple temperature
    readRegX (core#LTCBH, 3, @result)
    swapByteOrder(@result)
    result >>= 5
    result := umath.multdiv (result, TC_RES, 100_000)

PRI swapByteOrder(buff_addr)

    byte[buff_addr][3] := byte[buff_addr][0]
    byte[buff_addr][0] := byte[buff_addr][2]
    byte[buff_addr][2] := byte[buff_addr][3]
    byte[buff_addr][3] := 0

PRI writeRegX(reg, nr_bytes, buf_addr) | tmp
' Write reg to MOSI
    outa[_CS] := 0
    case nr_bytes
        1..4:
            spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg | core#WRITE_REG)     'Command w/nr_bytes data bytes following
            repeat tmp from 0 to nr_bytes-1
                spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buf_addr][tmp])
        OTHER:
            result := FALSE
            buf_addr := 0
    outa[_CS] := 1

PRI readRegX(reg, nr_bytes, buf_addr) | tmp
' Read reg from MISO
    outa[_CS] := 0
    spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)              'Which register to query

    case nr_bytes
        1..4:
            repeat tmp from 0 to nr_bytes-1
                byte[buf_addr][tmp] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
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
