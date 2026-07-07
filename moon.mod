name = "Arcelyth/aitne"

version = "0.4.8"

import {
  "moonbitlang/x@0.4.45",
  "Arcelyth/html_escape@0.3.1",
  "tonyfettes/any@0.1.5",
  "moonbitlang/async@0.19.4",
  "bobzhang/toml@0.4.1",
}

readme = "README.mbt.md"

repository = "https://github.com/Arcelyth/aitne"

license = "MIT"

keywords = [ "web", "reactive", "framework", "fine-grained" ]

description = "A lightweight and high-performance reactive web framework."

preferred_target = "js"

supported_targets = [ "js", "native" ]

options(
  exclude: [ "examples", "bench" ],
)
