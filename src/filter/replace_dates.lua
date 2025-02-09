local created_date = os.getenv("CREATED_DATE") or "N/A"
local updated_date = os.getenv("UPDATED_DATE") or "N/A"

function Pandoc(elem)
   for i, v in ipairs(elem.blocks) do
      if v.t == "Para" then

         local u = v.content
         for j = 1, #u do

            if u[j].t == "Str" and u[j].text == "{{CREATED_DATE}}" then
               v.content[j] = pandoc.Str(created_date)
            end

            if u[j].t == "Str" and u[j].text == "{{UPDATED_DATE}}" then
               v.content[j] = pandoc.Str(updated_date)
            end
         end
      end
   end
   return elem
end