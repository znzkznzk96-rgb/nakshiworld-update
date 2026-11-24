import sys
sys.argv=['x']
exec(open('gen5.py').read().split("if __name__")[0])
E={"image_size":{"width":64,"height":64},"outline":"lineless","detail":"medium detail"}
O='slot/fx/'
gen5("bright golden starburst explosion, eight pointed star with a white hot center and yellow orange rays, flat pixel art, nothing else",20261201,O+'seed_burst',E)
gen5("bright rainbow starburst explosion, eight pointed star with a white hot center and pink cyan yellow rays, flat pixel art, nothing else",20261202,O+'seed_rainbow',E)
gen5("one shiny blue diamond gem, faceted, with a white sparkle, flat pixel art, nothing else",20261203,O+'seed_gem',{**E,"image_size":{"width":32,"height":32},"outline":"single color black outline"})
gen5("one shiny gold coin seen from front with a star in the middle, flat pixel art, nothing else",20261204,O+'seed_coin',{**E,"image_size":{"width":32,"height":32},"outline":"single color black outline"})
