#!/usr/bin/env python3
"""
FlowCore Perk Database Builder
Parses 'perkexport.csv' exactly as defined by the user and compiles it into 'PerksData.lua'.
Matches exact export headers:
id, name, cat, category_name, assigned_class, set_name, spell_id, active, description
Provides dual-key compatibility (both snake_case matching CSV headers and camelCase).
"""

import csv
import os

def build_perks_data():
    addon_dir = os.path.dirname(os.path.abspath(__file__))
    csv_file = os.path.join(addon_dir, "perkexport.csv")
    lua_file = os.path.join(addon_dir, "PerksData.lua")

    if not os.path.exists(csv_file):
        print(f"[ERROR] '{csv_file}' not found.")
        return

    with open(csv_file, "r", encoding="utf-8", errors="replace") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    out_lines = [
        "-- =====================================================",
        "-- FLOWCORE PRECOMPILED PERK DATABASE",
        "-- Compiled from perkexport.csv",
        "-- Matches exact CSV headers: id, name, cat, category_name, assigned_class, set_name, spell_id, active, description",
        "-- Provides instantaneous zero-latency offline perk loading",
        "-- =====================================================",
        "local FC = FlowCore",
        "FC.PERK_DATABASE = FC.PERK_DATABASE or {}",
        ""
    ]

    for r in rows:
        p_id_str = str(r.get('id', '')).strip()
        if not p_id_str.isdigit():
            continue
        p_id = int(p_id_str)
        name = r.get('name', '').replace('\\', '\\\\').replace('"', '\\"')
        raw_cat = str(r.get('cat', '19')).strip()
        cat_id = int(raw_cat) if raw_cat.isdigit() else 19

        category = (r.get('category_name') or r.get('category') or 'Misc').strip()
        if not category:
            category = 'Misc'

        assigned_class = (r.get('assigned_class') or r.get('assignedClass') or 'ALL').strip()
        if not assigned_class:
            assigned_class = 'ALL'

        set_name = (r.get('set_name') or r.get('setName') or '').replace('\\', '\\\\').replace('"', '\\"').strip()
        spell_id_str = str(r.get('spell_id') or r.get('spellId') or '').strip()
        spell_id = int(spell_id_str) if spell_id_str.isdigit() and int(spell_id_str) > 0 else 'nil'
        active_val = str(r.get('active', '0')).strip()
        is_active = "true" if active_val in ("1", "true", "True") else "false"
        desc = (r.get('description') or r.get('desc') or '').replace('\\', '\\\\').replace('"', '\\"').replace('\r\n', '\\n').replace('\n', '\\n')

        icon_val = (r.get('icon') or '').replace('\\', '\\\\').replace('"', '\\"').strip()
        icon_str = f'"{icon_val}"' if icon_val else 'nil'

        entry_lua = (
            f"FC.PERK_DATABASE[{p_id}] = {{\n"
            f"    id = {p_id},\n"
            f"    name = \"{name}\",\n"
            f"    cat = {cat_id},\n"
            f"    category_name = \"{category}\",\n"
            f"    category = \"{category}\",\n"
            f"    assigned_class = \"{assigned_class}\",\n"
            f"    assignedClass = \"{assigned_class}\",\n"
            f"    set_name = \"{set_name}\",\n"
            f"    setName = \"{set_name}\",\n"
            f"    spell_id = {spell_id},\n"
            f"    spellId = {spell_id},\n"
            f"    active = {is_active},\n"
            f"    icon = {icon_str},\n"
            f"    description = \"{desc}\"\n"
            f"}}"
        )
        out_lines.append(entry_lua)

    with open(lua_file, "w", encoding="utf-8") as out:
        out.write("\n".join(out_lines) + "\n")

    print(f"[SUCCESS] Compiled {len(rows)} perks from 'perkexport.csv' into 'PerksData.lua' matching all export headers.")

if __name__ == "__main__":
    build_perks_data()
