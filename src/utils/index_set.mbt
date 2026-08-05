///|
using @hashmap {type HashMap}

///|
pub struct IndexSet[K] {
  keys : Array[K]
  key_index : HashMap[K, Int]
}

///|
#inline
pub fn[K : Hash + Eq] IndexSet::new() -> IndexSet[K] {
  { keys: [], key_index: HashMap([]) }
}

///|
#inline
pub fn[K] IndexSet::length(self : IndexSet[K]) -> Int {
  self.keys.length()
}

///|
#inline
pub fn[K] IndexSet::is_empty(self : IndexSet[K]) -> Bool {
  self.keys.is_empty()
}

///|
pub fn[K : Hash + Eq] IndexSet::insert(self : IndexSet[K], key : K) -> Bool {
  if self.key_index.contains(key) {
    return false
  }
  let index = self.keys.length()
  self.keys.push(key)
  self.key_index.set(key, index)
  true
}

///|
#inline
pub fn[K : Hash + Eq] IndexSet::contains(self : IndexSet[K], key : K) -> Bool {
  self.key_index.contains(key)
}

///|
#inline
pub fn[K : Hash + Eq] IndexSet::get_index(self : IndexSet[K], key : K) -> Int? {
  self.key_index.get(key)
}

///|
#inline
pub fn[K] IndexSet::get(self : IndexSet[K], index : Int) -> K? {
  if index >= 0 && index < self.keys.length() {
    Some(self.keys[index])
  } else {
    None
  }
}

///|
pub fn[K : Hash + Eq] IndexSet::swap_remove(
  self : IndexSet[K],
  key : K,
) -> Bool {
  match self.key_index.get(key) {
    None => false
    Some(index) => {
      self.key_index.remove(key)
      let last_index = self.keys.length() - 1
      if index != last_index {
        let last_key = self.keys[last_index]
        self.keys[index] = last_key
        self.key_index.set(last_key, index)
      }
      let _ = self.keys.pop()
      true
    }
  }
}

///|
pub fn[K : Hash + Eq] IndexSet::shift_remove(
  self : IndexSet[K],
  key : K,
) -> Bool {
  match self.key_index.get(key) {
    None => false
    Some(index) => {
      self.key_index.remove(key)
      let _ = self.keys.remove(index)

      let keys = self.keys
      let len = keys.length()
      let mut i = index
      while i < len {
        self.key_index.set(keys[i], i)
        i = i + 1
      }
      true
    }
  }
}

///|
#inline
pub fn[K] IndexSet::clear(self : IndexSet[K]) -> Unit {
  self.keys.clear()
  self.key_index.clear()
}

///|
#inline
pub fn[K] IndexSet::iter(self : IndexSet[K]) -> Iter[K] {
  self.keys.iter()
}
