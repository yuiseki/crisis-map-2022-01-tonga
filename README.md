# crisis-map-2022-01-tonga

## Setup requirements

### Setup `tilemaker` docker image

```bash
git clone https://github.com/systemed/tilemaker
cd tilemaker
docker build . -t tilemaker
```

### Setup `tippecanoe` docker image

```bash
git clone https://github.com/mapbox/tippecanoe
cd tippecanoe
docker build . -t tippecanoe
```

## Build

```bash
make
```

It will produce

- docs/tiles.json
- docs/zxy/\*

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
