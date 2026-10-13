"""Render one source-backed model as an offline HTML map and Markdown report."""
import html
import json
import sys
from pathlib import Path


def validate(data):
    ids = [node['id'] for node in data['nodes']]
    assert len(ids) == len(set(ids)), 'Duplicate component IDs'
    assert data['views'], 'At least one map view is required'
    for view in data['views']:
        assert view['nodes'] and set(view['nodes']) <= set(ids), 'Unknown view component'
        if 'columns' in view:
            placed = [node for column in view['columns'] for node in column['nodes']]
            assert len(placed) == len(set(placed)) and set(placed) == set(view['nodes']), 'Invalid view columns'
        for edge in view['edges']:
            assert {edge['from'], edge['to']} <= set(view['nodes']), 'Unknown connection endpoint'
            assert edge['evidence'], 'Connection needs evidence'
    for flow in data['flows']:
        assert flow['steps'], 'A flow needs at least one step'
        assert all(step['node'] in ids and step['evidence'] for step in flow['steps'])
        if 'sequence' in flow:
            actors = [actor['id'] for actor in flow['sequence']['participants']]
            assert len(actors) == len(set(actors)) and len(actors) >= 2, 'Invalid sequence participants'
            for message in flow['sequence']['messages']:
                assert {message['from'], message['to']} <= set(actors), 'Unknown sequence participant'
                assert 0 <= message['step'] < len(flow['steps']), 'Unknown sequence step'


def markdown(data):
    lines = [f"# {data['title']}", '', data['snapshot'], '', f"Scope: {data['scope']}", '', '## Architecture summary']
    lines += ['- ' + text for text in data['summary']]
    for node in data['nodes']:
        lines += ['', f"## {node['label']} [{node['id']}]", node['purpose'], '', 'Pattern: ' + node['pattern'], 'State: ' + node['state']]
        lines += ['- Contract: ' + text for text in node['contracts']]
        lines += ['- Source: ' + text for text in node['sources']]
    for view in data['views']:
        lines += ['', '## Connections: ' + view['label']]
        lines += [f"- {edge['from']} — {edge['label']} → {edge['to']} ({edge['evidence']})" for edge in view['edges']]
    for flow in data['flows']:
        lines += ['', '## Flow: ' + flow['title']]
        lines += [f"{i}. [{step['node']}] {step['text']} ({step['evidence']})" for i, step in enumerate(flow['steps'], 1)]
        if 'sequence' in flow:
            lines += ['', 'Messages:']
            actors = {actor['id']: actor['label'] for actor in flow['sequence']['participants']}
            lines += [f"- {actors[msg['from']]} → {actors[msg['to']]}: {msg['label']} (step {msg['step'] + 1}; {'response' if msg.get('response') else 'request/update'})" for msg in flow['sequence']['messages']]
        lines += ['Failure and recovery: ' + flow['failure']]
    for finding in data['findings']:
        lines += ['', f"## {finding['classification']}: {finding['title']}", finding['detail'], 'Keep separate: ' + finding['preserve']]
        lines += ['- Source: ' + source for source in finding['sources']]
    for task in data['delegation']:
        lines += ['', '## Delegation: ' + task['title'], 'Scope: ' + task['scope'], 'Contracts: ' + task['contracts']]
        lines += ['- Check: ' + check for check in task['checks']]
        lines += ['- Source: ' + source for source in task['sources']]
    lines += ['', '## Limits'] + ['- ' + text for text in data['unknowns']]
    return '\n'.join(lines) + '\n'


def main():
    model, output = Path(sys.argv[1]), Path(sys.argv[2])
    data = json.loads(model.read_text())
    validate(data)
    output.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(data, ensure_ascii=False).replace('<', '\\u003c').replace('>', '\\u003e').replace('&', '\\u0026')
    template = (Path(__file__).resolve().parent.parent / 'assets' / 'explorer.html').read_text()
    page = template.replace('__TITLE__', html.escape(data['title'])).replace('__DATA__', encoded)
    (output / 'index.html').write_text(page)
    (output / 'architecture.md').write_text(markdown(data))
    print(output / 'index.html')
    print(output / 'architecture.md')


if __name__ == '__main__':
    main()
