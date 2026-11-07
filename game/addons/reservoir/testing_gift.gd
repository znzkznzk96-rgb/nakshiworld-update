extends RefCounted
const Gifts = preload("res://addons/reservoir/mail_gifts.gd")
const ID = Gifts.DATA["0.78"]["id"]
static func claim(m) -> bool:
	return Gifts.claim(m,"0.78")
