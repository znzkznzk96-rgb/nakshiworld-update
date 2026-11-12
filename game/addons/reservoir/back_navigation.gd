extends RefCounted
# Match actual overlay drawing order; dismissal never executes a transaction.
static func dismiss_keyboard(m)->bool:
 var focus:Control=m.get_viewport().gui_get_focus_owner()
 if focus==null:focus=m.get_tree().root.gui_get_focus_owner()
 var virtual:bool=DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD)
 if focus is LineEdit or focus is TextEdit or (virtual and DisplayServer.virtual_keyboard_get_height()>0):
  if virtual:DisplayServer.virtual_keyboard_hide()
  if focus!=null:focus.release_focus()
  return true
 return false
static func handle(m)->bool:
 if dismiss_keyboard(m):return true
 if m.resetting or not m.trans.is_empty() or (m.cooperative_boot and not m.boot_ready):return true
 var handled:bool=close_top(m)
 if handled:
  m.holding=false;m.slider_drag=false;m.inventory.cancel_pointer();m.personal_dex.cancel_pointer()
  m.queue_redraw();m.play("ui",-5.0)
 return handled
static func close_top(m)->bool:
 if m.capture_robot.opened:
  m.capture_robot.opened=false;m.capture_robot.pointer=-1;m.capture_robot.dragging=false;return true
 var e=m.expedition
 if e.opened!="":
  e.formation_pointer=false;e.roster_pointer=false;e.drag_slot=-1
  if e.formation_uid>=0:e.formation_uid=-1
  elif e.opened=="management" and e.management.confirm:e.management.confirm=false
  elif e.choosing_slot>=0:e.choosing_slot=-1
  elif e.opened in ["management","training","merge_confirm"]:
   var merge:bool=e.opened=="merge_confirm"
   e.opened="alchemy";e.tab=1 if merge else 2
  else:e.effect_kind="";e.opened=""
  return true
 if m.personal_dex.opened:
  if m.personal_dex.photo.opened:m.personal_dex.photo.close()
  elif m.personal_dex.selected>=0:m.personal_dex.selected=-1
  else:m.personal_dex.opened=false
  return true
 if not m.equipment.pending_sale.is_empty():m.equipment.pending_sale="";return true
 if m.guide.opened:
  if m.guide.screen=="article":m.guide.change_screen("topics")
  elif m.guide.screen=="topics":m.guide.change_screen("home")
  else:m.guide.opened=false
  return true
 if m.mailbox.opened:
  if m.mailbox.detail!="":m.mailbox.detail="";m.mailbox.topic=0;m.mailbox.detail_page=0;m.mailbox.full_text=false
  elif m.mailbox.deleting:m.mailbox.deleting=false;m.mailbox.checked.clear()
  else:m.mailbox.opened=false
  return true
 if not m.V.commerce.pending.is_empty():m.V.commerce.pending={};return true
 if m.inventory.pouch.opened:
  m.inventory.pouch.opened=false;m.inventory.pouch.result=[];m.inventory.pouch.rects={};return true
 if m.inventory.selected>=0:m.inventory.selected=-1;m.inventory.selected_grade=-1;return true
 if m.settings_open:
  if m.reset_confirm:m.reset_confirm=false
  elif m.lesson_open and m.lesson_after=="book":m.close_card(true)
  elif m.set_view!="main":m.set_view="main"
  else:m.settings_open=false;m._save_set()
  return true
 if m.market_open:m.market_open=false;m.inventory.displayed=false;return true
 var v=m.V
 if v.shop!="":
  if v.enhancement.busy():return true
  if v.shop=="museum":
   var b=v.bundle_preview
   if b.reward_open:b.reward_open=false;b.just_claimed=false;b.dialog_notice="";return true
   if b.bulk_open:b.bulk_open=false;b.bulk_plan=[];return true
   if b.selected>=0:b.selected=-1;return true
  if v.pick_slot>=0:v.pick_slot=-1
  elif v.shop=="aqua" and v.aqua_manage:v.aqua_manage=false
  else:v.shop=""
  v.aquarium.reset();return true
 if m.bait_picker.opened:m.bait_picker.opened=false;return true
 if m.lesson_open:
  if m.S.get("tut",false):return true
  m.close_card(true);return true
 if m.menu_open:m.menu_open=false;return true
 if m.scene=="spots":m.start_trans("village");return true
 return false
