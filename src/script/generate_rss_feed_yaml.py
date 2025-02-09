import os
import yaml
from datetime import datetime
from zoneinfo import ZoneInfo
import pytz
import platform
import subprocess

class FixIndentDumper(yaml.Dumper):
    def increase_indent(self, flow=False, indentless=False):
        return super(FixIndentDumper, self).increase_indent(flow, False)

system = platform.system()

if system == 'Windows':
    markdown_dir = "src\\items"
    markdown_katex_dir = "src\\items\\with-katex"
    articles_on_qiita = "src\\items\\articles-on-qiita-and-devto"
else:
    markdown_dir = "src/items"
    markdown_katex_dir = "src/items/with-katex"
    articles_on_qiita = "src/items/articles-on-qiita-and-devto"


rss_yaml_file = "feed.yaml"

tz = pytz.timezone('Asia/Tokyo')
zi = ZoneInfo("Asia/Tokyo")
now =datetime.now(zi)

items = []

for filename in os.listdir(markdown_dir):
    if filename.endswith('.md'):
        filepath = os.path.join(markdown_dir, filename)
        with open(filepath, 'r', encoding='utf-8') as file:
            content = file.read()
            # Extract YAML header
            front_matter = content.split('---')[1]
            item = yaml.safe_load(front_matter)
            appended_date = subprocess.run(['git', 'log' ,'--diff-filter=A', '--format="%ci",' '--', '{filepath}'], capture_output=True)
            item["appended_date"] = appended_date.stdout.decode("utf-8").strip()
        items.append(item)

for filename in os.listdir(markdown_katex_dir):
    if filename.endswith('.md'):
        filepath = os.path.join(markdown_katex_dir, filename)
        with open(filepath, 'r', encoding='utf-8') as file:
            content = file.read()
            # Extract YAML header
            front_matter = content.split('---')[1]
            item = yaml.safe_load(front_matter)
            appended_date = subprocess.run(['git', 'log' ,'--diff-filter=A', '--format="%ci",' '--', '{filepath}'], capture_output=True)
            item["appended_date"] = appended_date.stdout.decode("utf-8").strip()
        items.append(item)

for filename in os.listdir(articles_on_qiita):
    if filename.endswith('.md'):
        filepath = os.path.join(articles_on_qiita, filename)
        with open(filepath, 'r', encoding='utf-8') as file:
            content = file.read()
            # Extract YAML header
            front_matter = content.split('---')[1]
            item = yaml.safe_load(front_matter)
            appended_date = subprocess.run(['git', 'log' ,'--diff-filter=A', '--format="%ci",' '--', '{filepath}'], capture_output=True)
            item["appended_date"] = appended_date.stdout.decode("utf-8").strip()
        items.append(item)
        

pub_date = now.strftime('%a, %d %b %Y %H:%M:%S %z')

for item in items:
    if 'date' not in item:
        if item['appended_date'] != "":
            dt = datetime.strptime(item['appended_date'][:19], "%Y-%m-%d %H:%M:%S")
            item['date'] = dt
            item['date'] = item['date'].astimezone(zi)
        else:
            item['date'] = now
            item['date'] = item['date'].astimezone(zi)

    else:
        item['date'] = datetime.combine(item['date'], datetime.min.time())
        item['date'] = item['date'].astimezone(zi)

items = sorted(items, key=lambda x:x['date'], reverse=True) # 新しい順に並び替え
for item in items:
    item['date'] = item['date'].strftime("%Y-%m-%d %H:%M:%S %Z") #%a, %d %b %Y %H:%M:%S %Z")

rss_feed = {
    'title': "RSS feed for Amasaki Shinobu's Website",
    'pubDate': pub_date,
    'item': items
}

with open(rss_yaml_file, 'w', encoding='utf-8') as file:
    file.write("---\n")
    yaml.dump(rss_feed, file, allow_unicode=True, sort_keys=False, default_flow_style=False, Dumper=FixIndentDumper)
    file.write("---\n")

print(f"RSS YAML file has been generated: {rss_yaml_file}")
