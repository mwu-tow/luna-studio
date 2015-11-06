module Reactive.State.ConnectionPen where


import Utils.PreludePlus
import Utils.Vector
import Object.Object
import Data.Aeson (ToJSON)


data DrawingType = Connecting | Disconnecting deriving (Show, Eq, Generic)

data Drawing = Drawing { _previousPos  :: Vector2 Int
                       , _drawingType  :: DrawingType
                       , _lastNode     :: Maybe NodeId
                       , _visitedNodes :: [NodeId]
                       } deriving (Eq, Show, Generic)


data State = State { _drawing  :: Maybe Drawing
                   } deriving (Eq, Show, Generic)


makeLenses ''State
makeLenses ''Drawing

instance ToJSON DrawingType
instance ToJSON Drawing
instance ToJSON State

instance Default State where
    def = State def
