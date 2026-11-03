// Add folders to the Favorites section of the Finder sidebar, leaving
// existing favorites (and their order) alone. New ones go at the end.
//
//   swift finder-favorites.swift [--dry-run] PATH...
//
// Prints one line per PATH: "<status>\t<path>", where status is one of
// added, would-add (dry run), present, missing (no such folder), failed.
// Exits non-zero only if the favorites list can't be opened at all.
//
// Finder keeps the sidebar in a protected .sfl3 file that `defaults` can't
// write, so this goes through the (deprecated, but still working)
// LSSharedFileList API. Run by install/macos-settings.sh.

import CoreServices
import Foundation

var args = Array(CommandLine.arguments.dropFirst())
let dryRun = args.first == "--dry-run"
if dryRun { args.removeFirst() }

guard
  let list = LSSharedFileListCreate(
    nil, kLSSharedFileListFavoriteItems.takeUnretainedValue(), nil)?.takeRetainedValue()
else {
  FileHandle.standardError.write("Could not open the Finder sidebar favorites.\n".data(using: .utf8)!)
  exit(1)
}

func normalized(_ url: URL) -> String {
  url.standardizedFileURL.resolvingSymlinksInPath().path
}

func currentFavorites() -> Set<String> {
  var seed: UInt32 = 0
  let items = LSSharedFileListCopySnapshot(list, &seed)?.takeRetainedValue() as? [LSSharedFileListItem] ?? []
  var paths = Set<String>()
  for item in items {
    if let url = LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() as URL? {
      paths.insert(normalized(url))
    }
  }
  return paths
}

// kLSSharedFileListItemLast is a sentinel pointer (0x2), not a real object:
// passing it through Swift's imported signature retains it and crashes. Call
// the C function with raw pointers instead.
typealias InsertFn = @convention(c) (
  UnsafeRawPointer, UnsafeRawPointer, UnsafeRawPointer?, UnsafeRawPointer?,
  UnsafeRawPointer, UnsafeRawPointer?, UnsafeRawPointer?
) -> UnsafeRawPointer?

let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)  // RTLD_DEFAULT
guard
  let insertSym = dlsym(rtldDefault, "LSSharedFileListInsertItemURL"),
  let lastSym = dlsym(rtldDefault, "kLSSharedFileListItemLast")
else {
  FileHandle.standardError.write("LSSharedFileList API not available.\n".data(using: .utf8)!)
  exit(1)
}
let insert = unsafeBitCast(insertSym, to: InsertFn.self)
let itemLast = lastSym.load(as: UnsafeRawPointer.self)

var present = currentFavorites()

for path in args {
  let url = URL(fileURLWithPath: path, isDirectory: true)
  let key = normalized(url)
  var isDir: ObjCBool = false

  if present.contains(key) {
    print("present\t\(path)")
  } else if !FileManager.default.fileExists(atPath: key, isDirectory: &isDir) || !isDir.boolValue {
    print("missing\t\(path)")
  } else if dryRun {
    print("would-add\t\(path)")
  } else {
    let cfList = Unmanaged.passUnretained(list).toOpaque()
    let cfURL = Unmanaged.passUnretained(url as CFURL).toOpaque()
    if let item = insert(cfList, itemLast, nil, nil, cfURL, nil, nil) {
      Unmanaged<AnyObject>.fromOpaque(item).release()  // returned retained
      present.insert(key)
      print("added\t\(path)")
    } else {
      print("failed\t\(path)")
    }
  }
}
