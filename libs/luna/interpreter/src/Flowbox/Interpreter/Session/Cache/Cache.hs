---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Flowbox Team <contact@flowbox.io>, 2014
-- Proprietary and confidential
-- Unauthorized copying of this file, via any medium is strictly prohibited
---------------------------------------------------------------------------
module Flowbox.Interpreter.Session.Cache.Cache where

import           Control.Monad.State hiding (mapM, mapM_)
import           Data.Hash           (Hash)
import qualified Data.Hash           as Hash
import qualified Data.Maybe          as Maybe
import qualified Data.Set            as Set

import           Flowbox.Data.MapForest                         (MapForest)
import qualified Flowbox.Data.MapForest                         as MapForest
import           Flowbox.Interpreter.Session.Data.CacheInfo     (CacheInfo (CacheInfo))
import qualified Flowbox.Interpreter.Session.Data.CacheInfo     as CacheInfo
import qualified Flowbox.Interpreter.Session.Data.CallData      as CallData
import           Flowbox.Interpreter.Session.Data.CallDataPath  (CallDataPath)
import qualified Flowbox.Interpreter.Session.Data.CallDataPath  as CallDataPath
import           Flowbox.Interpreter.Session.Data.CallPoint     (CallPoint)
import qualified Flowbox.Interpreter.Session.Data.CallPoint     as CallPoint
import           Flowbox.Interpreter.Session.Data.CallPointPath (CallPointPath)
import qualified Flowbox.Interpreter.Session.Env                as Env
import           Flowbox.Interpreter.Session.Session            (Session)
import qualified Flowbox.Interpreter.Session.Session            as Session
import           Flowbox.Prelude
import           Flowbox.System.Log.Logger



logger :: LoggerIO
logger = getLoggerIO "Flowbox.Interpreter.Session.Cache.Cache"


dump :: CallPointPath -> Maybe Hash -> Session ()
dump callPointPath mhash = do
    let varName = getVarName mhash callPointPath
    logger debug $ "Dumping " ++ varName
    Session.runStmt $ "print " ++ varName


exists :: CallPointPath -> Session Bool
exists callPointPath = MapForest.member callPointPath <$> cached


isDirty :: CallPointPath -> Session Bool
isDirty = onCacheInfo
    (\cacheInfo -> return $ cacheInfo ^. CacheInfo.modified || cacheInfo ^. CacheInfo.nonCacheable)
    (return True)


containsHash :: Hash -> CallPointPath -> Session Bool
containsHash hash = onCacheInfo
    (\cacheInfo -> return $ Set.member hash $ cacheInfo ^. CacheInfo.hashes)
    (return False)


setModified :: CallPointPath -> Session ()
setModified = modifyCacheInfo (CacheInfo.modified .~ True)


setNonCacheable :: CallPointPath -> Session ()
setNonCacheable = modifyCacheInfo (CacheInfo.nonCacheable .~ True)


modifyCacheInfo :: (CacheInfo -> CacheInfo) -> CallPointPath ->  Session ()
modifyCacheInfo f callPointPath = onCacheInfo
    (\cacheInfo -> modify (Env.cached %~ MapForest.insert callPointPath (f cacheInfo)))
    (return ())
    callPointPath


onCacheInfo :: (CacheInfo -> Session a) -> Session a -> CallPointPath -> Session a
onCacheInfo f alternative callPointPath =
    Maybe.maybe alternative f . MapForest.lookup callPointPath =<< cached


put :: CallDataPath -> Maybe Hash -> Session ()
put callDataPath mhash = do
    mapForest <- gets $ view Env.cached

    let callPointPath = CallDataPath.toCallPointPath callDataPath
        hash           = Maybe.maybe Set.empty Set.singleton mhash
        existingHashes = Maybe.maybe Set.empty (view CacheInfo.hashes)
                       $ MapForest.lookup callPointPath mapForest
        hashes = Set.union existingHashes hash
        cacheInfo = CacheInfo (last callDataPath ^. CallData.parentDefID)
                              False False hashes

    modify (Env.cached %~ MapForest.insert callPointPath cacheInfo)


delete :: CallPointPath -> Session ()
delete callPointPath = modify $ Env.cached %~ MapForest.delete callPointPath


cached :: Session (MapForest CallPoint CacheInfo)
cached = gets (view Env.cached)


getVarName :: Maybe Hash -> CallPointPath -> String
getVarName mhash callPointPath = concatMap gen callPointPath ++ hash where
    gen callPoint = "_" ++ (show $ abs (callPoint ^. CallPoint.libraryID))
                 ++ "_" ++ (show $ abs (callPoint ^. CallPoint.nodeID))
    hash = '_' : Maybe.maybe "" (show . Hash.asWord64)  mhash
