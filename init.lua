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

--In here is the registration of ammo items that this mod provides, as well as crafting recipes for weapons and ammo.
dofile(mp.."crafts.lua")



--A function that creates and launches a function out of a player's side when they use a projectile weapon.
function projectile.shoot(wep, user, level)
	--Some useful shorthands
	local pname = user:get_player_name()
	local inv = user:get_inventory()
	local def = wep:get_definition()

	--A projectile isn't spawned directly inside a player, and it doesn't come from the center of the screen.
	--It does start directly in front of the player...
	local pos = user:get_look_dir()
	--But then it's shifted to the right of the player, where it looks like the weapon is held.
	pos = vector.rotate(pos, {x=0 , y = -math.pi / 4, z=0})
	--Then it's shifted up by the player's face.
	pos.y = 1
	--The user's actual position is added last, to make rotating easier.
	pos = vector.add(pos, user:get_pos())

	--Charge level depends on how long the player waited before firing. 1 = 100% charge.
	level = math.min(level / def.charge_time, 1)

	--Look through each inventory slot...
	for i = 1, inv:get_size("main") do
		--get the stack itself
		local ammo = inv:get_stack("main", i)

		--If there is an item stack, and it's registered as an ammo type that this weapon can use...
		if not ammo:is_empty() and projectile.registered_projectiles[def.rw_category][ammo:get_name()] then
			--Create the projectile entity at the determined position
			local projectile = minetest.add_entity(pos, projectile.registered_projectiles[def.rw_category][ammo:get_name()])
			--A shorthand of the luaentity version of the projectile, where data can easily be stored
			local luapro = projectile:get_luaentity()

			--Set velocity according to the direction it was fired. Speed is determined by the weapon, ammo, and how long the weapon was charged.
			projectile:set_velocity(vector.multiply(user:get_look_dir(), luapro.speed * level * def.speed))
			--An acceleration of -9.81y is how gravity is applied.
			projectile:set_acceleration({x=0, y=-9.81, z=0})

			--Store level for later, to determine impact damage
			luapro.level = level
			--Also store the projectile's damage itself.
			luapro.damage = def.damage
			--The player's name is stored to prevent hitting yourself
			--And by "hitting yourself" I mean accidentally being hit by the arrow just by firing it at a somewhat low angle, the moment it spawns.
			luapro.owner = pname

			--If the player isn't in creative mode, some weapon durability and ammo is consumed.
			if not minetest.is_creative_enabled(pname) then
				ammo:take_item(1)
				inv:set_stack("main", i, ammo)

				wep:add_wear(65536 / (def.durability or 100))
			end

			--Once the ammo is found, the search is stopped.
			break
		end
	end

	return wep
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
				--Get the projectile weapon. get_wielded_item() can't be used, since the weapon is no longer held.
				local wep = player:get_inventory():get_stack("main", projectile.charge_levels[pname].slot)

				--Replace the weapon with the uncharged version
				wep:set_name(wep:get_definition().no_charge_name)
				player:get_inventory():set_stack("main", projectile.charge_levels[pname].slot, wep)

				--Delete the stored charge data for this player
				projectile.charge_levels[pname] = nil

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



--This function registers a weapon able to shoot projectiles
function projectile.register_weapon(name, def)
	--either create a groups table for the definition, or use the provided one
	def.groups = def.groups or {}
	--Every projectile weapon belongs to the projectile_weapon group.
	def.groups.projectile_weapon = 1

	--Charge time defaults to 1 second
	def.charge_time = def.charge_time or 1
	--The weapon's damage multiplier defaults to 1.
	def.damage = def.damage or 1
	--The weapon's speed multiplier defaults to 1.
	def.speed = def.speed or 1

	--If this weapons has to be charged...
	if def.charge then
		--Define a function to reset the weapon's sprite and delete the player's charge data.
		local uncharge = function(wep, user)
			projectile.charge_levels[user:get_player_name()] = nil

			wep:set_name(name)

			return wep
		end

		--A function that begins a new charge, or fires a shot if the player is charging.
		local charge = function(wep, user)
			local pname = user:get_player_name()

			--If there is no charge data yet...
			if not projectile.charge_levels[pname] then
				local inv = user:get_inventory()

				--Look for ammo in the player's inventory, starting from the first slot.
				for i = 1, inv:get_size("main") do
					--Get the itemstack of the current slot.
					local ammo = inv:get_stack("main", i)

					--If the stack is there, and it's registered as ammo that this weapon can use...
					if not ammo:is_empty() and projectile.registered_projectiles[def.rw_category][ammo:get_name()] then
						--Create new charge data. Store the inventory slot of the weapon, and start the charge at 0
						projectile.charge_levels[pname] = {slot = user:get_wield_index(), charge = 0}

						--As feedback for the charge beginning, change the weapon's sprite to show it loaded.
						--I originally wanted the item to be shown loaded with specific ammo, but it doesn't seem to be possible.
						wep = ItemStack({name = name.."_2", wear = wep:get_wear()})

						--Once ammo is found, the search can be stopped.
						break
					end
				end

				--If no ammo was found, a charge won't start at all. No dry-firing allowed.

			--Otherwise, if there is charge data...
			else
				--Shoot out the projectile
				projectile.shoot(wep, user, projectile.charge_levels[pname].charge)
				--Then, end the charge
				wep = uncharge(wep, user)
			end

			return wep
		end

		--Right-click to start a charge. Right-click again to fire.
		def.on_place = charge
		def.on_secondary_use = charge
		--Left-click to cancel a charge without firing.
		def.on_use = uncharge

		--Start the creating of the partially and fully charged versions of this item, first by copying the definition.
		local def2 = table.copy(def)
		local def3 = table.copy(def)

		--The partially and fully-charged versions have specific inventory images
		def2.inventory_image = def.inventory_image_2
		def3.inventory_image = def.inventory_image_3
		--The projectile_weapon group rating increases with charge level
		def2.groups.projectile_weapon = 2
		def3.groups.projectile_weapon = 3
		--Partially charged weapons cannot be grabbed from the creative inventory.
		def2.groups.not_in_creative_inventory = 1
		def3.groups.not_in_creative_inventory = 1

		--Some versions store the names of different versions, for convenience.
		--The partially-charged version stores the name of the fully charged version, to be used when transitioning to the fully charged version.
		def2.full_charge_name = name.."_3"
		--Full and partial charge versions can both be cancelled, so they remember the name of the uncharged version
		def2.no_charge_name = name
		def3.no_charge_name = name

		--Finally, register the partially and fully charged projectile weapons.
		minetest.register_tool(name.."_2", def2)
		minetest.register_tool(name.."_3", def3)

	--Otherwise, right-click simply shoots the projectile.
	else
		def.on_place = projectile.shoot
		def.on_secondary_use = projectile.shoot
	end

	--Finally, register the projectile weapon here.
	--This is the only thing that happens regardless of if the weapon has to charge or not.
	minetest.register_tool(name, def)
end

--The basic slingshot. Slingshots are weaker than bows, but the ammunition they use is way easier to find and create.
projectile.register_weapon("projectile:slingshot",  {
	description = "Slingshot",
	inventory_image = "projectile_slingshot.png",
	inventory_image_2 = "projectile_slingshot_charged.png",
	inventory_image_3 = "projectile_slingshot_charged_full.png",
	durability = 75,
	rw_category = "slingshot",
	charge = true
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
	charge_time = 2.1,
	damage = 1.5,
	speed = 1.9
})



--Register a projectile that can be fired by a weapon.
--Note that it also has to define what kind of weapon can fire it, and the item version of itself.
function projectile.register_projectile(name, usable_by, ammo, def)
	--First, check that a table exists for that particular weapon category. If not, make it.
	projectile.registered_projectiles[usable_by] = projectile.registered_projectiles[usable_by] or {}
	--Then, add this projectile to said table.
	projectile.registered_projectiles[usable_by][ammo] = name

	--Default initial properties for the projectile
	--Including the table itself, if it wasn't already created.
	def.initial_properties = def.initial_properties or {}
	--The projectile is always physical. It has to hit stuff, after all.
	def.initial_properties.physical = true
	--The projectile also definitely has to be able to hit other entities.
	def.initial_properties.collide_with_objects = true
	--By default, the projectile's hitbox is half a block in size.
	def.initial_properties.collisionbox = def.initial_properties.collisionbox or  {-.25, 0, -.25, .25, .5, .25}
	--The projectile can't be hit by players.
	def.initial_properties.pointable = false
	--By default, the projectile is a flat image, provided by the "image" field.
	def.initial_properties.visual = def.initial_properties.visual or "sprite"
	def.initial_properties.textures = def.initial_properties.textures or {def.image}
	--By default, the projectile's visual size is also half size.
	def.initial_properties.visual_size = def.initial_properties.visual_size or {x = 0.5, y = 0.5, z = 0.5}
	--The projectile should always have some kind of visual.
	def.initial_properties.is_visible = true
	--The projectile won't be saved if it becomes unloaded.
	def.initial_properties.static_save = false

	--During each of this entity's steps...
	def.on_step = function(self, dtime, info)
		--Let projectiles define their own on_step if they need to
		if self._on_step then
			self._on_step(self, dtime, info)
		end

		--A little shorthand
		local selfo = self.object
		--By default, assume nothing was hit this step.
		local hit = false

		--For each collision that was found...
		for k, c in pairs(info.collisions) do
			--If it's a node, don't do anything more than acknowledging that something was hit.
			if c.type == "node" and minetest.get_node(c.node_pos).name ~= "default:glass" then
				hit = true

			--If it's an object...
			else
				--As long as that object isn't the player who fired this projectile...
				if not (c.object:is_player() and self.owner == c.object:get_player_name()) then
					hit = true
					c.object:punch(selfo, 1, {full_punch_interval = 1, damage_groups = {fleshy = def.damage * self.level * self.damage}}, vector.normalize(selfo:get_velocity()))
				end
			end
		end

		--If this projectile hit something...
		if hit then
			--Grant the entity an on_impact function that it can define
			if self.on_impact then
				self:on_impact(info.collisions)
			end

			--Make the projectile destroy itself.
			selfo:remove()
		end
	end

	--Finally, register the entity.
	minetest.register_entity(name, def)
end

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

--A helper functions for arrows in general, as they rotate themselves according to how they move.
local function arrow_on_step(self)
	--Shorthand for velocity
	local v = self.object:get_velocity()
	--Set calculate rotation according to velocity
	local rot = vector.dir_to_rotation(v)

	--Define a timer for itself. Based on how fast its currently moving, and how far the timer has progressed,
	--this makes it seem to spin through the air, with the tip still always pointing forward.
	self.timer = (self.timer or 0) + (v.x + v.y + v.z) / 30
	rot.z = rot.z + self.timer

	--Apply the calculated rotation.
	self.object:set_rotation(rot)
end

--The basic arrow, which has twice the power of a rock.
projectile.register_projectile("projectile:arrow", "bow", "projectile:arrow", {
	damage = 10,
	speed = 30,

	initial_properties = {
		visual = "mesh",
		mesh = "projectile_arrow.obj",
		textures = {"projectile_arrow_texture.png"}
	},

	_on_step = arrow_on_step
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

		_on_step = arrow_on_step,

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

	_on_step = arrow_on_step
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

		_on_step = arrow_on_step,

		--Upon impact, create a small explosion.
		on_impact = function(self, collisions)
			tnt.boom(self.object:get_pos(), {radius = 2, damage_radius = 2})
		end
	})
end
