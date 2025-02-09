# Step 1: Run Python scripts
python src/script/generate_rss_feed_yaml.py
python src/script/generate_index_header.py
python src/script/generate_posts_list.py

# Step 2: Concatenate markdown files into index.md
Get-Content index_header.md, src/index_contents.md, index_posts.md, src/index_footer.md | Set-Content src/index.md

# Step 3: Create 'site/items' directory if it doesn't exist
if (-not (Test-Path "site/items")) {
   New-Item -ItemType Directory -Path "site/items"
}

# Step 4: Generate HTML for index page
pandoc -f markdown -t html --template=src/templates/index-template.html --eol=lf --toc --no-highlight -V pagetitle="index.html" src/index.md > site/index.html

# Step 5: Convert markdown files in 'src/before_pub' to HTML
Get-ChildItem src/before_pub/*.md | ForEach-Object {
   $filename = "$($_.BaseName).html"
   $CreatedDate = git log --diff-filter=A --format="%ci" -- $_ | Select-Object -First 1
   $UpdatedDate = git log -1 --format="%ci" -- $_

   $env:CREATED_DATE = $CreatedDate.Substring(0,10)
   $env:UPDATED_DATE = $UpdatedDate.Substring(0,10)

   pandoc -f markdown -t html --template=src/templates/template.html --lua-filter=src/filter/custom_meta_date.lua --lua-filter=src/filter/replace_dates.lua --preserve-tabs --eol=lf --toc --no-highlight -V pagetitle=$filename --mathjax $_.FullName > "site/items/$filename"
   Write-Output $filename
}

# Step 6: Convert markdown files in 'src/items' to HTML
Get-ChildItem src/items/*.md | ForEach-Object {
   $filename = "$($_.BaseName).html"

   $CreatedDate = git log --diff-filter=A --format="%ci" -- $_ | Select-Object -First 1
   $UpdatedDate = git log -1 --format="%ci" -- $_

   $env:CREATED_DATE = $CreatedDate.Substring(0,10)
   $env:UPDATED_DATE = $UpdatedDate.Substring(0,10)

   pandoc -f markdown -t html --template=src/templates/template.html --lua-filter=src/filter/custom_meta_date.lua --lua-filter=src/filter/replace_dates.lua --preserve-tabs --eol=lf --toc --no-highlight -V pagetitle=$filename --mathjax $_.FullName > "site/items/$filename"
   Write-Output $filename
}

# Step 7: Convert markdown files in 'src/items/with-katex' to HTML
Get-ChildItem src/items/with-katex/*.md | ForEach-Object {
   $filename = "$($_.BaseName).html"
   
   $CreatedDate = git log --diff-filter=A --format="%ci" -- $_ | Select-Object -First 1
   $UpdatedDate = git log -1 --format="%ci" -- $_
   
   $env:CREATED_DATE = $CreatedDate.Substring(0,10)
   $env:UPDATED_DATE = $UpdatedDate.Substring(0,10)
   
   pandoc -f markdown -t html5 --template=src/templates/template-with-katex.html --lua-filter=src/filter/custom_meta_date.lua --lua-filter=src/filter/replace_dates.lua --preserve-tabs --eol=lf --toc --no-highlight -V pagetitle=$filename --mathjax $_.FullName > "site/items/$filename"
   Write-Output $filename
}

# Step 8: Generate RSS feed
pandoc feed.yaml -f markdown -t html --template ./src/rss/template.rss --metadata title="RSS feed for Amasaki Shinobu's Website" -o feed.rss

# Step 9: Create 'site/rss' directory if it doesn't exist
if (-not (Test-Path "site/rss")) {
   New-Item -ItemType Directory -Path "site/rss"
}

# Step 10: Copy resources
Copy-Item -Recurse -Force src/img site/img
Copy-Item -Recurse -Force style/* site/style/.
Copy-Item -Force favicon.ico site/.
Copy-Item -Force feed.rss site/rss/.

Write-Output '*' > site/.gitignore
Remove-Item -Recurse -Force index_header.md, index_posts.md, src/index.md
