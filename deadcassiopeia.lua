if myHero.charName ~= "Cassiopeia" then
return
end

require 'VPrediction'

local version = 1.3
local AUTOUPDATE = true
local SCRIPT_NAME = "deadcassiopeia"
local HWID
local ID
local id
local Edelay, Wdelay, orbwalk, check = true, true, true, true
local VP = nil
local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

if FileExist(SOURCELIB_PATH) then
    require("SourceLib")
else
    DONLOADING_SOURCELIB = true
    DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() print("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...") return end

local RequireI = Require("SourceLib")
RequireI:Check()

if AUTOUPDATE then
     SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/dd2repo/BoL/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/dd2repo/BoL/master/"..SCRIPT_NAME..".version"):CheckUpdate()
end

function OnLoad()
ts = TargetSelector(TARGET_LESS_CAST_PRIORITY,950)
VP = VPrediction()
m = scriptConfig("Deadseries - Cassiopeia", "deadcassiopeia")
Ignite = (myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") and SUMMONER_2) or nil
m:addSubMenu("Combo Settings", "combosettings")
m.combosettings:addParam("useq", "Use Q", SCRIPT_PARAM_ONOFF, true)
m.combosettings:addParam("usew", "Use W", SCRIPT_PARAM_ONOFF, true)
m.combosettings:addParam("usee", "Use E", SCRIPT_PARAM_ONOFF, true)
m.combosettings:addParam("useonly", "Use delayed W", SCRIPT_PARAM_ONOFF, true)
m:addSubMenu("Harass Settings", "harasssettings")
m.harasssettings:addParam("usehq", "Use Q", SCRIPT_PARAM_ONOFF, true)
m.harasssettings:addParam("usehw", "Use W", SCRIPT_PARAM_ONOFF, true)
m.harasssettings:addParam("mana", "Stop Harass if Mana under -> %", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
m:addSubMenu("Legit Settings", "legit")
m.legit:addParam("lmode", "Legit Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("N"))
m.legit:addParam("orbing", "Orbwalking", SCRIPT_PARAM_ONOFF, true)
m.legit:addParam("stutter", "Stutterstep after every E", SCRIPT_PARAM_ONOFF, false)
m.legit:addParam("edelaym", "Delay between E's", SCRIPT_PARAM_SLICE, 1, 0.5, 2, 2)
m:addSubMenu("Item Settings", "items")
m.items:addParam("enableautozhonya", "Auto Zhonya's", SCRIPT_PARAM_ONOFF, false)
m.items:addParam("autozhonya", "Zhonya's if Health under -> %", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
m:addSubMenu("Drawings", "draws")
m.draws:addParam("drawq", "Draw Q & W range", SCRIPT_PARAM_ONOFF, false)
m.draws:addParam("drawe", "Draw E range", SCRIPT_PARAM_ONOFF, false)
m.draws:addParam("drawr", "Draw R range", SCRIPT_PARAM_ONOFF, false)
m:addSubMenu("Kill Steal", "ks")
m.ks:addParam("ignite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
m.ks:addParam("kse", "KS with E", SCRIPT_PARAM_ONOFF, false)
m.ks:addParam("ksr", "KS with R", SCRIPT_PARAM_ONOFF, false)
m:addParam("combokey", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
m:addParam("harass", "Toogle Auto Harass", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("C"))
m:addTS(ts)
ts.name = "Legit"
PrintChat ("<font color='#4ECB65'>Deadseries - Cassiopeia loaded!</font>")
end

function OnTick()
checks()
Combo()
walk()
autokill()
Harass()
autozhonya()
end

function checks()
ts:update()
Qready = (myHero:CanUseSpell(_Q) == READY)
Wready = (myHero:CanUseSpell(_W) == READY)
Eready = (myHero:CanUseSpell(_E) == READY)
Rready = (myHero:CanUseSpell(_R) == READY)
target = ts.target
end
   
function PoisN(unit)
 return TargetHaveBuff('cassiopeianoxiousblastpoison', unit)
end

function PoisM(unit)
 return TargetHaveBuff('cassiopeiamiasmapoison', unit)
end

function CastPreQ(unit)
	local CastPosition, HitChance, Position = VP:GetCircularCastPosition(target, 0.5, 90, 925, 1800, myHero)
		if HitChance >= 2 then
  		CastSpell(_Q, CastPosition.x, CastPosition.z)
  	end
end

function CastPreW(unit)
	local CastPosition, HitChance, Position = VP:GetCircularAOECastPosition(target, 0.5, 90, 925, 2500, myHero)
	if HitChance >= 2 then
	  CastSpell(_W, CastPosition.x, CastPosition.z)
	end
end

function cassdmg(spell, object)
	if spell == "e" then
		local dmg = ((30+25*myHero:GetSpellData(_E).level)+myHero.ap*(0.35+myHero:GetSpellData(_E).level*0.05))*(100/(100+(object.magicArmor*myHero.magicPenPercent-myHero.magicPen)))
		return dmg
	elseif spell == "r" then
		local dmg = ((50+100*myHero:GetSpellData(_R).level)+myHero.ap*0.5)*(100/(100+(object.magicArmor*myHero.magicPenPercent-myHero.magicPen)))
		return dmg
	end
end

function autokill()
	for i, enemy in ipairs(GetEnemyHeroes()) do
	 if enemy and not enemy.dead then
	 		if Ignite ~= nil and m.ks.ignite and enemy.health < getDmg("IGNITE", enemy, myHero) and ValidTarget(enemy, 600) then CastSpell(Ignite, enemy)
	 		end
			local dist = GetDistance(enemy)
			local edmg = cassdmg("e", enemy)
			local rdmg = cassdmg("r", enemy)
			if m.ks.ksr and Rready and Eready and dist < 680 and enemy.health < (edmg+rdmg) then
				CastSpell(_E, enemy)
				CastSpell(_R, enemy.x, enemy.z)
			elseif m.ks.ksr and Rready and dist < 750 and enemy.health < rdmg then
				CastSpell(_R, enemy.x, enemy.z)
			elseif m.ks.kse and Eready and dist < 690 and enemy.health < edmg then
				CastSpell(_E, enemy)
			end
		end
	end
end

function Combo()
	if not target then return
	end   
	if m.combokey then
		if Qready and m.combosettings.useq and target then
			CastPreQ(target)
  		end
  		if m.combosettings.useonly and Wdelay and Wready and m.combosettings.usew and target then
 			Wdelay = false
  			DelayAction(function() Wdelay = true end, 1)
  			CastPreW(target)
  		elseif not m.combosettings.useonly and Wready and m.combosettings.usew and target then
  			CastPreW(target)
  		end
		if m.legit.lmode then
			if m.legit.stutter and Eready and target and GetDistance(target) < 690 and m.combosettings.usee and Edelay and (PoisM(target) or PoisN(target)) then
  				Edelay = false
					orbwalk = false
					if check then 
						check = false 
						DelayAction(function() check = true orbwalk = true end, 0.5) 
					end
  				DelayAction(function() Edelay = true end, m.legit.edelaym)
  				CastSpell(_E, target)
  			end
  			if not m.legit.stutter and Eready and target and GetDistance(target) < 690 and m.combosettings.usee and Edelay and (PoisM(target) or PoisN(target)) then
  				Edelay = false
  				DelayAction(function() Edelay = true end, m.legit.edelaym)
  				CastSpell(_E, target)
  			end
		elseif not m.legit.lmode and Eready and target and GetDistance(target) < 690 and m.combosettings.usee and (PoisM(target) or PoisN(target)) then
  				CastSpell(_E, target)	
  		end
  	end	
end

function autozhonya()
	if m.items.enableautozhonya then
		if myHero.health <= (myHero.maxHealth * m.items.autozhonya / 100) then CastItem(3157) 
		end
	end
end

function Harass()
	if not target then return
	end   
	if m.harass and (myHero.maxMana * m.harasssettings.mana / 100) <= myHero.mana then 
		if Qready and m.harasssettings.usehq and target then
			CastPreQ(target)
  		end
  		if Wready and m.harasssettings.usehw and target then
			CastPreW(target)
  		end
  	end
end

function walk()
	if m.combokey and m.legit.orbing and orbwalk then
		myHero:MoveTo(mousePos.x, mousePos.z)
	end
end

function OnDraw()
	if m.draws.drawq then
		DrawCircle(myHero.x, myHero.y, myHero.z, 925, ARGB(255, 255, 255, 255))
	end
	if m.draws.drawe then
		DrawCircle(myHero.x, myHero.y, myHero.z, 690, ARGB(255, 255, 255, 255))
	end
	if m.draws.drawr then
		DrawCircle(myHero.x, myHero.y, myHero.z, 850, ARGB(255, 255, 255, 255))
	end
end
