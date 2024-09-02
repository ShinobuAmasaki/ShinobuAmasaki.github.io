import os
import yaml
from datetime import datetime
import pytz
import platform

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

items = []
timezone = pytz.timezone('Asia/Tokyo')
now =datetime.now(timezone)

for filename in os.listdir(markdown_dir):
    if filename.endswith('.md'):
        filepath = os.path.join(markdown_dir, filename)
        with open(filepath, 'r', encoding='utf-8') as file:
            content = file.read()
            # Extract YAML header
            front_matter = content.split('---')[1]
            item = yaml.safe_load(front_matter)
            items.append(item)

for filename in os.listdir(markdown_katex_dir):
    if filename.endswith('.md'):
        filepath = os.path.join(markdown_katex_dir, filename)
        with open(filepath, 'r', encoding='utf-8') as file:
            content = file.read()
            # Extract YAML header
            front_matter = content.split('---')[1]
            item = yaml.safe_load(front_matter)
            items.append(item)

for filename in os.listdir(articles_on_qiita):
    if filename.endswith('.md'):
        filepath = os.path.join(articles_on_qiita, filename)
        with open(filepath, 'r', encoding='utf-8') as file:
            content = file.read()
            # Extract YAML header
            front_matter = content.split('---')[1]
            item = yaml.safe_load(front_matter)
            items.append(item)

pub_date = now.strftime('%a, %d %b %Y %H:%M:%S %z')

for item in items:
    if 'date' not in item:
        print("Error: 'date'key is missing: ", item)

rss_feed = {
    'title': "RSS feed for Amasaki Shinobu's Website",
    'pubDate': pub_date,
    'item': sorted(items, key=lambda x: x['date'], reverse=True) # 新しい順に並び替え
}

with open(rss_yaml_file, 'w', encoding='utf-8') as file:
    yaml.dump(rss_feed, file, allow_unicode=True, sort_keys=False)

print(f"RSS YAML file has been generated: {rss_yaml_file}")