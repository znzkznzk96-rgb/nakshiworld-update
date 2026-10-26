extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.TUT.done=true;m.active_region=0;m.forge_lv=0
 var file=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE);file.store_line("parts,stock,species,price,bite_seconds")
 for parts in range(4):
  m.equipment.active_parts=["float","hook","line"].slice(0,parts)
  for stock in [0.7,1.0]:
   m.pond_stock=m.pond_max()*stock;m.region_shop.selected_bait=0;m.bait=100000
   seed(83000+parts*10+int(stock*10))
   for sample in 20000:
    m.start_wait()
    file.store_line("%d,%.1f,%d,%d,%.6f"%[parts,stock,int(m.S.sp),m.fish_price(int(m.S.sp),int(m.S.star),int(m.S.grade),float(m.S.lf)),float(m.S.biteAt)-m.clock])
 file.close();m.audio_feedback.dispose();m.queue_free();await process_frame;print("POUCH_FISH_SAMPLE draws=160000");quit()
