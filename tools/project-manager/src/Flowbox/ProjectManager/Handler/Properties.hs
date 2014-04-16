---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
module Flowbox.ProjectManager.Handler.Properties where

import qualified Data.IORef                                                                as IORef
import qualified Flowbox.Batch.Handler.Properties                                          as BatchP
import           Flowbox.Luna.Tools.Serialize.Proto.Conversion.Attributes                  ()
import           Flowbox.Prelude
import           Flowbox.ProjectManager.Context                                            (ContextRef)
import           Flowbox.System.Log.Logger
import           Flowbox.Tools.Serialize.Proto.Conversion.Basic
import qualified Generated.Proto.ProjectManager.Project.Library.AST.Properties.Get.Request as GetASTProperties
import qualified Generated.Proto.ProjectManager.Project.Library.AST.Properties.Get.Status  as GetASTProperties
import qualified Generated.Proto.ProjectManager.Project.Library.AST.Properties.Set.Request as SetASTProperties
import qualified Generated.Proto.ProjectManager.Project.Library.AST.Properties.Set.Update  as SetASTProperties
import qualified Generated.Proto.ProjectManager.Project.Library.AST.Function.Graph.Node.Properties.Get.Request as GetNodeProperties
import qualified Generated.Proto.ProjectManager.Project.Library.AST.Function.Graph.Node.Properties.Get.Status  as GetNodeProperties
import qualified Generated.Proto.ProjectManager.Project.Library.AST.Function.Graph.Node.Properties.Set.Request as SetNodeProperties
import qualified Generated.Proto.ProjectManager.Project.Library.AST.Function.Graph.Node.Properties.Set.Update  as SetNodeProperties


loggerIO :: LoggerIO
loggerIO = getLoggerIO "Flowbox.Batch.Server.Handlers.Properties"


getASTProperties :: ContextRef -> GetASTProperties.Request -> IO GetASTProperties.Status
getASTProperties ctxRef (GetASTProperties.Request tnodeID tlibID tprojectID) = do
    let nodeID    = decodeP tnodeID
        libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef ctxRef
    properties <- BatchP.getProperties nodeID libID projectID batch
    return $ GetASTProperties.Status (encode properties) tnodeID tlibID tprojectID


setASTProperties :: ContextRef -> SetASTProperties.Request -> IO SetASTProperties.Update
setASTProperties ctxRef (SetASTProperties.Request tproperties tnodeID tlibID tprojectID) = do
    properties <- decode tproperties
    let nodeID    = decodeP tnodeID
        libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef ctxRef
    newBatch <- BatchP.setProperties properties nodeID libID projectID batch
    IORef.writeIORef ctxRef newBatch
    return $ SetASTProperties.Update tproperties tnodeID tlibID tprojectID


getNodeProperties :: ContextRef -> GetNodeProperties.Request -> IO GetNodeProperties.Status
getNodeProperties ctxRef (GetNodeProperties.Request tnodeID tbc tlibID tprojectID) = do
    let nodeID    = decodeP tnodeID
        libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef ctxRef
    properties <- BatchP.getProperties nodeID libID projectID batch
    return $ GetNodeProperties.Status (encode properties) tnodeID tbc tlibID tprojectID


setNodeProperties :: ContextRef -> SetNodeProperties.Request -> IO SetNodeProperties.Update
setNodeProperties ctxRef (SetNodeProperties.Request tproperties tnodeID tbc tlibID tprojectID) = do
    properties <- decode tproperties
    let nodeID    = decodeP tnodeID
        libID     = decodeP tlibID
        projectID = decodeP tprojectID
    batch <- IORef.readIORef ctxRef
    newBatch <- BatchP.setProperties properties nodeID libID projectID batch
    IORef.writeIORef ctxRef newBatch
    return $ SetNodeProperties.Update tproperties tnodeID tbc tlibID tprojectID