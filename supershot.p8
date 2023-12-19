pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- supershot
-- by thedevnate

-- initialize vars
plr = {
	x=0,
	y=100,
	w=8,
	h=4,
	hp=100,
	dead=false,
	yvel=0,
	shotdelay=0,
	x2=0,
	y2=0
}
menu = true
menusel = 0
renderhud = false
delta = {0,0}
ms = {0,0}
lastpos = {0,0}
betatext = nil
c = nil
debug = false
deathreason = "press enter to start"

function retry()
	game.score = 0
	plr.hp = 100
	plr.x = util.center(plr.w)
	plr.y = 100
	plr.dead = false
	for i,v in pairs(game.stars) do
		deli(game.stars,i)
	end
	for i,v in pairs(game.objects) do
		deli(game.objects,i)
	end
	for i=1,25 do
		add(game.stars,{
			x=util.rx(),
			y=util.rng(127,false),
			a=util.rng(5,false),
			c=7--util.rng(15,false)
		})
	end
end

function _init()
	-- init cartdata
	cartdata("supershotv2")
	-- check for loadable data
	if (dget(3) == 1) then
		game.score = dget(4)
		plr.x = dget(5)
		plr.y = dget(6)
		plr.hp = dget(7)
		dset(3,0)
	end
	-- cursor
	--c = game.spawnobject(4)
	-- betatext
	local txtt = "3.0.0"
	betatext = game.spawnobject(-2,printw(txtt),5)
	betatext.txt = txtt
	betatext.x = 64-printw(txtt)/2
	betatext.y = 10
	-- center player
	plr.x = util.center(plr.w)
	-- add stars
	for i=1,25 do
		add(game.stars,{
			x=util.rx(),
			y=util.rng(127,false),
			a=util.rng(5,false),
			c=7--util.rng(15,false)
		})
	end
	-- enable devkit cursor
	poke(0x5f2d,1)
	-- suppress pause menu
	poke(0x5f30,1)
	-- add menu items
	menuitem(2, "save & quit",
  function()
  	if (plr.dead) then return end
  	dset(3, 1)
  	dset(4, game.score)
  	dset(5, plr.x)
  	dset(6, plr.y)
  	dset(7, plr.hp)
  	cls(0)
  	stop("saved.")
  end
	)
	menuitem(1, "retry",
  function()
  	if (not plr.dead) then return end
  	retry()
  end
	)
end
function _draw()
	-- clear screen
	cls(0)
	
	-- draw betatext
	game.rendersprite(betatext)
	
	-- draw objects
	if not menu then
		for k,v in pairs(game.objects) do
		game.rendersprite(v)
		if debug then
			rect(v.x,v.y,v.x2,v.y2,9)
		end
	end
	end
	-- draw stars
	for k,v in pairs(game.stars) do
		pset(v.x,v.y,v.c)
	end
	-- draw player
	if not menu then
		spr(3,plr.x,plr.y)
		if debug then
			rect(plr.x-1,plr.y-1,plr.x+plr.w,plr.y+plr.h,9)
			?"p1",plr.x+2,plr.y-7
		end
	end
	-- draw hud
	if renderhud then
		spr(5,1,120)
		color(7)
		?plr.hp,10,122
		spr(6,1,113)
		?game.score,10,115
	end
	if (plr.dead) then
		rectfill(0,0,128,6,1)
		rectfill(0,7,128,19,5)
		color(7)
		?deathreason,1,1
		?"high score: "..(dget(1) or 0),1,8
		?"score: "..game.score,1,14
	end
	-- menu renderer
	if menu then
		spr(9,32,60)
		spr(10,50,60)
		spr(10,70,60)
		spr(7,92,61)
		rectfill(42,23,83,31,1)
		rectfill(28,98,97,106)
		color(7)
		util.printc("supershot!",64,25)
		util.printc("press ❎ to play!",64,100)
	end
end
function _update60()
	if not betatext then
		return
	end
	if (peek(0x812d) == 0x1) then
		debug = true
	else
		debug = false
	end
	if menu then
		if btn(5) then
			menu = false
			renderhud=true
			betatext.x=-128
			retry()
		end
		goto mskip
	end
	-- play
	if plr.dead and btn(6) then
		retry()
		renderhud = true
	else
		-- suppress pause menu
		poke(0x5f30,1)
	end
	-- stop running game when dead
	if (plr.dead) then
		plr.x = -128
		renderhud = false
	end
	plr.x2 = plr.x+plr.w
	plr.y2 = plr.y+plr.h
	-- objects
	for k,v in pairs(game.objects) do
		-- check if off-screen
		if (v.y > 127) then
			deli(game.objects,k)
		end
		if (v.y<0) then
			deli(game.objects,k)
		end
		v.x1 = v.x
		v.x2 = v.x+v.w
		v.y1 = v.y
		v.y2 = v.y+v.h
		-- collision
		local collided = game.squarecollision(v,plr)
			if (collided and v.sint == 2) then
				deli(game.objects,k)
				game.pwrup()
			elseif (collided and v.sint == 7) then
				deli(game.objects,k)
				game.enemyhit()
			end
		for i,a in pairs(game.objects) do
			if (a.sint == 8 and v.sint == 7) then
				if game.squarecollision(a,v) then
					deli(game.objects,i)
					deli(game.objects,k)
					sfx(5)
					game.score += 1
					return
				end
			end
		end
		-- scroll
		if (v.sint ~= 8) then
			v.y += v.a
		else
			v.y -= 2
		end
	end
	::mskip::
	-- stars
	for k,v in pairs(game.stars) do
		-- check if off-screen
		if (v.y > 127) then
			-- reset
			v.y = -10
			v.a = util.rng(5,false)
			v.c = 7--util.rng(15,false)
		end
		v.y += v.a
	end
	if menu then
		goto mskip2
	end
	-- move player
	if (btn(0)) then plr.x-=1 end
	if (btn(1)) then plr.x+=1 end
	plr.x = mid(0,plr.x,120)
	-- randomspawn
	game.randomspawn()
	-- velocity
	if (plr.yvel > 0) then
		plr.yvel-=1
		plr.y-=1
	end
	-- slowly move down
	if not debug then
		plr.y+=0.05
	end
	-- death checks
	if (plr.y > 128 and not plr.dead) then
		sfx(2)
		plr.dead = true
		deathreason="fell too far behind!"
		if game.score > dget(1) then
			dset(1,game.score)
		end
	end
	if (plr.hp < 1) then
		sfx(2)
		plr.dead = true
		if game.score > dget(1) then
			dset(1,game.score)
		end
	end
	-- shoot lasers
	if (plr.shotdelay > 0) then plr.shotdelay-=1 end
	if (plr.shotdelay == 0 and btn(5) and not plr.dead) then
		add(game.objects,game.spawnobject(8))
		plr.shotdelay = 15
		sfx(3)
	end
	
	if debug then
		plr.hp = 100
	end
	::mskip2::
	plr.hp = mid(0,plr.hp,100)
end
-->8
-- game functions

game = {
	score = 0,
	stars = {},
	objects = {}
}
util = {}
enum = {
	object = {
		powerup = 2,
		enemy = 7
	}
}

-- section 1

function util.center(width)
	return (128/2)-(width/2)
end

-- centered printing

-- width of a printed string
function printw(s)
  if #s == 0 then 
    return 0
  end

  w = 0
  for i = 1, #s do
    if sub(s,i,i) >= "\x80" then
      w += 7
    else 
      w += 3
    end
  end

  return w + #s - 1
end

-- print centered
function util.printc(s, x, y)
  print(s, x - printw(s)/2, y)
end

function util.rng(m,d)
	if (d) then
		return rnd(m)
	else
		return ceil(rnd(m))
	end
end

function util.rx()
	return ceil(rnd(124))
end

function util.rxc(width)
	local mi = width/2
	local ma = 127-width/2
	
	return mid(mi,ceil(rnd(127)),ma)
end

function util.copytable(tbl)
	local tb = {}
	for k,v in pairs(tbl) do
		tb[k]=v
	end
	return tb
end

-- section 2

function game.rendersprite(obj)
	if obj.sint == -2 then
		print(obj.txt,obj.x,obj.y)
	else
		spr(obj.sint,obj.x,obj.y)
	end
end

function game.collisionchk(obj1,obj2,dist)
	local dx=obj1.x-obj2.x
	local dy=obj1.y-obj2.y
	local d = abs(dx)+abs(dy)
	if (d <= dist) then
		return true
	else
		return false
	end
end

function game.squarecollision(obj1,obj2)
	local hit = false
	if max(obj1.x,obj1.x2) >= min(obj2.x, obj2.x2) and
				min(obj1.x,obj1.x2) <= max(obj2.x, obj2.x2) then
		if max(obj1.y,obj1.y2) >= min(obj2.y, obj2.y2) and
					min(obj1.y,obj1.y2) <= max(obj2.y, obj2.y2) then
			hit=true
		end
	end
	return hit
end

function game.pwrup()
	game.score += 1
	plr.yvel += 15
	plr.hp += util.rng(15,false)
	if (game.score % 10 == 0) then
		sfx(1)
	else
		sfx(0)
	end
end

function game.enemyhit()
		sfx(5)
		plr.hp-=util.rng(30,false)
		deathreason="an enemy killed you!"
end

function game.spawnobject(t,w,h)
	-- create the object
	local obj = {
		x=util.rx(),
		y=0,
		w=w,
		h=h,
		sint=t,
		a=util.rng(3,false),
	}
	local sizes = {
		[2]={x=3,y=4},
		[7]={x=3,y=5},
		[8]={x=2,y=8},
		[4]={x=6,y=7}
	}
	if (t == 8) then
		obj.x = plr.x+3
		obj.y = plr.y-12
	end
	if not w and not h then
		obj.w=sizes[t].x
		obj.h=sizes[t].y
	end
	obj.x1 = obj.x
	obj.x2 = obj.x+obj.w
	obj.y1 = obj.y
	obj.y2 = obj.y+obj.h
	-- return the object
	return obj
end

function game.randomspawn()
	if (util.rng(100,false) == util.rng(100, false)) then
		add(game.objects,game.spawnobject(enum.object.powerup))
	end
	if (util.rng(100,false) == util.rng(100, false)) then
		add(game.objects,game.spawnobject(enum.object.enemy))
	end
end
-->8
-- docs

-- cartdata
-- 1: high score (needs work)
-- 2: unused
-- 3: resumable
-- 4: saved score
-- 5: saved position x
-- 6: saved position y
-- 7: saved hp
__gfx__
00000000000000000aa00000000bb0000100000000000000000000006006000088000000bb000000000000000000000000000000000000000000000000000000
0000000000000000aaaa000000bbbb001710000000000000000000007667000088000000bbb00000000000000000000000000000000000000000000000000000
0070070000000000aaaa00000bbbbbb0177100000000b0000000000066660000880000000bbb0000000000000000000000000000000000000000000000000000
00077000008888000aa00000bbb00bbb177710000000b00000099900866800008800000000bbb000888888880000000000000000000000000000000000000000
000770000088880000000000bb0000bb1777710000bbbbb000099900688600008800000000bbb000888888880000000000000000000000000000000000000000
00700700000000000000000000000000177110000000b0000009990000000000880000000bbb0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000011710000000b000000000000000000088000000bbb00000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000088000000bb000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000
00000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000000700000000000000000
00000000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000700000000000000000000000000
00000000000000000000000000000000000000000000007000000000000000088000000000000000000070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000700000000000000000000088000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000007000007000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000aa000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa00000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000bb000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000bbbb00000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000bbbbbb0000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000bbb00bbb000000000000000000000000000000000000000000000000000000000000
000000000000000000000000007000000000000000000000000000000000bb0000bb000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009990000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009990000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009990000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000b00007700777077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000b00000700707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bbbbb000700707070700000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000
00000b00000700707070707000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000
00000b00007770777077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
000100000b3500c3500c3500c3500c3500c3500c3500b3500b35002350013500235005350083500b3500e35013350183501b3501d3501e3501f3501f3501f3501e3501f350203502035020350203502035020350
000100000a3500a350093500935009350093500a3500b3500b3502235021350203502035020350203502035021350213502135021350213502235000000000000000000000000000000000000000000000000000
0001000027050270502705027050270502705027050270502505025050250502205022050220502005020050200501e0501e0501e0501b0501b0501b050190501905019050120501205012050000000000000000
0001000000250082500325002250032500525008250102501625020250072500625006250072500b2501a25025250002500025000250002500025000000000000000000000000000000000000000000000000000
00010000000000b3500c3500c3500c3500c3500d3500c3500c3500c3500c3500c350203501f350203502035020350203502035020350203502135021350213500000000000000000000000000000000000000000
000100001465014050136501365013650136501365014050006500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000