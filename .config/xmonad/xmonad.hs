-- ----------------------------------------------------------
--  IMPORT
-- ----------------------------------------------------------
-- default config one
import XMonad
import Data.Monoid
import System.Exit
import qualified XMonad.StackSet as W
import qualified Data.Map as M
-- gap between window
import XMonad.Layout.Spacing
-- spawnOne stuff
import XMonad.Util.SpawnOnce
-- avoid overlapping
import XMonad.Hooks.ManageDocks

-- stuff for the communication between xmonad and polybar
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import qualified XMonad.DBus as D
import qualified DBus.Client as DC
import XMonad.Hooks.DynamicLog
import XMonad.Util.NamedActions
import System.IO
import System.Posix.Types (ProcessID)
import qualified XMonad.Util.ExtensibleState as XS
import Control.Monad (when)
import qualified Data.Map as M
import Data.Monoid (All(..))

-- ----------------------------------------------------------
-- THEMING
-- ----------------------------------------------------------
-- see the palette > https://flatuicolors.com/palette/ca
wColor = "#c8d6e5"
bColor = "#222f3e"
rColor = "#ee5253"
yColor = "#feca57"
oColor = "#ff9f43"
blColor = "#54a0ff"

-- ----------------------------------------------------------
-- VARS
-- ----------------------------------------------------------
myTerminal = "alacritty"

myGap = 5
myBorderWidth = 2
myNormalBorderColor  = bColor
myFocusedBorderColor = wColor

-- mod1Mask ("left alt") mod3Mask ("right alt") mod4Mask (windows key)
myModMask = mod4Mask

-- Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

-- Whether clicking on a window to focus also passes the click to the window
myClickJustFocuses :: Bool
myClickJustFocuses = False

-- rofi start script
startRofi = "rofi -no-config -no-lazy-grab -show drun -modi drun -theme ~/.config/rofi/config.rasi"

-- ----------------------------------------------------------
-- WORKSPACE
-- ----------------------------------------------------------
-- The default number of workspaces (virtual screens) and their names.
-- By default we use numeric strings, but any string may be used as a
-- workspace name. The number of workspaces is determined by the length
-- of this list.
--
-- A tagging example:
--
-- > workspaces = ["web", "irc", "code" ] ++ map show [4..9]

--                 code      browser   coffee    microship  music     bug
myWorkspaces    = ["\xf0e8", "\xf269", "\xf0f4", "\xf2db",  "\xf001", "\xf188"]

-- -----------------------------------------------------------
-- KEY BINDINGS
-- -----------------------------------------------------------
myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $

    -- launch a terminal
    [ ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)

    -- launch rofi
    , ((modm,               xK_p     ), spawn startRofi)

    -- launch gmrun
    , ((modm .|. shiftMask, xK_p     ), spawn "gmrun")

    -- close focused window
    , ((modm .|. shiftMask, xK_c     ), kill)

     -- Rotate through the available layout algorithms
    , ((modm,               xK_space ), sendMessage NextLayout)

    --  Reset the layouts on the current workspace to default
    , ((modm .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)

    -- Resize viewed windows to the correct size
    , ((modm,               xK_n     ), refresh)

    -- Move focus to the next window
    , ((modm,               xK_Tab   ), windows W.focusDown)

    -- Move focus to the next window
    , ((modm,               xK_j     ), windows W.focusDown)

    -- Move focus to the previous window
    , ((modm,               xK_k     ), windows W.focusUp  )

    -- Move focus to the master window
    , ((modm,               xK_m     ), windows W.focusMaster  )

    -- Swap the focused window and the master window
    , ((modm,               xK_Return), windows W.swapMaster)

    -- Swap the focused window with the next window
    , ((modm .|. shiftMask, xK_j     ), windows W.swapDown  )

    -- Swap the focused window with the previous window
    , ((modm .|. shiftMask, xK_k     ), windows W.swapUp    )

    -- Shrink the master area
    , ((modm,               xK_h     ), sendMessage Shrink)

    -- Expand the master area
    , ((modm,               xK_l     ), sendMessage Expand)

    -- Push window back into tiling
    , ((modm,               xK_t     ), withFocused $ windows . W.sink)

    -- Increment the number of windows in the master area
    , ((modm              , xK_comma ), sendMessage (IncMasterN 1))

    -- Deincrement the number of windows in the master area
    , ((modm              , xK_period), sendMessage (IncMasterN (-1)))

    -- Toggle the status bar gap
    -- Use this binding with avoidStruts from Hooks.ManageDocks.
    -- See also the statusBar function from Hooks.DynamicLog.
    --
    -- , ((modm              , xK_b     ), sendMessage ToggleStruts)

    -- Quit xmonad
    , ((modm .|. shiftMask, xK_q     ), io (exitWith ExitSuccess))

    -- Restart xmonad
    , ((modm              , xK_q     ), spawn "xmonad --recompile; xmonad --restart")

    -- Run xmessage with a summary of the default keybindings (useful for beginners)
    , ((modm .|. shiftMask, xK_slash ), spawn ("echo \"" ++ help ++ "\" | xmessage -file -"))
    ]
    ++

    --
    -- mod-[1..9], Switch to workspace N
    -- mod-shift-[1..9], Move client to workspace N
    --
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++

    --
    -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
    --
    [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]


-- --------------------------------------------------------------------
-- MOUSE BINDINGS
-- --------------------------------------------------------------------
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $

    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w
                                       >> windows W.shiftMaster))

    -- mod-button2, Raise the window to the top of the stack
    , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modm, button3), (\w -> focus w >> mouseResizeWindow w
                                       >> windows W.shiftMaster))

    -- you may also bind events to the mouse scroll wheel (button4 and button5)
    ]

-- --------------------------------------------------------------------
-- LAYOUTS
-- --------------------------------------------------------------------
-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.

myLayout = spacing myGap $ avoidStruts (tiled ||| Mirror tiled ||| Full)
  where
     -- default tiling algorithm partitions the screen into two panes
     tiled   = Tall nmaster delta ratio

     -- The default number of windows in the master pane
     nmaster = 1

     -- Default proportion of screen occupied by master pane
     ratio   = 1/2

     -- Percent of screen to increment by when resizing panes
     delta   = 3/100

-- --------------------------------------------------------------------
-- WINDOWS RULES
-- --------------------------------------------------------------------
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.

myManageHook = composeAll
    [ className =? "MPlayer"        --> doFloat
    , className =? "Gimp"           --> doFloat
    , className =? "Xmessage"       --> doFloat
    , resource  =? "desktop_window" --> doIgnore
    , resource  =? "kdesktop"       --> doIgnore ]

-- ---------------------------------------------------------------------
-- POLYBAR STUFF
-- ---------------------------------------------------------------------
-- logHook for polybar
polybarLogHook :: DC.Client -> PP
polybarLogHook dbus = def { ppOutput = D.send dbus
                     , ppCurrent = wrap ("%{F" ++ activeColor ++ "}") "%{F-}" -- the current workspace
                     , ppUrgent = wrap ("%{F" ++ red ++ "}") "%{F-}" -- urgent workspace
                     , ppHidden = wrap ("%{F" ++ haveWColor ++ "}") "%{F-}" -- hidden but have window
                     , ppHiddenNoWindows = wrap ("%{F" ++ inactiveColor ++ "}") "%{F-}" -- hidden but not have window
                     , ppWsSep = " " -- separator between workspace (1, 2, 3, ...)
                     , ppSep = " : " -- separator between log section (window name, layout, workspace)
                     , ppTitle =  wrap ("%{F" ++ green ++ "} ") " %{F-}" . shorten 40 -- current window title
                     }
  where green = "#00ff00"
        inactiveColor = "#576574"
        activeColor = "#54a0ff"
        haveWColor = "#c8d6e5"
        red = "#ee5253"

-- generic bar polybar
polybarSB dbusConnection = statusBarGeneric "polybar -r" lh
  where lh = dynamicLogWithPP $ polybarLogHook dbusConnection

-- ---------------------------------------------------------------------
-- EVENT HANDLING
-- ---------------------------------------------------------------------
-- Defines a custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards. To
-- combine event hooks use mappend or mconcat from Data.Monoid.

myEventHook = mempty

-- ---------------------------------------------------------------------
-- STATUS BARS AND LOGGING
-- ---------------------------------------------------------------------
-- Perform an arbitrary action on each internal state change or X event.
-- See the 'XMonad.Hooks.DynamicLog' extension for examples.

myLogHook = return ()

-- ---------------------------------------------------------------------
-- STARTUP HOOK
-- ---------------------------------------------------------------------
-- Perform an arbitrary action each time xmonad starts or is restarted
-- Used by, e.g., XMonad.Layout.PerWorkspace to initialize per-workspace layout choices.

myStartupHook = do
    spawnOnce "picom &"
    spawnOnce "nitrogen --restore &"
    spawnOnce "deadd-notification-center &"
    spawn "~/.config/polybar/launch.sh"

-- ---------------------------------------------------------------------
-- RUN XMONAD
-- ---------------------------------------------------------------------
-- Run xmonad with the settings you specify.
-- main = xmonad $ docks defaults

main = do
  -- Connect to DBus
  dbus <- D.connect
  -- Request access (needed when sending messages)
  D.requestAccess dbus
  -- start xmonad
  xmonad . withEasySB (polybarSB dbus) defToggleStrutsKey $ docks defaults

-- ---------------------------------------------------------------------
-- CONFIG SETTINGS
-- ---------------------------------------------------------------------
-- Any you don't override, will use the defaults defined in xmonad/XMonad/Config.hs

defaults = def {
      -- simple stuff
        terminal           = myTerminal,
        focusFollowsMouse  = myFocusFollowsMouse,
        clickJustFocuses   = myClickJustFocuses,
        borderWidth        = myBorderWidth,
        modMask            = myModMask,
        workspaces         = myWorkspaces,
        normalBorderColor  = myNormalBorderColor,
        focusedBorderColor = myFocusedBorderColor,

      -- key bindings
        keys               = myKeys,
        mouseBindings      = myMouseBindings,

      -- hooks, layouts
        layoutHook         = myLayout,
        manageHook         = myManageHook,
        handleEventHook    = myEventHook,
        logHook            = myLogHook,
        startupHook        = myStartupHook
    }

-- ----------------------------------------------------------------------
-- TEXTUAL HELP CALL BY MODKEY + SHIFT + /
-- ----------------------------------------------------------------------
-- A copy of the default bindings in simple textual tabular format.
help :: String
help = unlines ["The default modifier key is 'super'. Default keybindings:",
    "",
    "-- launching and killing programs",
    "mod-Shift-Enter  Launch terminal",
    "mod-p            Launch rofi",
    "mod-Shift-p      Launch gmrun",
    "mod-Shift-c      Close/kill the focused window",
    "mod-Space        Rotate through the available layout algorithms",
    "mod-Shift-Space  Reset the layouts on the current workSpace to default",
    "mod-n            Resize/refresh viewed windows to the correct size",
    "",
    "-- move focus up or down the window stack",
    "mod-Tab        Move focus to the next window",
    "mod-Shift-Tab  Move focus to the previous window",
    "mod-j          Move focus to the next window",
    "mod-k          Move focus to the previous window",
    "mod-m          Move focus to the master window",
    "",
    "-- modifying the window order",
    "mod-Return   Swap the focused window and the master window",
    "mod-Shift-j  Swap the focused window with the next window",
    "mod-Shift-k  Swap the focused window with the previous window",
    "",
    "-- resizing the master/slave ratio",
    "mod-h  Shrink the master area",
    "mod-l  Expand the master area",
    "",
    "-- floating layer support",
    "mod-t  Push window back into tiling; unfloat and re-tile it",
    "",
    "-- increase or decrease number of windows in the master area",
    "mod-comma  (mod-,)   Increment the number of windows in the master area",
    "mod-period (mod-.)   Deincrement the number of windows in the master area",
    "",
    "-- quit, or restart",
    "mod-Shift-q  Quit xmonad",
    "mod-q        Restart xmonad",
    "mod-[1..9]   Switch to workSpace N",
    "",
    "-- Workspaces & screens",
    "mod-Shift-[1..9]   Move client to workspace N",
    "mod-{w,e,r}        Switch to physical/Xinerama screens 1, 2, or 3",
    "mod-Shift-{w,e,r}  Move client to screen 1, 2, or 3",
    "",
    "-- Mouse bindings: default actions bound to mouse events",
    "mod-button1  Set the window to floating mode and move by dragging",
    "mod-button2  Raise the window to the top of the stack",
    "mod-button3  Set the window to floating mode and resize by dragging"]
