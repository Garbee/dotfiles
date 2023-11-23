# Mas List

To recreate a formatted list of App Store installed items
run the following:

```shell
 while IFS= read -r line; do
    echo "$line"
done <<< "$(mas list | awk '{print "appStoreApps+=(\""$1"\") # " substr($0, index($0,$2))}' | sed 's/(\([^()]*\))$//' | sed 's/^ *//;s/ *$//')"
```

This gets the list from mas, pulls the names and ids while
stripping the version off the names and trimming any extra
whitespace. Nice clean list to update the install lists from.
