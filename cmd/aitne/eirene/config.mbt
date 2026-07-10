///|
suberror EireneError {
  TomlError(String)
} derive(Debug)

///|
pub enum CfgTarget {
  Js
} derive(Debug)

///|
pub enum CfgMode {
  Development
  Production
} derive(Debug)

///|
pub struct AppConfig {
  name : String
  mode : CfgMode
  entry_html : String
} derive(Debug)

///|
pub struct BuildConfig {
  target : CfgTarget
  src_dir : String
  out_dir : String
  style_root : Array[String]
  public_path : String
  minify : Bool
  sourcemap : Bool
  experimental_wasm_gc : Bool
} derive(Debug)

///|
pub struct ServerConfig {
  host : String
  port : Int
  spa_fallback : Bool
  hmr_enabled : Bool
  hmr_port : Int
  https_enabled : Bool
  proxy : Map[String, String]
} derive(Debug)

///|
pub struct AssetsConfig {
  static_dir : String
  inject_scripts : Array[String]
} derive(Debug)

///|
/// Local server configuration, some fields are not used.
pub struct Config {
  app : AppConfig
  build : BuildConfig
  server : ServerConfig
  assets : AssetsConfig
} derive(Debug)

///|
pub fn load_config(toml_content : String) -> Config raise EireneError {
  let root_ast = @toml.parse(toml_content) catch {
    err => raise TomlError("Failed to parse toml file \{to_repr(err)}.")
  }

  let root = match root_ast {
    TomlTable(t) => t
    _ => Map([])
  }

  let app_table = match root.get("app") {
    Some(TomlTable(t)) => t
    _ => Map([])
  }

  let mode = match get_string(app_table, "mode", "development") {
    "development" => CfgMode::Development
    _ => CfgMode::Production
  }

  let app = AppConfig::{
    name: get_string(app_table, "name", "aitne-app"),
    mode,
    entry_html: get_string(app_table, "entry_html", "index.html"),
  }

  let build_table = match root.get("build") {
    Some(TomlTable(t)) => t
    _ => Map([])
  }

  let target = match get_string(build_table, "target", "js") {
    _ => CfgTarget::Js
  }

  let build = BuildConfig::{
    target,
    src_dir: get_string(build_table, "src_dir", "src"),
    out_dir: get_string(build_table, "out_dir", "dist"),
    style_root: get_string_array(build_table, "style_root"),
    public_path: get_string(build_table, "public_path", "/"),
    minify: get_bool(build_table, "minify", false),
    sourcemap: get_bool(build_table, "sourcemap", true),
    experimental_wasm_gc: get_bool(build_table, "experimental_wasm_gc", false),
  }

  let server_table = match root.get("server") {
    Some(TomlTable(t)) => t
    _ => Map([])
  }
  let server = ServerConfig::{
    host: get_string(server_table, "host", "127.0.0.1"),
    port: get_int(server_table, "port", 8000),
    spa_fallback: get_bool(server_table, "spa_fallback", true),
    hmr_enabled: get_bool(server_table, "hmr_enabled", true),
    hmr_port: get_int(server_table, "hmr_port", 24678),
    https_enabled: get_bool(server_table, "https_enabled", false),
    proxy: get_proxy_map(server_table, "proxy"),
  }

  let assets_table = match root.get("assets") {
    Some(TomlTable(t)) => t
    _ => Map([])
  }
  let assets = AssetsConfig::{
    static_dir: get_string(assets_table, "static_dir", "public"),
    inject_scripts: get_string_array(assets_table, "inject_scripts"),
  }

  Config::{ app, build, server, assets }
}

///|
fn get_string(
  table : Map[String, @toml.TomlValue],
  key : String,
  default : String,
) -> String {
  match table.get(key) {
    Some(TomlString(s)) => s
    _ => default
  }
}

///|
fn get_bool(
  table : Map[String, @toml.TomlValue],
  key : String,
  default : Bool,
) -> Bool {
  match table.get(key) {
    Some(TomlBoolean(b)) => b
    _ => default
  }
}

///|
fn get_int(
  table : Map[String, @toml.TomlValue],
  key : String,
  default : Int,
) -> Int {
  match table.get(key) {
    Some(TomlInteger(i)) => i.to_int()
    _ => default
  }
}

///|
fn get_string_array(
  table : Map[String, @toml.TomlValue],
  key : String,
) -> Array[String] {
  let result = []
  match table.get(key) {
    Some(TomlArray(arr)) =>
      for item in arr {
        match item {
          TomlString(s) => result.push(s)
          _ => ()
        }
      }
    _ => ()
  }
  result
}

///|
fn get_proxy_map(
  table : Map[String, @toml.TomlValue],
  key : String,
) -> Map[String, String] {
  let proxy_map = Map([])
  match table.get(key) {
    Some(TomlTable(sub_table)) =>
      for k, v in sub_table {
        match v {
          TomlString(target) => proxy_map.set(k, target)
          _ => ()
        }
      }
    _ => ()
  }
  proxy_map
}
