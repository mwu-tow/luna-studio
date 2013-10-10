---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

import           Data.List                       as List
import           Options.Applicative             hiding (info)
import qualified Options.Applicative             as Opt

import           Flowbox.Prelude                 hiding (error)
import qualified Flowbox.Config.Config           as Config
import           Flowbox.Config.Config             (Config)
import           Flowbox.Control.Applicative       
import qualified Flowbox.Data.Version            as Version
import qualified Flowbox.Initializer.Initializer as Initializer
import qualified Flowbox.Lunac.Builder.File      as FileBuilder
import qualified Flowbox.Lunac.CmdArgs           as CmdArgs
import           Flowbox.Lunac.CmdArgs             (CmdArgs)
import           Flowbox.Lunac.Diagnostics         (Diagnostics(Diagnostics))
import           Flowbox.System.Log.Logger         
import qualified Flowbox.System.UniPath          as UniPath


rootLogger :: Logger
rootLogger = getLogger "Flowbox"


parser :: Parser CmdArgs
parser =   Opt.flag' CmdArgs.Version    (long "version" <> short 'V' <> hidden)
       <|> Opt.flag' CmdArgs.NumVersion (long "numeric-version"      <> hidden)
       <|> Opt.flag' CmdArgs.Hello      (long "hello"                <> hidden)
       <|> CmdArgs.Compilation
           <$> many1     ( argument str ( metavar "INPUTS" ))
           <*> many      ( strOption ( short 'l' <> metavar "LIBRARY" <> help "Library to link with.")                 )
           <*> strOption ( long "output"  <> short 'o' <> value "out"     <> metavar "OUTPUT"  <> help "Output folder" )
           <*> strOption ( long "name"    <> short 'n' <> value "name"    <> metavar "NAME"    <> help "Project name"  )
           <*> strOption ( long "root-path"            <> value ""        <> hidden                                    )
       
           <*> switch    ( long "global"                         <> help "Compile to global library"                   )
           <*> switch    ( long "library"                        <> help "Compile as a library"                        )
       
           <*> optIntFlag "verbose" 'v' 0 3 "Verbose level (level range is 0-5, default level is 3)"
           <*> switch    ( long "no-color"                       <> help "Disable color output"                       )
           <*> switch    ( long "version" <> short 'V'           <> help "Print version information"                  )
           <*> switch    ( long "numeric-version"                <> help "Print just the version number"              )

           <*> switch    ( long "dump-all"             <> hidden                                                      )
           <*> switch    ( long "dump-ast"             <> hidden                                                      )
           <*> switch    ( long "dump-va"              <> hidden                                                      )
           <*> switch    ( long "dump-fp"              <> hidden                                                      )
           <*> switch    ( long "dump-ssa"             <> hidden                                                      )
           <*> switch    ( long "dump-hast"            <> hidden                                                      )
           <*> switch    ( long "dump-hsc"             <> hidden                                                      )

-- TODO[WD] : Ponizsza funkcja powinna byc przeniesiona do "utilsow" parsowania argumentow
--            natomiast samo parsowanie powinno byc przeniesione w miejsce niezalezne od toola
optIntFlag longName shortName baseval defval helpmsg = 
    (\flag f -> let baselvl = if flag then defval else baseval
                    explvl  = read f :: Int
                    lvl     = if explvl < 0 then baselvl else explvl
                 in lvl
    )
    <$> switch    ( long longName <> short shortName <> help helpmsg         )
    <*> strOption (                  short shortName <> value "-1" <> hidden )

opts :: Config -> ParserInfo CmdArgs
opts cfg = Opt.info (helper <*> parser)
              (Opt.fullDesc
                  <> Opt.header (show_version cfg)
              )


show_version :: Config -> String
show_version cfg = "Luna compiler, version " ++ Version.str (Config.version cfg)

show_num_version :: Config -> String
show_num_version cfg = Version.numStr (Config.version cfg)


main :: IO ()
main = do
    cfg <- Config.load
    execParser (opts cfg) >>= (run cfg)


run :: Config -> CmdArgs -> IO ()
run cfg cmd = do
    case cmd of
        CmdArgs.Version     {} -> putStrLn $ show_version cfg
        CmdArgs.NumVersion  {} -> putStrLn $ show_num_version cfg
        CmdArgs.Hello       {} -> putStrLn $ "Hello, my name is John le Box. Nice to meet you :)"
        CmdArgs.Compilation {} -> do
            if CmdArgs.verbose cmd > 0
                then rootLogger setLevel DEBUG
                else rootLogger setLevel INFO

            let diag = Diagnostics ( CmdArgs.dump_ast  cmd || CmdArgs.dump_all cmd )
                                   ( CmdArgs.dump_va   cmd || CmdArgs.dump_all cmd )
                                   ( CmdArgs.dump_fp   cmd || CmdArgs.dump_all cmd )
                                   ( CmdArgs.dump_ssa  cmd || CmdArgs.dump_all cmd )
                                   ( CmdArgs.dump_hast cmd || CmdArgs.dump_all cmd )
                                   ( CmdArgs.dump_hsc  cmd || CmdArgs.dump_all cmd )

                inputs = map UniPath.fromUnixString $ CmdArgs.inputs cmd


            Initializer.initializeIfNeeded cfg

            mapM_ (FileBuilder.build cfg cmd diag) inputs
      

