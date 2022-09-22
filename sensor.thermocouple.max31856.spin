{
    --------------------------------------------
    Filename: sensor.thermocouple.max31856.spin
    Author: Jesse Burt
    Description: Driver object for Maxim's MAX31856 thermocouple amplifier
    Copyright (c) 2022
    Created: Sep 30, 2018
    Updated: Sep 22, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#define HAS_COLDJUNC
#define HAS_THERMCPL
#include "sensor.temp.common.spinh"

CON

' Sensor resolution (deg C per LSB, scaled up)
'    TC_RES          = 0_0078125                 ' 0.0078125 * 10_000_000
    TC_RES          = 0_00781                   ' 0.00781 * 100_000
    CJ_RES          = 0_15625                   ' 0.15625 * 100_000

' Operating modes
    SINGLE          = 0
    CONT            = 1

' Interrupt modes
    COMP            = 0                         ' comparator mode
    INTR            = 1                         ' interrupt mode

' Thermocouple types
    TYPE_B          = %0000
    TYPE_E          = %0001
    TYPE_J          = %0010
    TYPE_K          = %0011
    TYPE_N          = %0100
    TYPE_R          = %0101
    TYPE_S          = %0110
    TYPE_T          = %0111
    VOLTMODE_GAIN8  = %1000
    VOLTMODE_GAIN32 = %1100

' Interrupt mask bits (OR together any combination for use with IntMask())
    CJ_HIGH         = 1 << core#CJ_HIGH
    CJ_LOW          = 1 << core#CJ_LOW
    TC_HIGH         = 1 << core#TC_HIGH
    TC_LOW          = 1 << core#TC_LOW
    OV_UV           = 1 << core#OV_UV
    OPEN            = 1 << core#OPEN

' Temperature scales
    C               = 0
    F               = 1

VAR

    byte _CS

OBJ

{ decide: Bytecode SPI engine, or PASM? Default is PASM if BC isn't specified }
#ifdef MAX31856_SPI_BC
    spi : "com.spi.nocog"                       ' BC SPI engine
#else
    spi : "com.spi.4w"                          ' PASM SPI engine
#endif
    core: "core.con.max31856"                   ' HW-specific constants

PUB null{}
' This is not a top-level object

PUB startx(CS_PIN, SCK_PIN, SDI_PIN, SDO_PIN): status
' Start using custom settings
    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and {
}   lookdown(SDI_PIN: 0..31) and lookdown(SDO_PIN: 0..31)
        if (status := spi.init(SCK_PIN, SDI_PIN, SDO_PIN, core#SPI_MODE))
            _CS := CS_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    spi.deinit{}
    _CS := 0

PUB cj_inthighthresh(thresh): curr_thr
' Set Cold-Junction HIGH fault threshold
'   Valid values: -128..127 (default: 127)
'   Any other value polls the chip and returns the current setting
    case thresh
        -128..127:
            writereg(core#CJHF, 1, @thresh)
        other:
            readreg(core#CJHF, 1, @curr_thr)
            return ~~curr_thr

PUB cj_intlowthresh(thresh): curr_thr
' Set Cold-Junction LOW fault threshold
'   Valid values: -128..127 (default: -64)
'   Any other value polls the chip and returns the current setting
    case thresh
        -128..127:
            writereg(core#CJLF, 1, @thresh)
        other:
            readreg(core#CJLF, 1, @curr_thr)
            return ~~curr_thr

PUB cj_sensorenabled(state): curr_state
' Enable the on-chip Cold-Junction temperature sensor
'   Valid values: *TRUE (-1 or 1), FALSE
'   Any other value polls the chip and returns the current setting
    readreg(core#CR0, 1, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) ^ 1) << core#CJ ' logic is inverted in the reg
        other:                                  ' so flip the bit
            return (((curr_state >> core#CJ) & 1) ^ 1) == 1

    state := ((curr_state & core#CJ_MASK) | state) & core#CR0_MASK
    writereg(core#CR0, 1, @state)

PUB cj_word2temp(cj_word): temp
' Convert cold-junction ADC word to temperature, in hundredths of a degree
'   in chosen scale
    temp := (cj_word * CJ_RES) / 10_000
    case _temp_scale
        C:
        F:
            temp := ((temp * 90) / 50) + 32_00

PUB cj_bias(offset): curr_offs
' Set Cold-Junction temperature sensor offset, in ten-thousandths of a degree C
'   Valid values: -8_0000..7_9375 (default: 0)
'   Any other value polls the chip and returns the current setting
    case offset
        -8_0000..7_9375:
            offset /= 0_0625
            writereg(core#CJTO, 1, @offset)
        other:
            readreg(core#CJTO, 1, @curr_offs)
            return (~curr_offs * 0_0625)

PUB cj_data{}: cj_word
' Read cold-junction data
'   Returns: s16
    cj_word := 0
    readreg(core#CJTH, 2, @cj_word)
    ~~cj_word                                   ' extend sign from bit 15
    cj_word ~>= 2                               ' right-justify, keeping sign
                                                ' (ADC word is left-justified)

PUB intclear{} | tmp
' Clear fault status
'   NOTE: This has no effect when FaultMode is set to FAULTMODE_COMP
    readreg(core#CR0, 1, @tmp)
    tmp &= core#FAULTCLR_MASK
    tmp := (tmp | (1 << core#FAULTCLR)) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

PUB interrupt{}: src
' Return interrupt status
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
'   NOTE: Asserted interrupts will always be flagged in this register,
'       regardless of the set interrupt mask
'   NOTE: FAULT pin is active low
    readreg(core#SR, 1, @src)

PUB intmask(mask): curr_mask
' Set interrupt mask (affects FAULT pin only)
'   Valid values:
'   Bits: 543210 (For each bit, 0: disable interrupt, 1: enable interrupt)
'       Bit 5   Cold-junction interrupt HIGH threshold
'           4   Cold-junction interrupt LOW threshold
'           3   Thermocouple temperature interrupt HIGH threshold
'           2   Thermocouple temperature interrupt LOW threshold
'           1   Over-voltage or under-voltage input
'           0   Thermocouple open-circuit
'   Example: %000010 would assert the /FAULT pin when an over-voltage or
'       under-voltage condition is detected
'   Any other value polls the chip and returns the current setting
'   NOTE: FAULT pin is active low
    case mask
        %000000..%111111:
            ' the chip considers cleared bits as enabled and set bits
            ' as masked off, so invert the mask set by the user
            ' before actually writing it to the chip
            mask := (mask ^ core#FAULTMASK_MASK)
            mask |= (core#RSVD_BITS << core#RSVD)
            writereg(core#FAULTMASK, 1, @mask)
        other:
            readreg(core#FAULTMASK, 1, @curr_mask)
            return (curr_mask ^ core#FAULTMASK_MASK)

PUB intmode(mode): curr_mode
' Set interrupt mode
'   Valid values:
'       *COMP (0): Comparator mode - fault flag will be asserted
'       when fault condition is true, and will clear when the condition is
'       no longer true, _with a 2deg C hysteresis._
'
'       INTR (1): Interrupt mode - fault flag will be asserted when
'       fault condition is true, and will remain asserted until fault status
'       is explicitly cleared with IntClear().
'       NOTE: If the fault condition is still true when the status is cleared,
'       the flag will be asserted again immediately.
'   Any other value polls the chip and returns the current setting
    readreg(core#CR0, 1, @curr_mode)
    case mode
        COMP, INTR:
            mode := mode << core#FAULT
        other:
            return ((curr_mode >> core#FAULT) & 1)

    mode := ((curr_mode & core#FAULT_MASK) | mode) & core#CR0_MASK
    writereg(core#CR0, 1, @curr_mode)

PUB measure{} | tmp
' Perform single cold-junction and thermocouple conversion
'   NOTE: Single conversion is performed only if OpMode() is set to SINGLE
' Approximate conversion times:
'   Filter Setting      Time
'   60Hz                143ms
'   50Hz                169ms
'   NOTE: Conversion times will be reduced by approximately 25ms if the
'       cold-junction sensor is disabled
    readreg(core#CR0, 1, @tmp)
    tmp &= core#ONESHOT_MASK
    tmp := (tmp | (1 << core#ONESHOT)) & core#CR0_MASK
    writereg(core#CR0, 1, @tmp)

PUB notchfilter(freq): curr_freq | opmode_orig
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
            curr_freq &= 1
            return lookupz(curr_freq: 60, 50)

    freq := ((curr_freq & core#NOTCHFILT_MASK) | freq) & core#CR0_MASK
    writereg(core#CR0, 1, @freq)

    opmode(opmode_orig)                         ' restore user's OpMode

PUB ocfaulttesttime(time_ms): curr_time 'XXX Note recommendations based on circuit design
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

PUB opmode(mode): curr_mode
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
            return (curr_mode >> core#CMODE) & 1

    mode := ((curr_mode & core#CMODE_MASK) | mode) & core#CR0_MASK
    writereg(core#CR0, 1, @mode)

PUB tc_avg(samples): curr_smp
' Set number of samples averaged during thermocouple conversion
'   Valid values: *1, 2, 4, 8, 16
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

PUB tc_data{}: temp_word
' Read thermocouple data
'   Returns: s19
    temp_word := 0
    readreg(core#LTCBH, 3, @temp_word)
    temp_word <<= 8                             ' extend sign from bit 23
    temp_word ~>= 13                            ' right-justify, keeping sign
                                                ' (ADC word is left-justified)

PUB tc_inthighthresh(thresh): curr_thr
' Set thermocouple interrupt high threshold
'   Valid values: -32768..32767 (default: 32767)
'   Any other value polls the chip and returns the current setting
    case thresh
        -32768..32767:
            writereg(core#LTHFTH, 2, @thresh)
        other:
            readreg(core#LTHFTH, 2, @curr_thr)
            return ~~curr_thr

PUB tc_intlowthresh(thresh): curr_thr
' Set thermocouple interrupt low threshold
'   Valid values: -32768..32767 (default: -32768)
'   Any other value polls the chip and returns the current setting
    case thresh
        -32768..32767:
            writereg(core#LTLFTH, 2, @thresh)
        other:
            readreg(core#LTLFTH, 2, @curr_thr)
            return ~~curr_thr

PUB tc_type(type): curr_type
' Set type of thermocouple
'   Valid values: TYPE_B (0), TYPE_E (1), TYPE_J (2), *TYPE_K (3), TYPE_N (4),
'       TYPE_R (5), TYPE_S (6), TYPE_T (7)
'   Any other value polls the chip and returns the current setting
    readreg(core#CR1, 1, @curr_type)
    case type
        TYPE_B, TYPE_E, TYPE_J, TYPE_K, TYPE_N, TYPE_R, TYPE_S, TYPE_T:
        other:
            return curr_type & core#TC_TYPE_BITS

    type := ((curr_type & core#TC_TYPE_MASK) | type) & core#CR1_MASK
    writereg(core#CR1, 1, @type)

PUB tc_word2temp(tc_word): temp
' Convert thermocouple ADC word to temperature, in hundredths of a degree
'   in chosen scale
    temp := (tc_word * TC_RES) / 1000
    case _temp_scale
        C:
        F:
            temp := ((temp * 90) / 50) + 32_00

PUB tempword2deg(tword): temp
' Alias for TCWord2Temp
    return tc_word2temp(tword)

PRI readreg(reg_nr, nr_bytes, ptr_buff) | tmp
' Read nr_bytes from device into ptr_buff
    case reg_nr                                 ' validate register
        core#CR0..core#SR:
        other:                                  ' invalid; return
            return

    outa[_CS] := 0
    spi.wr_byte(reg_nr)                         ' shift out reg number
    spi.rdblock_msbf(ptr_buff, nr_bytes)        ' then read data, MSByte-first
    outa[_CS] := 1

PRI writereg(reg_nr, nr_bytes, ptr_buff) | tmp
' Write nr_bytes from ptr_buff to device
    case reg_nr
        core#CR0..core#CJTL:
            reg_nr |= core#WRITE_REG            ' OR reg_nr with $80 to write
        other:
            return

    outa[_CS] := 0
    spi.wr_byte(reg_nr)
    spi.wrblock_msbf(ptr_buff, nr_bytes)
    outa[_CS] := 1

DAT
{
Copyright 2022 Jesse Burt

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

