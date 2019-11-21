# max31856-spin 
---------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Maxim's MAX31856 SPI Thermocouple amplifier IC.

## Salient Features

* 4-wire SPI connection at up to 5MHz (verification of actual bus clock TBD)
* Reads on-chip cold-junction temperature sensor
* Reads thermocouple
* Supports automatic or one-shot conversion modes
* Supports built-in cold-junction offset compensation
* Supports 50/60Hz mains power frequency noise rejection
* Supports setting temperature fault thresholds
* Supports setting/checking for all fault types supported by the sensor
* Supports setting thermocouple type

## Requirements

* P1/SPIN1: 1 extra core/cog for the PASM SPI driver
* P2/SPIN2: N/A

## Compiler compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.0.3-beta)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* The chip has no known identification register, so the driver will start successfully as long as the SPI driver does

## TODO

- [ ] Modify ColdJuncOffset to take degrees as a parameter, rather than s8
- [ ] Handle Celsius/Fahrenheit in the driver
- [ ] Handle byte order in a cleaner fashion
- [x] Implement remaining functionality described in datasheet (*implemented, but some methods' parameters are currently raw values not calculated to any scale*)
- [x] Implement demo and test objects
