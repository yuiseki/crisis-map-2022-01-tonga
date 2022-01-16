# crisis-map-2022-01-tonga

## Build

```bash
make
```

It will produce

- docs/region.mbtiles
- docs/zxy/\*

NOTE: zxy style vector tile is under development.

## Rebuild

```bash
make clean
make
```

## Preview map

```bash
npm i -g tileserver-gl-light
make start
```

Open http://localhost:3000/
