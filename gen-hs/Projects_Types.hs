{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-missing-fields #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}
{-# OPTIONS_GHC -fno-warn-unused-matches #-}

-----------------------------------------------------------------
-- Autogenerated by Thrift Compiler (0.9.0)                      --
--                                                             --
-- DO NOT EDIT UNLESS YOU ARE SURE YOU KNOW WHAT YOU ARE DOING --
-----------------------------------------------------------------

module Projects_Types where
import Prelude ( Bool(..), Enum, Double, String, Maybe(..),
                 Eq, Show, Ord,
                 return, length, IO, fromIntegral, fromEnum, toEnum,
                 (.), (&&), (||), (==), (++), ($), (-) )

import Control.Exception
import Data.ByteString.Lazy
import Data.Hashable
import Data.Int
import Data.Text.Lazy ( Text )
import qualified Data.Text.Lazy as TL
import Data.Typeable ( Typeable )
import qualified Data.HashMap.Strict as Map
import qualified Data.HashSet as Set
import qualified Data.Vector as Vector

import Thrift
import Thrift.Types ()

import Attrs_Types


type ProjectID = Int32

data Project = Project{f_Project_name :: Maybe Text,f_Project_path :: Maybe Text,f_Project_attribs :: Maybe Attrs_Types.Attributes,f_Project_projectID :: Maybe Int32} deriving (Show,Eq,Typeable)
instance Hashable Project where
  hashWithSalt salt record = salt   `hashWithSalt` f_Project_name record   `hashWithSalt` f_Project_path record   `hashWithSalt` f_Project_attribs record   `hashWithSalt` f_Project_projectID record  
write_Project oprot record = do
  writeStructBegin oprot "Project"
  case f_Project_name record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("name",T_STRING,1)
    writeString oprot _v
    writeFieldEnd oprot}
  case f_Project_path record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("path",T_STRING,2)
    writeString oprot _v
    writeFieldEnd oprot}
  case f_Project_attribs record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("attribs",T_STRUCT,3)
    Attrs_Types.write_Attributes oprot _v
    writeFieldEnd oprot}
  case f_Project_projectID record of {Nothing -> return (); Just _v -> do
    writeFieldBegin oprot ("projectID",T_I32,4)
    writeI32 oprot _v
    writeFieldEnd oprot}
  writeFieldStop oprot
  writeStructEnd oprot
read_Project_fields iprot record = do
  (_,_t3,_id4) <- readFieldBegin iprot
  if _t3 == T_STOP then return record else
    case _id4 of 
      1 -> if _t3 == T_STRING then do
        s <- readString iprot
        read_Project_fields iprot record{f_Project_name=Just s}
        else do
          skip iprot _t3
          read_Project_fields iprot record
      2 -> if _t3 == T_STRING then do
        s <- readString iprot
        read_Project_fields iprot record{f_Project_path=Just s}
        else do
          skip iprot _t3
          read_Project_fields iprot record
      3 -> if _t3 == T_STRUCT then do
        s <- (read_Attributes iprot)
        read_Project_fields iprot record{f_Project_attribs=Just s}
        else do
          skip iprot _t3
          read_Project_fields iprot record
      4 -> if _t3 == T_I32 then do
        s <- readI32 iprot
        read_Project_fields iprot record{f_Project_projectID=Just s}
        else do
          skip iprot _t3
          read_Project_fields iprot record
      _ -> do
        skip iprot _t3
        readFieldEnd iprot
        read_Project_fields iprot record
read_Project iprot = do
  _ <- readStructBegin iprot
  record <- read_Project_fields iprot (Project{f_Project_name=Nothing,f_Project_path=Nothing,f_Project_attribs=Nothing,f_Project_projectID=Nothing})
  readStructEnd iprot
  return record
