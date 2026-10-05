# Haskell Relational Tables
 
A Haskell implementation of in-memory relational table operations, built for university functional programming coursework. Tables are schema-free lists of rows, and each row maps column names to values. The module provides the core relational operations: listing columns, projection, joining and renaming, implemented using `Data.Map` and `Data.Set`.
 
> This implements four functions against fixed type definitions and function signatures defined by the coursework specification. The types and declarations in `Table.hs` were supplied and must not change, because they are relied on for automatic testing.
 
## Features
 
- **Column discovery**: `columnNames` returns the set of all column names that appear in any row of a table.
- **Projection**: `projectTable` keeps only the requested columns and drops any row left with no columns.
- **Efficient joins**: `joinTables` builds an index over the second table so it avoids a nested-loop join. This gives roughly O((n + m) log m + k) time instead of O(n × m).
- **Correct join semantics**:
  - Rows missing the join column never match.
  - Rows that match more than one row produce every combination.
  - Values from the first table take precedence on shared columns.
- **Simultaneous renaming**: `renameTable` applies all renames at once, so `[("x","y"), ("y","x")]` swaps two columns cleanly.
- **Collision handling**: when a renamed column collides with an existing column, the renamed value replaces it. Renames whose old column is missing from a row are ignored.
## Project Structure
 
```
.
├── Table.hs     # Type definitions and all four table operations
└── README.md
```
 
## Prerequisites
 
- GHC (any recent version, installable via [GHCup](https://www.haskell.org/ghcup/))
- The `containers` package, which ships with GHC
## Build Instructions
 
1. Download or clone the repository. It contains `Table.hs`.
2. Open a terminal in the project folder and load the module into GHCi:
```bash
   ghci Table.hs
```
 
   To check that it compiles without the REPL, run:
 
```bash
   ghc -c Table.hs
```
 
## Running Examples
 
From inside GHCi:
 
```haskell
import qualified Data.Map as Map
import qualified Data.Set as Set
 
let people = [ Map.fromList [("id","1"), ("name","Ana")]
             , Map.fromList [("id","2"), ("name","Ben")] ]
 
let pets   = [ Map.fromList [("owner","1"), ("pet","Cat")]
             , Map.fromList [("owner","1"), ("pet","Dog")] ]
 
columnNames people
-- fromList ["id","name"]
 
projectTable (Set.fromList ["name"]) people
-- [fromList [("name","Ana")],fromList [("name","Ben")]]
 
joinTables "id" "owner" people pets
-- [fromList [("id","1"),("name","Ana"),("owner","1"),("pet","Cat")],
--  fromList [("id","1"),("name","Ana"),("owner","1"),("pet","Dog")]]
 
renameTable [("id","name"), ("name","id")] people
-- [fromList [("id","Ana"),("name","1")],fromList [("id","Ben"),("name","2")]]
```
 
## Implementation Overview
 
The data model is:
 
```haskell
type Table      = [Row]
type Row        = Map ColumnName Value
type ColumnName = String
type Value      = String
```
 
**`joinTables`**
- Builds a `Map Value [Row]` index over `t2`, keyed on `col2`, using `Map.fromListWith (++)`.
- Looks up each row of `t1` in that index by its `col1` value.
- Merges each pair of matching rows with `Map.union`. `Map.union` is left-biased, so the `t1` values win on shared columns.
**`renameTable`**
- Reads every new value from the *original* row.
- Removes all old columns with `Map.withoutKeys`.
- Unions the renamed columns over what remains.
Because each rename reads from the original row, no rename can see the result of another one, so the renames behave as if they happen simultaneously.
 
**`projectTable`**
- Uses `Map.restrictKeys` to keep only the requested columns.
- Filters out rows that end up empty.
## Known Limitations / Notes
 
- **No test suite included.** The functions were checked manually in GHCi and against the coursework's automatic tests. A QuickCheck or HUnit suite would be a natural addition.
- **Values are untyped strings.** All cell values are `String`, as required by the specification, so there is no numeric comparison or typed schema.
- **Duplicate old names in `renameTable`.** If the same old column appears in more than one rename pair, it is copied to every new name. If two pairs share the same new name, the later pair wins.
- **Join output order** follows the row order of `t1`, then the order of matching rows in `t2`'s index. It is not sorted.
- **Not a cabal/stack project.** The module is a single standalone file, so there is no package configuration.
## Working Functionality Summary
 
- `columnNames`: returns every column name in the table
- `projectTable`: keeps the selected columns and removes empty rows
- `joinTables`: index-based join with all-combinations matching and `t1` precedence
- `renameTable`: simultaneous renames, with missing columns ignored and collisions replaced
All four functions compile against the supplied signatures and behave as specified on the coursework test cases.
 
