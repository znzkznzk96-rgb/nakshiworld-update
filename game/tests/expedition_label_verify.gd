extends SceneTree
func _initialize() -> void:
 var v=load("res://addons/expedition/view.gd").new()
 var failures=[]
 for r in range(1,11):
  for encounter in 3:
   v.data.battle={"round":r,"index":encounter}
   if v.strip_label()!="1-%d · %d/3전투"%[r,encounter+1]: failures.append([r,encounter])
 v.data.battle={"round":2,"index":2}
 if v.strip_label()!="1-2 · 3/3전투": failures.append("reported mismatch")
 v.data.battle={}
 if v.strip_label()!="탐험대를 편성해 보세요":failures.append("idle")
 print("EXPEDITION_LABEL_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
