module Reactive.Plugins.Core.Action.Backend.GraphFetcher where

import           Utils.PreludePlus

import           Event.Event     (Event(Batch))
import qualified Event.Batch     as Batch
import           Batch.Workspace (interpreterState, InterpreterState(..))

import qualified Reactive.State.Global         as Global
import           Reactive.State.Global         (State)
import           Reactive.Commands.Command     (Command, execCommand, performIO)
import           Reactive.Commands.RenderGraph (renderGraph)

import qualified BatchConnector.Monadic.Commands as BatchCmd
import           Empire.API.Data.Node (Node)
import           Empire.API.Data.PortRef (OutPortRef, InPortRef)


toAction :: Event -> Maybe (Command State ())
-- toAction (Batch (Batch.GraphViewFetched response)) = Just $ showGraph nodes edges
toAction _                                            = Nothing

showGraph :: [Node] -> [(OutPortRef, InPortRef)] -> Command State ()
showGraph nodes edges = do
    renderGraph nodes edges
    prepareValues nodes

isModule _ = False -- TODO

prepareValues :: [Node] -> Command State ()
prepareValues nodes = do
    let nonModules = filter (not . isModule) nodes
    workspace <- use Global.workspace
    case workspace ^. interpreterState of
        Fresh  -> zoom Global.workspace $ BatchCmd.insertSerializationModes nonModules
        AllSet -> zoom Global.workspace $ do
            BatchCmd.runMain
            BatchCmd.requestValues nonModules
