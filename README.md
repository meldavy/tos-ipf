# tos-ipf
## TODSDump.exe

TOSDump.exe is used to extract and dump all ipf files.

Use `TOSDump.exe <path-to-tos-dir>` to use. It detects tos dir by checking for `/data` and `/patch` dir.

But don't actually use real tos dir, because it uses IPKUnpacker, which decrypts all ipf. Copy `/data` and `/patch` dir to any folder, and use that dir as the argument to TOSDump.
  
Because IPKUnpacker's extension-based extraction seems to be broken and extracts every file regardless of extension (maybe I just have a bad version), TOSDump performs cleanup on the resulting `extract` dir by deleting all non-lua and xml files, and then deleting all empty directories recursively. Thus, only XML and lua files will remain.

## MessageDump.exe

MessageDump.exe is a tool used after executing TOSDump.

Use `MessageDump.exe <path>` to use. It checks for all lua files in its path and finds all broadcasted messages and its data and dumps it into a wiki table format.

The regex used to extract message data is not accurate and resulting file may require minor manual cleanup.