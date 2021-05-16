# max31856-spin 
---------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Maxim's MAX31856 SPI Thermocouple amplifier IC.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* 4-wire SPI connection at up to 1MHz (P1), 5MHz (P2)
* Reads on-chip cold-junction temperature sensor
* Reads thermocouple
* Supports automatic or one-shot conversion modes
* Supports built-in cold-junction offset compensation
* Supports 50/60Hz mains power frequency noise rejection
* Supports setting temperature interrupt thresholds
* Supports setting/checking for all fault types supported by the sensor
* Supports setting thermocouple type

## Requirements

P1/SPIN1:
* spin-standard-library
* P1/SPIN1: 1 extra core/cog for the PASM SPI driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81), FlexSpin (tested with 5.3.3-beta)
* P2/SPIN2: FlexSpin (tested with 5.3.3-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* The chip has no known identification register, so the driver will start successfully as long as the SPI driver does

## TODO

- [ ] Modify ColdJuncOffset to take degrees as a parameter, rather than s8
- [x] Handle Celsius/Fahrenheit in the driver
- [x] Handle byte order in a cleaner fashion
- [x] Implement remaining functionality described in datasheet (*implemented, but some methods' parameters are currently raw values not calculated to any scale*)
- [x] Implement demo and test objects
