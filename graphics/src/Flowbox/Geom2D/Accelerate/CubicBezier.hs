---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Flowbox.Geom2D.Accelerate.CubicBezier where

import           Data.Array.Accelerate
import           Data.Array.Accelerate.Smart
import           Data.Array.Accelerate.Tuple
import           Data.Array.Accelerate.Array.Sugar
import           Data.Typeable

import Math.Coordinate.Cartesian (Point2(..))
import Flowbox.Prelude



data CubicBezier a = CubicBezier (Point2 a) (Point2 a) (Point2 a) (Point2 a) deriving (Eq, Ord, Show,Typeable)

----------------------------------------------------------------------------------
---- CubicBezier accelerate tuple instances
----------------------------------------------------------------------------------
instance Functor CubicBezier where
    fmap f (CubicBezier a b c d) = CubicBezier (fmap f a) (fmap f b) (fmap f c) (fmap f d)

instance Applicative CubicBezier where
    pure a = CubicBezier (pure a) (pure a) (pure a) (pure a)
    {-# INLINE pure #-}
    CubicBezier a b c d <*> CubicBezier e f g h = CubicBezier (a <*> e) (b <*> f) (c <*> g) (d <*> h)
    {-# INLINE (<*>) #-}

type instance EltRepr (CubicBezier a)  = EltRepr ((a, a), (a, a), (a, a), (a, a))
type instance EltRepr' (CubicBezier a) = EltRepr' ((a, a), (a, a), (a, a), (a, a))

instance Elt a => Elt (CubicBezier a) where
  eltType _ = eltType (undefined :: ((a,a),(a,a),(a,a),(a,a)))
  toElt e = case toElt e of
     ((a, b), (c, d), (e, f), (g, h)) -> CubicBezier (Point2 a b) (Point2 c d) (Point2 e f) (Point2 g h)
  fromElt (CubicBezier (Point2 a b) (Point2 c d) (Point2 e f) (Point2 g h)) = fromElt ((a, b), (c, d), (e, f), (g, h))

  eltType' _ = eltType' (undefined :: ((a,a),(a,a),(a,a),(a,a)))
  toElt' e = case toElt' e of
     ((a, b), (c, d), (e, f), (g, h)) -> CubicBezier (Point2 a b) (Point2 c d) (Point2 e f) (Point2 g h)
  fromElt' (CubicBezier (Point2 a b) (Point2 c d) (Point2 e f) (Point2 g h)) = fromElt' ((a, b), (c, d), (e, f), (g, h))

instance IsTuple (CubicBezier a) where
  type TupleRepr (CubicBezier a) = TupleRepr ((a,a),(a,a),(a,a),(a,a))
  fromTuple (CubicBezier (Point2 a b) (Point2 c d) (Point2 e f) (Point2 g h)) = fromTuple ((a, b), (c, d), (e, f), (g, h))
  toTuple t = case toTuple t of
     ((a, b), (c, d), (e, f), (g, h)) -> CubicBezier (Point2 a b) (Point2 c d) (Point2 e f) (Point2 g h)

instance (Lift Exp a, Elt (Plain a)) => Lift Exp (CubicBezier a) where
  type Plain (CubicBezier a) = CubicBezier (Plain a)
  --  lift = Exp . Tuple . F.foldl SnocTup NilTup
  lift (CubicBezier (Point2 a b) (Point2 c d) (Point2 e f) (Point2 g h)) =
    Exp $ Tuple $ NilTup `SnocTup`
    (Exp $ Tuple $ NilTup `SnocTup` lift a `SnocTup` lift b)
     `SnocTup`
    (Exp $ Tuple $ NilTup `SnocTup` lift c `SnocTup` lift d)
    `SnocTup`
    (Exp $ Tuple $ NilTup `SnocTup` lift e `SnocTup` lift f)
    `SnocTup`
    (Exp $ Tuple $ NilTup `SnocTup` lift g `SnocTup` lift h)

instance (Elt a, e ~ Exp a) => Unlift Exp (CubicBezier e) where
  unlift t = let
    p1 = Exp $ SuccTupIdx (SuccTupIdx (SuccTupIdx ZeroTupIdx)) `Prj` t
    p2 = Exp $ SuccTupIdx (SuccTupIdx ZeroTupIdx) `Prj` t
    p3 = Exp $ SuccTupIdx ZeroTupIdx `Prj` t
    p4 = Exp $ ZeroTupIdx `Prj` t
    in CubicBezier
      (Point2 (Exp $ SuccTupIdx ZeroTupIdx `Prj` p1) (Exp $ ZeroTupIdx `Prj` p1))
      (Point2 (Exp $ SuccTupIdx ZeroTupIdx `Prj` p2) (Exp $ ZeroTupIdx `Prj` p2))
      (Point2 (Exp $ SuccTupIdx ZeroTupIdx `Prj` p3) (Exp $ ZeroTupIdx `Prj` p3))
      (Point2 (Exp $ SuccTupIdx ZeroTupIdx `Prj` p4) (Exp $ ZeroTupIdx `Prj` p4))
