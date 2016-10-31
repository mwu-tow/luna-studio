module UI.Handlers.Connection where

import           Utils.PreludePlus

import           Data.HMap.Lazy                     (TypeKey (..))
import           Utils.Vector

import qualified Empire.API.Data.Connection         as Connection
import qualified Empire.API.Data.PortRef            as PortRef

import           Event.Event                        (JSState)
import qualified Event.Mouse                        as Mouse
import           Object.Widget                      (DragMoveHandler, UIHandlers, WidgetId, dragMove, mouseMove, mouseOut, mousePressed,
                                                     startPos)
import qualified Object.Widget.Connection           as Model
import qualified Object.Widget.Node                 as NodeModel
import qualified Object.Widget.Port                 as PortModel
import           Reactive.Commands.Command          (Command)
import           Reactive.Commands.Graph.Disconnect (disconnectAll)
import qualified Reactive.Commands.UIRegistry       as UICmd
import qualified Reactive.State.Connect             as Connect
import           Reactive.State.Global              (inRegistry)
import qualified Reactive.State.Global              as Global
import qualified Reactive.State.Graph               as Graph
import qualified Reactive.State.UIRegistry          as UIRegistry

import           UI.Generic                         (abortDrag, startDrag)



data ConnectionEnd = Source | Destination
newtype DragConnectionEndHandler = DragConnectionEndHandler (WidgetId -> ConnectionEnd -> Command UIRegistry.State ())

triggerDragConnectionEndHandler :: WidgetId -> ConnectionEnd -> Command UIRegistry.State ()
triggerDragConnectionEndHandler wid end = do
    let key = TypeKey :: TypeKey DragConnectionEndHandler
    maybeHandler <- UICmd.handler wid key
    withJust maybeHandler $ \(DragConnectionEndHandler handler) -> handler wid end

setCurrentConnectionColor :: Int -> Command UIRegistry.State ()
setCurrentConnectionColor color = UICmd.update_ UIRegistry.currentConnectionId $ Model.currentColor .~ color

endCoeff :: Double
endCoeff = 0.2

shiftVec :: Vector2 Double
shiftVec = Vector2 10 10

mousePressedHandler :: Mouse.Event' -> JSState -> WidgetId -> Command Global.State ()
mousePressedHandler evt _ = startDrag evt

dragHandler :: DragMoveHandler Global.State
dragHandler ds _ wid = do
    let mouseX = ds ^. startPos . x
    when (mouseX > endCoeff) $ do
        connId <- inRegistry $ UICmd.get wid Model.connectionId
        connectionColor <- inRegistry $ UICmd.get wid Model.color
        Just srcPortRef   <- preuse $ Global.graph . Graph.connectionsMap . ix connId . Connection.src
        Just portWidgetId <- use $ Global.graph . Graph.portWidgetsMap . at (PortRef.OutPortRef' srcPortRef)
        Just nodeWidgetId <- use $ Global.graph . Graph.nodeWidgetsMap . at (srcPortRef ^. PortRef.srcNodeId)
        disconnectAll [connId]
        sourceNodePos   <- inRegistry $ UICmd.get nodeWidgetId NodeModel.position
        sourcePortAngle <- inRegistry $ UICmd.get portWidgetId PortModel.angleVector
        -- let coord = floor <$> sourceNodePos + shiftVec
        Global.connect . Connect.connecting ?= Connect.connectingFromPort (PortRef.OutPortRef' srcPortRef) sourcePortAngle sourceNodePos
        void $ zoom Global.uiRegistry $ setCurrentConnectionColor connectionColor
    when (mouseX < (-endCoeff)) $ do
        connId <- inRegistry $ UICmd.get wid Model.connectionId
        connectionColor <- inRegistry $ UICmd.get wid Model.color
        Just dstPortRef <- preuse $ Global.graph . Graph.connectionsMap . ix connId . Connection.dst
        Just portWidgetId <- use $ Global.graph . Graph.portWidgetsMap . at (PortRef.InPortRef' dstPortRef)
        Just nodeWidgetId <- use $ Global.graph . Graph.nodeWidgetsMap . at (dstPortRef ^. PortRef.dstNodeId)
        disconnectAll [connId]
        dstNodePos   <- inRegistry $ UICmd.get nodeWidgetId NodeModel.position
        dstPortAngle <- inRegistry $ UICmd.get portWidgetId PortModel.angleVector
        -- let coord = floor <$> dstNodePos + shiftVec
        Global.connect . Connect.connecting ?= Connect.connectingFromPort (PortRef.InPortRef' dstPortRef) dstPortAngle dstNodePos
        void $ zoom Global.uiRegistry $ setCurrentConnectionColor connectionColor
    abortDrag

onMouseMove :: Mouse.Event' -> JSState -> WidgetId -> Command Global.State()
onMouseMove evt _ wid  = inRegistry $ do
    let mouseX = evt ^. Mouse.position . x
    when (mouseX > endCoeff) $
        UICmd.update_ wid $ Model.highlight .~ Model.SrcHighlight
    when (mouseX < (-endCoeff)) $
        UICmd.update_ wid $ Model.highlight .~ Model.DstHighlight

onMouseOut :: WidgetId -> Command Global.State ()
onMouseOut wid = inRegistry $
    UICmd.update_ wid $ Model.highlight .~ Model.None

widgetHandlers :: UIHandlers Global.State
widgetHandlers = def & mouseMove .~ onMouseMove
                     & mouseOut  .~ const onMouseOut
                     & mousePressed  .~ mousePressedHandler
                     & dragMove  .~ dragHandler
