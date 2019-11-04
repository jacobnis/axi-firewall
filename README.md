# AXI Firewall

A flexible and lightweight security-enhanced hardware wrapper for cores with an
AXI interface. Cores can be easily integrated into the wrapper and
subsequently connected to the AXI bus. The wrapper stores access commands and
prevents the core from accessing other memory regions than designated by
software driving it through the command interface. In principle it can be
regarded as a stripped-down IOMMU. However, functionality is restricted to a
minimum to support easy review, and a small trusted code base for easy re-use.

This repository is part of the paper "How to Break Secure Boot on FPGA SoCs
through Malicious Hardware", which will be presented at
[CHES 2017](https://ches.iacr.org/2017/).

## Repository

|        Folder        |                        Description                           |
| -------------------- | ------------------------------------------------------------ |
| [hdl](./hdl)		     | VHDL files for the security enhanced AXI wrapper             |
| [example](./example) | Working directory of an example IP core using the wrapper    |
| [paper](./paper)     | Related publication at the <a href="https://link.springer.com/chapter/10.1007/978-3-319-66787-4_21">CHES2017</a> conference |

## Example
This folder consists of example IP core with the security enhanced AXI wrapper.
For this example the a simple XOR IP core is implemented. 
This is a place holder for high speed cryptographic core.
The IP core was packaged using Vivado for the Xilinx 7 series FPGAs.

## License

This project is released under the MIT [License](./LICENSE).
