## 存档管理：JSON 持久化 + 版本字段。
## user://saves/ 下以 .slab.json 结尾；含版本号供未来迁移。
extends RefCounted

const SAVE_DIR := "user://saves"
const EXT := ".slab.json"
const CURRENT_VERSION := 1

func _ready_dir() -> void:
        DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _sanitize(file_name: String) -> String:
        var out := ""
        for c in file_name:
                if (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9") \
                                or c == "_" or c == "-" or c == ".":
                        out += c
                elif c.len_utf8() == 3 and c.to_utf8_buffer().size() >= 3:
                        # 保留中日韩字符（Godot 文件系统支持 UTF-8 文件名）
                        var b := c.to_utf8_buffer()
                        if b[0] >= 0xE0:
                                out += c
        return out

func save_game(payload: Dictionary, file_name: String) -> bool:
        _ready_dir()
        var safe := _sanitize(file_name)
        if safe.length() < 1:
                safe = "save_%d" % Time.get_unix_time_from_system()
        var path := SAVE_DIR + "/" + safe + EXT
        var json := JSON.stringify(payload, "  ")
        var f := FileAccess.open(path, FileAccess.WRITE)
        if f == null:
                return false
        f.store_string(json)
        f.close()
        return true

func list_saves() -> Array:
        _ready_dir()
        var out: Array = []
        var dir := DirAccess.open(SAVE_DIR)
        if dir == null:
                return out
        dir.list_dir_begin()
        var name := dir.get_next()
        while not name.is_empty():
                if name.ends_with(EXT):
                        var payload := load_game(SAVE_DIR + "/" + name)
                        if not payload.is_empty():
                                var meta: Dictionary = payload.get("meta", {})
                                out.append({
                                        "file": name,
                                        "path": SAVE_DIR + "/" + name,
                                        "world_name": str(meta.get("name", "未知世界")),
                                        "year": int(meta.get("year", 0)),
                                        "seed": int(meta.get("seed", 0)),
                                        "god_mode": int(meta.get("god_mode", 0)),
                                        "settlements": int(meta.get("settlements", 0)),
                                })
                name = dir.get_next()
        dir.list_dir_end()
        out.sort_custom(func(a, b): return int(a.get("year", 0)) > int(b.get("year", 0)))
        return out

func load_game(path: String) -> Dictionary:
        if not FileAccess.file_exists(path):
                return {}
        var f := FileAccess.open(path, FileAccess.READ)
        if f == null:
                return {}
        var json := f.get_as_text()
        f.close()
        var parsed = JSON.parse_string(json)
        if parsed == null or not (parsed is Dictionary):
                return {}
        var ver := int(parsed.get("version", 0))
        if ver > CURRENT_VERSION:
                push_warning("存档版本 %d 高于当前支持版本 %d" % [ver, CURRENT_VERSION])
                return {}
        return parsed

func delete_save(path: String) -> bool:
        return DirAccess.remove_absolute(path) == Error.OK

func has_saves() -> bool:
        return not list_saves().is_empty()
