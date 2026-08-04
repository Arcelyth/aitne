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
        let content = @fs.read_file_to_string(cfg.build.out_dir + path) catch {
          _ => {
            conn.send_response(404, "Not Found")
            conn.write_string("Asset `\{path}` not found")
            return
          }
        }
        let headers = Map::from_iter(
          [("Content-Type", get_mime_type(path))].iter(),
        )
        conn.send_response(200, "OK", extra_headers=headers)
        conn.write_string(content)
      } else {
        let html_content = @fs.read_file_to_string(
          join_paths(cfg.build.out_dir, cfg.app.entry_html),
        ) catch {
          _ => {
            conn.send_response(500, "Internal Server Error")
            conn.write_string(
              "Fatal: \{cfg.build.out_dir} \{cfg.app.entry_html} is missing.",
            )
            return
          }
        }
        let headers = Map::from_iter(
          [("Content-Type", "text/html; charset=utf-8")].iter(),
        )
        conn.send_response(200, "OK", extra_headers=headers)
        conn.write_string(html_content)
      }
    },
  )
}

///|
#cfg(target="native")
fn is_static_asset(path : String) -> Bool {
  path.has_suffix(".js") ||
  path.has_suffix(".css") ||
  path.has_suffix(".png") ||
  path.has_suffix(".wasm") ||
  path.has_suffix(".ico")
}

///|
#cfg(target="native")
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
#cfg(target="native")
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
