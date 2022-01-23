
import os, fnmatch

def findReplace(directory, find, replace, filePattern):
    for path, dirs, files in os.walk(os.path.abspath(directory)):
        for filename in fnmatch.filter(files, filePattern):
            filepath = os.path.join(path, filename)
            with open(filepath) as f:
                s = f.read()
            s = s.replace(find, replace)
            with open(filepath, "w") as f:
                f.write(s)

collection = "/Users/dried/Repositories/Baudi/portal-app/dist"

old = 'https://baumann-digital.de'
new = 'http://localhost:8080/exist/apps/baudiApp'

findReplace(collection, old, new, "*.*")