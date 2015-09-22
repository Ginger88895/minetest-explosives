local tnt_tables = {["checkertnt:tnt1"] = {r=1},
					["checkertnt:tnt2"] = {r=2},
					["checkertnt:tnt3"] = {r=4},
					["checkertnt:tnt4"] = {r=6},
					["checkertnt:tnt5"] = {r=8},
					["checkertnt:tnt6"] = {r=10},
					["checkertnt:tnt7"] = {r=12},
					["checkertnt:tnt8"] = {r=14},
					["checkertnt:tnt9"] = {r=16},
					["checkertnt:tnt10"] = {r=18},
					["checkertnt:tnt11"] = {r=20},
					["checkertnt:tnt12"] = {r=22},
					["checkertnt:tnt13"] = {r=25},
					["checkertnt:tnt14"] = {r=30},
					["checkertnt:tnt15"] = {r=35},
					["checkertnt:tnt16"] = {r=40},
					["checkertnt:tnt17"] = {r=45},
					["checkertnt:tnt18"] = {r=50},
					["checkertnt:tnt19"] = {r=55},
					["checkertnt:tnt20"] = {r=60},
					["checkertnt:tnt21"] = {r=65},
					["checkertnt:tnt22"] = {r=70},
					["checkertnt:tnt23"] = {r=75},
					["checkertnt:tnt24"] = {r=80},
					["checkertnt:tnt25"] = {r=85},
					["checkertnt:tnt26"] = {r=90},
					["checkertnt:tnt27"] = {r=95},
					["checkertnt:tnt28"] = {r=100},
					["checkertnt:tnt29"] = {r=105},
					["checkertnt:tnt30"] = {r=110},
					["checkertnt:tnt31"] = {r=115},
					["checkertnt:tnt32"] = {r=120},
					["checkertnt:tnt33"] = {r=125},
					["checkertnt:tnt34"] = {r=130},
					["checkertnt:tnt35"] = {r=135},
					["checkertnt:tnt36"] = {r=140},
					["checkertnt:tnt37"] = {r=145},
					["checkertnt:tnt38"] = {r=150},
					["checkertnt:tnt39"] = {r=160},
					["checkertnt:tnt40"] = {r=170},
}
				

tnt = {}
tnt.force = {}
tnt.accl = {} 

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

local animated_tnt_texture = combine_texture(16, 4, "default_tnt_top.png", "checkertnt_top_burning_animated.png")
	
tnt_c_tnt = {}
tnt_c_tnt_burning = {}
tnt_types_int = {}

for name,data in pairs(tnt_tables) do
	
	tnt_types_int[#tnt_types_int] = name

	minetest.register_node(name, {
		description = "TNT ("..name..")",
		tiles = {"default_tnt_top.png", "default_tnt_bottom.png", "default_tnt_side.png"},
		groups = {dig_immediate=2, mesecon=2},
		sounds = default.node_sound_wood_defaults(),
		
		on_punch = function(pos, node, puncher)
			if puncher:get_wielded_item():get_name() == "default:torch" then
				if minetest.is_protected(pos, puncher:get_player_name()) then
					print(puncher:get_player_name() .. " tried to light TNT at " .. minetest.pos_to_string(pos))
					minetest.record_protection_violation(pos, puncher:get_player_name())
					return
				end
				minetest.sound_play("checkertnt_ignite", {pos=pos})
				boom_checkertnt(pos, 4, puncher)
				minetest.set_node(pos, {name=name.."_burning"})
			end
		end,
		
		mesecons = {
			effector = {
				action_on = function(pos, node)
					boom_checkertnt(pos, 0)
				end
			},
		},
	})
	
	minetest.register_node(name.."_burning", {
	        tiles = {{name=animated_tnt_texture, animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=1}},
	        "default_tnt_bottom.png", "default_tnt_side.png"},
	        light_source = 5,
	        drop = "",
	        sounds = default.node_sound_wood_defaults(),
	})
	
	local prev = "checkertnt:tnt"..tonumber(strs:rem_from_start(name, "checkertnt:tnt"))-1
	if prev=="checkertnt:tnt0" then prev="" end
	--print(name .. " is made from " .. prev)
	
	minetest.register_craft({
		output = name,
		recipe = {
			{"",prev,""},
			{"","checkertnt:gunpowder",""},
			{"",prev,""},
		}
	})
	
	tnt_c_tnt[#tnt_c_tnt + 1] = minetest.get_content_id(name)
	tnt_c_tnt_burning[#tnt_c_tnt_burning + 1] = minetest.get_content_id(name.."_burning")

end


local function get_tnt_random(pos)
        return PseudoRandom(math.abs(pos.x+pos.y*3+pos.z*5)+15)
end





function boom_checkertnt(pos, time, player)
	local id = minetest.get_node(pos).name
	boom_checkertnt_id(pos, time, player, id)
end

function boom_checkertnt_id(pos, time, player, id)
	minetest.after(time, function(pos)
		
		local tnt_range = tnt_tables[id].r * 2
	
		local t1 = os.clock()
		pr = get_tnt_random(pos)
		minetest.sound_play("checkertnt_explode", {pos=pos, gain=1.5, max_hear_distance=tnt_range*64})
		
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
		minetest.add_particle(pos, {x=0,y=0,z=0}, {x=0,y=0,z=0}, 0.5, 16, false, "checkertnt_explode.png")
		--minetest.set_node(pos, {name="tnt:boom_checkertnt"})
		
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
		
		if id~="checkertnt:tnt1" then
			for dx=-tnt_range,tnt_range do
				for dz=-tnt_range,tnt_range do
					for dy=-tnt_range,tnt_range do
						local p = {x=pos.x+dx, y=pos.y+dy, z=pos.z+dz}
						if is_tnt(nodename)==true then
							minetest.remove_node(p)
							boom_checkertnt_id(p, 0.5, player, nodename) -- was {x=p.x, y=p.y, z=p.z}
						elseif (dx+dz+dy) % 2 == 0 then
							minetest.remove_node(p)
						end
					end
				end
			end
		end
		
		minetest.add_particlespawner(
			100, --amount
			1, --time
			{x=pos.x-(tnt_range / 2), y=pos.y-(tnt_range / 2), z=pos.z-(tnt_range / 2)}, --minpos
			{x=pos.x+(tnt_range / 2), y=pos.y+(tnt_range / 2), z=pos.z+(tnt_range / 2)}, --maxpos
			{x=-0, y=-0, z=-0}, --minvel
			{x=0, y=0, z=0}, --maxvel
			{x=-0.5,y=5,z=-0.5}, --minacc
			{x=0.5,y=5,z=0.5}, --maxacc
			0.1, --minexptime
			1, --maxexptime
			8, --minsize
			15, --maxsize
			true, --collisiondetection
			"checkertnt_smoke.png" --texture
		)
		print(string.format("[tnt] exploded in: %.2fs", os.clock() - t1))
	end, pos)
end



---------------------  GUNPOWDER  -------------------


function burn(pos, player)
        local nodename = minetest.get_node(pos).name
        if  strs:starts(nodename, "checkertnt:tnt") then
                minetest.sound_play("checkertnt_ignite", {pos=pos})
                boom_checkertnt(pos, 1, player)
                minetest.set_node(pos, {name=minetest.get_node(pos).name.."_burning"})
                return
        end
        if nodename ~= "checkertnt:gunpowder" then
                return
        end
        minetest.sound_play("checkertnt_gunpowder_burning", {pos=pos, gain=2})
        minetest.set_node(pos, {name="checkertnt:gunpowder_burning"})
        
        minetest.after(1, function(pos)
                if minetest.get_node(pos).name ~= "checkertnt:gunpowder_burning" then
                        return
                end
                minetest.after(0.5, function(pos)
                        minetest.remove_node(pos)
                end, {x=pos.x, y=pos.y, z=pos.z})
                for dx=-1,1 do
                        for dz=-1,1 do
                                for dy=-1,1 do
                                        pos.x = pos.x+dx
                                        pos.y = pos.y+dy
                                        pos.z = pos.z+dz
                                        
                                        if not (math.abs(dx) == 1 and math.abs(dz) == 1) then
                                                if dy == 0 then
                                                        burn({x=pos.x, y=pos.y, z=pos.z}, player)
                                                else
                                                        if math.abs(dx) == 1 or math.abs(dz) == 1 then
                                                                burn({x=pos.x, y=pos.y, z=pos.z}, player)
                                                        end
                                                end
                                        end
                                        
                                        pos.x = pos.x-dx
                                        pos.y = pos.y-dy
                                        pos.z = pos.z-dz
                                end
                        end
                end
        end, pos)
end


minetest.register_node("checkertnt:gunpowder", {
        description = "Gun Powder",
        drawtype = "raillike",
        paramtype = "light",
        sunlight_propagates = true,
        walkable = false,
        tiles = {"checkertnt_gunpowder.png",},
        inventory_image = "checkertnt_gunpowder_inventory.png",
        wield_image = "checkertnt_gunpowder_inventory.png",
        selection_box = {
                type = "fixed",
                fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
        },
        groups = {dig_immediate=2,attached_node=1},
        sounds = default.node_sound_leaves_defaults(),
        
        on_punch = function(pos, node, puncher)
                if puncher:get_wielded_item():get_name() == "default:torch" then
                        burn(pos, puncher)
                end
        end,
})

minetest.register_node("checkertnt:gunpowder_burning", {
        drawtype = "raillike",
        paramtype = "light",
        sunlight_propagates = true,
        walkable = false,
        light_source = 5,
        tiles = {{name="checkertnt_gunpowder_burning_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=1}}},
        selection_box = {
                type = "fixed",
                fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
        },
        drop = "",
        groups = {dig_immediate=2,attached_node=1},
        sounds = default.node_sound_leaves_defaults(),
})

local tnt_plus_gunpowder = {"checkertnt:gunpowder"}
for name,data in pairs(tnt_tables) do
	tnt_plus_gunpowder[#tnt_plus_gunpowder+1] = name
end


minetest.register_abm({
        nodenames = tnt_plus_gunpowder,
        neighbors = {"fire:basic_flame"},
        interval = 2,
        chance = 10,
        action = function(pos, node)
                if tnt_tables[node.name]~=nil then
                        boom_checkertnt({x=pos.x, y=pos.y, z=pos.z}, 0)
                else
                        burn(pos)
                end
        end
})

minetest.register_abm({
        nodenames = tnt_plus_gunpowder,
        neighbors = {"tnt:gunpowder"},
        interval = 2,
        chance = 10,
        action = function(pos, node)
                if tnt_tables[node.name]~=nil then
                        boom_checkertnt({x=pos.x, y=pos.y, z=pos.z}, 0)
                else
                        burn(pos)
                end
        end
})

minetest.register_craft({
        output = "checkertnt:gunpowder",
        type = "shapeless",
        recipe = {"default:coal_lump", "default:gravel", "default:dirt"}
})


tnt_c_air = minetest.get_content_id("air")
tnt_c_fire = minetest.get_content_id("fire:basic_flame")

