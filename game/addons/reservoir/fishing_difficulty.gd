extends RefCounted
# Approved final_Q study: 71,380 isolated fights. Reservoir uses legacy rules.
const REGION_RESISTANCE = [1.0,1.4,3.8]
const ROD_POWER = [1.0,1.65,2.9]
const STAR_RESISTANCE = [0.0,0.16,0.06]
static func rod_power(tier: int) -> float:
 var n:int=clampi(tier,0,5)
 if n<ROD_POWER.size():return ROD_POWER[n]
 # Preserve existing tier increments beyond the three calibrated rods.
 # Future-region 5.3/10/20 proposal values remain inactive until tested.
 return ROD_POWER[2]*(1.0+0.12*n)/(1.0+0.12*2)
static func configure(m) -> void:
 m.S.progress_loss_factor=1.0;m.S.progress_bonus_factor=1.0
 var area:int=int(m.active_region)
 if area not in [1,2] or m.S.get("tutFish",false):return
 var region:float=REGION_RESISTANCE[area]
 var species:float=pow(maxf(.5,float(m.FISH_LEN[m.S.sp])/float(m.FISH_LEN[area*20])),.04)
 var individual:float=pow(float(m.S.lf),.45)
 var rank:float=1.0+STAR_RESISTANCE[area]*int(m.S.star)+.04*int(m.S.grade)
 var resistance:float=region*species*individual*rank
 var power:float=rod_power(m.rod_lv)
 m.S.reelMul=power*(1.0+.06*m.forge_lv)/resistance
 m.S.tensionMul=pow(region,.32)/(pow(power,.9)*(1.0+.06*m.forge_lv))
 m.S.progress_loss_factor=pow(resistance,-.75)
 m.S.progress_bonus_factor=minf(1.5,m.S.reelMul)
static func warning_floor(m) -> void:
 if m.active_region==2 and not m.S.get("tutFish",false) and m.S.beh in ["tell","nose","rise","turn"]:
  m.S.bt=maxf(m.S.bt,.55);m.S.warningDuration=m.S.bt
static func base_reel_power(tier:int,area:int) -> float:
 return rod_power(tier) if area in [1,2] else 1.0+.12*tier
static func upgrade_labels(level:int,area:int) -> Array:
 if area in [1,2]:return ["+%d%%"%roundi(6.0*level),"-%d%%"%roundi(100.0*(1.0-1.0/(1.0+.06*level))),"+%d%%"%(level*5)]
 return ["+%d%%"%(level*3),"-%d%%"%(level*2),"+%d%%"%(level*5)]
