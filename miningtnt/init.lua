local tnt_tables = {["miningtnt:tnt1"] = {r=1},
					["miningtnt:tnt2"] = {r=2},
					["miningtnt:tnt3"] = {r=3},
					["miningtnt:tnt4"] = {r=4},
					["miningtnt:tnt5"] = {r=5},
					["miningtnt:tnt6"] = {r=7},
					["miningtnt:tnt7"] = {r=9},
					["miningtnt:tnt8"] = {r=11},
					["miningtnt:tnt9"] = {r=13},
					["miningtnt:tnt10"] = {r=15},
					["miningtnt:tnt11"] = {r=20},
					["miningtnt:tnt12"] = {r=25},
					["miningtnt:tnt13"] = {r=30},
					["miningtnt:tnt14"] = {r=35},
					["miningtnt:tnt15"] = {r=40},
					["miningtnt:tnt16"] = {r=50},
					["miningtnt:tnt17"] = {r=60},
					["miningtnt:tnt18"] = {r=70},
					["miningtnt:tnt19"] = {r=85},
					["miningtnt:tnt20"] = {r=100},
}

local function is_tnt(name)
	if tnt_tables[name]~=nil then return true end
	return false
end

local function combine_texture(texture_size, frame_count, texture, ani_texture)
        local l = frame_count
        local px = 0
        local combine_textures = ":0,"..px.."="..texture
        while l ~= 0 do
                combine_textures = combine_textures..":0,"..px.."="..texture
                px = px+texture_size
                l = l-1
        end
        return ani_texture.."^[combine:"..texture_size.."x"..texture_size*frame_count..":"..combine_textures.."^"..ani_texture
end

local animated_tnt_texture = combine_texture(16, 4, "tnt_top.png", "miningtnt_top_burning_animated.png")

function miningtnt_storage_dump(pos)
	--Add dump
	local meta=minetest.get_meta(pos)
	local dumpitem=meta:get_string("dump_item")
	local i=0
	while true do 
		local item=meta:get_string('item_name'..i)
		local candump=true
		if item=="" then
			break
		elseif dumpitem~="" and item~=dumpitem then
			i=i+1
		else
			local num=meta:get_int('item_num'..i)
			if num==0 then
				i=i+1
			else
				local itemstack=ItemStack(item)
				local maxstack=itemstack:get_stack_max()
				local dropcount=math.min(num,maxstack)
				minetest.add_item({x=pos.x,y=pos.y+1,z=pos.z},item..' '..dropcount)
				meta:set_int('item_num'..i,num-dropcount)
				break
			end
		end
	end
end

minetest.register_node("miningtnt:storage", {
	description = "Mining Storage",
	tiles = {"tnt_top.png", "tnt_bottom.png", "tnt_side.png"},
	groups = {cracky=1, level=2, not_in_creative_inventory=1},
	sounds = default.node_sound_wood_defaults(),
	metadata_name = "generic",
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec","field[text;;${text}]")
		meta:set_string("dump_item","")
		meta:set_string("infotext","Now trying to dump some random items")
	end,
	on_punch = function(pos, node, puncher)
		miningtnt_storage_dump(pos)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		fields.text = fields.text or ""
		meta:set_string("dump_item", fields.text)
		if fields.text~="" then
			meta:set_string("infotext","Now trying to dump "..fields.text)
		else
			meta:set_string("infotext","Now trying to dump some random items")
		end
	end,
	mesecons={
		effector={
			action_on=function(pos,node)
				miningtnt_storage_dump(pos)
			end
		}
	}
})



for name,data in pairs(tnt_tables) do
	
	minetest.register_node(name, {
		description = "TNT ("..name..")",
		tiles = {"tnt_top.png", "tnt_bottom.png", "tnt_side.png"},
		groups = {dig_immediate=2, mesecon=2, not_in_creative_inventory=1},
		sounds = default.node_sound_wood_defaults(),
		
		on_punch = function(pos, node, puncher)
			if puncher:get_wielded_item():get_name() == "default:torch" then
				if minetest.is_protected(pos, puncher:get_player_name()) then
					print(puncher:get_player_name() .. " tried to light TNT at " .. minetest.pos_to_string(pos))
					minetest.record_protection_violation(pos, puncher:get_player_name())
					return
				end
				minetest.sound_play("miningtnt_ignite", {pos=pos})
				boom_miningtnt(pos, 4)
				minetest.set_node(pos, {name=name.."_burning"})
			end
		end,
		
		mesecons = {
			effector = {
				action_on = function(pos, node)
					boom_miningtnt(pos, 0)
				end
			},
		},
	})
	
	minetest.register_node(name.."_burning", {
	        tiles = {{name=animated_tnt_texture, animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=1}},
	        "tnt_bottom.png", "tnt_side.png"},
	        light_source = 5,
	        drop = "",
	        sounds = default.node_sound_wood_defaults(),
	})
	
	local prev = "miningtnt:tnt"..tonumber(strs:rem_from_start(name, "miningtnt:tnt"))-1
	if prev=="miningtnt:tnt0" then prev="" end
	--print(name .. " is made from " .. prev)
	
	minetest.register_craft({
		output = name,
		recipe = {
			{"",prev,""},
			{"","miningtnt:gunpowder",""},
			{"",prev,""},
		}
	})
	
end

function boom_miningtnt(pos, time)
	local id = minetest.get_node(pos).name
	boom_miningtnt_id(pos, time, id)
end

function boom_miningtnt_id(pos, time, id)
	minetest.after(time, function(pos)
		
		local tnt_range = tnt_tables[id].r * 2
	
		local t1 = os.clock()
		minetest.sound_play("miningtnt_explode", {pos=pos, gain=1.5, max_hear_distance=tnt_range*64})
		
		minetest.remove_node(pos)
		
--		local manip = minetest.get_voxel_manip()
--		local width = tnt_range
--		local emerged_pos1, emerged_pos2 = manip:read_from_map({x=pos.x-width, y=pos.y-width, z=pos.z-width},
--		{x=pos.x+width, y=pos.y+width, z=pos.z+width})
--		area = VoxelArea:new{MinEdge=emerged_pos1, MaxEdge=emerged_pos2}
--		nodes = manip:get_data()
--		
--		local p_pos = area:index(pos.x, pos.y, pos.z)
--		nodes[p_pos] = tnt_c_air
		minetest.add_particle(pos, {x=0,y=0,z=0}, {x=0,y=0,z=0}, 0.5, 16, false, "miningtnt_explode.png")
		--minetest.set_node(pos, {name="tnt:boom_miningtnt"})
		
		local objects = minetest.get_objects_inside_radius(pos, tnt_range/2)
		for _,obj in ipairs(objects) do
			if obj:is_player() or (obj:get_luaentity() and obj:get_luaentity().name ~= "__builtin:item") then
				local obj_p = obj:getpos()
				local vec = {x=obj_p.x-pos.x, y=obj_p.y-pos.y, z=obj_p.z-pos.z}
				local dist = (vec.x^2+vec.y^2+vec.z^2)^0.5
				local damage = 0
				if dist < tnt_range/3.0 then damage = tnt_range end
				obj:punch(obj, 1.0, {
					full_punch_interval=1.0,
					damage_groups={fleshy=damage},
				}, vec)
			end
		end
		
		local storedPoses = {}
		local ts = tnt_range * tnt_range

		local mined_items = {}

		for dx=-tnt_range,tnt_range do
			local zm=math.floor((ts-dx*dx)^(1/2.0))
			for dz=-zm,zm do
				local ym=math.floor((ts-dx*dx-dz*dz)^(1/2.0))
				for dy=-ym,ym do
					local p = {x=pos.x+dx, y=pos.y+dy, z=pos.z+dz}
					----------------------------------------
					--local p = {x=pos.x+dx, y=pos.y+dy, z=pos.z+dz}
					--vector.add(p, dir)
					----------------------------------------
--							local p_node = area:index(p.x, p.y, p.z)
--							local d_p_node = nodes[p_node]
					local node = minetest.get_node(p)
					local nodename = node.name
					if nodename~="air" then
						--if math.abs(dx)<tnt_range and math.abs(dy)<tnt_range and math.abs(dz)<tnt_range then
						if mined_items[nodename]==nil then
							mined_items[nodename]=1
						else
							mined_items[nodename]=mined_items[nodename]+1
						end
						minetest.remove_node(p)
						--elseif pr:next(1,5) <= 4 then
						--	destroy(p, player, ents)
						--end
					end
				end
			end
		end

		minetest.add_node({x=pos.x,y=pos.y-tnt_range,z=pos.z},{name="miningtnt:storage"})
		local meta=minetest.get_meta({x=pos.x,y=pos.y-tnt_range,z=pos.z})
		local i=0
		for name in pairs(mined_items) do
			meta:set_string("item_name"..i,name)
			meta:set_int("item_num"..i,mined_items[name])
			i=i+1
		end
		
		print(string.format("[tnt] exploded in: %.2fs", os.clock() - t1))
	end, pos)
end

---------------------  GUNPOWDER  -------------------

minetest.register_craftitem("miningtnt:gunpowder", {
        description = "Gun Powder",
        inventory_image = "miningtnt_gunpowder_inventory.png",
})

minetest.register_craft({
        output = "miningtnt:gunpowder",
        type = "shapeless",
        recipe = {"default:coal_lump", "default:gravel", "default:pick_stone"}
})

