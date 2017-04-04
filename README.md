## awesome-calendar

### Description

Small calendar popup for awesome window manager.

This is a more modern derivative of the `calendar2.lua` module.

### Installation

Drop the script into your awesome config folder. Suggestion:

```bash
cd ~/.config/awesome
git clone git@github.com:coldfix/awesome-calendar.git
```


### Usage

In your `rc.lua`:

```lua
-- load the widget code
local calendar = require("awesome-calendar")

-- attach it as popup to your text clock widget:
calendar({}):attach(mytextclock)
```


### Requirements

* [awesome 4.0](http://awesome.naquadah.org/) or possibly 3.5
