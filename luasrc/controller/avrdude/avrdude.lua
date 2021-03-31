--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

avrdude.lua 2013-08-26 by histamine
]]--

module("luci.controller.avrdude.avrdude", package.seeall)

local board_info = {
	arduino_uno 		= { name = "Arduino Uno", 			protocol = "arduino", mcu = "m328p", speed = 115200, max_size = 32256 },
	arduino_duemilanove_328 = { name = "Arduino Duemilanove w/ ATmega328", 	protocol = "arduino", mcu = "m328p", speed = 57600,  max_size = 30720 },
	arduino_duemilanove_168 = { name = "Arduino Duemilanove w/ ATmega168", 	protocol = "arduino", mcu = "m168",  speed = 19200,  max_size = 14336 },
	arduino_nano_328 	= { name = "Arduino Nano w/ ATmega328", 	protocol = "arduino", mcu = "m328p", speed = 57600,  max_size = 30720 },
	arduino_nano_168 	= { name = "Arduino Nano w/ ATmega168", 	protocol = "arduino", mcu = "m168",  speed = 19200,  max_size = 14336 },
	arduino_pro_mini_328 	= { name = "Arduino Pro or Pro Mini w/ ATmega328", 	protocol = "arduino", mcu = "m328p", speed = 57600,  max_size = 30720 },
	arduino_pro_mini_168 	= { name = "Arduino Pro or Pro Mini w/ ATmega168", 	protocol = "arduino", mcu = "m168",  speed = 19200,  max_size = 14336 },
	arduino_mega_2560 	= { name = "Arduino Mega 2560 or Mega ADK", 	protocol = "stk500v2", mcu = "m2560", speed = 115200, max_size = 258048 },
	arduino_mega_1280 	= { name = "Arduino Mega (ATmega1280)", 	protocol = "arduino",  mcu = "m2560", speed = 57600,  max_size = 126976 },
	arduino_leonardo 	= { name = "Arduino Leonardo", 			protocol = "avr109",   mcu = "m32u4", speed = 57600,  max_size = 28672  },
	arduino_micro		= { name = "Arduino Micro", 			protocol = "avr109",   mcu = "m32u4", speed = 57600,  max_size = 28672  }
}

function index()
	entry({"admin", "avrdude"}, alias("admin", "avrdude", "upload"), _("Avrdude"), 90)
	entry({"admin", "avrdude", "upload"}, call("action_upload"), _("Uploader"), 10)
end

function action_upload()
	local tmpfile = "/tmp/avr.hex"
	local file
	luci.http.setfilehandler(
		function(meta, chunk, eof)
			if not nixio.fs.access(tmpfile) and not file and chunk and #chunk > 0 then
				file = io.open(tmpfile, "w")
			end
			if file and chunk then
				file:write(chunk)
			end
			if file and eof then
				file:close()
			end
		end
	)

	local step	= tonumber(luci.http.formvalue("step") or 1)
	local has_hex 	= nixio.fs.access(tmpfile)
	local has_supported = nixio.fs.access("/usr/bin/avrdude")
	if not has_hex or step == 1 then
		if has_hex then
			nixio.fs.unlink(tmpfile)
		end

		luci.template.render("avrdude/avrdude", {
			step=1,
			supported = has_supported,
			board_info = board_info
		} )
	elseif step == 2 then
		local arduino_type = luci.http.formvalue("arduino_type") or "arduino_uno"
		if has_hex then
			luci.http.prepare_content("text/plain")
			local tty_name  = luci.http.formvalue("tty_name") or "/dev/ttyACM0"
			local max_size 	= board_info[arduino_type].max_size
			local protocol 	= board_info[arduino_type].protocol
			local speed    	= board_info[arduino_type].speed
			local mcu 	= board_info[arduino_type].mcu
			local cmd 	= "/usr/bin/avrdude -p %s -D -c %s -b %u -P %s -C /etc/avrdude.conf -U flash:w:%s 2>&1" %{mcu, protocol, speed, tty_name, tmpfile}

			luci.http.write("Starting avrdude...\n")
			luci.http.write("%s\n" % {cmd})
			local flash = ltn12_popen(cmd)
			luci.ltn12.pump.all(flash, luci.http.write)

			nixio.fs.unlink(tmpfile)
		end
	end
end

function ltn12_popen(command)

	local fdi, fdo = nixio.pipe()
	local pid = nixio.fork()

	if pid > 0 then
		fdo:close()
		local close
		return function()
			local buffer = fdi:read(2048)
			local wpid, stat = nixio.waitpid(pid, "nohang")
			if not close and wpid and stat == "exited" then
				close = true
			end

			if buffer and #buffer > 0 then
				return buffer
			elseif close then
				fdi:close()
				return nil
			end
		end
	elseif pid == 0 then
		nixio.dup(fdo, nixio.stdout)
		fdi:close()
		fdo:close()
		nixio.exec("/bin/sh", "-c", command)
	end
end
