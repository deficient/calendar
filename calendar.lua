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

local version_major, version_minor = awesome.version:match("(%d+)%.(%d+)")
version_major = tonumber(version_major)
version_minor = tonumber(version_minor)
local can_update_size = version_major and version_minor and version_major >= 4 and version_minor >= 2

------------------------------------------
-- utility functions
------------------------------------------

local function format_date(format, date)
    return os.date(format, os.time(date))
end


------------------------------------------
-- calendar popup widget
------------------------------------------

local calendar = {}

function calendar:new(args)
    return setmetatable({}, {__index = self}):init(args)
end

function calendar:init(args)
    self.num_lines   = 0
    self.today_color = args.today_color or "#00ff00"
    -- first day of week: monday=1, …, sunday=7
    self.fdow        = args.fdow        or 1
    -- notification area:
    self.html        = args.html        or '<span font_desc="monospace">\n%s</span>'
    -- highlight current date:
    self.today       = args.today       or '<b><span color="' .. self.today_color .. '">%2i</span></b>'
    self.anyday      = args.anyday      or '%2i'
    self.page_title  = args.page_title  or '%B %Y'    -- month year
    self.col_title   = args.col_title   or '%a '      -- weekday
    -- Date equality check is based on day_id. We deliberately ignore the year
    -- to highlight the same day in different years:
    self.day_id      = args.day_id      or '%m-%d'
    self.empty_sep   = args.empty_sep   or "   -"
    self.week_col    = args.week_col    or " %V"
    self.days_style  = args.days_style  or {}
    self.position    = args.position    or naughty.config.defaults.position
    return self
end

function calendar:day_style(day_of_week)
    return self.days_style[day_of_week] or '%s'
end

function calendar:page(month, year)

    local today = format_date(self.day_id)

    -- 2001 started with a monday:
    local d0 = format_date("*t", {year=2001, month=1,       day=self.fdow })
    local dA = format_date("*t", {year=year, month=month,   day=1         })
    local dB = format_date("*t", {year=year, month=month+1, day=0         })
    local tA =                   {year=year, month=month,   day=1         }
    local colA = (dA.wday - d0.wday) % 7

    local page_title = format_date(self.page_title, tA)

    -- print column titles (weekday)
    local page = "    "
    for d = 0, 6 do
        page = page .. self:day_style(d+1):format(format_date(self.col_title, {
            year  = d0.year,
            month = d0.month,
            day   = d0.day + d,
        }))
    end

    -- print empty space before first day
    page = page .. "\n" .. format_date(self.week_col, tA)
    for column = 1, colA do
        page = page .. self.empty_sep
    end

    -- iterate all days of the month
    local nLines = 1
    local column = colA
    for day = 1, dB.day do
        if column == 7 then
            column = 0
            nLines = nLines + 1
            page = page .. "\n" .. format_date(self.week_col, {year=year, month=month, day=day})
        end
        if today == format_date(self.day_id, {day=day, month=month, year=year}) then
            page = page .. "  " .. self.today:format(day)
        else
            page = page .. "  " .. self:day_style(column+1):format(self.anyday:format(day))
        end
        column = column + 1
    end

    for column = column, 6 do
        page = page .. self.empty_sep
    end

    return page_title, self.html:format(page)
end

function calendar:switch(months)
    self:show(self.year, self.month+months)
end

function calendar:show(year, month)
    local today = os.time()
    self.month  = month or os.date('%m', today)
    self.year   = year  or os.date('%Y', today)
    local title, text = self:page(self.month, self.year)

    -- NOTE: `naughty.replace_text` does not update bounds and can therefore
    -- not be used when the size increases (before #1756 was merged):
    local num_lines = select(2, text:gsub('\n', ''))
    local will_fit = can_update_size or num_lines <= self.num_lines
    if naughty.replace_text and self.notification and will_fit then
        naughty.replace_text(self.notification, title, text)
    else
        self:hide()
        self.notification = naughty.notify({
            title = title,
            text = text,
            timeout = 0,
            hover_timeout = 0.5,
            screen = capi.mouse.screen,
            position = self.position,
        })
        self.num_lines = num_lines
    end
end

function calendar:hide()
    if self.notification then
        naughty.destroy(self.notification)
        self.notification = nil
        self.num_lines = 0
    end
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
