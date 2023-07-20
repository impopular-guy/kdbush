module kdbush

import math

pub interface Point {
	coordinates() (f64, f64)
}

pub struct SimplePoint {
	x f64
	y f32
}

fn (s SimplePoint) coordinates() (f64, f64) {
	return s.x, s.y
}

pub struct KDBush {
	node_size int
mut:
	idxs   []int // array of indexes
	coords []f64 // array of coordinates
}

// `KDBush.new` takes objects as input and builds the index.
// It takes the following inputs:
//
// `points` - array of objects, that implements Point interface
// `node_size` - size of the KD-tree node (i.e 64). Higher means faster indexing but slower search, and vise versa.
pub fn KDBush.new(points []Point, node_size int) &KDBush {
	mut b := &KDBush{
		node_size: node_size
	}
	b.build_index(points)
	return b
}

// `range` finds all items within the given bounding box and returns an array of indices that refer to the items in the original points input slice.
pub fn (bush KDBush) range(minX f64, minY f64, maxX f64, maxY f64) []int {
	mut stack := [0, bush.idxs.len - 1, 0]
	mut result := []int{}
	mut x, mut y := f64(0), f64(0)

	for stack.len > 0 {
		axis := stack.pop()
		right := stack.pop()
		left := stack.pop()
		if right - left <= bush.node_size {
			for i := left; i <= right; i++ {
				x = bush.coords[2 * i]
				y = bush.coords[2 * i + 1]
				if x >= minX && x <= maxX && y >= minY && y <= maxY {
					result << bush.idxs[i]
				}
			}
			continue
		}
		m := int(math.floor(f64(left + right) / 2.0))
		x = bush.coords[2 * m]
		y = bush.coords[2 * m + 1]
		if x >= minX && x <= maxX && y >= minY && y <= maxY {
			result << bush.idxs[m]
		}

		next_axis := (axis + 1) % 2
		if (axis == 0 && minX <= x) || (axis != 0 && minY <= y) {
			stack << [left, m - 1, next_axis]
		}
		if (axis == 0 && maxX >= x) || (axis != 0 && maxY >= y) {
			stack << [m + 1, right, next_axis]
		}
	}
	return result
}

// `within` finds all items within a given radius from the query point and returns an array of indices.
pub fn (bush KDBush) within(qx f64, qy f64, radius f64) []int {
	mut stack := [0, bush.idxs.len - 1, 0]
	mut result := []int{}
	r2 := radius * radius

	for stack.len > 0 {
		axis := stack.pop()
		right := stack.pop()
		left := stack.pop()
		if right - left <= bush.node_size {
			for i := left; i <= right; i++ {
				dx, dy := bush.coords[2 * i] - qx, bush.coords[2 * i + 1] - qy
				dst := dx * dx + dy * dy
				if dst <= r2 {
					result << bush.idxs[i]
				}
			}
			continue
		}
		m := int(math.floor(f64(left + right) / 2.0))
		x := bush.coords[2 * m]
		y := bush.coords[2 * m + 1]
		if (x - qx) * (x - qx) + (y - qy) * (y - qy) <= r2 {
			result << bush.idxs[m]
		}

		next_axis := (axis + 1) % 2
		if (axis == 0 && qx - radius <= x) || (axis != 0 && qy - radius <= y) {
			stack << [left, m - 1, next_axis]
		}
		if (axis == 0 && qx + radius >= x) || (axis != 0 && qy + radius >= y) {
			stack << [m + 1, right, next_axis]
		}
	}
	return result
}

fn (mut bush KDBush) build_index(points []Point) {
	bush.idxs = []int{len: points.len}
	bush.coords = []f64{len: 2 * points.len}
	for i, v in points {
		bush.idxs[i] = i
		x, y := v.coordinates()
		bush.coords[i * 2] = x
		bush.coords[i * 2 + 1] = y
	}
	bush.sort(0, bush.idxs.len - 1, 0)
}

fn (mut bush KDBush) sort(left int, right int, depth int) {
	if right - left <= bush.node_size {
		return
	}
	m := int(math.floor(f64(left + right) / 2.0))
	bush.sselect(m, left, right, depth % 2)
	bush.sort(left, m - 1, depth + 1)
	bush.sort(m + 1, right, depth + 1)
}

fn (mut bush KDBush) sselect(k int, l int, r int, inc int) {
	mut left, mut right := l, r
	for right > left {
		if right - left > 600 {
			n := right - left + 1
			m := k - left + 1
			z := math.log(f64(n))
			s := 0.5 * math.exp(2.0 * z / 3.0)
			mut sds := 1.0
			if f64(m) - f64(n) / 2.0 < 0 {
				sds = -1.0
			}
			n_s := f64(n) - s
			sd := 0.5 * math.sqrt(z * s * n_s / f64(n)) * sds
			mut new_left := int(math.floor(f64(k) - f64(m) * s / f64(n) + sd))
			if left > new_left {
				new_left = left
			}
			mut new_right := int(math.floor(f64(k) + f64(n - m) * s / f64(n) + sd))
			if right < new_right {
				new_right = right
			}
			bush.sselect(k, new_left, new_right, inc)
		}
		t := bush.coords[2 * k + inc]
		mut i, mut j := left, right
		bush.swap_item(left, k)
		if bush.coords[2 * right + inc] > t {
			bush.swap_item(left, right)
		}
		for i < j {
			bush.swap_item(i, j)
			i += 1
			j -= 1
			for bush.coords[2 * i + inc] < t {
				i += 1
			}
			for bush.coords[2 * j + inc] > t {
				j -= 1
			}
		}
		if bush.coords[2 * left + inc] == t {
			bush.swap_item(left, j)
		} else {
			j += 1
			bush.swap_item(j, right)
		}
		if j <= k {
			left = j + 1
		}
		if k <= j {
			right = j - 1
		}
	}
}

fn (mut bush KDBush) swap_item(i int, j int) {
	bush.idxs[i], bush.idxs[j] = bush.idxs[j], bush.idxs[i]
	bush.coords[2 * i], bush.coords[2 * j] = bush.coords[2 * j], bush.coords[2 * i]
	bush.coords[2 * i + 1], bush.coords[2 * j + 1] = bush.coords[2 * j + 1], bush.coords[2 * i + 1]
}
