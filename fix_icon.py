import struct, zlib, sys

path = sys.argv[1]
with open(path, 'rb') as f:
    data = f.read()

sig = data[:8]
pos = 8
chunks = []
while pos < len(data):
    length = struct.unpack('>I', data[pos:pos+4])[0]
    ctype = data[pos+4:pos+8]
    cdata = data[pos+8:pos+8+length]
    pos += 12 + length
    chunks.append((ctype, cdata))

ihdr = chunks[0][1]
w, h, bd, ct = struct.unpack('>IIBB', ihdr[:10])
print(f'PNG: {w}x{h} color_type={ct}')

if ct != 6:
    print('No alpha, skipping')
    sys.exit(0)

idat = zlib.decompress(b''.join(c for t, c in chunks if t == b'IDAT'))
new_rows = []
for y in range(h):
    row = idat[y*(w*4+1):(y+1)*(w*4+1)]
    rgb = b''.join(row[1+i*4:1+i*4+3] for i in range(w))
    new_rows.append(row[0:1] + rgb)
new_idat = zlib.compress(b''.join(new_rows), 9)

def make_chunk(t, d):
    crc = zlib.crc32(t + d) & 0xffffffff
    return struct.pack('>I', len(d)) + t + d + struct.pack('>I', crc)

new_ihdr = struct.pack('>IIBB', w, h, bd, 2) + ihdr[10:]
out = sig + make_chunk(b'IHDR', new_ihdr) + make_chunk(b'IDAT', new_idat) + make_chunk(b'IEND', b'')
with open(path, 'wb') as f:
    f.write(out)
print('Alpha removed successfully')
