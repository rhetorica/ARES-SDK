# Light Bus Protocol

The Light Bus is the main communications system for interactions between the system and compatible hardware. Originally designed for attached peripherals carrying lighting-related state (color, power), it has grown into a full protocol covering recharging, user authentication, and device control.

## Channel

Messages are exchanged on a per-user channel:

```lsl
channel_lights = 105 - (integer)("0x" + llGetSubString(llGetOwner(), 29, 35));
```

## Device Categories

| Category    | Description                                                                                                    |
|-------------|----------------------------------------------------------------------------------------------------------------|
| **Passive** | Listens for messages and reacts. No authentication required. Examples: status lights, eyes, reactive clothing. |
| **Active**  | Has sent `add <device>` and received `add-confirm`. May send active commands and receive active responses.     |

Foreign devices (not owned by the unit) must be granted access according to the unit's local access permissions.

## Parsing Notes

Tokens are separated by spaces. For messages with unquoted trailing string arguments, `llParseString2List()` may be inadequate. Instead:
- Use `llGetSubString()` to extract remaining text after the keyword, or
- Use `llDumpList2String(llList2List(...), " ")` to re-concatenate parameters.

## Device Names

`<device>` is a short, one-word identifier for the device's role (e.g. `horns`, `icon`). It must not contain spaces. This is distinct from the object name of the device in-world.

> **Object naming convention:** Peripherals that users can interact with should name themselves as `<unit full name> (<device role>)`, e.g. `SXD vi0let (icon)`. See `name` message for details.

## Ports

_(New in Companion 8.4 / ATOS 12.1)_
Ports are particle targets used to enhance appearance when connected to other devices. Supported types: `power`, `data-1`, `data-2`, `audio-in`, `audio-out`.

---

## Handshaking

The following exchanged messages are always available, but are not really 'passive' in any semantic sense:

---

### `ping`

Sent from a device to the system to detect if the system is present. The system will reply with `pong`.

---

### `pong`

Sent from the system to the device in response to a `ping` query.

---

## Passive Messages

Sent automatically by the system. Available to all devices, including unauthenticated ones.

---

### `bolts on|off`
Safety bolts have been engaged or disengaged (corresponding to the bolts policy).

- `on` → lock peripheral in place: `@detach=n`
- `off` → release detachment restriction: `@detach=y`

The automatic bolts mode (release when powered down) is handled by the system. Devices do not need to check power state before reacting.

> Also sent to newly-authenticated active devices immediately after `add-confirm`.

---

### `broken` / `fixed`
The unit has entered or left the **broken** state (e.g. after taking damage or briefly after a teleport). Apply appropriate visual and sound effects.

Triggered by: ATOS damage, teleport, or manual `!broken`/`!fixed` cortex commands.

---

### `carrier <device> <key>`
The unit is being carried by avatar `<key>` using handle `<device>`. If no handle applies, `<device>` is `none` and `<key>` is `NULL_KEY`.

---

### `charge start|stop`
The charging process has begun or ended. Apply visual effects as appropriate. Sent even for stative wireless chargers.

---

### `color <r> <g> <b>`
The system's primary color as floating-point values in `[0, 1]`. Sent on change or in response to `color-q`.

### `color-2 <r> <g> <b>`
Secondary color. By convention, indicates a **positive** situation (default: green).

### `color-3 <r> <g> <b>`
Tertiary color. By convention, indicates a **negative** situation (default: red or orange).

### `color-4 <r> <g> <b>`
Quaternary color. By convention, indicates a **concerning or urgent** situation (default: yellow).

---

### `device <device> <key>`
A device at address `<device>` has key `<key>`. Normally sent only to the HUD.

> **Deprecated** in 8.6 in favor of `device-list`.

---

### `error retry`
_(ARES 0.5.4+)_ The system cannot handle the device's request right now (e.g. during a kernel restart). Mission-critical devices should retry after a few seconds.

---

### `fan <level>`
Current fan speed, from `0` to `100`.

---

### `follow <target>`
The unit has been instructed to follow avatar or object `<target>`. If not following anything, `<target>` is `NULL_KEY`. Useful for collar/leash particle effects.

---

### `freeze` / `unfreeze`
The unit's motors have been locked or released for a reason other than normal movement subsystem disablement (e.g. during charging or while being carried).

---

### `fx <effect> <parameters>`
Trigger a visual or audio effect on the device. The effect name is a single word.

**Observed values:**
| effect       | parameters                 | observed result                                                                       |
|--------------|----------------------------|---------------------------------------------------------------------------------------|
| `spark`      | *none*                     | Triggers a spark/electrical effect                                                    |
| `s`          | `UUID`, `volume (0.0-1.0)` | Plays sound `UUID` through controller speaker at `volume`.                            |
| `tp`         | *none*                     | Suppresses the next teleport flash effect the controller would generate.              |
| `repair`     | *none*                     | If `repairing` state is active, play controller repair nanites sound/particles.       |
| `reclaim`    | *none*                     | Plays controller reclamation sound/particles                                          |
---

### `gender <topic> <value>`

Reports gender settings for a given topic.

| Topic      | `<value>` format                                                 |
|------------|------------------------------------------------------------------|
| `physical` | `possessive,obj-possessive,subject,object,reflexive,gender-name` |
| `mental`   | `possessive,obj-possessive,subject,object,reflexive,gender-name` |
| `voice`    | `gender-name` only                                               |

**Examples:**
```
gender physical its,its,it,it,itself,inanimate
gender mental hers,her,she,her,herself,female
gender voice male
```

**Usage guidance:**
- Use **physical** gender for pronouns in emotes: *"/me uses \<physical possessive\> charger."*
- Use **mental** gender when the unit speaks about itself.
- Use **voice** gender only for selecting vocalizations (e.g. pain/pleasure sounds).

> Speech Standard 1 dictates that physical gender be used when speaking *about* a unit. This synergizes with gender transformation roleplay where physical change may precede mental acceptance.

---

### `integrity <current> <chassis-strength> <max-integrity>`

The unit's integrity is currently `<current>`, where `<current>` is a floating-point value between `0.0` and `1.0` representing the percentage of the unit's health. `<chassis-strength>` is a floating-point value between `0.0` and `1.0`, representing the amount of hit points it will have at max health and `<max-integrity>` is a floating-point value between `0.0` and `1.0` that shows how much health the unit can heal up to, which automatically decreases as self-repair occurs until a unit can repair externally.

---

### `interference-state <type>`
The system has been exposed to ACS interference. `<type>` is a string of class characters:

| Class | Effect                       |
|-------|------------------------------|
| `M`   | Motor control impaired       |
| `C`   | Cortex operation impaired    |
| `S`   | Sound/speech output impaired |
| `N`   | Sensory functions impaired   |
| `Y`   | Memory access impaired       |

**Example:** `interference-state MCY` → motor, cortex, and memory are impaired.

At the end of interference, `interference-state ` is sent (with a trailing space).

---
### `light <frac>`
_(Obsolete)_ The system's power usage is currently `<frac>`, where 1.0 indicates all subsystems are currently engaged and 0.0 indicates all subsystems are currently disengaged. This message is not sent when the system is powered off. Expected by certain very old NS peripherals instead of the `on` message.

---

### `name <name>`
The unit's current full name, including prefix. Sent when the name changes.

Peripherals with interactive features should rename themselves to `<full unit name> (<role>)` whenever this message is received. Example: `SXD vi0let (icon)`.

---

### `on` / `off`
System main power state. No message is sent for auxiliary power transitions.

> This may be re-sent without the power state actually changing (e.g. in response to `power-q`). Store the last known state and check for a real change before triggering boot/shutdown actions.

> Very old NS peripherals like the SynthOPTICAL eyes and the first versions of the Ornamental System Lights expected to receive a `light` update message instead of `on`. The `off` message is still recognized by these early products.

---

### `persona <name>`
The active persona is now `<name>`. If no persona is active, `<name>` is `default`. Sent on change or in response to `persona-q`.

---

### `power <level>`
Remaining power as a fraction of total capacity (`0.0`–`1.0`). Sent when the battery connects or when the integer percentage changes. Also triggered by `power-q`.

---

### `rate <amount>`
Net power consumption in J/s. Negative during charging (power received exceeds consumption).

---

### `subsystem <SS> 0|1`
_(ARES 0.5.7+)_ Subsystem named `<SS>` is enabled (`1`) or disabled (`0`).

Standard subsystems are: amplifier, athletics, base, flight, hearing, hud, identify, lidar, location, locomotion, mind, motors, optics, radio, reach, receive, speech, teleport, transmit, video, voice, wifi.

This replaces the historic Companion numeric convention (below), which was only suitable for hardcoded numbers. Truly paranoid developers might consider supporting both, although not all standard ARES subsystems had direct Companion equivalents.

_(Companion)_ Subsystem index `<SS>` is enabled (`1`) or disabled (`0`).

| Subsystem   | Value |
|-------------|-------|
| `VIDEO`     | 1     |
| `AUDIO`     | 2     |
| `MOVE`      | 4     |
| `TELEPORT`  | 8     |
| `RAPID`     | 16    |
| `VOICE`     | 32    |
| `MIND`      | 64    |
| `PREAMP`    | 128   |
| `POWER_AMP` | 256   |
| `RADIO_IN`  | 512   |
| `RADIO_OUT` | 1024  |
| `GPS`       | 2048  |
| `IDENTIFY`  | 4096  |

Prior to Companion 8.4, the ordering was:

| Subsystem   | Value |
|-------------|-------|
| `VIDEO`     | 1     |
| `AUDIO`     | 2     |
| `RADIO_IN`  | 4     |
| `MOVE`      | 8     |
| `TELEPORT`  | 16    |
| `RAPID`     | 32    |
| `VOICE`     | 64    |
| `MIND`      | 128   |
| `PREAMP`    | 256   |
| `RADIO_OUT` | 512   |
| `GPS`       | 1024  |
| `IDENTIFY`  | 2048  |
| `POWER_AMP` | 4096  |

---

### `temperature <temperature>`
See combat protocols.

---

### `wait-teleport <time>`
The FTL subsystem is refreshing; the unit cannot teleport for `<time>` more seconds. Sent every second.

---

### `weather <type> <temperature>`
See combat protocols.

---

### `working` / `done`
The unit has entered or left a **working** state (processing/calculation in progress). Apply lighting and sound effects accordingly.

Triggered by: vox filter processing, or manual `!working`/`!done` cortex commands.

---

## Active Messages — Device to MC

These require the device to have completed authentication (`add` → `add-confirm`). However, some messages (such as ones ending in `-q`) can be sent without authentication to request information from the system.

---

### `add <device>`
Register this device at address `<device>` (one-word mnemonic, e.g. `icon`, `battery`). Send on `on_rez()`, `attach()`, or in response to `probe`. The system will reply with `add-confirm` or `add-fail` as appropriate.

### `add <device> <version>`
Variant with version check. Used to block old, incompatible devices. Required for HUD and shield devices.

### `add <device> <version> <PIN>`
For firmware-update-capable devices. The system's package manager will recognize the device as the updatable package `<device>_<version>`. Required for the chassis device. During update, `<PIN>` is passed to the installer in cleartext alongside the root UUID.

---

### `add-command <command>`
Register a federated `@` command with the system. Active until the device is removed or re-probed. When a user invokes the command, the system sends a `command` message to the device.

---

### `animate start <name>`
_(ARES)_ Starts playing the specified animation. Animation must be visible to link 2 of the system (s_dead, s_charging, etc, or a Linden built-in animation)

### `animate stop <name>`
_(ARES)_ Stops playing the specified animation. Animation must have previously been started using `start` above.

### `animate clear`
_(ARES)_ Stops playing all animations started by the device.

> Animations created via this mechanism will automatically be cleared when the device is removed, including if it is automatically removed due to being derezzed.

---

### `auth <device> <key>`
Ask the system to verify that user `<key>` has local access. If authorized, the system responds with `accept <key>`. If not, the system notifies the user directly; the device receives no response.

> Do not cache auth results. Obtain permission immediately upon user contact; do not queue pending actions.

For complex security interactions, see internal message numbers `205 SEC_PROGRAMMABLE_LOCAL` and `210 SEC_PROGRAMMABLE_REMOTE`.

### `auth-compare <device> <user1> <user2>`
Check if `<user2>` is at least `<user1>`'s rank. If so, sends `accept` for `<user2>`. Useful for leash pre-emption and similar rank-based decisions.

---

### `carrier <device> <key>`
Report that the unit is being carried by `<key>` using handle `<device>`. When carrying stops, send with `<key>` = `NULL_KEY`. Accepted from any attachment. Also sent by the system in response to `carrier-q`.

### `carrier-q`
Request the system to send `carrier`.

---

### `color-q`
Request the system to send `color`, `color-2`, `color-3`, and `color-4`.

---

### `command <user> <outs> <command>`
_(ARES only)_ Execute `<command>` as `<user>`, sending results to pipe `<outs>`. Both `<user>` and `<outs>` are usually the user's UUID.

- Omit the leading `@` from `<command>`.
- To execute a shell command or alias, prefix with `exec `:
  ```
  exec service status restart
  exec say Hello, world!
  ```

> Not to be confused with the MC-to-device `command` message, which notifies the device of a user-invoked custom command.

---

### `conf-get <setting-name>`
Retrieve one or more settings from the config manager. Multiple settings separated by newlines:

```
conf-get boot.model
boot.serial
```

Response:
```
conf boot.model DAX/2
boot.serial 998123456
```

### `conf-set <setting-name> <value>`
Update one or more settings. Multiple directives separated by newlines:

```
conf-set mydevice.myfeature 1
mydevice.otherfeature myvalue
```

> Although ARES understands the `conf-set` message, it is disabled, to prevent accidental damage by outdated backup disks.

### `conf-delete <setting-name>`
Remove a setting from the config store.

---
### `damage <amount>`
_(ARES)_ Deals `<amount>` points of damage to the unit, where 100 is the amount required to incapacitate a standard unit. Negative values will apply repairs.

> Damage applied through this mechanism is treated as having the 'special' damage type, which ignores shielding and other forms of mitigation. It is intended for use in simulating internal malfunctions and is not broadly suitable as a replacement for collision-based combat.

---

### `devices`
Request a list of connected devices. The system will respond with one or more `device-list` messages.

> If the ATOS security module is installed, it will also send `weapon-active` to the destination key.

---

### `follow-q`
Request the system to send `follow`.

---

### `freeze` / `unfreeze`
_(ARES)_ Lock or release the unit's motors, e.g. during charging or while being carried.

> As with standard RLV restrictions, multiple sources of motor freeze are tracked independently. Sending `unfreeze` merely removes the freeze applied by the current device; it cannot guarantee there are no other sources of motor freeze, and has no effect except to cancel prior restrictions imposed by the same device.

> Freezes are automatically canceled if the device responsible is removed or derezzed.

---

### `gender-q <topic>`
Query gender settings. `<topic>` must be `physical`, `mental`, or `voice`. The system will respond with `gender`.

---

### `integrity-q`

Request the system to send `integrity`.

---

### `internal <device> <number> <key> <message>`
_(Companion)_ Relay a linked message through the system to trigger an internal system function.

- To send a system command, use `<number>` = `0` and the interacting user's UUID as `<key>` (or `NULL_KEY` for root access).
- **Example** — turn off the unit:
  ```
  internal <device> 0 00000000-0000-0000-0000-000000000000 off
  ```

> This command will not work unless the device has authenticated with `add`.
> In Companion 8.5+, all internal calls are wrapped as `TASK_START` messages for backward compatibility.
> In ARES, `internal` calls are replaced with bespoke messages, such as `command`. Using an internal call will automatically eject the device from ARES with a message to the user that the device is incompatible with ARES.

---

### `load <device> <task> <W>`
Report that `<device>` is consuming `<W>` watts for task `<task>`. Task names must be unique per device; re-sending updates the wattage. Send with `W` = `0` to remove the load.

**Example:** `load shield recharge 100`

Loads are shown by the `power` command under *external loads*.

---

### `persona-q`
Request the system to send `persona`.

---

### `policy-q <policy>`
Request the `policy` message for a given policy.

| System          | Supported policies                                           |
|-----------------|--------------------------------------------------------------|
| Companion 8.6.4 | `subsystems`, `radio`, `persona`, `apparel`, `vox`, `curfew` |
| ARES 0.4.1      | `curfew`, `autolock`, `beacon`, `apparel`, `locked`, `radio` |

---

### `port <type> <key>`
Signal that prim `<key>` can provide port functionality of type `<type>`, to be used as a particle target for wires from base stations.

Supported types: `class`, `power`, `audio-in`, `audio-out`, `data-1`, `data-2`

> When the system sends this message it means a redirect to another device; see `port-real` and `port-connect`.

### `port-connect <type>`
Request to connect a cable to a port of the given type. The system responds with either:
- `port <type> <key>` — resend the query to `<key>` (the actual port host)
- `port-real <type> <key>` — use `<key>` as the particle destination and begin effects

If forwarded to a port host, the host is guaranteed to follow up with `port-real`.

### `port-disconnect <type>`
Signal that the port of the given type is no longer in use. The connecting device must stop sending particles. The system will correctly forward this to the port host.

> Devices that provide ports should periodically check for derezzed clients, and fulfill port disconnection themselves when the object currently using a port no longer exists.

---

### `power-q`
Request the system to send `on` or `off` as appropriate, plus `bolts`.

---

### `release <rule-name>`
_(ARES)_ Removes an RLV rule previously created with `restrict`. If the restriction specification started with `a:`, then the animation will be canceled.

> Restrictions are automatically canceled if the device responsible is removed or derezzed.

---

### `restrict <rule-name> <restriction-spec>`
_(ARES)_ Adds RLV restrictions. The syntax for `<restriction-spec>` resembles standard RLV rules, but without the leading `@`, and the `=y` or `=n` terms replaced with `=?`. For example, adding sit and unsit restrictions would be `sit=?,unsit=?` rather than `@sit=n,unsit=n` (direct form) or `@sit=n|@unsit=n` (relay form).

In ARES, an additional restriction called `move=?` is provided. This pseudo-RLV rule uses `llTakeControls()` to prevent walking, flying, crouching, or turning.

Alternatively, the `<restriction-spec>` may be `a:` followed by the name of an animation present in ring 2 (s_dead, s_charging, etc), in which case the animation will be activated. (Note that the shutdown state, if applied by the operating system, takes priority over all other animations.)

In ARES, the `release` and `restrict` rules are implemented by the effector daemon, which goes to great lengths to correctly integrate certain RLV rules and ensure they do not conflict. See ARES/api/effector.h.lsl for more documentation.

---

### `rlv <restrictions>`
_(ARES)_ Executes RLV commands immediately without any signal integration. This should be used with caution as it can be used to break subsystem restrictions.

---

### `remove <device>`
Remove `<device>` from the device manager. Most peripherals don't need this, but foreign devices (e.g. docking stations) and standard batteries (when ejected) should use it.

> This occurs automatically when an active device derezzes.

---

### `remove-command <command>`
Cancel a previously registered `add-command`.

> Commands are automatically removed if the device responsible is removed or derezzed.

---

### `subsystem-q <subsystem>`
Check whether `<subsystem>` is enabled. The system responds with `subsystem`. See subsystem table above for parameter values.

> Before Companion 8.5m3, the parameter was ignored and only video (0) status could be queried.

---

### `teleport <x> <y> <z> <region>`
_(ARES)_ Effectuates a guaranteed teleport. This will cause the unit to teleport to the specified coordinates in the specified region name.

### `teleport <x> <y> <z> external <region>`
_(ARES)_ If the "`external`" keyword is included, then the unit's FTL capacitor will skip recharging and no teleport effects will be played, as though it had just walked through a portal.

> Using this mechanism instead of simply trying to implement the effect directly when coding e.g. a teleport pad is recommended, as it prevents the system from interfering with teleportation.

---

### `version <device> <version> <PIN>`
Declare that the device supports Xanadu-assisted firmware updates, currently running `<version>`. Both the updater package and device firmware should apply salt to `<PIN>` and exchange only the salted portion.

---

### `weapon <...>`
See combat protocols.

---

## Active Messages — MC to Device

Sent by the system to devices that have previously successfully authenticated with the `add` message.

---

### `accept <key>`
User `<key>` is authorized to operate the unit. Sent in response to `auth` or `auth-compare`.

> Do not cache this. Authorization may be revoked after the fact.

### `add-confirm`
Device successfully installed. May now send active commands.

### `add-fail`
Device installation failed. Usually caused by a slot conflict or a refused foreign connection.

---

### `command <user key> <command> <parameters>`
The user has typed `@<command> <parameters>`, invoking a command registered by the device via `add-command`. Handle accordingly.

> Not to be confused with the device-to-MC `command` message, which executes ARES commands.

---

### `conf <setting-name> <value>`
Returns a setting value in response to `conf-get`. Multiple results are newline-separated.

---

### `defend`
See combat protocols.

### `denyaccess <key>`
User `<key>` failed an `auth` or `auth-compare` check. Refuse access.

> Do not cache this. Access may be granted after the fact.

---

### `device-list [<device> <key> ...]`
Sends device address/key pairs over the light bus. Multiple messages may be sent if the list exceeds ~240 characters (~5 devices).

> Clear any cached device list *before* sending `devices`, not when receiving `device-list`.

---

### `integrity`
See combat protocols.

---

### `peek <id>`
User `<id>` has requested the device's status. Send a status summary to `<id>` on channel 0.

---

### `poke <id>`
User `<id>` has requested the device's menu interface. Present a UI (`llDialog()`, hotlinked text, Facet welcome, etc.) to `<id>`.

> _Mostly historical:_ Hotlinked text is incompatible with chat-forwarding (output pipe) mode.

---

### `policy <name> <state>`
The policy `<name>` is in the given state. State is usually `1` (enforced) or `0` (unenforced).

Special cases:
- `radio`: `1` = users only, `2` = owners only
- `curfew`: `<state> <time> <triggered> <home_sim> <home_pos>`

If a policy is unsupported, `<state>` will be an empty string.

---

### `port <type> <key>`
The key provided can serve port functionality of the given type. Resend your connection request to `<key>`. Sent in response to `port-connect`.

### `port-connect <type>`
Something is connecting to this device. Trigger connect effects.

### `port-disconnect <type>`
Something is disconnecting from this device. Trigger disconnect effects.

### `port-real <type> <key>`
Send cable particles to `<key>`. Sent in response to `port-connect` when the system itself hosts the port. Under Companion this could happen if the main controller had ports attached to it; ARES will generate this message to spoof directly sending cable particles to the root prim of the main controller attachment if no port of the specified `<type>` is available.

---

### `probe`
The device manager has been reset. All devices wishing to use active messages must re-send `add`.

---

### `remove-confirm`
Uninstallation successful.

### `remove-fail`
Uninstallation failed (e.g. removing a battery while power is on).

---

### `sentinel-flags`
See combat protocols.

### `session-ready <key> <session-number>`
_(Companion only — sxdwm/exhibition 4)_ A menu session has been created for `<key>`, identified by `<session-number>`.

### `weapon charge <amount>` / `weapon-active`
See combat protocols.

---

## Device-to-Device Messages

Sent over the light bus between peripherals directly.

---

### `block-holo`
Sent by containers or equipment that tightly enclose the avatar (e.g. packing crates, power armor). Receiving devices with holographic elements should:

1. Maintain a list of **holo-blockers** (keys preventing holo display).
2. Periodically check each key — remove it from the list when it is neither:
   - The `OBJECT_ROOT` of the unit (its chair/seat), nor
   - In the unit's attachment list.
3. When the list is empty, holographic elements can be shown again.

> Always suppress holographic elements while the unit is powered down.

---

### `connected <device>`
Sent when a device is installed. `<device>` is the one-word name, not the key.

> **Mandatory** for battery devices.

### `disconnected <device>`
Sent when a device is removed.

> **Mandatory** for battery devices.

### `reconnected <device>`
Sent when a device is re-installed.

> **Mandatory** for battery devices.

---

### `icon <uuid>`
Sent to the HUD device to change this device's icon on the HUD console.

- `<uuid>`: UUID of a white/transparent texture, ideally 32×32px (designed to look good at 16×16px).
- _(Native 8.6.3+ only; builds before Oct 6 2021 and Screen HUD do not support this.)_

Send in response to `icon-q`, directed to the key that sent the query. Alternatively, query the correct target via `devices`.

### `icon-q`
Sent by the HUD to request that a device send its `icon`.

---

### `port-connect <type>` / `port-disconnect <type>` / `port-real <type> <key>`
Same semantics as the MC-to-device versions. See above.

---

## Device-Specific Active Messages

Messages for specific peripheral types.

---

### Screen Console Manager (`_screen`) Messages
These messages are unique to the Companion _console-screen attachment.

#### `add-section <name> <width>`
Add a new section to the Screen Console Manager HUD. `<name>` should be a short unique ID (e.g. the device address). `<width>` is the number of icons to display. The system replies with `add-section-confirm`.

> Not supported by Native Console (`_native`) HUD — use `icon-q` instead.
> Sections and buttons cannot be removed or modified once added.

#### `add-section-confirm <name>`
The section was successfully created. Proceed with `add-button` messages.

#### `add-button <section-name> <icon> <command ...>`
Add a button to a section. `<icon>` is a UUID for a white-and-transparent texture (≤ 128×128px). `<command ...>` (space-separated) is sent as a `COMMAND` system message when pressed. The system replies with `add-button-confirm` or `add-button-fail`.

> If the section doesn't exist, no error is produced. Re-send `add-section` if you're unsure.

#### `add-button-confirm <section-name>`
Button successfully added to `<section-name>`.

#### `add-button-fail <section-name>`
Button could not be added (section is full).

#### `config-q`
Sent by the Companion `_console-screen` HUD to the operating system to request the `_console-config` file.

#### `config-update`
Sent by Companion to the `_console-screen` HUD. A new config file is available — delete the old copy, then send `config-q` to request the replacement.

---

### Hatch Messages

These are used to control the battery hatch on the main controller. Historically this was a separate light bus device embedded into the lid itself, although nearly all ARES controllers implement it directly inside their main firmware (ctrl.lsl) or via a delegate thereof.

#### `hatch open|close`
Open or close the battery hatch. Sent from the system to the hatch device.

#### `hatch-blocked`
The battery is positioned in a way that prevents the hatch from closing. The controller will open the hatch or refuse to close it upon receiving this.

#### `hatch-blocked-q`
Sent by the hatch to the battery. Ask the battery if it would block the hatch; if so, battery should respond with `hatch-blocked`.

---

### Shield Messages

#### `interference <type> <intensity> <duration> <source_key>`
Sent by the shield device to the system after it is overwhelmed by a `shield` message, describing the interference that could not be mitigated. No message should be sent if all radiation was successfully mitigated.

#### `shield <duration> <intensity> <id> <type>`
Sent by the system to the shield device after interference of `<type>` from source `<id>` has been received. The shield should mitigate what is possible, then return an `interference` message describing any remaining radiation.

---

### SuperBit Messages

#### `sign <string>`
Display the image or sequence named `<string>`.

Use `sign cancel` to deactivate any currently displayed sign.
