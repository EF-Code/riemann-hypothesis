import Lean.Elab.ParseImportsFast

def main (args : List String) : IO Unit := do
  let [listPath] := args | throw (IO.userError "Expected a path with one file per line")
  let paths ← IO.FS.lines listPath
  let stdout ← IO.getStdout
  for path in paths do
    let data ← IO.FS.readFile path
    let header ← Lean.parseImports' data path
    let imports := header.imports.map (fun imp => toString imp.module)
    stdout.putStrLn (String.intercalate "\t" (path :: imports.toList))
