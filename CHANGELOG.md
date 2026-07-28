# Change log

## 0.11.0 (July 28, 2026)

- Support passing Unicode strings to `egd:text/5`
- Correct several named color values (`white`, `red` and a few others)
- Include Cozette font for more complete Unicode glyph support
- Include Terminus font and add more glyphs to default 6x11 font

## 0.10.1 (February 09, 2025)

- Align to OTP 24: use `erlang:crc32/1` instead of `zlib:crc32/2`, as the later
  one has been deprecated in OTP 24 and was removed in OTP 27.
- Convert documentation from `erl_docgen` style XML files to `ex_doc` style
  Markdown files.

## Previous versions

- 0.10.0: Add `egd_font:load_binary/1`
- 0.9.1: Reinstate `priv_dir` with fonts
- 0.9.0: Initial commit or [erlang/egd](https://github.com/erlang/egd)
