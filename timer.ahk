; only one timer is allowed
;
; the 'reset/pause/stop timer' parameter (the last parameter) in the examples are as follow:
; 'reset' = starts an existing timer over, or starts the last timer over
; 'pause' = pauses/resume timer, if timer doesn't exist, it restarts the last one
; 'stop' = stops the timer and hides the gui - default
;
;
; when using Timer.Hold_to_StartTimer or Timer.Toggle_to_StartTimer methods,
; the minutes and seconds become the new starting point when the using
; Timer.Pause_Timer(), Timer.Reset_Timer(), or Timer.Stop_Timer()
;
;
; method 1
; example of a hotkey you have to hold to start a timer of 00:12, hold again to reset the timer if it's still running
; parameters(minutes, seconds, key, duration to hold button, reset/pause/stop timer)
; ~Space::{
;     Timer.Hold_to_StartTimer(0, 12, 'Space', 1000, 'reset')
;     KeyWait('Space')
; }
;
;
; method 2
; example of a hotkey to toggle a timer of 3:00 that pauses on reactivation if timer is still running
; parameters(minutes, seconds, hotkey reactivation action)
; <!a::Timer.Toggle_to_StartTimer(3, 0, 'pause'), KeyWait('a')
;
;
; you can also call these methods to affect an existing or last existing Timer
; <!s::Timer.Pause_Timer(), KeyWait('s')
; <!d::Timer.Reset_Timer(), KeyWait('d')
; <!f::Timer.Stop_Timer(), KeyWait('f')


Timer.CreateGui()


class Timer {
    ; variables
    static TimerGui     := unset
    static timer        := unset    ; TimerGui timer text
    static timerRunning := false    ; state of Timer running, used for pause
    static priorHotkey  := unset    ; A_PriorHotKey registers separate pause, reset, and stop method calls
                                    ; this makes sure only calls to Hold and Toggle methods are remembered

    static minutes      := 3        ; minutes left on timer
    static seconds      := 0        ; seconds left on timer
    static const_minutes := unset   ; keeps track of minutes sent by hotkey
    static const_seconds := unset   ; keeps track of seconds sent by hotkey


    ; one line functions to make code more readable
    static UpdateTime := ObjBindMethod(this, 'UpdateDisplayedTime')
    static UpdateTimeByOneSecond() => SetTimer(this.UpdateTime, 1000)
    static StopUpdatingTime() => SetTimer(this.UpdateTime, 0)
    static Toggle_Timer() => this.timerRunning := !this.timerRunning ; toggle


    ;;;;;;;;;;;;;;;;;;;;;;
    ; Methods
    ;;;;;;;;;;;;;;;;;;;;;;


    ;;;;;;;;;;;;;;;;;;;;;;;;;
    ; method 1 to start timer
    static Hold_to_StartTimer(_minutes, _seconds, key, durationOfHoldToActivate, TimerAction := 'stop') {
        if this.InvalidTime(_minutes, _seconds) ; guard clause
            return

        this.startOfKeyPress := A_TickCount ; keep track of beginning of key press

        while GetKeyState(key, 'P')
            ; if key is held at least as long as the required activation duration
            if A_TickCount - this.startOfKeyPress >= durationOfHoldToActivate
                break

        ; if key isn't held long enough to activate
        if A_TickCount - this.startOfKeyPress < durationOfHoldToActivate
            return


        this.const_minutes := _minutes
        this.const_seconds := _seconds

        this.HotkeyCheck()

        ; pause, reset, or stop timer
        try this.%TimerAction%_Timer()
        catch {
            MsgBox('Invalid TimerAction parameter.')
        }
    }


    ;;;;;;;;;;;;;;;;;;;;;;;;;
    ; method 2 to start timer
    static Toggle_to_StartTimer(_minutes, _seconds, TimerAction := 'stop') {
        if this.InvalidTime(_minutes, _seconds)
            return

        this.const_minutes := _minutes
        this.const_seconds := _seconds

        this.HotkeyCheck()

        try this.%TimerAction%_Timer()
        catch {
            MsgBox('Invalid TimerAction parameter.')
        }
    }


    static UpdateDisplayedTime() {
        try {
            ; if more than 1 minute remain
            if this.minutes > 0 {
                if this.seconds = 0 {
                    this.minutes -= 1
                    this.seconds := 59
                }
                else this.seconds -= 1
            }

            ; if less than a minute remaining
            else {
                this.seconds -= 1

                if this.seconds < 0 {
                    this.Hide_Timer()
                }
            }

            this.timer.Value := Format('{:02}', this.minutes) ':' Format('{:02}', this.seconds)
        }
    }


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;; TIMER ACTIONS ;;;;;;;;;;;;;;
    static Start_Timer() {
        this.minutes := this.const_minutes
        this.seconds := this.const_seconds
        try this.timer.Value := Format('{:02}', this.minutes) ':' Format('{:02}', this.seconds)

        this.Toggle_Timer()

        if WinExist('ahk_id ' this.TimerGui.Hwnd)
            this.Hide_Timer()
        else {
            this.timer.Opt('cffffff')
            this.TimerGui.Show('xCenter y-8 NoActivate')
            this.RoundedCorners(15)
        }

        this.UpdateTimeByOneSecond()
    }


    static Pause_Timer() {
        if not WinExist('ahk_id ' this.TimerGui.Hwnd) {
            this.Start_Timer()
            return
        }

        if this.timerRunning {
            this.StopUpdatingTime()
            this.timer.Opt('cffc400')
        } else {
            this.UpdateTimeByOneSecond()
            this.timer.Opt('cffffff')
        }
        this.Toggle_Timer()
    }


    static Stop_Timer() {
        if WinExist('ahk_id ' this.TimerGui.Hwnd)
            this.Hide_Timer()
        else
            this.Start_Timer()
    }


    static Reset_Timer() {
        this.Hide_Timer()
        this.Start_Timer()
    }
    ;;;;;;;;;;;;;; TIMER ACTIONS ;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



    static CreateGui() {
        TimerGui := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border')
        TimerGui.SetFont('cffffff s12 bold')
        TimerGui.BackColor := '292a35'
        this.TimerGui := TimerGui
        this.timer := this.TimerGui.AddText('y+15', Format('{:02}', this.minutes) ':' Format('{:02}', this.seconds))
    }


    static RoundedCorners(curve) { ; dynamically rounds the corners of the gui, param is the curve radius as an integer
        this.TimerGui.GetPos(,, &width, &height)
        WinSetRegion('0-0 w' width ' h' height ' r' curve '-' curve, this.TimerGui)
    }


    ; check if the parameters used follow xx:xx format
    static InvalidTime(minutes, seconds) {
        if StrLen(minutes) > 2 or StrLen(seconds) > 2 or
            (minutes = 0 and seconds = 0) {
            MsgBox('The time you entered is invalid.`nMax time allowed: 59:59`nMin time allowed: 00:01')
            return true
        }
    }


    ; check if a different timer is trying to be set with another hotkey
    static HotkeyCheck() {
        if A_ThisHotkey != this.priorHotkey {
            this.minutes := this.const_minutes
            this.seconds := this.const_seconds
            this.priorHotkey := A_ThisHotkey
            this.timerRunning := false
            try this.timer.Value := Format('{:02}', this.minutes) ':' Format('{:02}', this.seconds)
        }
    }


    static Hide_Timer() {
        if WinExist('ahk_id ' this.TimerGui.Hwnd) {
            this.TimerGui.Hide()
            this.StopUpdatingTime()
            this.timerRunning := false
        }
    }
} ;;;;;;;;;;;;;;;;;;END OF CLASS;;;;;;;;;;;;;;;;;;;
