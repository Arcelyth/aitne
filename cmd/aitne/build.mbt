///|
async fn handle_build() -> Unit {
  println("aitne mbxc")
  let mut style_root = []
  let content = match get_config(None) {
    Some(c) => c
    None => return
  }
  match (try? @eirene.load_config(content)) {
    Ok(cfg) => style_root = cfg.build.style_root
    Err(err) => debug("Config Error: \{to_repr(err)}")
  }

  let style_dir = "./dist"
  let style_buffer = StringBuilder::new()
  let res = try? walk_and_compile(".", None, Ref(style_buffer), style_root)
  match res {
    Ok(_) => ()
    Err(e) => debug(e)
  }

  if !@fs.path_exists(style_dir) {
    let _ = try? @fs.create_dir(style_dir)
  }
  let css_path = if style_dir.has_suffix("/") || style_dir.has_suffix("\\") {
    style_dir + "style.css"
  } else {
    style_dir + "/style.css"
  }
  let write_res = try? @fs.write_string_to_file(
    css_path,
    style_buffer.to_string(),
  )
  match write_res {
    Ok(_) => ()
    Err(_) => println("Error: Failed to write style file '\{css_path}'")
  }

  println("aitne mbxc done")
  let _ = @async.with_task_group(async fn(group) {
    match (try? @process.spawn(group, "moon", ["build"])) {
      Ok(process) => {
        let _status = process.wait()
        println("moon build done")
        match (try? delete_gen_mbt()) {
          Ok(_) => ()
          Err(e) => println("Failed to delete temporary files")
        }
      }
      Err(_) => println("Failed to build.")
    }
  })
}

///|
pub fn delete_gen_mbt(dir? : String = ".") -> Unit raise @fs.IOError {
  let entries = try? @fs.read_dir(dir)
  match entries {
    Ok(files) =>
      for file in files {
        if file == "." || file == ".." {
          continue
        }

        let path = dir + "/" + file

        if @fs.is_dir(path) {
          delete_gen_mbt(dir=path)
        } else if file.ends_with(".mbx.mbt") {
          @fs.remove_file(path)
        }
      }
    Err(e) => debug(e)
  }
}
