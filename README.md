# ARES Software Development Kit

ARES is a small nanokernel operating system written in the [Second Life](https://secondlife.com/) [Linden Scripting Language](https://wiki.secondlife.com/wiki/LSL_Portal). It is normally used to power immersive HUD attachments for roleplaying as a robot, but in principle can be adapted as a general-purpose platform through the addition and removal of system components.

ARES provides a robust API which is quite dissimilar to normal LSL programming. Here are the highlights:
- Many common "`ll`"-prefixed LSL functions are renamed for brevity and convenience. This was optional in Companion but highly encouraged in ARES. These definitions come from the `utils.lsl` file in the SDK root.
- No `default {}` state—the program's entry point for command-line use is the `SIGNAL_INVOKE` block inside a `main()` function. Timers and events like `on_rez` are emulated through kernel signals, but can still be implemented for programs that need high performance.
- A basic stream API is used for text input and output, similar to Unix pipes. `llSay(0, "Hello World!");` is now `print(outs, user, "Hello World!");` — pipes can be chained together to automatically pass messages from one program to another, or even in and out of normal chat.

## ARES SDK
ARES software development requires the Firestorm viewer, which augments the LSL compilation process with the [Boost::Wave](https://www.boost.org/doc/libs/1_40_0/libs/wave/index.html) preprocessor. The SDK includes UDL 2.1 syntax highlighting definitions for Notepad++ (provided you like dark mode.)

To install the SDK, download this Git repo's contents into a new directory (ideally one without any spaces in the path), and configure Firestorm's preprocessor (Preferences > Firestorm > Build 1) to point at it. The LSL preprocessor must be enabled, along with the 'Script optimizer' and '#includes from local disk' checkboxes.

**Not all of the files in the ARES SDK may be reused freely**. Your use of the SDK is subject to the terms of the [ARES Software Copyright License](http://nanite-systems.com/ASCL).  Please make sure you are familiar with the terms of the ASCL's different sublicenses before downloading.

Once the SDK is installed, look for the file `ARES/application/template.lsl` as a basis for writing your own programs.

### Hardware Development

Device development for ARES is similar to development for Companion, and most of the familiar processes still apply. Most development is done using the <a href="/light_bus">light bus</a>, albeit with minor differences. For the time being, starting materials can be found from the Companion 8 SDK, available for free from our store in Eisa. ARES also uses many of the <a href="/public_bus">public bus</a> commands, and compatibility with ACS devices and interference is similar to that of Companion.

### Packaging and Distribution
The server axtest:1 in Eisa contains the `sample` package, which is a self-documenting template for creating your own packages. To obtain it, use the following commands while in Eisa:

```@software connect 0ad8309f-e354-e1c2-a799-b2746b8b276b
@software update
@software install sample
```

This will store the relevant files (sample-3.0.0.pkg, sample-3.0.0.ax.parc, and sample.info) in user memory (link 3) of your ARES HUD. Copy all three to your avatar inventory and modify them as you see fit. When you are done developing your project, pack all files except the .pkg manifest into the .ax.parc archive, and submit both the .pkg and .ax.parc to the package server. (Remember to change all the names and version numbers!)

### File Licenses
Most of the files in the SDK are ASCL-iii, which is a "BSD-like" permissive open source license that allows for closed-source derivatives. However, many (especially those in the `ARES/application/` directory) fall under more restrictive licenses. See the opening block comment in each program for more information.