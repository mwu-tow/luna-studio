---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE ConstraintKinds  #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE Rank2Types       #-}

module Flowbox.Luna.Passes.Transform.AST.IDFixer.IDFixer where

import qualified Flowbox.Luna.Data.AST.Common                    as AST
import           Flowbox.Luna.Data.AST.Expr                      (Expr)
import qualified Flowbox.Luna.Data.AST.Expr                      as Expr
import           Flowbox.Luna.Data.AST.Lit                       (Lit)
import qualified Flowbox.Luna.Data.AST.Lit                       as Lit
import           Flowbox.Luna.Data.AST.Module                    (Module)
import qualified Flowbox.Luna.Data.AST.Module                    as Module
import           Flowbox.Luna.Data.AST.Pat                       (Pat)
import qualified Flowbox.Luna.Data.AST.Pat                       as Pat
import           Flowbox.Luna.Data.AST.Type                      (Type)
import qualified Flowbox.Luna.Data.AST.Type                      as Type
import           Flowbox.Luna.Data.AST.Zipper.Focus              (Focus)
import qualified Flowbox.Luna.Data.AST.Zipper.Focus              as Focus
import           Flowbox.Luna.Passes.Pass                        (Pass)
import qualified Flowbox.Luna.Passes.Pass                        as Pass
import           Flowbox.Luna.Passes.Transform.AST.IDFixer.State (IDFixerState)
import qualified Flowbox.Luna.Passes.Transform.AST.IDFixer.State as State
import           Flowbox.Prelude
import           Flowbox.System.Log.Logger



logger :: Logger
logger = getLogger "Flowbox.Luna.Passes.Transform.AST.IDFixer.IDFixer"


type IDFixerPass result = Pass IDFixerState result


runPass :: (Monad m, Functor m)
        => AST.ID -> Maybe AST.ID -> Bool -> Pass.ESRT err Pass.Info IDFixerState m result -> m (Either err result)
runPass maxID rootID fixAll = Pass.run_ (Pass.Info "IDFixer") $ State.make maxID rootID fixAll


run :: AST.ID -> Maybe AST.ID -> Bool -> Focus -> Pass.Result Focus
run maxID rootID fixAll = Pass.run_ (Pass.Info "IDFixer") (State.make maxID rootID fixAll) . fixFocus


runModule :: AST.ID -> Maybe AST.ID -> Bool -> Module -> Pass.Result Module
runModule maxID rootID fixAll = runPass maxID rootID fixAll . fixModule


runExpr :: AST.ID -> Maybe AST.ID -> Bool -> Expr -> Pass.Result Expr
runExpr maxID rootID fixAll = runPass maxID rootID fixAll . fixExpr


runExpr' :: AST.ID -> Maybe AST.ID -> Bool -> Expr -> Pass.Result (Expr, AST.ID)
runExpr' maxID rootID fixAll = runPass maxID rootID fixAll . fixExpr'


runExprs :: AST.ID -> Maybe AST.ID -> Bool -> [Expr] -> Pass.Result [Expr]
runExprs maxID rootID fixAll = runPass maxID rootID fixAll . mapM fixExpr


runType :: AST.ID -> Maybe AST.ID -> Bool -> Type -> Pass.Result Type
runType maxID rootID fixAll = runPass maxID rootID fixAll . fixType


fixFocus :: Focus -> IDFixerPass Focus
fixFocus = Focus.traverseM fixModule fixExpr


fixModule :: Module -> IDFixerPass Module
fixModule m = do n <- State.fixID $ m ^. Module.id
                 Module.traverseM fixModule fixExpr fixType fixPat fixLit $ m & Module.id .~ n


fixExpr' :: Expr -> IDFixerPass (Expr, AST.ID)
fixExpr' e = (,) <$> fixExpr e <*> State.getMaxID


fixExpr :: Expr -> IDFixerPass Expr
fixExpr e = do n <- State.fixID $ e ^. Expr.id
               Expr.traverseM fixExpr fixType fixPat fixLit $ e & Expr.id .~ n


fixPat :: Pat -> IDFixerPass Pat
fixPat p = do n <- State.fixID $ p ^. Pat.id
              Pat.traverseM fixPat fixType fixLit $ p & Pat.id .~ n


fixType :: Type -> IDFixerPass Type
fixType t = do n <- State.fixID $ t ^. Type.id
               Type.traverseM fixType $ t & Type.id .~ n


fixLit :: Lit -> IDFixerPass Lit
fixLit l = do n <- State.fixID $ l ^. Lit.id
              return $ l & Lit.id .~ n


clearIDs :: AST.ID -> Module -> Module
clearIDs zero x = runIdentity (Module.traverseMR (return . set Module.id zero)
                                                 (return . set   Expr.id zero)
                                                 (return . set   Type.id zero)
                                                 (return . set    Pat.id zero)
                                                 (return . set    Lit.id zero) x)
