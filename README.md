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
* 1 extra core/cog for the PASM SPI engine (none if bytecode-based engine is used)

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Bytecode    | OK                    |
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | NuCode      | Builds, doesn't run   |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | Native code | OK                    |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Limitations

* The chip has no known identification register, so the driver will start successfully as long as the SPI engine does

