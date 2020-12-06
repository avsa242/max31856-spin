{
    --------------------------------------------
    Filename: sensor.thermocouple.max31856.spi.spin
    Author: Jesse Burt
    Description: Driver object for Maxim's MAX31856 thermocouple amplifier
    Copyright (c) 2018
    Created: Sep 30, 2018
    Updated: Dec 6, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Sensor resolution (deg C per LSB, scaled up)
    TC_RES          = 78125 ' 0.0078125 * 10_000_000)
    CJ_RES          = 15625 ' 0.15625 * 100_000

' Conversion modes
    CMODE_OFF       = 0
    CMODE_AUTO      = 1

' Fault modes
    FAULTMODE_COMP  = 0
    FAULTMODE_INT   = 1

' Thermocouple types
    B               = %0000
    E               = %0001
    J               = %0010
    K               = %0011
    N               = %0100
    R               = %0101
    S               = %0110
    T               = %0111
    VOLTMODE_GAIN8  = %1000
    VOLTMODE_GAIN32 = %1100

' Fault mask bits (OR together any combination for use with FaultMask)
    FAULT_CJ_HIGH   = 1 << core#CJ_HIGH
    FAULT_CJ_LOW    = 1 << core#CJ_LOW
    FAULT_TC_HIGH   = 1 << core#TC_HIGH
    FAULT_TC_LOW    = 1 << core#TC_LOW
    FAULT_OV_UV     = 1 << core#OV_UV
    FAULT_OPEN      = 1 << core#OPEN

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

PUB ColdJuncHighFault(thresh) | tmp
' Set Cold-Junction HIGH fault threshold
'   Valid values: 0..255
'   Any other value polls the chip and returns the current setting
    readreg(core#CJHF, 1, @tmp)
    case thresh
        0..255:
        other:
            return tmp & $FF

    writereg(core#CJHF, 1, @thresh)

PUB ColdJuncLowFault(thresh) | tmp
' Set Cold-Junction LOW fault threshold
'   Valid values: 0..255
'   Any other value polls the chip and returns the current setting
    readreg(core#CJLF, 1, @tmp)
    case thresh
        0..255:
        other:
            return tmp & $FF

    writereg(core#CJLF, 1, @thresh)

PUB ColdJuncOffset(offset) | tmp  'XXX Make param units degrees
' Set Cold-Junction temperature sensor offset
    readreg(core#CJTO, 1, @tmp)
    case offset
        0..255:
        other:
            return tmp

    writereg(core#CJTO, 1, @offset)

PUB ColdJuncSensor(enabled) | tmp
' Enable the on-chip Cold-Junction temperature sensor
'   Valid values: TRUE (-1 or 1), FALSE
'   Any other value polls the chip and returns the current setting
    readreg(core#CR0, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled ^ 1) << core#CJ
        other:
            result := (((tmp >> core#CJ) & %1) ^ 1) * TRUE
            return

    tmp &= core#CJ_MASK
    tmp := (tmp | enabled) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

PUB ColdJuncTemp
' Read the Cold-Junction temperature sensor
    readreg(core#CJTH, 2, @result)
    result >>=2
    return umath.multdiv (result, CJ_RES, 10_000)

PUB ConversionMode(mode) | tmp
' Enable automatic conversion mode
'   Valid values: CMODE_OFF (0): Normally Off (default), CMODE_AUTO (1): Automatic Conversion Mode
'   Any other value polls the chip and returns the current setting
'   NOTE: In Automatic mode, conversions occur continuously approx. every 100ms
    readreg(core#CR0, 1, @tmp)
    case mode
        CMODE_OFF, CMODE_AUTO:
            mode := (mode << core#CMODE)
        other:
            result := (tmp >> core#CMODE) & %1
            return

    tmp &= core#CMODE_MASK
    tmp := (tmp | mode) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

PUB FaultClear | tmp
' Clear fault status
'   NOTE: This has no effect when FaultMode is set to FAULTMODE_COMP
    readreg(core#CR0, 1, @tmp)
    tmp &= core#FAULTCLR_MASK
    tmp := (tmp | (1 << core#FAULTCLR)) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

PUB FaultMask(mask) | tmp
' Set fault output mask
'   Valid values: (for each individual bit)
'       0: /FAULT output asserted
'      *1: /FAULT output masked
'   Bit: 5    0
'       %000000
'       Bit 5   Cold-junction HIGH fault threshold
'           4   Cold-junction LOW fault threshold
'           3   Thermocouple temperature HIGH fault threshold
'           2   Thermocouple temperature LOW fault threshold
'           1   Over-voltage or Under-voltage input
'           0   Thermocouple open-circuit
'   Example: %111101 would assert the /FAULT pin when an over-voltage or under-voltage condition is detected
'   Any other value polls the chip and returns the current setting
    readreg(core#FAULTMASK, 1, @tmp)
    case mask
        %000000..%111111:
        other:
            return tmp & core#FAULTMASK_MASK

    tmp := mask & core#FAULTMASK_MASK
    writereg(core#FAULTMASK, 1, @tmp)

PUB FaultMode(mode) | tmp
' Defines behavior of fault flag
'   Valid values:
'       *FAULTMODE_COMP (0): Comparator mode - fault flag will be asserted when fault condition is true, and will clear
'           when the condition is no longer true, with a 2deg C hysteresis.
'       FAULTMODE_INT (1): Interrupt mode - fault flag will be asserted when fault condition is true, and will remain
'           asserted until fault status is explicitly cleared with FaultClear.
'           NOTE: If the fault condition is still true when the status is cleared, the flag will be asserted again immediately.
'   Any other value polls the chip and returns the current setting
    readreg(core#CR0, 1, @tmp)
    case mode
        FAULTMODE_COMP, FAULTMODE_INT:
            mode := mode << core#FAULT
        other:
            result := ((tmp >> core#FAULT) & 1)
            return

    tmp &= core#FAULT_MASK
    tmp := (tmp | mode) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

PUB FaultStatus
' Return fault status, as bitfield
'   Returns: (for each individual bit)
'       0: No fault detected
'       1: Fault detected
'
'   Bit 7   Cold-junction out of normal operating range
'       6   Thermcouple out of normal operating range
'       5   Cold-junction above HIGH temperature threshold
'       4   Cold-junction below LOW temperature threshold
'       3   Thermocouple temperature above HIGH temperature threshold
'       2   Thermocouple temperature below LOW temperature threshold
'       1   Over-voltage or Under-voltage
'       0   Thermocouple open-circuit
    readreg(core#SR, 1, @result)

PUB FaultTestTime(time_ms) | tmp 'XXX Note recommendations based on circuit design
' Sets open-circuit fault detection test time, in ms
'   Valid values: 0 (disable fault detection), 10, 32, 100
'   Any other value polls the chip and returns the current setting
    readreg(core#CR0, 1, @tmp)
    case time_ms
        0, 10, 32, 100:
            time_ms := lookdownz(time_ms: 0, 10, 32, 100) << core#OCFAULT
        other:
            result := ((tmp >> core#OCFAULT) & core#OCFAULT_BITS)
            return lookupz(result: 0, 10, 32, 100)

    tmp &= core#OCFAULT_MASK
    tmp := (tmp | time_ms) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

PUB Measure | tmp
' Perform single cold-junction and thermocouple conversion
' NOTE: Single conversion is performed only if ConversionMode is set to CMODE_OFF (Normally Off)
' Approximate conversion times:
'   Filter Setting      Time
'   60Hz                143ms
'   50Hz                169ms
    readreg(core#CR0, 1, @tmp)
    tmp &= core#ONESHOT_MASK
    tmp := (tmp | (1 << core#ONESHOT)) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

PUB NotchFilter(Hz) | tmp, cmode_tmp
' Select noise rejection filter frequency, in Hz
'   Valid values: 50, 60*
'   Any other value polls the chip and returns the current setting
'   NOTE: The conversion mode will be temporarily set to Normally Off when changing notch filter settings
'       per MAX31856 datasheet, if it isn't already.
    if cmode_tmp := ConversionMode (-2)
        ConversionMode (CMODE_OFF)
    readreg(core#CR0, 1, @tmp)
    case Hz
        50, 60:
            Hz := lookdownz(Hz: 60, 50)
        other:
            if cmode_tmp
                ConversionMode (CMODE_AUTO)
            result := tmp & %1
            return lookupz(result: 60, 50)

    tmp &= core#NOTCHFILT_MASK
    tmp := (tmp | Hz) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

    if cmode_tmp
        ConversionMode (CMODE_AUTO)

PUB ThermoCoupleAvg(samples) | tmp
' Set number of samples averaged during thermocouple conversion
'   Valid values: 1*, 2, 4, 8, 16
'   Any other value polls the chip and returns the current setting
    readreg(core#CR1, 1, @tmp)
    case samples
        1, 2, 4, 8, 16:
            samples := lookdownz(samples: 1, 2, 4, 8, 16) << core#AVGSEL
        other:
            result := (tmp >> core#AVGSEL) & core#AVGSEL_BITS
            return lookupz(result: 1, 2, 4, 8, 16)

    tmp &= core#AVGSEL_MASK
    tmp := (tmp | samples) & core#CR1_MASK
    writereg(core#CR1, 1, @tmp)

PUB ThermocoupleHighFault(thresh) | tmp
' Set Thermocouple HIGH fault threshold
'   Valid values: 0..32767
'   Any other value polls the chip and returns the current setting
    readreg(core#LTHFTH, 2, @tmp)
    case thresh
        0..32767:
        other:
            return tmp & $7FFF

    writereg(core#LTHFTH, 2, @thresh)

PUB ThermocoupleLowFault(thresh) | tmp
' Set Thermocouple LOW fault threshold
'   Valid values: 0..32767
'   Any other value polls the chip and returns the current setting
    readreg(core#LTLFTH, 2, @tmp)
    case thresh
        0..32767:
        other:
            return tmp & $7FFF

    writereg(core#LTLFTH, 2, @thresh)

PUB ThermoCoupleTemp
' Read the Thermocouple temperature
    readreg(core#LTCBH, 3, @result)
'    swapByteOrder(@result)
    result >>= 5
    result := umath.multdiv (result, TC_RES, 100_000)
    return

PUB ThermoCoupleType(type) | tmp
' Set type of thermocouple
'   Valid values: B (0), E (1), J (2), K* (3), N (4), R (5), S (6), T (7)
'   Any other value polls the chip and returns the current setting
    readreg(core#CR1, 1, @tmp)
    case type
        B, E, J, K, N, R, S, T:
        other:
            result := tmp & core#TC_TYPE_BITS
            return

    tmp &= core#TC_TYPE_MASK
    tmp := (tmp | type) & core#CR1_MASK
    writereg(core#CR1, 1, @tmp)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | tmp
' Read nr_bytes from device into ptr_buff
    case reg_nr                                 ' validate register
        core#CR0..core#SR:
        other:                                  ' invalid; return
            return

    outa[_CS] := 0                              ' shift out reg number
    spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg_nr)
    repeat tmp from nr_bytes-1 to 0             ' then read the data, MSB-first
        byte[ptr_buff][tmp] := spi.shiftin(_MISO, _SCK, core#MISO_BITORDER, 8)
    outa[_CS] := 1

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | tmp
' Write nr_bytes from ptr_buff to device
    case reg_nr
        core#CR0..core#CJTL:
            reg_nr |= core#WRITE_REG            ' OR reg_nr with $80 to write
        other:
            return

    outa[_CS] := 0
    spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg_nr)
    repeat tmp from nr_bytes-1 to 0
        spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[ptr_buff][tmp])
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
