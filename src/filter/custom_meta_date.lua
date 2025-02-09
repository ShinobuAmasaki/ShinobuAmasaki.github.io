local created_date = os.getenv("CREATED_DATE") or "N/A"

function Meta(m)
   m.date = pandoc.MetaInlines(created_date)
   return m
end