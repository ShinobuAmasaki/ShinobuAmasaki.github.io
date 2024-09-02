import re
import yaml

def replace_domain(url):
    return re.sub(r'https://shinobuamasaki.github.io/(.*)', r'\1', url)

# YAMLファイルの読み込み
with open('feed.yaml', 'r', encoding='utf-8') as file:
    rss_feed = next(yaml.safe_load_all(file))


for item in rss_feed.get('item', []):
    if 'link' in item:
        item['link'] = replace_domain(item['link'])

# Markdownリストの生成
markdown_list = "## Posts\n"
for item in rss_feed['item']:
    date = item.get('date', '')
    title = item.get('title', '')
    link = item.get('link', '')
    markdown_list += f'- *{date}:*<br class="br-sp"> [{title}]({link})\n'

print(markdown_list)

# Markdownファイルに保存
with open('index_posts.md', 'w', encoding='utf-8') as md_file:
    md_file.write(markdown_list)
