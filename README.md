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
The server axtest:0 in Eisa contains the `sample` package, which is a self-documenting template for creating your own packages.
ARES package servers are not yet available for purchase. In the interim, note that any inventory items (with the exception of scripts) ctrl-dragged onto the ARES HUD will be automatically relocated to user memory, where you may act upon them.

### File Licenses
Most of the files in the SDK are ASCL-iii, which is a "BSD-like" permissive open source license that allows for closed-source derivatives. However, many (especially those in the `ARES/application/` directory) fall under more restrictive licenses, as summarized below.

|file|description|terms|
|--- |--- |--- |
|ARES/application/calc.lsl|calculator|ASCL-ii (copyleft/share-alike)|
|ARES/application/db.lsl|database utility|ASCL-ii (copyleft/share-alike)|
|ARES/application/define.lsl|wiki lookup|ASCL-ii (copyleft/share-alike)|
|ARES/application/filter.lsl|vox filters|ASCL-i (modding only)|
|ARES/application/find.lsl|grep clone (WIP)|ASCL-ii (copyleft/share-alike)|
|ARES/application/fortune.lsl|GNU fortune frontend|ASCL-ii (copyleft/share-alike)|
|ARES/application/fortune.h.lsl|GNU fortune frontend (dependency)|ASCL-i (modding only)|
|ARES/application/help.lsl|manual interface|ASCL-ii (copyleft/share-alike)|
|ARES/application/id.lsl|system configuration tool|ASCL-i (modding only)|
|ARES/application/land.lsl|parcel and region utilities|ASCL-ii (copyleft/share-alike)|
|ARES/application/lslisp.lsl|LSLisp programming language|ASCL-ii (copyleft/share-alike)|
|ARES/application/mantra.lsl|self-hypnosis tool|ASCL-ii (copyleft/share-alike)|
|ARES/application/mail.lsl|email utility|ASCL-ii (copyleft/share-alike)|
|ARES/application/media.lsl|sound & animation playback widget|ASCL-ii (copyleft/share-alike)|
|ARES/application/media.event.lsl|sound & animation playback widget (dependency)|ASCL-ii (copyleft/share-alike)|
|ARES/application/news.lsl|RSS aggregator|ASCL-ii (copyleft/share-alike)|
|ARES/application/persona.lsl|personality configuration tool|ASCL-ii (copyleft/share-alike)|
|ARES/application/scidb.lsl|scientific database query tool|ASCL-ii (copyleft/share-alike)|
|ARES/application/tell.lsl|sends chat messages|ASCL-ii (copyleft/share-alike)|
|ARES/application/xset.lsl|captures standard output|ASCL-ii (copyleft/share-alike)|
|ARES/system/exec.lsl|command shell|ASCL-i (modding only)|
|ARES/system/exec.event.lsl|command shell (dependency)|ASCL-i (modding only)|
|ARES/system/policy.lsl|security policies|ASCL-i (modding only)|
|ARES/system/power.lsl|subsystem manager|ASCL-i (modding only)|
|ARES/system/security.lsl|user access control|ASCL-i (modding only)|
|glob.lsl|Linux filename pattern matching|Dual GPL 2.0 and MIT|
|lslisp.lsl|LSLisp programming language|ASCL-ii (copyleft/share-alike)|
|lslisp.h.lsl|LSLisp programming language|ASCL-ii (copyleft/share-alike)|

In case of disagreements or omissions between actual files and the entries above, license declarations inside the files take precedence.