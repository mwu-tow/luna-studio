path = require 'path'
{View} = require 'atom-space-pen-views'

uniqueTabNo = 0

module.exports =
class LunaStudioTab extends View
    mountPoint = ""
    pushShortcutEvent = null
    pushSearcherEvent = null

    constructor: (@uri, @nodeEditor, @codeEditor) ->
        super
        @on 'contextmenu', -> false
        @handleEvents()
        pushShortcutEvent = (name, arg = null) => @nodeEditor.pushEvent({_shortcut: name, _arg : arg})
        pushSearcherEvent = (name, arg = null) => @nodeEditor.pushEvent(if arg == null then {tag: name} else {tag: name, contents : arg})

    attached: =>
        @nodeEditor.start(@uri, mountPoint)

    @content: ->
        uniqueTabNo++
        mountPoint = "luna-studio-mount" + uniqueTabNo

        @div
            id: mountPoint
            =>
                @h1 "Loading ..."

    # getTitle:     -> path.basename(@uri)
    getTitle:     -> 'Node editor'

    handleEvents: =>
        atom.commands.add @element,
            'core:cancel':              -> pushShortcutEvent("Cancel")
            'core:close': (e)           => @handleClose(e)
            'core:save': (e)            => @handleSave(e)
            # camera
            'luna-studio:center-graph': -> pushShortcutEvent("CenterGraph")
            'luna-studio:pan-down':     -> pushShortcutEvent("PanDown")
            'luna-studio:pan-left':     -> pushShortcutEvent("PanLeft")
            'luna-studio:pan-right':    -> pushShortcutEvent("PanRight")
            'luna-studio:pan-up':       -> pushShortcutEvent("PanUp")
            'luna-studio:reset-camera': -> pushShortcutEvent("ResetCamera")
            'luna-studio:reset-pan':    -> pushShortcutEvent("ResetPan")
            'luna-studio:reset-zoom':   -> pushShortcutEvent("ResetZoom")
            'luna-studio:zoom-in':      -> pushShortcutEvent("ZoomIn")
            'luna-studio:zoom-out':     -> pushShortcutEvent("ZoomOut")
            # clipboard
            'core:copy':  -> pushShortcutEvent("Copy")
            'core:cut':   -> pushShortcutEvent("Cut")
            'core:paste': -> pushShortcutEvent("Paste", atom.clipboard.readWithMetadata().metadata[0])
            # navigation
            'luna-studio:exit-graph':    -> pushShortcutEvent("ExitGraph")
            'luna-studio:go-cone-down':  -> pushShortcutEvent("GoConeDown")
            'luna-studio:go-cone-left':  -> pushShortcutEvent("GoConeLeft")
            'luna-studio:go-cone-right': -> pushShortcutEvent("GoConeRight")
            'luna-studio:go-cone-up':    -> pushShortcutEvent("GoConeUp")
            'luna-studio:go-down':       -> pushShortcutEvent("GoDown")
            'luna-studio:go-left':       -> pushShortcutEvent("GoLeft")
            'luna-studio:go-next':       -> pushShortcutEvent("GoNext")
            'luna-studio:go-prev':       -> pushShortcutEvent("GoPrev")
            'luna-studio:go-right':      -> pushShortcutEvent("GoRight")
            'luna-studio:go-up':         -> pushShortcutEvent("GoUp")
            # nodes
            'luna-studio:autolayout-all-nodes':        -> pushShortcutEvent("AutolayoutAllNodes")
            'luna-studio:autolayout-selected-nodes':   -> pushShortcutEvent("AutolayoutSelectedNodes")
            'luna-studio:close-visualization-preview': -> pushShortcutEvent("CloseVisualizationPreview")
            'luna-studio:collapse-to-function':        -> pushShortcutEvent("CollapseToFunction")
            'luna-studio:edit-selected-nodes':         -> pushShortcutEvent("EditSelectedNodes")
            'luna-studio:expand-selected-nodes':       -> pushShortcutEvent("ExpandSelectedNodes")
            'luna-studio:open-visualization-preview':  -> pushShortcutEvent("OpenVisualizationPreview")
            'luna-studio:remove-selected-nodes':       -> pushShortcutEvent("RemoveSelectedNodes")
            'luna-studio:select-all':                  -> pushShortcutEvent("SelectAll")
            'luna-studio:unfold-selected-nodes':       -> pushShortcutEvent("UnfoldSelectedNodes")
            'luna-studio:zoom-visualization':          -> pushShortcutEvent("ZoomVisualization")
            # undo/redo
            'core:redo': -> pushShortcutEvent("Redo")
            'core:undo': -> pushShortcutEvent("Undo")
            # MockMonads
            'luna-studio:mock-add-monad':    -> pushShortcutEvent("MockAddMonad")
            'luna-studio:mock-clear-monads': -> pushShortcutEvent("MockClearMonads")
            # searcher
            'luna-studio:searcher-open':         -> pushShortcutEvent("SearcherOpen")
        atom.commands.add '.luna-searcher',
            # searcher
            'luna-studio:searcher-accept-0':     -> pushSearcherEvent("HintShortcut", 0)
            'luna-studio:searcher-accept-1':     -> pushSearcherEvent("HintShortcut", 1)
            'luna-studio:searcher-accept-2':     -> pushSearcherEvent("HintShortcut", 2)
            'luna-studio:searcher-accept-3':     -> pushSearcherEvent("HintShortcut", 3)
            'luna-studio:searcher-accept-4':     -> pushSearcherEvent("HintShortcut", 4)
            'luna-studio:searcher-accept-5':     -> pushSearcherEvent("HintShortcut", 5)
            'luna-studio:searcher-accept-6':     -> pushSearcherEvent("HintShortcut", 6)
            'luna-studio:searcher-accept-7':     -> pushSearcherEvent("HintShortcut", 7)
            'luna-studio:searcher-accept-8':     -> pushSearcherEvent("HintShortcut", 8)
            'luna-studio:searcher-accept-9':     -> pushSearcherEvent("HintShortcut", 9)
            'luna-studio:searcher-accept-input': -> pushSearcherEvent("AcceptInput")
            'luna-studio:searcher-accept':       -> pushSearcherEvent("Accept")
            'luna-studio:searcher-tab-pressed':  -> pushSearcherEvent("TabPressed")
            'luna-studio:searcher-move-down':    -> pushSearcherEvent("MoveDown")
            'luna-studio:searcher-move-left':    -> pushSearcherEvent("MoveLeft")
            'luna-studio:searcher-move-up':      -> pushSearcherEvent("MoveUp")


    handleClose: (e) =>
        e.preventDefault()
        e.stopImmediatePropagation()

    handleSave: (e) =>
        e.preventDefault()
        e.stopImmediatePropagation()
        @codeEditor.pushInternalEvent(tag: "SaveFile", _path: atom.workspace.getActivePaneItem().uri)
