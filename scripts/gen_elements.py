#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
import re

SELF_CLOSING_ELEMENTS = [
    {"tag": "area", "attrs": ["alt", "coords", "download", "href", "hreflang", "ping", "rel", "shape", "target"], "self_closing": True},
    {"tag": "base", "attrs": ["href", "target"], "self_closing": True},
    {"tag": "br", "attrs": [], "self_closing": True},
    {"tag": "col", "attrs": ["span"], "self_closing": True},
    {"tag": "embed", "attrs": ["height", "src", "type", "width"], "self_closing": True},
    {"tag": "hr", "attrs": [], "self_closing": True},
    {"tag": "img", "attrs": ["alt", "attributionsrc", "crossorigin", "decoding", "elementtiming", "fetchpriority", "height", "ismap", "loading", "referrerpolicy", "sizes", "src", "srcset", "usemap", "width"], "self_closing": True},
    {"tag": "input", "attrs": ["accept", "alt", "autocomplete", "capture", "checked", "dirname", "disabled", "form", "formaction", "formenctype", "formmethod", "formnovalidate", "formtarget", "height", "list", "max", "maxlength", "min", "minlength", "multiple", "name", "pattern", "placeholder", "popovertarget", "popovertargetaction", "readonly", "required", "size", "src", "step", "type", "value", "width"], "self_closing": True},
    {"tag": "link", "attrs": ["as", "blocking", "crossorigin", "fetchpriority", "href", "hreflang", "imagesizes", "imagesrcset", "integrity", "media", "rel", "referrerpolicy", "sizes", "type"], "self_closing": True},
    {"tag": "meta", "attrs": ["charset", "content", "http_equiv", "name"], "self_closing": True},
    {"tag": "source", "attrs": ["src", "type", "srcset", "sizes", "media", "height", "width"], "self_closing": True},
    {"tag": "track", "attrs": ["default", "kind", "label", "src", "srclang"], "self_closing": True},
    {"tag": "wbr", "attrs": [], "self_closing": True},
]

NORMAL_ELEMENTS = [
    {"tag": "a", "attrs": ["download", "href", "hreflang", "ping", "referrerpolicy", "rel", "target", "type"], "self_closing": False},
    {"tag": "abbr", "attrs": [], "self_closing": False},
    {"tag": "address", "attrs": [], "self_closing": False},
    {"tag": "article", "attrs": [], "self_closing": False},
    {"tag": "aside", "attrs": [], "self_closing": False},
    {"tag": "audio", "attrs": ["autoplay", "controls", "crossorigin", "loop", "muted", "preload", "src"], "self_closing": False},
    {"tag": "b", "attrs": [], "self_closing": False},
    {"tag": "bdi", "attrs": [], "self_closing": False},
    {"tag": "bdo", "attrs": [], "self_closing": False},
    {"tag": "blockquote", "attrs": ["cite"], "self_closing": False},
    {"tag": "body", "attrs": [], "self_closing": False},
    {"tag": "button", "attrs": ["command", "commandfor", "disabled", "form", "formaction", "formenctype", "formmethod", "formnovalidate", "formtarget", "name", "type", "value", "popovertarget", "popovertargetaction"], "self_closing": False},
    {"tag": "canvas", "attrs": ["height", "width"], "self_closing": False},
    {"tag": "caption", "attrs": [], "self_closing": False},
    {"tag": "cite", "attrs": [], "self_closing": False},
    {"tag": "code", "attrs": [], "self_closing": False},
    {"tag": "colgroup", "attrs": ["span"], "self_closing": False},
    {"tag": "data", "attrs": ["value"], "self_closing": False},
    {"tag": "datalist", "attrs": [], "self_closing": False},
    {"tag": "dd", "attrs": [], "self_closing": False},
    {"tag": "del", "attrs": ["cite", "datetime"], "self_closing": False},
    {"tag": "details", "attrs": ["name", "open"], "self_closing": False},
    {"tag": "dfn", "attrs": [], "self_closing": False},
    {"tag": "dialog", "attrs": ["closedby", "open"], "self_closing": False},
    {"tag": "div", "attrs": [], "self_closing": False},
    {"tag": "dl", "attrs": [], "self_closing": False},
    {"tag": "dt", "attrs": [], "self_closing": False},
    {"tag": "em", "attrs": [], "self_closing": False},
    {"tag": "fieldset", "attrs": ["disabled", "form", "name"], "self_closing": False},
    {"tag": "figcaption", "attrs": [], "self_closing": False},
    {"tag": "figure", "attrs": [], "self_closing": False},
    {"tag": "footer", "attrs": [], "self_closing": False},
    {"tag": "form", "attrs": ["accept_charset", "action", "autocomplete", "enctype", "method", "name", "novalidate", "target"], "self_closing": False},
    {"tag": "h1", "attrs": [], "self_closing": False},
    {"tag": "h2", "attrs": [], "self_closing": False},
    {"tag": "h3", "attrs": [], "self_closing": False},
    {"tag": "h4", "attrs": [], "self_closing": False},
    {"tag": "h5", "attrs": [], "self_closing": False},
    {"tag": "h6", "attrs": [], "self_closing": False},
    {"tag": "head", "attrs": [], "self_closing": False},
    {"tag": "header", "attrs": [], "self_closing": False},
    {"tag": "hgroup", "attrs": [], "self_closing": False},
    {"tag": "html", "attrs": [], "self_closing": False},
    {"tag": "i", "attrs": [], "self_closing": False},
    {"tag": "iframe", "attrs": ["allow", "allowfullscreen", "allowpaymentrequest", "height", "name", "referrerpolicy", "sandbox", "src", "srcdoc", "width"], "self_closing": False},
    {"tag": "ins", "attrs": ["cite", "datetime"], "self_closing": False},
    {"tag": "kbd", "attrs": [], "self_closing": False},
    {"tag": "label", "attrs": ["for", "form"], "self_closing": False},
    {"tag": "legend", "attrs": [], "self_closing": False},
    {"tag": "li", "attrs": ["value"], "self_closing": False},
    {"tag": "main", "attrs": [], "self_closing": False},
    {"tag": "map", "attrs": ["name"], "self_closing": False},
    {"tag": "mark", "attrs": [], "self_closing": False},
    {"tag": "menu", "attrs": [], "self_closing": False},
    {"tag": "meter", "attrs": ["value", "min", "max", "low", "high", "optimum", "form"], "self_closing": False},
    {"tag": "nav", "attrs": [], "self_closing": False},
    {"tag": "noscript", "attrs": [], "self_closing": False},
    {"tag": "object", "attrs": ["data", "form", "height", "name", "type", "usemap", "width"], "self_closing": False},
    {"tag": "ol", "attrs": ["reversed", "start", "type"], "self_closing": False},
    {"tag": "optgroup", "attrs": ["disabled", "label"], "self_closing": False},
    {"tag": "output", "attrs": ["for", "form", "name"], "self_closing": False},
    {"tag": "p", "attrs": [], "self_closing": False},
    {"tag": "picture", "attrs": [], "self_closing": False},
    {"tag": "portal", "attrs": ["referrerpolicy", "src"], "self_closing": False},
    {"tag": "pre", "attrs": [], "self_closing": False},
    {"tag": "progress", "attrs": ["min", "max", "value"], "self_closing": False},
    {"tag": "q", "attrs": ["cite"], "self_closing": False},
    {"tag": "rp", "attrs": [], "self_closing": False},
    {"tag": "rt", "attrs": [], "self_closing": False},
    {"tag": "ruby", "attrs": [], "self_closing": False},
    {"tag": "s", "attrs": [], "self_closing": False},
    {"tag": "samp", "attrs": [], "self_closing": False},
    {"tag": "script", "attrs": ["async", "crossorigin", "defer", "fetchpriority", "integrity", "nomodule", "referrerpolicy", "src", "type", "blocking"], "self_closing": False},
    {"tag": "search", "attrs": [], "self_closing": False},
    {"tag": "section", "attrs": [], "self_closing": False},
    {"tag": "select", "attrs": ["autocomplete", "disabled", "form", "multiple", "name", "required", "size"], "self_closing": False},
    {"tag": "slot", "attrs": ["name"], "self_closing": False},
    {"tag": "small", "attrs": [], "self_closing": False},
    {"tag": "span", "attrs": [], "self_closing": False},
    {"tag": "strong", "attrs": [], "self_closing": False},
    {"tag": "style", "attrs": ["media", "blocking"], "self_closing": False},
    {"tag": "sub", "attrs": [], "self_closing": False},
    {"tag": "summary", "attrs": [], "self_closing": False},
    {"tag": "sup", "attrs": [], "self_closing": False},
    {"tag": "table", "attrs": [], "self_closing": False},
    {"tag": "tbody", "attrs": [], "self_closing": False},
    {"tag": "td", "attrs": ["colspan", "headers", "rowspan"], "self_closing": False},
    {"tag": "template", "attrs": [], "self_closing": False},
    {"tag": "textarea", "attrs": ["autocomplete", "cols", "dirname", "disabled", "form", "maxlength", "minlength", "name", "placeholder", "readonly", "required", "rows", "wrap"], "self_closing": False},
    {"tag": "tfoot", "attrs": [], "self_closing": False},
    {"tag": "th", "attrs": ["abbr", "colspan", "headers", "rowspan", "scope"], "self_closing": False},
    {"tag": "thead", "attrs": [], "self_closing": False},
    {"tag": "time", "attrs": ["datetime"], "self_closing": False},
    {"tag": "title", "attrs": [], "self_closing": False},
    {"tag": "tr", "attrs": [], "self_closing": False},
    {"tag": "u", "attrs": [], "self_closing": False},
    {"tag": "ul", "attrs": [], "self_closing": False},
    {"tag": "var", "attrs": [], "self_closing": False},
    {"tag": "video", "attrs": ["autoplay", "controls", "controlslist", "crossorigin", "disablepictureinpicture", "disableremoteplayback", "height", "loop", "muted", "playsinline", "poster", "preload", "src", "width"], "self_closing": False},
    {"tag": "option", "attrs": ["disabled", "label", "selected", "value"], "self_closing": False},
]

ELEMENTS = SELF_CLOSING_ELEMENTS + NORMAL_ELEMENTS


def camel_tag(tag: str) -> str:
    if tag in ["option", "main", "var"]:
        return f"Tag{tag.capitalize()}_"
    parts = re.split(r"[^A-Za-z0-9]+", tag)
    body = "".join(p[:1].upper() + p[1:] for p in parts if p)
    return "Tag" + body


def fn_name(tag: str) -> str:
    return f"{tag}_" if tag in ["option", "main", "var"] else tag

def emit_elements(elements) -> str:
    out: list[str] = []
    out.append("/// Generated by gen_elements.py")
    out.append("/// Edit ELEMENTS in this script, then rerun it to regenerate this file.")
    out.append("")
    for item in elements:
        tag = item["tag"]
        ty = camel_tag(tag)
        fn = fn_name(tag)
        sc = "true" if item["self_closing"] else "false"
        out.append(f"pub struct {ty} {{}}")
        out.append(f'pub impl ElementType for {ty} with tag(_self) {{ "{tag}" }}')
        out.append(f"pub impl ElementType for {ty} with is_self_closing(_self) {{ {sc} }}")
        out.append(f"pub fn {fn}(children?: Array[&View] = []) -> HtmlElement[{ty}, Array[&View]] {{ {{ tag: {ty}::{{}}, attrs: AttrList::new(), children: children }} }}")
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def emit_map(elements) -> str:
    out: list[str] = []
    out.append("/// Generated by gen_elements.py")
    out.append("/// Edit ELEMENTS in this script, then rerun it to regenerate this file.")
    out.append("")
    out.append("pub let builtin_elements : HashSet[String] = HashSet::from_array([")
    for item in elements:
        out.append(f'  "{item["tag"]}",')
    out.append("])")
    out.append("")
    return "\n".join(out).rstrip() + "\n"

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--output", required=True, help="output elements .mbt file")
    ap.add_argument("-m", "--map-output", required=True, help="output builtin map .mbt file")
    args = ap.parse_args()

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(emit_elements(ELEMENTS), encoding="utf-8")
    print(f"wrote {len(ELEMENTS)} elements to {out_path}")

    map_path = Path(args.map_output)
    map_path.parent.mkdir(parents=True, exist_ok=True)
    map_path.write_text(emit_map(ELEMENTS), encoding="utf-8")
    print(f"wrote builtin map to {map_path}")

if __name__ == "__main__":
    main()
