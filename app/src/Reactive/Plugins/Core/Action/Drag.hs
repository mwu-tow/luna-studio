module Reactive.Plugins.Core.Action.Drag where

import           Prelude       hiding       ( mapM_, forM_ )
import           Data.Foldable              ( mapM_, forM_ )
import           Control.Lens
import           Control.Applicative
import           Data.Default
import           Data.Maybe
import           Data.List
import           Data.Monoid
import           Data.Function
import           System.Mem

import           JS.Bindings
import           JS.Appjs
import           Object.Object
import qualified Object.Node    as Node     ( position )
import           Object.Node    hiding      ( position )
import           Event.Keyboard hiding      ( Event )
import qualified Event.Keyboard as Keyboard
import           Event.Mouse    hiding      ( Event, WithObjects )
import qualified Event.Mouse    as Mouse
import           Event.Event
import           Event.WithObjects
import           Utils.Vector
import           Utils.Wrapper
import           Utils.PrettyPrinter
import           Reactive.Plugins.Core.Action.Action
import           Reactive.Plugins.Core.Action.State.Drag
import qualified Reactive.Plugins.Core.Action.State.Selection as Selection
import qualified Reactive.Plugins.Core.Action.State.Camera    as Camera
import qualified Reactive.Plugins.Core.Action.State.Global    as Global


data ActionType = StartDrag
                | Moving
                | Dragging
                | StopDrag
                deriving (Eq, Show)

data Action = DragAction { _actionType :: ActionType
                         , _actionPos  :: Vector2 Int
                         }
              deriving (Eq, Show)


makeLenses ''Action


instance PrettyPrinter ActionType where
    display = show

instance PrettyPrinter Action where
    display (DragAction tpe point) = "dA(" <> display tpe <> " " <> display point <> ")"


toAction :: Event Node -> NodeCollection -> Maybe Action
toAction (Mouse (Mouse.Event tpe pos button keyMods)) nodes = case button of
    1                  -> case tpe of
        Mouse.Pressed  -> if isNoNode then Nothing
                                      else case keyMods of
                                           (KeyMods False False False False) -> Just (DragAction StartDrag pos)
                                           _                                 -> Nothing
        Mouse.Released -> Just (DragAction StopDrag pos)
        Mouse.Moved    -> Just (DragAction Moving   pos)
    _                  -> Nothing
    where isNoNode      = null nodes
toAction _ _ = Nothing

moveNodes :: Double -> Vector2 Int -> NodeCollection -> NodeCollection
moveNodes factor delta = fmap $ \node -> if node ^. selected then node & Node.position +~ deltaWs else node where
    deltaWs = deltaToWs factor delta

deltaToWs :: Double -> Vector2 Int -> Vector2 Double
deltaToWs factor delta = (/ factor) . fromIntegral <$> (negateSnd delta)

instance ActionStateUpdater Action where
    execSt newActionCandidate oldState = case newAction of
        Just action -> ActionUI newAction newState
        Nothing     -> ActionUI NoAction  newState
        where
        oldDrag                          = oldState ^. Global.drag . history
        oldNodes                         = oldState ^. Global.nodes
        camFactor                        = oldState ^. Global.camera . Camera.camera . Camera.factor
        emptySelection                   = null oldNodes
        newState                         = oldState & Global.iteration       +~ 1
                                                    & Global.drag  . history .~ newDrag
                                                    & Global.nodes           .~ newNodes
        newAction                        = case newActionCandidate of
            DragAction Moving pt        -> case oldDrag of
                Nothing                 -> Nothing
                _                       -> Just $ DragAction Dragging pt
            _                           -> Just newActionCandidate
        newNodes                         = case newActionCandidate of
            DragAction tpe point        -> case tpe of
                StopDrag                -> case oldDrag of
                    Just oldDragState   -> moveNodes camFactor deltaSum oldNodes
                        where prevPos    = oldDragState ^. dragCurrentPos
                              startPos   = oldDragState ^. dragStartPos
                              delta      = point - prevPos
                              deltaSum   = point - startPos
                    Nothing             -> oldNodes
                _                       -> oldNodes
        newDrag                          = case newActionCandidate of
            DragAction tpe point        -> case tpe of
                StartDrag               -> Just $ DragHistory point point point
                Moving                  -> if emptySelection then Nothing else case oldDrag of
                    Just oldDragState   -> Just $ DragHistory startPos prevPos point
                        where startPos   = oldDragState ^. dragStartPos
                              prevPos    = oldDragState ^. dragCurrentPos
                    Nothing             -> Nothing
                StopDrag                -> Nothing


instance ActionUIUpdater Action where
    updateUI (WithState action state) = case action of
        DragAction tpe pt            -> case tpe of
            StartDrag                -> return ()
            Moving                   -> return ()
            Dragging                 -> dragNodesUI deltaWs selNodes
            StopDrag                 -> moveNodesUI selNodes
            where
                allNodes              = state ^. Global.nodes
                selNodeIds            = state ^. Global.selection . Selection.nodeIds
                selNodes              = filter (\node -> node ^. nodeId `elem` selNodeIds) allNodes
                factor                = state ^. Global.camera . Camera.camera . Camera.factor
                deltaWs               = case state ^. Global.drag . history of
                    Just dragState   -> deltaToWs factor delta where
                        delta         = dragState ^. dragCurrentPos - dragState ^. dragStartPos
                    Nothing          -> Vector2 0.0 0.0




dragNodesUI :: Vector2 Double -> NodeCollection -> IO ()
dragNodesUI delta nodes = mapM_ (dragNode delta) nodes

moveNodesUI :: NodeCollection -> IO ()
moveNodesUI nodes = mapM_ moveNode nodes
                  -- >> performGC
