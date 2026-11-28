extends RefCounted
# Preserve every source character; prefer Korean spacing over character breaks.
static func wrap(m, value: String, size: int, width: float) -> Array[String]:
	var result: Array[String] = []
	for paragraph in value.split("\n"):
		var first_line := result.size()
		var rest: String = paragraph
		if rest.is_empty():
			result.append("")
		while not rest.is_empty():
			var fit := 0
			for i in rest.length():
				if m._text_w(rest.left(i+1),size)>width: break
				fit=i+1
			fit=maxi(1,fit)
			var cut := fit
			if fit<rest.length():
				# A space belongs to the preceding line, preserving the original text.
				var boundary := rest.left(fit).rfind(" ")
				if boundary>0: cut=boundary+1
				# Closing punctuation stays with the preceding syllable.
				if rest.substr(cut,1) in ["!", "?", ".", ",", ")", "]", "。", "…"] and cut>1:
					cut-=1
			result.append(rest.left(cut))
			rest=rest.substr(cut)
		# 두 줄이 된 문단은 띄어쓰기 자리 중 두 줄 폭이 가장 비슷한 곳에서 다시 나눈다(마지막 단어 하나만 떨어지지 않게)
		if result.size()-first_line==2:
			var best_cut:=-1
			var best:=INF
			for i in paragraph.length():
				if paragraph[i]!=" ": continue
				var tail:String=paragraph.substr(i+1)
				if tail.strip_edges().is_empty() or tail.substr(0,1) in ["→", "·", "-", "~"]: continue   # 화살표·이음표로 줄을 시작하지 않는다
				var wa:float=m._text_w(paragraph.left(i+1).strip_edges(),size)
				var wb:float=m._text_w(tail,size)
				if wa<=width and wb<=width and maxf(wa,wb)<best: best=maxf(wa,wb);best_cut=i+1
			if best_cut>0:
				result[first_line]=paragraph.left(best_cut)
				result[first_line+1]=paragraph.substr(best_cut)
		# Move the preceding word onto a short final line when it fits.
		elif result.size()-first_line>=3 and result.back().strip_edges().length()<=2:
			var previous: String=result[result.size()-2]
			var boundary := previous.left(previous.strip_edges().length()).rfind(" ")
			if boundary>0:
				var joined: String=previous.substr(boundary+1)+result.back()
				if m._text_w(joined,size)<=width:
					result[result.size()-2]=previous.left(boundary+1)
					result[result.size()-1]=joined
	return result
