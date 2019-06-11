# max31856-spin 
---------------

This is a P8X32A/Propeller driver object for Maxim's MAX31856 SPI Thermocouple amplifier IC.

## Salient Features

* 4-wire SPI connection at up to 1MHz (device supports 5MHz)
* Reads on-chip cold-junction temperature sensor
* Reads thermocouple
* Supports automatic or one-shot conversion modes
* Supports built-in cold-junction offset compensation
* Supports 50/60Hz mains power frequency noise rejection
* Supports setting temperature fault thresholds
* Supports setting/checking for all fault types supported by the sensor
* Supports setting thermocouple type

## Requirements

* Requires one extra cog/core for PASM SPI driver

## Limitations

* The chip has no known identification register, so the driver will start successfully as long as the SPI driver does
* Driver is early in development and may malfunction or outright fail to build
* Driver currently returns temperature data as hundredths of a degree

## TODO

- [ ] Modify ColdJuncOffset to take degrees as a parameter, rather than s8
- [x] Implement remaining functionality described in datasheet (*implemented, but some methods' parameters are currently raw values not calculated to any scale*)
- [x] Implement demo and test objects
