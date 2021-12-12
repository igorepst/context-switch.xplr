# Context switch plugin for [xplr](https://xplr.dev)

---

https://user-images.githubusercontent.com/1630792/141197469-c9fd38ae-2822-4acf-8d6c-537414d8e3f5.mp4

Saves and loads 10 contexts, incl. focused node, sorters & filters.<br/>
Presents to the user a vertically split layout with a file system on the top and
a panel with contexts list. Not initialized contexts have '?' as their path.
Current context is marked by '->'.<br/>
Please note, this is a context switch and not a bookmarking plugin, hence every time
you open this mode, the stored information for the current context will be changed
(current working directory, focused node, sorters & filters).<br/>
Upon quitting `xplr` the contexts will be cleared.

## Keybindings

| Key             | Action                                                   |
| --------------- | -------------------------------------------------------- |
| 0-9             | switch to context number                                 |
| j/down          | next context                                             |
| k/up            | previous context                                         |
| tab/ctrl-n      | next initialized context                                 |
| back-tab/ctrl-p | previous initialized context                             |
| esc             | close context switch mode and return to the previous one |
| enter           | switch to the context under cursor                       |
| q               | quit the context under cursor                            |
| ctrl-c          | terminate `xplr`                                         |

## Installation

- Add the following line in `~/.config/xplr/init.lua`

  ```lua
  package.path = os.getenv("HOME") .. '/.config/xplr/plugins/?/src/init.lua'
  ```

- Clone the plugin

  ```bash
  mkdir -p ~/.config/xplr/plugins

  git clone https://github.com/igorepst/context-switch.xplr ~/.config/xplr/plugins/context-switch
  ```

- Require the module in `~/.config/xplr/init.lua`

  ```lua
  require("context-switch").setup()
  ```

## Arguments

The plugin supports passing multiple arguments to `setup` function

- mode: `xplr` mode ('default' if absent)
- key: keybinding to switch to context mode ('ctrl-s' if absent)
- layout_height: the height in percents of the context switch window (a number between 1-99, default - 32)

## Features

- Save current focus, sort & filter
- Get current context number (use `get_current_context_num()`)<br/>
  Example:

  ```lua
    local csw = require('context-switch')
    csw.setup()
    xplr.fn.custom.render_context_num = function(_)
        return '  ' .. tostring(csw.get_current_context_num())
    end
    -- and then somewhere in your layout use
    {
        CustomContent = {
            title = 'Ctx',
            body = {
                DynamicParagraph = {
                    render = 'custom.render_context_num',
                },
            },
        }
    }
  ```
