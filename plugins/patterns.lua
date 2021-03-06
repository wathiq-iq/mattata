local patterns = {}
local functions = require('functions')
function patterns:init(configuration)
	patterns.command = 's/<pattern>/<substitution>'
	patterns.help_word = 'sed'
	patterns.triggers = { configuration.command_prefix .. '?s/.-/.-$' }
	patterns.documentation = configuration.command_prefix .. 's/<pattern>/<substitution> Replace all matches for the Lua pattern(s).'
end
function patterns:action(msg)
	if not msg.reply_to_message then
		return true
	end
	local output = msg.reply_to_message.text
	if msg.reply_to_message.from.id == self.info.id then
		output = output:gsub('Did you mean:\n"', '')
		output = output:gsub('"$', '')
	end
	local m1, m2 = msg.text:match('^/?s/(.-)/(.-)/?$')
	if not m2 then
		return true
	end
	local res
	res, output = pcall(
		function()
			return output:gsub(m1, m2)
		end
	)
	if res == false then
		functions.send_reply(msg, 'Invalid pattern.')
	else
		output = 'Did you mean _' .. functions.trim(output:sub(1, 4000)) .. '_?'
		functions.send_reply(msg, output, true)
	end
end
return patterns