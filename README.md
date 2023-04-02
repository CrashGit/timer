# Timer
## Simple on-screen Timer
### Written in ahkv2 beta13

A full description is in the `timer.ahk` file but I'll try to give a brief summary.

There are two main methods to call when setting up a timer. One requires you to hold a key down to trigger it, the other is just a press.

&nbsp;

For example: `<!a::Timer.Toggle_to_StartTimer(3, 0)`

Pressing `left alt + a` will immediately start a timer of 3:00 minutes.

&nbsp;

There is a third parameter you can pass, `pause/reset/stop (default)`

**When you press the hotkey a second time with the timer running, using the parameter**

`pause` will pause the timer

`reset` will start the timer over again

`stop` will stop the timer and hide it

&nbsp;

There also exists a `Timer.Pause_Timer()` `Timer.Reset_Timer()` and `Timer_Stop_Timer()` that you can bind to hotkeys. These methods affect existing or last used timers.

&nbsp;

There's also a method for pulling up a gui to enter a time in manually for those one-off situations.
