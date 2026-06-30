///|
#cfg(target="native")
pub async fn start_server(cfg : Config) -> Unit {
  @http.Server(@socket.Addr::parse("\{cfg.server.host}:\{cfg.server.port}")).run_forever((
      request,
      _body,
      conn,
    ) => {
      let path = request.path
      if is_static_asset(path) {
        match (try? @fs.read_file_to_string(cfg.build.out_dir + path)) {
          Ok(content) => {
            let headers = Map::from_array([
              ("Content-Type", get_mime_type(path)),
            ])
            conn.send_response(200, "OK", extra_headers=headers)
            conn.write_string(content)
          }
          _ => {
            conn.send_response(404, "Not Found")
            conn.write_string("Asset `\{path}` not found")
          }
        }
      } else {
        match
          (try? @fs.read_file_to_string(join_paths(cfg.build.out_dir, cfg.app.entry_html))) {
          Ok(html_content) => {
            let headers = Map::from_array([
              ("Content-Type", "text/html; charset=utf-8"),
            ])
            conn.send_response(200, "OK", extra_headers=headers)
            conn.write_string(html_content)
          }
          _ => {
            conn.send_response(500, "Internal Server Error")
            conn.write_string(
              "Fatal: \{cfg.build.out_dir} \{cfg.app.entry_html} is missing.",
            )
          }
        }
      }
    },
  )
}

///|
fn is_static_asset(path : String) -> Bool {
  path.has_suffix(".js") ||
  path.has_suffix(".css") ||
  path.has_suffix(".png") ||
  path.has_suffix(".wasm") ||
  path.has_suffix(".ico")
}

///|
fn get_mime_type(path : String) -> String {
  if path.has_suffix(".js") {
    "application/javascript"
  } else if path.has_suffix(".css") {
    "text/css"
  } else if path.has_suffix(".wasm") {
    "application/wasm"
  } else if path.has_suffix(".png") {
    "image/png"
  } else {
    "application/octet-stream"
  }
}

///|
fn join_paths(base : String, relative : String) -> String {
  if base.length() == 0 {
    return relative
  }
  if relative.length() == 0 {
    return base
  }

  let base_has_slash = base.has_suffix("/")
  let rel_has_slash = relative.has_prefix("/")

  if base_has_slash && rel_has_slash {
    base + relative[1:relative.length()].to_owned()
  } else if !base_has_slash && !rel_has_slash {
    base + "/" + relative
  } else {
    base + relative
  }
}
