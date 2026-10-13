"""Small renderer check: python3 -m unittest discover -s skills/codebase-map/scripts."""
import copy
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from render import validate


MODEL = {
    'title': 'Map </script><script>alert(1)</script>',
    'snapshot': 'Example commit', 'scope': 'Example slice', 'summary': ['Summary'],
    'nodes': [{'id': 'a', 'label': 'Component', 'group': 'UI', 'purpose': 'Purpose',
               'pattern': 'Pattern', 'state': 'State', 'contracts': ['Keep behavior'],
               'sources': ['src/a.ts:1']}],
    'views': [{'id': 'overview', 'label': 'Overview', 'nodes': ['a'], 'edges': [],
               'columns': [{'label': 'UI', 'nodes': ['a']}]}],
    'flows': [], 'findings': [], 'delegation': [], 'unknowns': []
}


class RenderTest(unittest.TestCase):
    def test_offline_render_and_escape(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            model = path / 'map.json'
            model.write_text(json.dumps(MODEL))
            subprocess.run([sys.executable, str(Path(__file__).with_name('render.py')),
                            str(model), tmp], check=True, capture_output=True)
            page = (path / 'index.html').read_text()
            self.assertNotIn('</script><script>alert(1)', page)
            self.assertIn('Map &lt;/script&gt;', page)
            self.assertNotIn('src="http', page)
            self.assertIn('Copy report handoff', page)
            self.assertIn('Clipboard access is unavailable', page)
            self.assertIn(MODEL['title'], (path / 'architecture.md').read_text())

    def test_invalid_layout_and_sequence(self):
        model = copy.deepcopy(MODEL)
        model['views'][0]['columns'][0]['nodes'].append('a')
        with self.assertRaises(AssertionError):
            validate(model)
        model = copy.deepcopy(MODEL)
        model['flows'] = [{'steps': [{'node': 'a', 'evidence': 'src/a.ts:1'}],
                           'sequence': {'participants': [{'id': 'ui'}, {'id': 'cache'}],
                                        'messages': [{'from': 'ui', 'to': 'unknown', 'step': 0}]}}]
        with self.assertRaises(AssertionError):
            validate(model)


if __name__ == '__main__':
    unittest.main()
