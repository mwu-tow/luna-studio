---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------
module Flowbox.Data.Version where

import           Flowbox.Prelude   



data Version = Version { major :: Int
                       , minor :: Int
                       , patch :: Int
                       , build :: String
                       , stage :: Stage
                       } deriving (Show, Eq, Ord)

data Stage = Alpha
           | Beta
           | Release
           | Final
           deriving (Show, Eq, Ord, Read)


mk :: Version
mk = Version 0 0 0 "" Final


str :: Version -> String
str v  = numStr v
      ++ case stage v of
              Final -> ""
              _     -> " " ++ show (stage v)
      ++ " (build " ++ build v ++ ")"


numStr :: Version -> String
numStr v  = show(major v) ++ "." 
         ++ show(minor v) ++ "." 
         ++ show(patch v)
         