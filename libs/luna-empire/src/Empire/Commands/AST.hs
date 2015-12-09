module Empire.Commands.AST where

import           Prologue
import           Control.Monad.State
import           Control.Monad.Error (ErrorT, runErrorT, throwError)
import           Data.Variants       (match, case', ANY(..))
import           Data.Layer.Coat     (uncoat)
import           Data.Maybe          (fromMaybe)
import           Data.Construction   (destruct)

import           Empire.Data.AST (AST)
import           Empire.Empire

import           Luna.Syntax.Builder.Star  (StarBuilderT)
import qualified Luna.Syntax.Builder.Star  as StarBuilder
import           Luna.Syntax.Builder.Node  (NodeBuilderT)
import qualified Luna.Syntax.Builder.Node  as NodeBuilder
import           Luna.Syntax.Builder.Class (BuilderT)
import qualified Luna.Syntax.Builder       as Builder
import           Luna.Syntax.Repr.Graph    (Ref(..), Node(..))
import           Luna.Syntax.AST.Term      (Var(..), App(..), Blank(..))
import qualified Luna.Syntax.AST.Term      as Term
import qualified Luna.Syntax.AST.Typed     as Typed
import qualified Luna.Syntax.AST.Arg       as Arg

import           Empire.Utils.ParserMock   as Parser

type ASTOp = ErrorT Error (NodeBuilderT (Ref Node) (BuilderT AST (StarBuilderT (Maybe (Ref Node)) IO)))

runAstOp :: ASTOp a -> Command AST a
runAstOp cmd = empire $ \g -> flip StarBuilder.evalT Nothing
             $ flip Builder.runT g
             $ flip NodeBuilder.evalT (Ref $ Node (0 :: Int))
             $ runErrorT
             $ cmd

addNode :: String -> Command AST (Ref Node)
addNode expr = fromMaybe (addVar expr) (whenString <|> whenInt) where
    whenString = addString  <$> Parser.asString  expr
    whenInt    = addInteger <$> Parser.asInteger expr

addInteger :: Int -> Command AST (Ref Node)
addInteger num = runAstOp $ Builder._int num

addVar :: String -> Command AST (Ref Node)
addVar name = runAstOp $ Builder.var name

addString :: String -> Command AST (Ref Node)
addString lit = runAstOp $ Builder._string lit

makeAccessor :: Ref Node -> Ref Node -> Command AST (Ref Node)
makeAccessor src dst = runAstOp $ Builder.accessor dst src

removeNode' :: Ref Node -> ASTOp ()
removeNode' ref = do
    node     <- Builder.readRef ref
    typeNode <- Builder.follow $ node ^. Typed.tp
    destruct typeNode
    destruct ref

removeIfBlank :: Ref Node -> ASTOp ()
removeIfBlank ref = do
    node <- Builder.readRef ref
    case' (uncoat node) $ do
        match $ \Blank -> removeNode' ref
        match $ \ANY -> return ()

removeNode :: Ref Node -> Command AST ()
removeNode = runAstOp . removeNode'

getVarNameNode :: Ref Node -> Command AST (Ref Node)
getVarNameNode ref = runAstOp $ do
    node <- Builder.readRef ref
    case' (uncoat node) $ do
        match $ \(Var n) -> do
            Builder.follow n
        match $ \ANY -> do
            throwError "Expected Var node, got wrong type."

newApplication :: Ref Node -> Ref Node -> Int -> ASTOp (Ref Node)
newApplication fun arg pos = do
    blanks <- sequence $ replicate pos Builder._blank
    let args = blanks ++ [arg]
    Builder.app fun (Builder.arg <$> args)

rewireApplication :: Ref Node -> Ref Node -> Int -> ASTOp (Ref Node)
rewireApplication fun arg pos = do
    oldApp  <- Builder.readRef fun
    (target, oldArgs) <- case' (uncoat oldApp) $ do
        match $ \(App tg args) -> do
            unpackedArgs <- mapM (Builder.follow . Arg.__arec) $ Term.inputs args
            target <- Builder.follow tg
            return (target, unpackedArgs)
        match $ \ANY -> throwError "Expected App node, got wrong type."

    let argsLength = max (pos + 1) (length oldArgs)
        argsCmd    = take argsLength $ (return <$> oldArgs) ++ (repeat Builder._blank)
        oldArgCmd  = argsCmd !! pos
        withNewArg = argsCmd & ix pos .~ return arg

    args <- sequence withNewArg
    oldArg <- oldArgCmd

    removeNode' fun
    removeIfBlank oldArg
    Builder.app target (Builder.arg <$> args)

applyFunction :: Ref Node -> Ref Node -> Int -> Command AST (Ref Node)
applyFunction fun arg pos = runAstOp $ do
    funNode <- Builder.readRef fun
    case' (uncoat funNode) $ do
        match $ \(App _ _) -> rewireApplication fun arg pos
        match $ \ANY -> newApplication fun arg pos
