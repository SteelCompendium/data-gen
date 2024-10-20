function Link(el)
  -- Replace links ending with .html to .md
  el.target = el.target:gsub("%.html$", ".md")
  return el
end
