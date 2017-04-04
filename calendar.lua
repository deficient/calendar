-- original code made by Bzed and published on http://awesome.naquadah.org/wiki/Calendar_widget
-- modified by Marc Dequènes (Duck) <Duck@DuckCorp.org> (2009-12-29), under the same licence,
-- and with the following changes:
--   + transformed to module
--   + the current day formating is customizable

-- captures
local os = os
local capi = {
    mouse = mouse,
    screen = screen,
}
local awful = require("awful")
local naughty = require("naughty")


-- utility functions
local function format_date(format, date)
    return os.date(format, os.time(date))
end

local function day_id(date)
    return format_date("%m-%d", date)
end

local calendar = {}

function calendar:new(args)
    return setmetatable({}, {__index = self}):init(args)
end

function calendar:init(args)
    -- first day of week: monday=1, …, sunday=7
    self.fdow       = args.fdow       or 1
    self.html       = args.html       or '<span font_desc="monospace">%s</span>'
    self.today      = args.today      or '<b><span color="#00ff00">%2i</span></b>'
    self.anyday     = args.anyday     or '%2i'
    self.page_title = args.page_title or '%B %Y\n\n'
    self.col_title  = args.col_title  or '%a '
    return self
end

function calendar:page(month, year)

    local today = day_id()

    -- 2001 started with a monday:
    local d0 = format_date("*t", {year=2001, month=1,       day=self.fdow })
    local dA = format_date("*t", {year=year, month=month,   day=1         })
    local dB = format_date("*t", {year=year, month=month+1, day=0         })
    local tA =                   {year=year, month=month,   day=1         }
    local colA = (dA.wday - d0.wday) % 7

    -- print page title
    local page = format_date(self.page_title, tA)

    -- print column titles (weekday)
    page = page .. "    "
    for d = 0, 6 do
        page = page .. format_date(self.col_title, {
            year  = d0.year,
            month = d0.month,
            day   = d0.day + d,
        })
    end

    -- print empty space before first day
    page = page .. "\n" .. format_date(" %V", tA)
    for column = 1, colA do
        page = page .. "   -"
    end

    -- iterate all days of the month
    local nLines = 1
    local column = colA
    for day = 1, dB.day do
        if column == 7 then
            column = 0
            nLines = nLines + 1
            page = page .. "\n" .. format_date(" %V", {year=year, month=month, day=day})
        end
        if today == day_id {day=day, month=month, year=year} then
            page = page .. "  " .. self.today:format(day)
        else
            page = page .. "  " .. self.anyday:format(day)
        end
        column = column + 1
    end

    for column = column, 6 do
        page = page .. "   -"
    end

    return page
end

function calendar:switch(months)
    self:show(self.year, self.month+months)
end

function calendar:show(year, month)
    local today = os.time()
    self.month  = month or os.date('%m', today)
    self.year   = year  or os.date('%Y', today)

    self:hide()
    self.notification = naughty.notify({
        text = self.html:format(self:page(self.month, self.year)),
        timeout = 0,
        hover_timeout = 0.5,
        screen = capi.mouse.screen
    })
end

function calendar:hide()
    naughty.destroy(self.notification)
end

function calendar:attach(widget)
    widget:connect_signal('mouse::enter', function() self:show() end)
    widget:connect_signal('mouse::leave', function() self:hide() end)
    widget:buttons(awful.util.table.join(
        awful.button({         }, 1, function() self:switch( -1) end),
        awful.button({         }, 3, function() self:switch(  1) end),
        awful.button({         }, 4, function() self:switch( -1) end),
        awful.button({         }, 5, function() self:switch(  1) end),
        awful.button({ 'Shift' }, 1, function() self:switch(-12) end),
        awful.button({ 'Shift' }, 3, function() self:switch( 12) end),
        awful.button({ 'Shift' }, 4, function() self:switch(-12) end),
        awful.button({ 'Shift' }, 5, function() self:switch( 12) end)
    ))
end

return setmetatable(calendar, {
    __call = calendar.new,
})
