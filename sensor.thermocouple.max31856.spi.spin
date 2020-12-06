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

' Operating modes
    SINGLE          = 0
    CONT            = 1

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

PUB Null{}
' This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, SDI_PIN, SDO_PIN): okay

    if okay := spi.start(core#CLK_DELAY, core#CPOL)
        _CS := CS_PIN
        _MOSI := SDI_PIN
        _MISO := SDO_PIN
        _SCK := SCK_PIN
        dira[_CS] := 1
        outa[_CS] := 1
    else
        return FALSE

PUB Stop{}

    spi.stop{}

PUB ColdJuncHighFault(thresh): curr_thr
' Set Cold-Junction HIGH fault threshold
'   Valid values: -128..127
'   Any other value polls the chip and returns the current setting
    case thresh
        -128..127:
            writereg(core#CJHF, 1, @thresh)
        other:
            readreg(core#CJHF, 1, @curr_thr)
            return ~~curr_thr

PUB ColdJuncLowFault(thresh): curr_thr
' Set Cold-Junction LOW fault threshold
'   Valid values: -128..127
'   Any other value polls the chip and returns the current setting
    case thresh
        -128..127:
            writereg(core#CJLF, 1, @thresh)
        other:
            readreg(core#CJLF, 1, @curr_thr)
            return ~~curr_thr

PUB ColdJuncOffset(offset): curr_offs 'XXX Make param units degrees
' Set Cold-Junction temperature sensor offset
    case offset
        -128..127:
            writereg(core#CJTO, 1, @offset)
        other:
            readreg(core#CJTO, 1, @curr_offs)
            return ~~curr_offs

PUB ColdJuncSensor(state): curr_state
' Enable the on-chip Cold-Junction temperature sensor
'   Valid values: TRUE (-1 or 1), FALSE
'   Any other value polls the chip and returns the current setting
    readreg(core#CR0, 1, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) ^ 1) << core#CJ ' logic is inverted in the reg
        other:                                  ' so flip the bit
            return (((curr_state >> core#CJ) & %1) ^ 1) == 1

    state := ((curr_state & core#CJ_MASK) | state) & core#CR0_MASK
    writereg(core#CR0, 1, @state)

PUB ColdJuncTemp{}: cjtemp
' Read the Cold-Junction temperature sensor
    readreg(core#CJTH, 2, @cjtemp)
    cjtemp ~>= 2                                ' shift right but keep
    return umath.multdiv(cjtemp, CJ_RES, 10_000)'   the sign

PUB FaultClear{} | tmp
' Clear fault status
'   NOTE: This has no effect when FaultMode is set to FAULTMODE_COMP
    readreg(core#CR0, 1, @tmp)
    tmp &= core#FAULTCLR_MASK
    tmp := (tmp | (1 << core#FAULTCLR)) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

PUB FaultMask(mask): curr_mask
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
    case mask
        %000000..%111111:
            curr_mask := mask & core#FAULTMASK_MASK
            writereg(core#FAULTMASK, 1, @curr_mask)
        other:
            readreg(core#FAULTMASK, 1, @curr_mask)
            return curr_mask & core#FAULTMASK_MASK

PUB FaultMode(mode): curr_mode
' Defines behavior of fault flag
'   Valid values:
'       *FAULTMODE_COMP (0): Comparator mode - fault flag will be asserted when fault condition is true, and will clear
'           when the condition is no longer true, with a 2deg C hysteresis.
'       FAULTMODE_INT (1): Interrupt mode - fault flag will be asserted when fault condition is true, and will remain
'           asserted until fault status is explicitly cleared with FaultClear.
'           NOTE: If the fault condition is still true when the status is cleared, the flag will be asserted again immediately.
'   Any other value polls the chip and returns the current setting
    readreg(core#CR0, 1, @curr_mode)
    case mode
        FAULTMODE_COMP, FAULTMODE_INT:
            mode := mode << core#FAULT
        other:
            return ((curr_mode >> core#FAULT) & 1)

    mode := ((curr_mode & core#FAULT_MASK) | mode) & core#CR0_MASK
    writereg(core#CR0, 1, @curr_mode)

PUB FaultStatus{}: src
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
    readreg(core#SR, 1, @src)

PUB FaultTestTime(time_ms) | curr_time 'XXX Note recommendations based on circuit design
' Sets open-circuit fault detection test time, in ms
'   Valid values: 0 (disable fault detection), 10, 32, 100
'   Any other value polls the chip and returns the current setting
    readreg(core#CR0, 1, @curr_time)
    case time_ms
        0, 10, 32, 100:
            time_ms := lookdownz(time_ms: 0, 10, 32, 100) << core#OCFAULT
        other:
            result := ((curr_time >> core#OCFAULT) & core#OCFAULT_BITS)
            return lookupz(result: 0, 10, 32, 100)

    time_ms := ((curr_time & core#OCFAULT_MASK) | time_ms) & core#CR0_MASK
    writereg(core#CR0, 1, @time_ms)

PUB Measure{} | tmp
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

PUB NotchFilter(freq): curr_freq | opmode_orig
' Select noise rejection filter frequency, in Hz
'   Valid values: 50, 60*
'   Any other value polls the chip and returns the current setting
'   NOTE: The conversion mode will be temporarily set to Normally Off when changing notch filter settings
'       per MAX31856 datasheet, if it isn't already.
    opmode_orig := opmode(-2)                   ' store user's OpMode
    opmode(SINGLE)
    readreg(core#CR0, 1, @curr_freq)
    case freq
        50, 60:
            freq := lookdownz(freq: 60, 50)
        other:
            opmode(opmode_orig)
            curr_freq &= %1
            return lookupz(curr_freq: 60, 50)

    freq := ((curr_freq & core#NOTCHFILT_MASK) | freq) & core#CR0_MASK
    writereg(core#CR0, 1, @freq)

    opmode(opmode_orig)                         ' restore user's OpMode

PUB OpMode(mode) | curr_mode
' Set operating mode
'   Valid values:
'       SINGLE (0): Single-shot/normally off
'       CONT (1): Continuous conversion
'   Any other value polls the chip and returns the current setting
'   NOTE: In CONT mode, conversions occur continuously approx. every 100ms
    readreg(core#CR0, 1, @curr_mode)
    case mode
        SINGLE, CONT:
            mode := (mode << core#CMODE)
        other:
            return (curr_mode >> core#CMODE) & %1

    mode := ((curr_mode & core#CMODE_MASK) | mode) & core#CR0_MASK
    writereg(core#CR0, 1, @mode)

PUB ThermoCoupleAvg(samples) | curr_smp
' Set number of samples averaged during thermocouple conversion
'   Valid values: 1*, 2, 4, 8, 16
'   Any other value polls the chip and returns the current setting
    readreg(core#CR1, 1, @curr_smp)
    case samples
        1, 2, 4, 8, 16:
            samples := lookdownz(samples: 1, 2, 4, 8, 16) << core#AVGSEL
        other:
            curr_smp := (curr_smp >> core#AVGSEL) & core#AVGSEL_BITS
            return lookupz(curr_smp: 1, 2, 4, 8, 16)

    samples := ((curr_smp & core#AVGSEL_MASK) | samples) & core#CR1_MASK
    writereg(core#CR1, 1, @samples)

PUB ThermocoupleHighFault(thresh): curr_thr
' Set Thermocouple HIGH fault threshold
'   Valid values: -32768..32767
'   Any other value polls the chip and returns the current setting
    case thresh
        -32768..32767:
            writereg(core#LTHFTH, 2, @thresh)
        other:
            readreg(core#LTHFTH, 2, @curr_thr)
            return ~~curr_thr

PUB ThermocoupleLowFault(thresh): curr_thr
' Set Thermocouple LOW fault threshold
'   Valid values: -32768..32767
'   Any other value polls the chip and returns the current setting
    case thresh
        -32768..32767:
            writereg(core#LTLFTH, 2, @thresh)
        other:
            readreg(core#LTLFTH, 2, @curr_thr)
            return ~~curr_thr

PUB ThermoCoupleTemp{}: temp
' Read the Thermocouple temperature
    readreg(core#LTCBH, 3, @temp)
    temp ~>= 5                                  ' shift right, but keep
    return umath.multdiv(temp, TC_RES, 100_000) '   the sign
    'xxx the above won't work for negative temps (unsigned math64 object)

PUB ThermoCoupleType(type): curr_type
' Set type of thermocouple
'   Valid values: B (0), E (1), J (2), K* (3), N (4), R (5), S (6), T (7)
'   Any other value polls the chip and returns the current setting
    readreg(core#CR1, 1, @curr_type)
    case type
        B, E, J, K, N, R, S, T:
        other:
            return curr_type & core#TC_TYPE_BITS

    type := ((curr_type & core#TC_TYPE_MASK) | type) & core#CR1_MASK
    writereg(core#CR1, 1, @type)

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
