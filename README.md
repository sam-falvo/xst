# Experimental Serial Transmitter (XST) and Receiver (XSR)

The Kestrel-3's new mainframe-inspired architecture
will need high-performance I/O channels
to communicate with intelligent peripherals with.
Many serial protocols exist:
SPI,
EIA-232,
IEEE-1355/Spacewire,
Ethernet,
PS/2 Keyboard/Mouse,
and so forth.
XST aims to implement a serial output *transmitter* capable of servicing
SPI,
EIA-232/422/485,
and PS/2
devices.
This core aims to replace the use of IEEE-1355 REMEX
as I've discovered IEEE-1355 to have hidden complexities
which inhibits a single person from succeeding in its implementation.

Except for its use in an SPI context,
this core *does not* attempt to handle receiving data.

In the future,
this package *may* also provide a complimentary XSR core for receiving data as well.

## Why not base Remex ports on IEEE-1355?

Making a receiver for IEEE-1355 or Spacewire
(hereafter collectively called "Spacewire")
is rather simple.
Making the transmitter section of a Spacewire link, however,
requires surprisingly complicated state machines
which renders implementation by a single person (namely **me**) nearly impossible.
Since I'm the only person working on the Kestrel-3 at the moment,
it's important that I restrict myself to technology
which I can grasp without any unnecessary effort.

Further, EIA-232 defines a *very* standardized,
*very* widely available serial interconnect.
Even the smallest and cheapest of off-the-shelf microcontrollers typically includes a UART,
capable of handling data rates adequate for most non-bulk-transfer applications.
Implementing EIA-232 in software is a solved problem for many platforms.

When EIA-232 fails you, SPI picks up the slack in many cases.
SPI handles multi-megabit-per-second data rates with ease,
and is even *easier* to implement in software for those cheap microcontrollers which lack an available dedicated controller.
SPI introduces some tradeoffs, however.
You need at least one general-purpose output pin to serve as a slave-select signal.
To support asynchronous feedback from a slave,
you'll also need a general purpose input pin to serve as an interrupt request or attention signal.
Otherwise, SPI is *strictly* master-slave;
EIA-family operation works on a more peer-to-peer basis.

Since most of the benefits of Spacewire's hardware level protocol
can be achieved using clever software stacks
on either side of the link,
and since I'm targeting small-to-mid-sized FPGAs with the latest Kestrel-3 specifications,
I think it makes sense
to explore the use of a serial transmitter
capable of supporting the two most popular serial interconnects on the planet today
(after Ethernet, that is).

It is said that Spacewire implementations can be realized
with resources on par with a UART
(it is never mentioned *which* UART they're comparing against).
Synthesis results show this to not be generally true.

We can estimate overall complexity in terms of LUTs/word size supported.
[My Remex core consists of two parts, a receiver and a transmitter,](https://github.com/sam-falvo/remex)
which, as I write this, are not interconnected.
This allows me to focus easily on the transmitter logic in isolation.

The transmitter cores implemented so far consume 75 LUTs of a iCE40HX4K/8K part.
Since the shift register is only 8-bits wide,
we can estimate complexity at 9.3 LUTs/bit shifted.

The XST core synthesized to 289 LUTs, which is significantly larger area than the Remex TX engine.
However, XST also uses a 64-bit shift register,
which brings its complexity to 4.5 LUTs/bit shifted.
XST is slightly better than twice as area efficient as Spacewire,
particularly for packets of 8 bytes or less in SPI mode.

For EIA-232-specific applications, you simply don't need all 64 bits.
11 bits will suffice, supporting 8 data bits, a parity bit, and two stop bits.
When the `xst.v` file was refit for this constraint,
the core synthesized to only 118 LUTs.
This equates to an area efficiency of 14.75 LUTs/bit.

If we were to extrapolate complexity from Spacewire's efficiency,
we would expect to see a complexity of 9.3 LUTs/bit &times; 11 bits = 102.3 LUTs.
Thus, we're about 13% less area efficient than expected.
However, we must remember that the TX engine in the Spacewire implementation *is not finished.*
It still lacks the hardware protocol state machine!
Meanwhile, XST is *functionally complete* as transmitters go,
and is actually usable at least as a MMIO-accessible SPI engine *today* if you wanted to.

Based on this analysis,
*complete* Spacewire implementations
will always consume
more resources than a comparably sized UART.

Spacewire transmitters also proves *slower* than comparable UART-based designs.
Based on the timing analyses provided by the `icotime` tool,
XST out-performs Remex's minimal implementation handily.

The following table summarizes my results.

| Parameter             | Remex TX Engine (unfinished) | XST 64-bit   | XST 11-bit     |
|:---------------------:|:---------------:|:------------:|:--------------:|
| Bits Configured       | 8               | 64           | 11             |
| Max Data Rate (w/ TXC)| 25 Mbps         | 53.5 Mbps    | 53.5 Mbps      |
| Max Data Rate         | 25 Mbps         | 107 Mbps     | 107 Mbps       |
| Max Clock Freq.       | 75 MHz          | 107 MHz      | 107 MHz        |
| LUTs                  | 75              | 289          | 118            |
| LUTs/Bit              | 9.3 LUTs/bit    | 4.5 LUTs/bit | 14.75 LUTs/bit |
| LSB-first shifting    | YES             | YES          | YES            |
| MSB-first shifting    | NO              | YES          | YES            |

Remember that LSB/MSB-first agility is required to support both EIA-232 (LSB-first) and SPI (MSB-first) formats.
The XST core would be *smaller still* if this logic were removed.

## What Will Become of the IEEE-1355 Remex concept?

If XST proves easier to implement,
and especially, comparably easy to support in software,
IEEE-1355 will be displaced in favor of a re-engineered, non-prototype version of XST.
The non-prototype versions of the XST and XSR cores
are probably going to be given the name GSIA (General Serial Interface Adapter).
The GSIA will likely also subsume the functionality of the KIA and KIA-2 cores as well.

## How Does the Remex Port Pin-Out Change?

Instead of:

|Pin|Name|
|:-:|:--:|
|1  |TD  |
|2  |TS  |
|3  |RD  |
|4  |RS  |

We simply replace Spacewire's "strobe" signals with explicitly forwarded clocks:

|Pin|Name|
|:-:|:--:|
|1  |TXD |
|2  |TXC |
|3  |RXD |
|4  |RXC |

The explicit clock forwarding allows for multi-megabit-per-second service.

A real-world implementation of XST, such as the GSIA,
must support reconfiguring the Pmod pinout according to attached peripheral:

* Mode 2 pinout supports SPI slaves.
* Modes 3, 4A, and 4B offer three different pinout variants for EIA-232 with hardware handshake.
* Remex pinout ("Mode 7") supports higher-throughput peripherals suitable for, e.g., block storage devices.
* SD card ("Mode 8") supports SD cards (not 100% compatible with Mode 2, unfortunately).

These six different modes are **not** addressed by XST.

## Theory of Operation

At its core is a 64-bit shift register called `TXREG`.
The shift register always shifts to the right (e.g., LSB outputs first).
This supports EIA-232/422/423/485 links, Spacewire links, and PS/2 links.

The host loads a value into any portion of `TXREG` via whatever memory or I/O store operation it normally uses.
When this happens, another register `BITS` is reloaded from another configuration register (not specified).
As you might have guessed, `BITS` contains the maximum number of bits that needs to be sent.

The `TXD` output signal always reflects the state of `TXREG[0]`.
When a signal `TXSHEN` is asserted *and* the system clock goes high,
`TXREG` shifts right one bit position.
Bit 63 is loaded with whatever value appeared on `RXD` at the time.
In this way, supporting SPI is automatic.

               64-bit data bus to/from CPU
                    ~~~~~~~~~~~~~~~~~
                    |               |
                   /                 \
                  --.               .--
                    |               |
                  __|               |__
                   \                 /
                    |               |
                +-----------------------+
    RXD o------>| 64-bit shift register |-------> TXD
                +-----------------------+
                    |  |  |  |
    TXREG_WE o------+  |  |  |  (asserted when CPU writes to TXREG)
    TXREG_OE o---------+  |  |  (asserted when CPU reads from TXREG)
    TXSHEN   o------------+  |
    CLK      o---------------+

### Sending EIA-232 and PS/2 Character Frames

Characters comprise of one start bit, *n* data bits, an optional parity bit, followed by *at least* one stop bit.
Assuming the host wishes to send a byte in `chrOut`,
it may do so by shifting its value into an appropriate place,
setting parity if required,
and asserting the stop bit(s):

    #define STOP_BIT    0x400

    txreg_value = (chrOut << 1)                 // adds start bit (0)
                | (parity_for(chrOut) << 9)     // adds parity bit (if required)
                | STOP_BIT;                     // adds the stop bit(s).

Prior to stuffing this value into the `TXREG` register,
the `BITS` register should be set to 1+8+1+1 = 11 (the sum of all the bits that need to be sent).

As long as `RXD` is configured to repeat bit 63 of `TXREG`,
and all bits in `TXREG[63:11]` are *set*,
this is a necessary and sufficient condition to support transmitting EIA-232 characters.

The baud rate generator (not specified)
must also be configured to generate `TXSHEN` pulses at the appropriate rate.


### Sending SPI Data

Unlike EIA-232 and PS/2 signaling requirements,
SPI generally shifts data **MSB**-bit first.
To support this, the XST provides a `TXREGR` register.
This register references the exact same shift register as `TXREG`,
but does so with all the data bits *reversed*.
That is, what you write in bit 0 will be received by `TXREG` in bit 63,
bit 1 will be received in bit 62,
bit 2 in bit 61, and so forth.
Put another way, this will load `TXREG` with the MSB in bit 0 (which is always shifted first),
and the LSB in an appropriate higher bit.

Sending data simply requires you to send the data in the *upper-most* bits of `TXREGR`,
since you don't have framing bits to worry about.
The *slave-select* signal is responsible for framing.
Simply write the data you wish to send to the `TXREGR` register
(**NOTE**: *not* `TXREG`!).

    // bits = 8;
    txregr_value = chrOut << 56;

Obviously, if you need to send more than 8 bits, be sure to shift an appropriate amount:

    // bits = 12;
    txregr_value = wordOut << 52;

### Receiving SPI Data

When data is shifted out onto TXD,
whatever appears on the `RXD` input will be shifted in from the opposite end of the shift register.
For EIA-232/422/485 and PS/2 operations, you normally want this to be the sign-bit of the register.
For SPI, however, `RXD` should be driven by the selected slave peripheral.

Thus, as data are shifted out the top of the shift register MSB-first (when written using `TXREGR`),
new data are shifted in starting at bit 0, also MSB-first (assuming you read from `TXREGR`).
The receiver need only mask the value appropriately to discard previously read data.

    // bits = 10;
    received_data = txregr_value & 0x3FF;

### Observation on Some SPI Device Protocols

Many SPI devices
(particularly memories, such as SD or SPI Flash memories)
expose a strictly command/response protocol.
Most require between four and eight bytes for commands.
Therefore, the XST is suitable for easily working with these devices
with at most two write operations:
one to set the desired number of command bits,
and one to set the actual payload.

## Host Bus Interface

The XST core does not explicitly provide any official form of host interface.
However, if one were to be provided,
it probably would look something like this:

|Offset|Name  |R/W|Description|
|:----:|:----:|:-:|:----------|
|00    |TXREG |R/W|Bits [63:0] of the output shift register.  Shifts LSB first.|
|08    |TXREGR|R/W|Bits [0:63] of the output shift register.  *Appears* to shift MSB first.|
|10    |TXCTL |R/W|Configures and reports status of the transmitter.  Described below.|
|18    |TXBAUD|R/W|Down-counter that determines transmission data rate.|

### TXCTL

Important groups of signals are aligned on 8-bit boundaries to make it easier to operate on sub-fields of this register.

|Bit(s)|Name     |R/W|Description|
|:----:|:-------:|:-:|:----------|
|63    |TxIrqP   |R/O|0 = no service requested; 1 = At least one IRQ is pending and enabled.|
|62:25 |---      |R/O|Undefined; reads as 0.|
|24    |TxIdleEn |R/W|1 = IRQ for idle transmitter is enabled.|
|23:17 |---      |R/O|Undefined; reads as 0.|
|16    |TxIdleP  |R/W|1 = Transmitter is idle.|
|15:8  |---      |R/O|Undefined; reads as 0.|
|7:6   |TxFillSrc|R/W|Source for fill bits: 00=Always 0; 01=always 1; 10=external `RXD` pin; 11=Recirculate `TXREG`|
|5:0   |TxBits   |R/W|Number of bits to shift (0 = 64 bits)|

The `TxIrqP` signal is placed at bit 63 to facilitate rapid service checks using signed less-than-zero comparisons and branches.

A proper UART-class device would probably also provide interrupts for handshaking signals.
