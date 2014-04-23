---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

module Flowbox.ZMQ.RPC.RPC where

import Control.Monad.Trans.Either

import Flowbox.Prelude



type RPC a = EitherT Error IO a


type Error = String
