module JS.CustomEvent
    ( registerCallback
    ) where

import           GHCJS.Foreign.Callback
import           GHCJS.Types
import           Utils.PreludePlus

foreign import javascript safe "app.customEvent = $1"
    registerCallback' :: Callback (JSVal -> JSVal -> IO ()) -> IO ()

foreign import javascript safe "connectionPen.customEvent = function(){ return null; }"
    unregisterCallback' :: Callback (JSVal -> JSVal -> IO ()) -> IO ()

registerCallback :: (JSVal -> JSVal -> IO ()) -> IO (IO ())
registerCallback callback = do
    wrappedCallback <- asyncCallback2 callback
    registerCallback' wrappedCallback
    return $ unregisterCallback' wrappedCallback >> releaseCallback wrappedCallback


