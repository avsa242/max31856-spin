This is a P8X32A/Propeller driver object for Maxim's max31856 thermocouple amplifier, written in SPIN.

The driver communicates using 4-wire SPI (expects pullups on CS, SDI, SCK). The SPI driver is written in PASM, so this driver requires one total additional cog/core.
