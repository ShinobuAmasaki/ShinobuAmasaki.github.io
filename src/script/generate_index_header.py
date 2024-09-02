import datetime
import pytz

timezone = pytz.timezone('Asia/Tokyo')
current_time = datetime.datetime.now(timezone).strftime('%a, %d %b %Y %H:%M:%S %z')

yaml_header = f"""---
title: Amasaki Shinobu's Website
date: {current_time}
description: index.html
---

"""

with open('index_header.md', 'w') as file:
    file.write(yaml_header)