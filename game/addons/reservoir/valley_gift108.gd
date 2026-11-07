extends RefCounted
const Gifts = preload("res://addons/reservoir/mail_gifts.gd")
const ID = Gifts.DATA["1.08"]["id"]
const GOLD_AMOUNT = Gifts.DATA["1.08"]["gold"]
static func claim(m) -> bool:
	return Gifts.claim(m,"1.08")
