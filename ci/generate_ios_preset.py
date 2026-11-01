"""Create the iOS Xcode-only Godot export preset with the verified Apple Team ID.

Does not create an IPA, Apple signing certificate, or provisioning profile.
The source project is deliberately native-only (no Web export profile).
"""
import os
import re
from pathlib import Path

team = os.environ.get("GODOT_IOS_TEAM_ID", "").strip().upper()
if not re.fullmatch(r"[A-Z0-9]{10}", team):
    raise SystemExit("GODOT_IOS_TEAM_ID must be an actual 10-character Apple Team ID")

path = Path("source/export_presets.cfg")
raw = path.read_text(encoding="utf-8")
if 'platform="Web"' in raw:
    raise SystemExit("Web export is prohibited in native mobile builds")
if 'platform="iOS"' in raw:
    raise SystemExit("iOS export preset already exists; refusing duplication")
raw += f'''
[preset.1]
name="iOS"
platform="iOS"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="assets/data/floor_surfaces.json"
exclude_filter="art/*,tests/*,assets/models/two_storey_base.glb,assets/models/two_storey_base.glb.gz,assets/models/two_storey_base_*.png,assets/models/cartoon_cast.glb,assets/data/campaign_24_design.json"
export_path="../native-dist/Pakosti.ipa"
script_export_mode=1

[preset.1.options]
custom_template/debug=""
custom_template/release=""
architectures/arm64=true
application/app_store_team_id="{team}"
application/bundle_identifier="com.tembur.pakosti"
application/signature="Пакости по соседству"
application/short_version="0.1.0"
application/version="1"
application/export_project_only=true
application/targeted_device_family=1
'''
path.write_text(raw, encoding="utf-8")
print("IOS_XCODE_PRESET_READY", team)
