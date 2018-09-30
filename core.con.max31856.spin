CON

'' SPI Clock Polarity/Mode
    CPOL            = 1

'' Read register addresses ORd with $80 to form Write Addresses
    W               = $80

'' Configuration 0
    REG_CR0_R       = $00
    REG_CR0_W       = REG_CR0_R|W
        CMODE_OFF   = %0
        CMODE_AUTO  = %1 << 7
'' Configuration 1
    REG_CR1_R       = $01
    REG_CR1_W       = REG_CR1_R|W

'' Fault mask
    REG_MASK_R      = $02
    REG_MASK_W      = REG_MASK_R|W

'' Cold-junction high-fault threshold
    REG_CJHF_R      = $03
    REG_CJHF_W      = REG_CJHF_R|W

'' Cold-junction low-fault threshold
    REG_CJLF_R      = $04
    REG_CJLF_W      = REG_CJLF_R|W

'' Linearized temperature High-fault threshold
    REG_LTHFTH_R    = $05
    REG_LTHFTH_W    = REG_LTHFTH_R|W
    REG_LTHFTL_R    = $06
    REG_LTHFTL_W    = REG_LTHFTL_R|W

'' Linearized temperature Low-fault threshold
    REG_LTLFTH_R    = $07
    REG_LTLFTH_W    = REG_LTLFTH_R|W
    REG_LTLFTL_R    = $08
    REG_LTLFTL_W    = REG_LTLFTL_R|W

'' Cold-junction Temperature Offset
    REG_CJTO_R      = $09
    REG_CJTO_W      = REG_CJTO_R|W

'' Cold-junction Temperature
    REG_CJTH_R      = $0A
    REG_CJTH_W      = REG_CJTH_R|W
    REG_CJTL_R      = $0B
    REG_CJTL_W      = REG_CJTL_R|W

'' Linearized TC Temperature (19bits; LTCBH=MSB, LTCBL=LSB, 5 LSB of LTCBL unused)
    LTCBH           = $0C
    LTCBM           = $0D
    LTCBL           = $0E
    
'' Fault Status
    REG_SR          = $0F
    
PUB Null
'' This is not a top-level object
