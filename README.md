## awesome-calendar

Small calendar popup for awesome window manager.

![Screenshot](/screenshot.png?raw=true "Screenshot")

This is a polished up and improved module based on the `calendar2.lua` module
by Bernd Zeimetz and Marc Dequènes.

### Installation

Drop the script into your awesome config folder. Suggestion:

```bash
cd ~/.config/awesome
git clone https://github.com/deficient/calendar.git
```


### Usage

In your `rc.lua`:

```lua
-- load the widget code
local calendar = require("calendar")

-- attach it as popup to your text clock widget:
calendar({}):attach(mytextclock)
```


### Requirements

* [awesome 4.0](http://awesome.naquadah.org/). May work on 3.5 with minor changes.
