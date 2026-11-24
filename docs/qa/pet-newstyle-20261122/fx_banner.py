import sys
sys.argv=['x']
exec(open('gen5.py').read().split("if __name__")[0])
E={"image_size":{"width":192,"height":64},"outline":"single color black outline","detail":"medium detail"}
O='slot/fx/'
gen5("an empty golden ribbon banner with red center and gold trim, curled ends, plain blank center without any text, flat pixel art, nothing else",20261220,O+'banner_a',E)
gen5("an empty ornate gold and red ribbon banner with a small crown on top, blank center without any text, flat pixel art, nothing else",20261221,O+'banner_b',E)
