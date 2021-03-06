local pgc = {}
local functions = require('functions')
function pgc:init(configuration)
	pgc.command = 'gocalc <required candy> <#pokemon> <#candy>'
	pgc.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('gocalc', true).table
	pgc.documentation = configuration.command_prefix .. 'gocalc <required candy> <number of Pokémon> <number of candy> - Calculates the number of Pokémon that must be transferred before evolving, how many evolutions the user is able to perform, and how many Pokémon and candy will be left over. All arguments must be positive numbers. Batch jobs may be performed by separating valid sets of arguments by lines. Example (forty pidgeys and three hundred pidgey candies): ' .. configuration.command_prefix .. 'gocalc 12 40 300.'
end
local pidgey_calc = function(candies_to_evolve, mons, candies)
	local transferred = 0;
	local evolved = 0;
	while true do
		if math.floor(candies / candies_to_evolve) == 0 or mons == 0 then
			break
		else
			mons = mons - 1
			candies = candies - candies_to_evolve + 1
			evolved = evolved + 1
			if mons == 0 then
				break
			end
		end
	end
	while true do
		if (candies + mons) < (candies_to_evolve + 1) or mons == 0 then
			break
		end
		while candies < candies_to_evolve do
			transferred = transferred + 1
			mons = mons - 1
			candies = candies + 1
		end
		mons = mons - 1
		candies = candies - candies_to_evolve + 1
		evolved = evolved + 1
	end
	return {
		transfer = transferred,
		evolve = evolved,
		leftover_mons = mons,
		leftover_candy = candies
	}
end
local single_job = function(input)
	local req_candy, mons, candies = input:match('^(%d+) (%d+) (%d+)$')
	req_candy = tonumber(req_candy)
	mons = tonumber(mons)
	candies = tonumber(candies)
	if not (req_candy and mons and candies) then
		return { err = 'Invalid input: Three numbers expected.' }
	elseif req_candy > 400 then
		return { err = 'Invalid required candy: Maximum is 400.' }
	elseif mons > 1000 then
		return { err = 'Invalid number of Pokémon: Maximum is 1000.' }
	elseif candies > 10000 then
		return { err = 'Invalid number of candies: Maximum is 10000.' }
	else
		return pidgey_calc(req_candy, mons, candies)
	end
end
function pgc:action(msg)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, pgc.documentation)
		return
	end
	input = input .. '\n'
	local output = ''
	local total_evolutions = 0
	for line in input:gmatch('(.-)\n') do
		local info = single_job(line)
		output = output .. '`' .. line .. '`\n'
		if info.err then
			output = output .. info.err .. '\n\n'
		else
			total_evolutions = total_evolutions + info.evolve
			local s = '*Transfer:* %s. \n*Evolve:* %s (%s XP, %s minutes). \n*Leftover:* %s mons, %s candy.\n\n'
			s = s:format(info.transfer, info.evolve, info.evolve .. 'k', info.evolve * 0.5, info.leftover_mons, info.leftover_candy)
			output = output .. s
		end
	end
	local s = '*Total evolutions:* %s. \n*Recommendation:* %s'
	local recommendation
	local egg_count = math.floor(total_evolutions / 60)
	if egg_count < 1 then
		recommendation = 'I recommend you wait until you have, at least, sixty Pokémon to evolve before using a lucky egg.'
	else
		recommendation = 'Use %s lucky egg(s) for %s evolutions.'
		recommendation = recommendation:format(egg_count, egg_count * 60)
	end
	s = s:format(total_evolutions, recommendation)
	output = output .. s
	functions.send_reply(msg, output, true)
end
return pgc