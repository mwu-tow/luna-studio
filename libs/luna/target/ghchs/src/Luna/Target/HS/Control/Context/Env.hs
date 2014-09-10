---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE CPP #-}

module Luna.Target.HS.Control.Context.Env where

import GHC.Generics
import Control.PolyMonad
import Control.PolyApplicative
import Control.Applicative
import Control.Monad.Morph
import Data.Typeable (Typeable)

import Flowbox.Utils

--------------------------------------------------------------------------------
-- Structures
--------------------------------------------------------------------------------

data Pure a = Pure a deriving (Eq, Ord, Typeable, Generic)

newtype IOS s a = IOS (IO (s a)) deriving (Show)

newtype PureS s a = PureS (Pure (s a)) deriving (Typeable)

fromPure (Pure a) = a
fromPureS (PureS a) = a

fromIOS (IOS a) = a

--------------------------------------------------------------------------------
-- Utils
--------------------------------------------------------------------------------

returnPure :: a -> Pure a
returnPure = return

returnIO :: a -> IO a
returnIO = return



--------------------------------------------------------------------------------
-- Type classes
--------------------------------------------------------------------------------

class IOEnv m where
    toIOEnv :: m a -> IO a


--------------------------------------------------------------------------------
-- Type families
--------------------------------------------------------------------------------

type family EnvMerge a b where
  EnvMerge Pure Pure = Pure
  EnvMerge a    b    = IO

type family EnvMerge2 a b where
  EnvMerge2 PureS PureS = PureS
  EnvMerge2 a    b      = IOS

type family GetEnv t where
    GetEnv Pure  = Pure
    GetEnv IO    = IO
    GetEnv (t m) = GetEnv m
    

--------------------------------------------------------------------------------
-- Instances
--------------------------------------------------------------------------------

instance Show a => Show (Pure a) where
#ifdef DEBUG
    show (Pure a) = "Pure (" ++ child ++ ")" where
        child = show a
        content = if ' ' `elem` child then "(" ++ child ++ ")" else child
#else
    show (Pure a) = show a
#endif


instance Show (s a) => Show (PureS s a) where
#ifdef DEBUG
    show (PureS (Pure a)) = "PureS (" ++ child ++ ")" where
        child = show a
        content = if ' ' `elem` child then "(" ++ child ++ ")" else child
#else
    show (PureS (Pure a)) = show a
#endif

---

instance Monad Pure where
    return = Pure
    (Pure a) >>= f = f a

instance Functor Pure where
    fmap f (Pure a) = Pure (f a)

instance Applicative Pure where
    pure = Pure
    (Pure f) <*> (Pure a) = Pure $ f a


instance MonadMorph IO IO where
    morph = id

instance MonadMorph Pure Pure where
    morph = id

instance MonadMorph Pure IO where
    morph = return . fromPure

---

instance IOEnv Pure where
    toIOEnv = return . fromPure

instance IOEnv IO where
    toIOEnv = id 