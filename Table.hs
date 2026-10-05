module Table where

import Data.Map (Map)
import qualified Data.Map as Map
import Data.Set (Set)
import qualified Data.Set as Set

type Table = [Row]
type Row = Map ColumnName Value
type ColumnName = String
type Value = String


-- Return all the column names occurring in the table.
columnNames :: Table -> Set ColumnName
columnNames table = Set.unions (map Map.keysSet table)

-- Return a table obtained by removing any column not in the set and
-- any row not containing any columns in the set.
projectTable :: Set ColumnName -> Table -> Table
projectTable cols table =
  filter (not . Map.null) (map projectRow table)
  where
    projectRow :: Row -> Row
    projectRow row = Map.restrictKeys row cols

-- Join two tables on common values in the named columns in the respective
-- tables.
joinTables :: ColumnName -> ColumnName -> Table -> Table -> Table
joinTables col1 col2 t1 t2 =
  concatMap joinRow t1
  where
    index :: Map Value [Row]
    index = Map.fromListWith (++) (concatMap indexRow t2)

    indexRow :: Row -> [(Value, [Row])]
    indexRow row =
      case Map.lookup col2 row of
        Just v  -> [(v, [row])]
        Nothing -> []

    joinRow :: Row -> [Row]
    joinRow row1 =
      case Map.lookup col1 row1 of
        Nothing -> []
        Just v  ->
          case Map.lookup v index of
            Nothing    -> []
            Just rows2 -> map (combine row1) rows2

    combine :: Row -> Row -> Row
    combine r1 r2 = Map.union r1 r2

-- Given a list of (oldname, newname) pairs, rename the indicated
-- columns of the table.
renameTable :: [(ColumnName, ColumnName)] -> Table -> Table
renameTable renames table =
  map renameRow table
  where
    oldSet :: Set ColumnName
    oldSet = Set.fromList (map fst renames)

    renameRow :: Row -> Row
    renameRow row =
      let base :: Row
          base = Map.withoutKeys row oldSet

          renamedPairs :: [(ColumnName, Value)]
          renamedPairs = concatMap (mkPair row) renames

          renamedMap :: Row
          renamedMap = Map.fromList renamedPairs
      in
      Map.union renamedMap base

    mkPair :: Row -> (ColumnName, ColumnName) -> [(ColumnName, Value)]
    mkPair row (old, new) =
      case Map.lookup old row of
        Just v  -> [(new, v)]
        Nothing -> []
