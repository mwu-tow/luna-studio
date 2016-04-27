{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Data.Monoid                    ((<>))
import           Data.Default
import           Test.HUnit
import           Data.Text.Lazy                 (Text)
import qualified Data.Text.Lazy                 as Text

import           Text.ScopeSearcher.Item
import           Text.ScopeSearcher.QueryResult
import qualified Text.ScopeSearcher.Scope       as Scope
import qualified Text.ScopeSearcher.Searcher    as Searcher

import qualified Mock.NodeSearcher              as Mock


-- Helpers

assertMsg :: String -> String -> Int -> String
assertMsg query sugg ind = "'" <> sugg <> "' should be " <> show ind <> " on suggestions list for '" <> query <> "' query"

prepareTest :: String -> ([QueryResult], String -> Int -> String)
prepareTest query = (Scope.searchInScope False Mock.items $ Text.pack query, assertMsg query)

assertMatch :: String -> QueryResult -> QueryResult -> Assertion
assertMatch msg expQR resQR = assertEqual msg expQR (resQR { _score = def })

-- Query helpers

queryResult :: Text -> Text -> [Highlight] -> Text -> QueryResult
queryResult modl name hl tpe = QueryResult modl name name hl tpe def

functionType = "function"
moduleType   = "module"

-- Tests

testSearchApp :: Test
testSearchApp = let (suggestions, msg) = prepareTest "app" in TestCase $ do
    assertMatch (msg "APP"    0) (queryResult ""     "app"    [ Highlight 0 3 ] functionType) $ suggestions !! 0
    assertMatch (msg "APPend" 1) (queryResult "List" "append" [ Highlight 0 3 ] functionType) $ suggestions !! 1

testSearchCos :: Test
testSearchCos = let (suggestions, msg) = prepareTest "cos" in TestCase $ do
    assertMatch (msg "COS"   0) (queryResult "Double" "cos"   [ Highlight 0 3 ] functionType) $ suggestions !! 0
    assertMatch (msg "COSh"  1) (queryResult "Double" "cosh"  [ Highlight 0 3 ] functionType) $ suggestions !! 1
    assertMatch (msg "aCOS"  2) (queryResult "Double" "acos"  [ Highlight 1 3 ] functionType) $ suggestions !! 2
    assertMatch (msg "aCOSh" 3) (queryResult "Double" "acosh" [ Highlight 1 3 ] functionType) $ suggestions !! 3
    assertMatch (msg "COnSt" 4) (queryResult ""       "const" [ Highlight 0 2, Highlight 3 1 ] functionType) $ suggestions !! 4

testSearchDou :: Test
testSearchDou = let (suggestions, msg) = prepareTest "dou" in TestCase $ do
    assertMatch (msg "DOUble"   0) (queryResult ""    "Double"   [ Highlight 0 3 ] moduleType)   $ suggestions !! 0
    assertMatch (msg "toDOUble" 1) (queryResult "Int" "toDouble" [ Highlight 2 3 ] functionType) $ suggestions !! 1



testSearchAe :: Test
testSearchAe = let (suggestions, msg) = prepareTest "ae" in TestCase $ do
    assertMatch (msg "AppEnd"   0) (queryResult   "List" "append"   [ Highlight 0 1, Highlight 3 1 ] functionType) $ suggestions !! 0
    assertMatch (msg "tAkE"     1) (queryResult   "List" "take"     [ Highlight 1 1, Highlight 3 1 ] functionType) $ suggestions !! 1
    assertMatch (msg "tAkE"     2) (queryResult "String" "take"     [ Highlight 1 1, Highlight 3 1 ] functionType) $ suggestions !! 2
    assertMatch (msg "nEgAte"   3) (queryResult "Double" "negate"   [ Highlight 3 1, Highlight 5 1 ] functionType) $ suggestions !! 3
    assertMatch (msg "nEgAte"   4) (queryResult    "Int" "negate"   [ Highlight 3 1, Highlight 5 1 ] functionType) $ suggestions !! 4
    assertMatch (msg "reAdFilE" 5) (queryResult       "" "readFile" [ Highlight 2 1, Highlight 7 1 ] functionType) $ suggestions !! 5


main :: IO Counts
main = do
    runTestTT $ TestList [
          testSearchApp
        , testSearchCos
        , testSearchDou
        , testSearchAe
        ]