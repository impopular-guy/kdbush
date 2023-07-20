# kdbush

A static spacial index for 2D points in V. This is a V port of [kdbush Go](https://github.com/MadAppGang/kdbush).

## Install
```
v install impopular-guy.kdbush
```

## Usage

```v
import impopular_guy.kdbush
```

### interface Point
```v
interface Point {
	coordinates() (f64, f64)
}
```
You can use objects that implements Point interface or you can also use `kdbush.SimplePoint` which also implements the interface.

### KDBush.new
```v
fn KDBush.new(points []Point, node_size int) &KDBush
```

`KDBush.new` takes objects as input and builds the index.

It takes the following inputs:  
`points` - array of objects, that implements Point interface  
`node_size` - size of the KD-tree node (i.e 64). Higher means faster indexing but slower search, and vise versa.  

### range
```v
fn (bush KDBush) range(minX f64, minY f64, maxX f64, maxY f64) []int
```

`range` finds all items within the given bounding box and returns an array of indices that refer to the items in the original points input slice.  

### within
```v
fn (bush KDBush) within(qx f64, qy f64, radius f64) []int
```

`within` finds all items within a given radius from the query point and returns an array of indices.

## LICENSE
MIT