"""Run synthetic Lua tests; optionally exercise an installed ElvUI formatter.

python -m pip install --target .test-tools -r tests/requirements.txt
python tests/run.py [--elvui-chat /path/to/ElvUI/.../Chat.lua]
"""
import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.test-tools'))
from lupa.lua51 import LuaRuntime as Lua51
from lupa.lua54 import LuaRuntime as Lua54

parser = argparse.ArgumentParser()
parser.add_argument('--elvui-chat', type=Path)
args = parser.parse_args()
for runtime in (Lua51, Lua54):
    lua = runtime(unpack_returned_tuples=True)
    lua.globals().ROOT = ROOT.as_posix()
    if args.elvui_chat:
        source = args.elvui_chat.read_text(encoding='utf-8-sig')
        start = source.index('function CH:MessageFormatter(')
        end = source.index('\nfunction CH:GetDiscordInfo(', start)
        lua.globals().ELVUI_FORMATTER = source[start:end]
    lua.execute((ROOT / 'tests/bridge_spec.lua').read_text(encoding='utf-8'))
    print(f'{runtime.__module__}: passed')
