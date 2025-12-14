@module("./jsHelpers.js")
external getPath: unit => string = "getPath"
@module("./jsHelpers.js")
external replaceHistory: string => unit = "replaceHistory"
@module("./jsHelpers.js")
external pushHistory: string => unit = "pushHistory"
@module("./jsHelpers.js")
external attachPopStateListener: (JSON.t => unit) => (unit => unit) = "attachPopStateListener"
@module("./jsHelpers.js")
external setHtmlDark: bool => unit = "setHtmlDark"

let routes = Belt.List.fromArray(["/r/", "/g/", "/q/", "/a/"])

@react.component
let make = () => {
  let getIndexFromPath = (path: string) =>
    switch path {
    | "/r/" => 0
    | "/g/" => 1
    | "/q/" => 2
    | "/a/" => 3
    | _ => 0
    }

  // Load initial state from StateService
  let initialState = StateService.loadAppState()

  // Module state
  let (availableModules, setAvailableModules) = React.useState(() => [])
  let (selectedModuleIds, setSelectedModuleIds) = React.useState(() =>
    initialState.selectedModuleIds
  )

  // Selected word state (wid, moduleId)
  let (selectedWord, setSelectedWord) = React.useState(() => initialState.selectedWord)

  // Search terms state
  let (searchTerms, setSearchTerms) = React.useState(() => initialState.searchTerms)
  let (currentBook, setCurrentBook) = React.useState(() =>
    switch initialState.readingPosition {
    | Some(pos) => pos.book->BibleData.getBookById
    | None => None
    }
  )

  // Dark mode state
  let (darkMode, setDarkMode) = React.useState(() => initialState.darkMode)

  // Base module state
  let (baseModuleId, setBaseModuleId) = React.useState(() => initialState.baseModuleId)

  // Search settings state
  let (syntaxRange, setSyntaxRange) = React.useState(() => initialState.syntaxRange)
  let (corpusFilter, setCorpusFilter) = React.useState(() => initialState.corpusFilter)

  // Load modules on mount
  React.useEffect0(() => {
    let fetchData = async () => {
      let result = await ParabibleApi.fetchModules()
      switch result {
      | Ok(modules) => {
          setAvailableModules(_ => modules)

          // Set default modules if none are selected (first load)
          if selectedModuleIds->Array.length == 0 {
            let defaultAbbreviations = ["BHSA", "NA1904", "NET", "CAFE", "APF"]
            let defaultIds = defaultAbbreviations->Array.filterMap(abbr => {
              modules->Array.find(m => m.abbreviation == abbr)->Belt.Option.map(m => m.moduleId)
            })
            if defaultIds->Array.length > 0 {
              setSelectedModuleIds(_ => defaultIds)
              setBaseModuleId(_ => Some(2)) // Default to NET
            }
          }
        }
      | Error(_) => () // Silently fail, use empty array
      }
    }
    let _ = fetchData()
    None
  })

  // Initialize dark mode on mount
  React.useEffect1(() => {
    setHtmlDark(darkMode)
    None
  }, [darkMode])

  // Save selected modules to localStorage whenever they change
  React.useEffect1(() => {
    StateService.saveSelectedModuleIds(selectedModuleIds)
    None
  }, [selectedModuleIds])

  // Save selected word whenever it changes
  React.useEffect1(() => {
    StateService.saveSelectedWord(selectedWord)
    None
  }, [selectedWord])

  // Save search terms whenever they change
  React.useEffect1(() => {
    StateService.saveSearchTerms(searchTerms)
    None
  }, [searchTerms])

  // Save dark mode whenever it changes
  React.useEffect1(() => {
    StateService.saveDarkMode(darkMode)
    None
  }, [darkMode])

  // Save search settings
  React.useEffect1(() => {
    StateService.saveSyntaxRange(syntaxRange)
    None
  }, [syntaxRange])

  React.useEffect1(() => {
    StateService.saveCorpusFilter(corpusFilter)
    None
  }, [corpusFilter])

  // Ensure base module is valid
  React.useEffect2(() => {
    switch baseModuleId {
    | Some(id) =>
      if !(selectedModuleIds->Array.includes(id)) {
        // Base module was removed, select a new one (first available)
        setBaseModuleId(_ => selectedModuleIds[0])
      }
    | None =>
      if selectedModuleIds->Array.length > 0 {
        setBaseModuleId(_ => Some(selectedModuleIds[0]->Option.getOr(0)))
      }
    }
    None
  }, (selectedModuleIds, baseModuleId))

  // Save base module
  React.useEffect1(() => {
    StateService.saveBaseModuleId(baseModuleId)
    None
  }, [baseModuleId])

  let (index, setIndex) = React.useState(() => {
    let path = getPath()
    getIndexFromPath(path)
  })
  let (animatingTo, setAnimatingTo) = React.useState(() => None)
  let containerSelector = "pagesContainer"

  let animateTo = (target: int) => {
    if target == index {
      ()
    } else {
      setAnimatingTo(_ => Some(target))

      // Trigger the index change which will cause pages to slide
      let _ = setTimeout(() => {
        setIndex(_ => target)

        // Clear animation state after transition
        let _ = setTimeout(() => setAnimatingTo(_ => None), 300)
      }, 10)
    }
  }

  let handleWordClick = (wid: int, moduleId: int) => {
    setSelectedWord(_ => Some((wid, moduleId)))
    animateTo(1) // Switch to Tools tab
  }

  let handleAddSearchTerms = (
    newTerms: array<ParabibleApi.searchTermData>,
    clearPrevious: bool,
  ) => {
    if clearPrevious {
      setSearchTerms(_ => newTerms)
    } else {
      setSearchTerms(current => Array.concat(current, newTerms))
    }
    animateTo(2) // Switch to Search tab
  }

  let handleUpdateSearchTerm = (index: int, updatedTerm: ParabibleApi.searchTermData) => {
    setSearchTerms(current =>
      current->Array.mapWithIndex((term, idx) =>
        if idx == index {
          updatedTerm
        } else {
          term
        }
      )
    )
  }

  let handleDeleteSearchTerm = (index: int) => {
    setSearchTerms(current => current->Belt.Array.keepWithIndex((_, idx) => idx != index))
  }

  let handleReadingPositionChange = (book: string, chapter: int, verse: int) => {
    StateService.saveReadingPosition({book, chapter, verse})
    setCurrentBook(_ => BibleData.getBookById(book))
  }

  let pageFor = (~idx) =>
    switch idx {
    | 0 =>
      <Read
        selectedModuleIds
        availableModules
        onWordClick={handleWordClick}
        selectedWord
        initialPosition={initialState.readingPosition}
        onPositionChange={handleReadingPositionChange}
        baseModuleId
      />
    | 1 =>
      <Tools
        selectedWord
        onAddSearchTerms={handleAddSearchTerms}
        hasExistingSearchTerms={searchTerms->Array.length > 0}
      />
    | 2 =>
      <Search
        currentBook
        searchTerms
        selectedModuleIds
        availableModules
        onUpdateSearchTerm={handleUpdateSearchTerm}
        onDeleteSearchTerm={handleDeleteSearchTerm}
        onWordClick={handleWordClick}
        selectedWord
        baseModuleId
        syntaxRange
        setSyntaxRange
        corpusFilter
        setCorpusFilter
      />
    | 3 =>
      <Settings
        darkMode
        onDarkModeChange={dark => setDarkMode(_ => dark)}
        availableModules
        selectedModuleIds
        onModuleToggle={moduleId => {
          setSelectedModuleIds(current => {
            if current->Array.includes(moduleId) {
              current->Array.filter(id => id != moduleId)
            } else {
              current->Array.concat([moduleId])
            }
          })
        }}
        onModuleReorder={newOrder => setSelectedModuleIds(_ => newOrder)}
        baseModuleId
        onBaseModuleChange={id => setBaseModuleId(_ => Some(id))}
      />
    | _ =>
      <Read
        selectedModuleIds
        availableModules
        onWordClick={handleWordClick}
        selectedWord
        initialPosition={initialState.readingPosition}
        onPositionChange={handleReadingPositionChange}
        baseModuleId
      />
    }

  let getPageTransform = (pageIdx: int) => {
    if pageIdx == index {
      "translateX(0%)"
    } else if pageIdx < index {
      "translateX(-100%)"
    } else {
      "translateX(100%)"
    }
  }

  let isPageVisible = (pageIdx: int) => {
    pageIdx == index ||
      switch animatingTo {
      | None => false
      | Some(target) => pageIdx == target
      }
  }

  React.useEffect1(() => {
    // Push a new history entry for this navigation. We use pushHistory so
    // the browser keeps a proper back/forward stack.
    pushHistory(Belt.List.get(routes, index)->Belt.Option.getWithDefault("/r/"))
    None
  }, [index])

  // Keep track of whether the next popstate should be treated as programmatic
  // navigation (to avoid re-pushing history). Similar pattern to other
  // `useRef` flags in the codebase.
  let handlingPopRef = React.useRef(false)

  // Update index when the user navigates via browser back/forward.
  React.useEffect0(() => {
    let cleanup = attachPopStateListener(_event => {
      // Prevent pushing history while handling this event
      handlingPopRef.current = true
      let path = getPath()
      setIndex(_ => getIndexFromPath(path))
      // small delay before allowing pushes again
      let _ = setTimeout(() => handlingPopRef.current = false, 50)
    })
    Some(() => cleanup())
  })

  <div
    className="h-screen w-screen flex flex-col bg-white dark:bg-black text-black dark:text-white"
  >
    <div className="flex-1 relative overflow-hidden">
      <div id={containerSelector} className="absolute inset-0 overflow-hidden">
        <div
          className={"absolute border-slate-400 border-r-1 -right-px top-0 bottom-0 w-[calc(100vw+2px)] h-full transition-all duration-300" ++ (
            isPageVisible(0) ? "" : " pointer-events-none invisible"
          )}
          style={transform: getPageTransform(0)}
        >
          {pageFor(~idx=0)}
        </div>
        <div
          className={"absolute border-slate-400 border-r-1 -right-px top-0 bottom-0 w-[calc(100vw+2px)] h-full transition-all duration-300" ++ (
            isPageVisible(1) ? "" : " pointer-events-none invisible"
          )}
          style={transform: getPageTransform(1)}
        >
          {pageFor(~idx=1)}
        </div>
        <div
          className={"absolute border-slate-400 border-r-1 -right-px top-0 bottom-0 w-[calc(100vw+2px)] h-full transition-all duration-300" ++ (
            isPageVisible(2) ? "" : " pointer-events-none invisible"
          )}
          style={transform: getPageTransform(2)}
        >
          {pageFor(~idx=2)}
        </div>
        <div
          className={"absolute border-slate-400 border-r-1 -right-px top-0 bottom-0 w-[calc(100vw+2px)] h-full transition-all duration-300" ++ (
            isPageVisible(3) ? "" : " pointer-events-none invisible"
          )}
          style={transform: getPageTransform(3)}
        >
          {pageFor(~idx=3)}
        </div>
      </div>
    </div>

    <div className="flex-shrink-0">
      <BottomNav index onSelect={animateTo} />
    </div>
  </div>
}
