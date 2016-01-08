module Empire.API.Response where

import           Prologue

import           Data.Binary (Binary)

data ResultOk = Ok deriving (Generic, Show, Eq)

instance Binary ResultOk

data Response req upd = Update    { _request  :: req
                                  , _update   :: upd
                                  }
                      deriving (Generic, Show, Eq)

type SimpleResponse req = Response req ResultOk

makeLenses ''Response

instance (Binary req, Binary upd) => Binary (Response req upd)
