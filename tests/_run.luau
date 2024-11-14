function load_tests()
	-- tests execute in the order they are loaded
	require("./my_tests")()
end

function run_tests()
	local frktest = require("@frktest/")
	local lune_console_reporter = require("@frktest/reporters/lune_console_reporter")

	lune_console_reporter.init()
	local success = frktest.run()
	if not success then
		require("@lune/process").exit(1)
	end
end

load_tests()
run_tests()
