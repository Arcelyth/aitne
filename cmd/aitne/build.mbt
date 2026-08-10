///|
async fn handle_build() -> Unit {
  println("aitne mbxc")
  let mut style_root = []
  let content = match get_config(None) {
    Some(c) => c
    None => return
  }
  let cfg = @eirene.load_config(content) catch {
    err => {
      debug("Config Error: \{to_repr(err)}")
      return
    }
  }
  style_root = cfg.build.style_root

  let style_dir = "./dist"
  let style_buffer = StringBuilder::new()
  walk_and_compile(".", None, Ref(style_buffer), style_root) catch {
    e => debug(e)
  }

  if !@fs.path_exists(style_dir) {
    @fs.create_dir(style_dir) catch {
      _ => ()
    }
  }
  let css_path = if style_dir.has_suffix("/") || style_dir.has_suffix("\\") {
    style_dir + "style.css"
  } else {
    style_dir + "/style.css"
  }
  @fs.write_string_to_file(css_path, style_buffer.to_string()) catch {
    _ => println("Error: Failed to write style file '\{css_path}'")
  }

  println("aitne mbxc done")
  let _ = @async.with_task_group(async fn(group) {
    let args = match cfg.build.target {
      @eirene.CfgTarget::WasmGc => ["build", "--target=wasm-gc"]
      @eirene.CfgTarget::Js => ["build", "--target=js"]
    }
    let process = @process.spawn(group, "moon", args) catch {
      _ => {
        println("Failed to build.")
        return
      }
    }
    let _status = process.wait()
    println("moon build done")
    delete_gen_mbt() catch {
      _ => println("Failed to delete temporary files")
    }
  })
}

///|
pub fn delete_gen_mbt(dir? : String = ".") -> Unit raise @fs.IOError {
  let files = @fs.read_dir(dir) catch {
    e => {
      debug(e)
      return
    }
  }
  for file in files {
    if file == "." || file == ".." {
      continue
    }
    let path = dir + "/" + file
    if @fs.is_dir(path) {
      delete_gen_mbt(dir=path)
    } else if file.has_suffix(".mbx.mbt") {
      @fs.remove_file(path)
    }
  }
}
