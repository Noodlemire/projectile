--[[
Research N' Duplication
Copyright (C) 2020 Noodlemire

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
--]]

--Mod-specific global variable
projectile = {}

--A list of registered projectile entites, indexed by the category of weapon that uses them.
projectile.registered_projectiles = {}

--Per-player list of much a projectile weapon has been charged.
projectile.charge_levels = {}



--MP = Mod Path
local mp = minetest.get_modpath(minetest.get_current_modname())..'/'

--In here is every publicly available function that this mod uses.
dofile(mp.."api.lua")

--In here is the registration of ammo items that this mod provides, as well as crafting recipes for weapons and ammo.
dofile(mp.."crafts.lua")



--A helper function to cancel a player's charge when necessary.
local function uncharge_player(player)
	--Useful shorthand
	local pname = player:get_player_name()

	--If there is charge data...
	if projectile.charge_levels[pname] then
		--Get store the previous slot for possible use after charge data deletion.
		local old_slot = projectile.charge_levels[pname].slot
		--Get the projectile weapon. get_wielded_item() can't be used, since the weapon may no longer be held.
		local wep = player:get_inventory():get_stack("main", old_slot)

		--Call the weapon's on_use function, which will cancel it.
		wep:get_definition().on_use(wep, player, true)

		--Update the player's inventory with any modifications.
		player:get_inventory():set_stack("main", old_slot, wep)
	end
end

--Globalsteps are used to either cancel a charge if a player switches weapons, or to update the weapon sprite when charging is complete.
minetest.register_globalstep(function(dtime)
	--For each player on the server...
	for _, player in pairs(minetest.get_connected_players()) do
		--Useful shorthand
		local pname = player:get_player_name()

		--If this player is currently charging a projectile weapon...
		if projectile.charge_levels[pname] then
			--If the player's selected hotbar slot changed...
			if player:get_wield_index() ~= projectile.charge_levels[pname].slot then
				--Cancel their charge.
				uncharge_player(player)

			--Otherwise, as long as the player doesn't change weapon...
			else
				--Add a little charge, according the how much time that has passed since the last globalstep.
				projectile.charge_levels[pname].charge = projectile.charge_levels[pname].charge + dtime

				--Get the charging weapon and its definition
				local wep = player:get_wielded_item()
				local def = wep:get_definition()

				--if the weapon has a listed full_charge_name, meaning it hasn't already fully charged,
				--but now the charge level has reached or exceeded the max...
				if def.full_charge_name and projectile.charge_levels[pname].charge >= def.charge_time then
					--Once this happens, replace the weapon with a fully charged sprite version.
					wep:set_name(def.full_charge_name)
					player:set_wielded_item(wep)
				end
			end
		end
	end
end)

--When a weapon is charging, it's a lot harder to check for when the stack has moved elsewhere, at least in terms of checking it.
--So, if a player tries any inventory action related to a charging projectile weapon, prevent it.
minetest.register_allow_player_inventory_action(function(player, action, inv, info)
	if (action == "take" and minetest.get_item_group(info.stack:get_name(), "projectile_weapon") >= 2) or
			(action == "put" and minetest.get_item_group(inv:get_stack(info.listname, info.index):get_name(), "projectile_weapon") >= 2) or
			(action == "move" and 
			(minetest.get_item_group(inv:get_stack(info.from_list, info.from_index):get_name(), "projectile_weapon") >= 2 or
			minetest.get_item_group(inv:get_stack(info.to_list, info.to_index):get_name(), "projectile_weapon") >= 2)) then
		return 0
	end
end)

--If a player leaves, cancel their charge.
minetest.register_on_leaveplayer(function(player)
	uncharge_player(player)
end)

--If a server is shutdown, cancel all charges.
minetest.register_on_shutdown(function()
	for _, player in pairs(minetest.get_connected_players()) do
		uncharge_player(player)
	end
end)



--The basic slingshot. Slingshots are weaker than bows, but the ammunition they use is way easier to find and create.
projectile.register_weapon("projectile:slingshot",  {
	description = "Slingshot",
	inventory_image = "projectile_slingshot.png",
	inventory_image_2 = "projectile_slingshot_charged.png",
	inventory_image_3 = "projectile_slingshot_charged_full.png",
	durability = 75,
	rw_category = "slingshot",
	charge = true,
	fire_while_charging = true
})

--An upgraded slingshot, which fires faster and harder, but is slightly harder to charge up. Metal wire is stiffer than string, after all.
projectile.register_weapon("projectile:steel_slingshot",  {
	description = "Steel Slingshot",
	inventory_image = "projectile_steel_slingshot.png",
	inventory_image_2 = "projectile_steel_slingshot_charged.png",
	inventory_image_3 = "projectile_steel_slingshot_charged_full.png",
	durability = 150,
	rw_category = "slingshot",
	charge = true,
	fire_while_charging = true,
	charge_time = 1.1,
	damage = 1.25,
	speed = 1.75
})

--The basic bow. It is more powerful than a slingshot, but it takes way longer to charge and ammunition is harder to get.
projectile.register_weapon("projectile:bow",  {
	description = "Bow",
	inventory_image = "projectile_bow.png",
	inventory_image_2 = "projectile_bow_charged.png",
	inventory_image_3 = "projectile_bow_charged_full.png",
	durability = 100,
	rw_category = "bow",
	charge = true,
	fire_while_charging = true,
	charge_time = 2
})

--An upgraded bow, which fires faster and harder, but is slightly harder to charge up. Metal wire is stiffer than string, after all.
projectile.register_weapon("projectile:steel_bow",  {
	description = "Steel Bow",
	inventory_image = "projectile_steel_bow.png",
	inventory_image_2 = "projectile_steel_bow_charged.png",
	inventory_image_3 = "projectile_steel_bow_charged_full.png",
	durability = 200,
	rw_category = "bow",
	charge = true,
	fire_while_charging = true,
	charge_time = 2.1,
	damage = 1.5,
	speed = 1.9
})

--The basic flintlock weapon, which can fire fairly often and has fair damage, but can't be fired before it is fully loaded.
projectile.register_weapon("projectile:flintlock_pistol",  {
	description = "Flintlock Pistol",
	inventory_image = "projectile_flintlock_pistol.png",
	inventory_image_2 = "projectile_flintlock_pistol.png",
	inventory_image_3 = "projectile_flintlock_pistol_charged.png",
	durability = 250,
	rw_category = "flintlock",
	charge = true,
	charge_time = 0.667,

	can_fire = projectile.needs_gunpowder,
	on_cancel = projectile.return_gunpowder
})

--A slowler, more powerful flintlock weapon.
projectile.register_weapon("projectile:musket",  {
	description = "Musket",
	inventory_image = "projectile_musket.png",
	inventory_image_2 = "projectile_musket.png",
	inventory_image_3 = "projectile_musket_charged.png",
	durability = 300,
	rw_category = "flintlock",
	charge = true,
	charge_time = 1.333,
	damage = 1.5,
	speed = 1.1,

	can_fire = projectile.needs_gunpowder,
	on_cancel = projectile.return_gunpowder
})

--A flintlock weapon that fires bursts of shot, rather than individual musket balls.
projectile.register_weapon("projectile:blunderbuss",  {
	description = "Blunderbuss",
	inventory_image = "projectile_blunderbuss.png",
	inventory_image_2 = "projectile_blunderbuss.png",
	inventory_image_3 = "projectile_blunderbuss_charged.png",
	durability = 250,
	rw_category = "flintlock_shot",
	charge = true,
	charge_time = 1,

	can_fire = projectile.needs_gunpowder,
	on_cancel = projectile.return_gunpowder
})



--The basic slingshot projectile: rocks from hardtrees
projectile.register_projectile("projectile:rock", "slingshot", "hardtrees:rock", {
	image = "rock_lump.png",
	damage = 5,
	speed = 15
})

--A helper function for mese projectiles, to check if a particular node can be powered.
local is_mesecon = function(pos)
	local def = minetest.registered_nodes[minetest.get_node(pos).name]

	return def and def.mesecons
end

--Mese projectiles for slingshots, which have medium power and can be used to power mesecon effectors.
projectile.register_projectile("projectile:mese", "slingshot", "default:mese_crystal_fragment", {
	image = "default_mese_crystal_fragment.png",
	damage = 7,
	speed = 20,

	--When a mese crystal fragment hits something...
	on_impact = function(self, collisions)
		--If the mesecon mod is loaded...
		if mesecon then
			--For each collided thing...
			for _, c in pairs(collisions) do
				--If the thing is a node and can be powered...
				if c.type == "node" and is_mesecon(c.node_pos) then
					--Grab data about the node.
					local node = minetest.get_node(c.node_pos)

					--As long as it isn't already powered...
					if not mesecon.is_powered(c.node_pos) then
						--Activate the node.
						mesecon.activate(c.node_pos, node, nil, 0)
						--Then, after 1/4 of the second, deactivate it.
						minetest.after(0.25, function() mesecon.deactivate(c.node_pos, node, nil, 0) end)
					end
				end
			end
		end
	end
})

--Obsidian shards are the strongest slingshot projectile.
projectile.register_projectile("projectile:obsidian", "slingshot", "default:obsidian_shard", {
	image = "default_obsidian_shard.png",
	damage = 9,
	speed = 25
})

--The basic arrow, which has twice the power of a rock.
projectile.register_projectile("projectile:arrow", "bow", "projectile:arrow", {
	damage = 10,
	speed = 30,

	initial_properties = {
		visual = "mesh",
		mesh = "projectile_arrow.obj",
		textures = {"projectile_arrow_texture.png"}
	},

	_on_step = function(self, dtime)
		projectile.autorotate_arrow(self, dtime)

		if fire then
			local selfo = self.object
			local node = minetest.get_node(selfo:get_pos())

			if minetest.get_item_group(node.name, "lava") > 0 or minetest.get_item_group(node.name, "fire") > 0 then
				local arrow = minetest.add_entity(selfo:get_pos(), "projectile:arrow_fire")
				local arrowlua = arrow:get_luaentity()

				arrow:set_velocity(selfo:get_velocity())
				arrow:set_acceleration(selfo:get_acceleration())
				arrow:set_rotation(selfo:get_rotation())

				arrowlua.level = self.level
				arrowlua.damage = 12
				arrowlua.owner = self.owner
				arrowlua.oldvel = self.oldvel
				arrowlua.timer = self.timer

				selfo:remove()
			end
		end
	end
})

--If the fire mod is present...
if fire then
	--Register arrows that can combust flammable terrain.
	projectile.register_projectile("projectile:arrow_fire", "bow", "projectile:arrow_fire", {
		damage = 12,
		speed = 35,

		initial_properties = {
			visual = "mesh",
			mesh = "projectile_arrow.obj",
			textures = {"projectile_arrow_fire_texture.png"}
		},

		_on_step = function(self, dtime)
			projectile.autorotate_arrow(self, dtime)

			local selfo = self.object
			local node = minetest.get_node(selfo:get_pos())

			if minetest.get_item_group(node.name, "water") > 0 then
				local arrow = minetest.add_entity(selfo:get_pos(), "projectile:arrow")
				local arrowlua = arrow:get_luaentity()

				arrow:set_velocity(selfo:get_velocity())
				arrow:set_acceleration(selfo:get_acceleration())
				arrow:set_rotation(selfo:get_rotation())

				arrowlua.level = self.level
				arrowlua.damage = 10
				arrowlua.owner = self.owner
				arrowlua.oldvel = self.oldvel
				arrowlua.timer = self.timer

				selfo:remove()
			end
		end,

		--On impact...
		on_impact = function(self, collisions)
			--For each collision...
			for _, c in pairs(collisions) do
				--For each flammable node it hit...
				if c.type == "node" and minetest.get_item_group(minetest.get_node(c.node_pos).name, "flammable") > 0 then
					--Replace that node with fire.
					minetest.set_node(c.node_pos, {name = "fire:basic_flame"})
				end
			end
		end
	})
end

--Arrows made from gold, which have super high velocity and good damage.
projectile.register_projectile("projectile:arrow_high_velocity", "bow", "projectile:arrow_high_velocity", {
	damage = 15,
	speed = 70,

	initial_properties = {
		visual = "mesh",
		mesh = "projectile_arrow.obj",
		textures = {"projectile_arrow_high_velocity_texture.png"}
	},

	_on_step = projectile.autorotate_arrow
})

--If the tnt mod is present...
if tnt then
	--Register arrows that explode upon contact with anything.
	projectile.register_projectile("projectile:arrow_bomb", "bow", "projectile:arrow_bomb", {
		--Instead of dealing direct damage, bomb arrows rely on the explosion to deal damage.
		damage = 0,
		--Also, it's not like fat sticks of tnt are particularly aerodynamic.
		speed = 25,

		initial_properties = {
			visual = "mesh",
			mesh = "projectile_arrow_bomb.obj",
			textures = {"projectile_arrow_bomb_texture.png"}
		},

		_on_step = projectile.autorotate_arrow,

		--Upon impact, create a small explosion.
		on_impact = function(self, collisions)
			tnt.boom(self.object:get_pos(), {radius = 2, damage_radius = 2})
		end
	})
end

--Basic flintlock ammunition with decent damage, and extremely high speed, and slight spread.
projectile.register_projectile("projectile:musket_ball", "flintlock", "projectile:musket_ball", {
	damage = 15,
	speed = 250,
	spread = 2.5,

	image = "projectile_dot.png^[multiply:#AEAEAE"
})

--A weaker flintlock ammunition that bursts on impact, striking all enemies in a small radius.
--Note that damage of the initial hit is set to 0 so that the radius damage doesn't cause this bullet to hit the same enemy twice.
projectile.register_projectile("projectile:musket_ball_diamond", "flintlock", "projectile:musket_ball_diamond", {
	damage = 0,
	speed = 275,
	spread = 5,

	image = "projectile_dot.png^[multiply:#5AAFE7",

	on_impact = function(self, collisions)
		--Center the blast on the first node or object that the projectile hit.
		local pos = collisions[1].node_pos or collisions[1].object:get_pos()

		--For each object in a radius of 2.5 meters/nodes...
		for _, target in pairs(minetest.get_objects_inside_radius(pos, 2.5)) do
			--As long as this wouldn't be self-damage or friendly fire...
			if not target:is_player() or (self.owner ~= target:get_player_name() and projectile.in_same_party(self, target)) then
				--Punch that target for 9 damage.
				--The direction is just 0, so affected targets won't be knocked anywhere.
				--Instead, they'll just freeze in place for a moment.
				target:punch(self.object, 1, {full_punch_interval = 1, damage_groups = {fleshy = 9}}, {x=0, y=0, z=0})
			end
		end

		--Then, create 16 little particles.
		for i = 1, 16 do
			--ps = particle speed.
			local ps = 25
			--Make a completely random velocity for each particle.
			local vel = {x = math.random(-ps, ps), y = math.random(-ps, ps), z = math.random(-ps, ps)}
			--Multiply and normalize are used so that every particle has exactly 25 velocity
			vel = vector.multiply(vector.normalize(vel), ps)

			--Add the particle so that it lasts only long enough to travel 2.5 meters. Have it look like a smaller version of the bullet fired.
			minetest.add_particle(pos, vel, {x=0, y=0, z=0}, 2.5 / ps, 1, false, "projectile_dot.png^[multiply:#5AAFE7")
		end
	end
})

--An upgrade to the musket ball that deal a lot more damage and is slightly faster and more accurate.
projectile.register_projectile("projectile:musket_ball_mithril", "flintlock", "projectile:musket_ball_mithril", {
	damage = 24,
	speed = 300,
	spread = 2,

	image = "projectile_dot.png^[multiply:#8282D5"
})

--A standard shotgun blast, with smaller than average pellets that basically tickle enemies if only one or two land.
projectile.register_projectile("projectile:shot_pile", "flintlock_shot", "projectile:shot_pile", {
	damage = 4,
	speed = 250,
	count = 9,
	spread = 22.5,
	collide_self = false,

	initial_properties = {
		collisionbox = {-.125, 0, -.125, .125, .25, .125},
		visual_size = {x = 0.25, y = 0.25, z = 0.25}
	},

	image = "projectile_dot.png^[multiply:#AEAEAE"
})

--A massive burst of shot that deals less damage at range, but much more damage up close. Has a lot wider spread as well.
projectile.register_projectile("projectile:shot_pile_diamond", "flintlock_shot", "projectile:shot_pile_diamond", {
	damage = 3,
	speed = 275,
	count = 18,
	spread = 30,
	collide_self = false,

	initial_properties = {
		collisionbox = {-.125, 0, -.125, .125, .25, .125},
		visual_size = {x = 0.25, y = 0.25, z = 0.25}
	},

	image = "projectile_dot.png^[multiply:#5AAFE7"
})

--Stronger shot than steel with nearly double the damage and slightly better speed as well.
projectile.register_projectile("projectile:shot_pile_mithril", "flintlock_shot", "projectile:shot_pile_mithril", {
	damage = 6,
	speed = 300,
	count = 9,
	spread = 22.5,
	collide_self = false,

	initial_properties = {
		collisionbox = {-.125, 0, -.125, .125, .25, .125},
		visual_size = {x = 0.25, y = 0.25, z = 0.25}
	},

	image = "projectile_dot.png^[multiply:#8282D5"
})
