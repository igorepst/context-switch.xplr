local csw = {}

local cur = 1
local cs = {}

local rend_ins = function(i, v)
    return { i == cur and 'v' or '', tostring(i), v.inited and v.pwd or '?' }
end

local capture = function(c, app)
    c.pwd = app.pwd
    c.inited = true
    c.focused_path = app.focused_node.absolute_path
    c.selection = {}
    if app.selection then
        for _, v in pairs(app.selection) do
            table.insert(c.selection, v.absolute_path)
        end
    end
end

csw.get_current_context_num = function()
    return cur
end

csw.setup = function(args)
    args = args or {}
    args.mode = args.mode or 'default'
    args.key = args.key or 'ctrl-s'
    if not args.layout_height or args.layout_height < 1 or args.layout_height > 99 then
        args.layout_height = 30
    end

    ---@diagnostic disable
    local xplr = xplr
    ---@diagnostic enable

    xplr.fn.custom.render_context_switch_layout = function(_)
        local t = {}
        for k, v in pairs(cs) do
            if k ~= 1 then
                table.insert(t, rend_ins(k - 1, v))
            end
        end
        table.insert(t, rend_ins(0, cs[1]))
        return t
    end
    xplr.config.modes.custom.context_switch = {
        name = 'context switch',
        key_bindings = {
            on_key = {
                ['ctrl-c'] = {
                    help = 'terminate',
                    messages = { 'Terminate' },
                },
                esc = {
                    help = 'escape',
                    messages = { 'PopMode' },
                },
                ['q'] = {
                    help = 'quit',
                    messages = { 'Quit' },
                },
            },
            default = { messages = {} },
        },
        layout = {
            Vertical = {
                config = {
                    constraints = {
                        {
                            Percentage = 100 - args.layout_height,
                        },
                        {
                            Percentage = args.layout_height,
                        },
                    },
                },
                splits = {
                    'Table',
                    {
                        CustomContent = {
                            title = 'Context Switch',
                            body = {
                                DynamicTable = {
                                    widths = {
                                        { Percentage = 5 },
                                        { Percentage = 5 },
                                        { Percentage = 90 },
                                    },
                                    col_spacing = 1,
                                    render = 'custom.render_context_switch_layout',
                                },
                            },
                        },
                    },
                },
            },
        },
    }
    xplr.fn.custom['context_switch_to_helper'] = function(app)
        local c = cs[cur + 1]
        capture(c, app)
    end
    xplr.config.modes.builtin[args.mode].key_bindings.on_key[args.key] = {
        help = 'context switch',
        messages = {
            'PopMode',
            {
                CallLuaSilently = 'custom.context_switch_to_helper',
            },
            {
                SwitchModeCustom = 'context_switch',
            },
        },
    }

    for i = 0, 9 do
        local c = {}
        table.insert(cs, c)
        xplr.fn.custom['context_switch_to_' .. i] = function(app)
            cur = i
            if c.inited then
                local msgs = {
                    { ChangeDirectory = c.pwd },
                }
                if c.focused_path then
                    table.insert(msgs, { FocusPath = c.focused_path })
                end
                if c.selection then
                    table.insert(msgs, 'ClearSelection')
                    for _, v in pairs(c.selection) do
                        table.insert(msgs, { SelectPath = v })
                    end
                end
                return msgs
            else
                capture(c, app)
            end
        end
        xplr.config.modes.custom.context_switch.key_bindings.on_key[tostring(i)] = {
            help = 'context switch ' .. i,
            messages = {
                { CallLuaSilently = 'custom.context_switch_to_' .. i },
                'PopMode',
            },
        }
    end
end

return csw
