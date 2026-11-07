extends RefCounted
const Gifts = preload("res://addons/reservoir/mail_gifts.gd")
const ID = Gifts.DATA["0.93"]["id"]
static func claim(m) -> bool:
	return Gifts.claim(m,"0.93")
