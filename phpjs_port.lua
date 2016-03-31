--[[
	LUA variant of the php unserialize function 
	Port of http://phpjs.org/functions/unserialize
]]--
local function unserialize (data)
	
	local function utf8Overhead (chr)
		local code = chr:byte()
		if (code < 0x0080) then
			return 0
		end
		
		if (code < 0x0800) then
			return 1
		end
		
		return 2
	end
	
	local function error (type, msg, filename, line)
		print ("[Error(" .. type .. ", " ..  message ..")]")
	end
	
	local function read_until (data, offset, stopchr)
		local buf, chr, len;
		
	    buf = {}; chr = data:sub(offset, offset); 
		len = string.len(data);
	    while (chr ~= stopchr) do
	        if (offset > len) then
	           error('Error', 'Invalid')
		    end
	        table.insert(buf, chr)
			offset = offset + 1
		
	        chr = data:sub(offset, offset)
		end
		
	    return {table.getn(buf), table.concat(buf,'')};
	end
	
	local function read_chrs(data, offset, length)
		local i, buf;
		buf = {};
	    for i = 0, length - 1, 1 do
	        chr = data:sub(offset + i, offset + i);
	        table.insert(buf, chr);
		
	        length = length - utf8Overhead(chr);
		end
	    return {table.getn(buf), table.concat(buf,'')};
	end

	
	local function _unserialize(data, offset)
		local dtype, dataoffset, keyandchrs, keys, 
			  readdata, readData, ccount, stringlength, 
			  i, key, kprops, kchrs, vprops, vchrs, value,
              chrs, typeconvert;
		chrs = 0;
		typeconvert = function(x) return x end;
		
		if offset == nil then
			offset = 1 -- lua offsets starts at 1
		end
		
		dtype = string.lower(data:sub(offset, offset))
		-- print ("dtype " .. dtype .. " offset " ..offset)
		
		dataoffset = offset + 2
		if (dtype == 'i') or (dtype == 'd') then
			typeconvert = function(x) 
				return tonumber(x) 
			end
            
			readData = read_until(data, dataoffset, ';');
            chrs     = tonumber(readData[1]);
            readdata = readData[2];
            dataoffset = dataoffset + chrs + 1;
			
		elseif dtype == 'b' then
			typeconvert = function(x) 
				return tonumber(x) ~= 0 
			end
            
			readData = read_until(data, dataoffset, ';');
            chrs 	 = tonumber(readData[1]);
            readdata = readData[2];
            dataoffset = dataoffset + chrs + 1;
		elseif dtype == 'n' then
			readData = nil
			
		elseif dtype == 's' then
			ccount = read_until(data, dataoffset, ':');
			
			chrs         = tonumber(ccount[1]);
            stringlength = tonumber(ccount[2]);
            dataoffset = dataoffset + chrs + 2;
			
            readData = read_chrs(data, dataoffset, stringlength);
            chrs     = readData[1];
            readdata = readData[2];
            dataoffset = dataoffset + chrs + 2;
			
            if ((chrs ~= stringlength) and (chrs ~= string.length(readdata.length))) then
                error('SyntaxError', 'String length mismatch');
			end
		
		elseif dtype == 'a' then
			readdata = {}
			
			keyandchrs = read_until(data, dataoffset, ':');
            chrs = tonumber(keyandchrs[1]);
            keys = tonumber(keyandchrs[2]);
			
			dataoffset = dataoffset + chrs + 2
			
			for i = 0, keys - 1, 1 do
				kprops = _unserialize(data, dataoffset);
				
				kchrs  = tonumber(kprops[2]);
				key    = kprops[3];
				dataoffset = dataoffset + kchrs
				
				vprops = _unserialize(data, dataoffset)
                vchrs  = tonumber(vprops[2]);
                value  = vprops[3];
				dataoffset = dataoffset + vchrs;
				 
                readdata[key] = value;				
			end
			
			dataoffset = dataoffset + 1
		else 
			error('SyntaxError', 'Unknown / Unhandled data type(s): ' + dtype);
		end
		
		return {dtype, dataoffset - offset, typeconvert(readdata)};
	end
	
	return _unserialize((data .. ''), 1)[3];
end

local thing = 'a:4:{s:3:"ugh";s:4:"that";s:6:"ughhhh";i:2;i:2;s:8:"whatever";i:3;i:4;}'
print(unserialize(thing))
