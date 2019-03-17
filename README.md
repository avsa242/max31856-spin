# max31856-spin 
---------------

This is a P8X32A/Propeller driver object for Maxim's MAX31856 SPI Thermocouple amplifier IC.

## Salient Features

* Reads on-chip cold-junction temperature sensor
* Supports automatic or one-shot conversion modes
* Supports built-in cold-junction offset compensation
* Supports 50/60Hz mains power frequency noise rejection

## Requirements

* Requires one extra cog/core for PASM SPI driver

## Limitations

* The chip has no known identification register, so the driver will start successfully as long as the SPI driver does
* Driver is early in development and may malfunction or outright fail to build

## TODO

* Implement remaining functionality described in datasheet
* Implement demo and test objects
