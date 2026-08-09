///|
pub async fn build_project(cfg : Config) -> Unit {
  println("aitne mbxc")
  let style_dir = "./dist"
  let style_buffer = StringBuilder::new()
  walk_and_compile(".", None, Ref(style_buffer), cfg.build.style_root) catch {
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
      CfgTarget::WasmGc => ["build", "--target=wasm-gc"]
      CfgTarget::Js => ["build", "--target=js"]
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
fn compile_mbx_file(
  path : String,
  show : Bool,
  not_tmp : Bool,
  out_dir : String?,
  style_buffer : Ref[StringBuilder],
) -> Unit {
  if path.has_suffix(".mbx") {
    let target = match out_dir {
      Some(dir) => {
        let mut last_slash = -1
        for i = 0; i < path.length(); i = i + 1 {
          if path[i] == '/' || path[i] == '\\' {
            last_slash = i
          }
        }
        let filename = if last_slash == -1 {
          path
        } else {
          path[last_slash:path.length()].to_owned()
        }
        dir + filename + ".mbt"
      }
      None => path + ".mbt"
    }
    let _ = @mbxc.from_file(
      path,
      show~,
      to=Some(target),
      not_tmp~,
      style_buffer,
    )
  }
}

///|
pub fn walk_and_compile(
  dir : String,
  show? : Bool = false,
  not_tmp? : Bool = false,
  out_dir : String?,
  style_buffer : Ref[StringBuilder],
  style_root : Array[String],
) -> Unit raise @fs.IOError {
  ignore(style_root)
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
      walk_and_compile(path, show~, not_tmp~, out_dir, style_buffer, style_root)
    } else if path.has_suffix(".mbx") {
      compile_mbx_file(path, show, not_tmp, out_dir, style_buffer)
    }
  }
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
