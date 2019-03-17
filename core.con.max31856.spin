{
    --------------------------------------------
    Filename: core.con.max31856.spin
    Author: Jesse Burt
    Description: Low-level driver constants
    Copyright (c) 2019
    Created: Sep 30, 2018
    Updated: Mar 16, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Clock Polarity/Mode
    CPOL                = 1
    CLK_DELAY           = 10
    MOSI_BITORDER       = 5             'MSBFIRST
    MISO_BITORDER       = 2             'MSBPOST

' Read register addresses ORd with $80 to form Write Addresses
    WRITE_REG           = $80

    CR0                 = $00
    CR0_MASK            = $FF
        FLD_CMODE       = 7
        MASK_CMODE      = CR0_MASK ^ (1 << FLD_CMODE)

    CR1                 = $01

    MASK                = $02

    CJHF                = $03

    CJLF                = $04

    LTHFTH              = $05
    LTHFTL              = $06

    LTLFTH              = $07
    LTLFTL              = $08

    CJTO                = $09

    CJTH                = $0A
    CJTL                = $0B

    LTCBH               = $0C
    LTCBM               = $0D
    LTCBL               = $0E
    
    SR                  = $0F
    
PUB Null
' This is not a top-level object
