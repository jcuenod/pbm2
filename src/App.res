@module("./jsHelpers.js")
external getPath: unit => string = "getPath"
@module("./jsHelpers.js")
external replaceHistory: string => unit = "replaceHistory"
@module("./jsHelpers.js")
external getLocalStorage: string => Nullable.t<string> = "getLocalStorage"
@module("./jsHelpers.js")
external setLocalStorage: (string, string) => unit = "setLocalStorage"

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

  // Module state
  let (availableModules, setAvailableModules) = React.useState(() => [])
  let (selectedModuleIds, setSelectedModuleIds) = React.useState(() => {
    // Try to load from localStorage
    switch getLocalStorage("selectedModules")->Nullable.toOption {
    | Some(stored) => // Parse comma-separated IDs
      stored
      ->String.split(",")
      ->Array.filterMap(idStr => Int.fromString(idStr))
    | None => [] // Will be set once modules are loaded
    }
  })

  // Selected word state (wid, moduleId)
  let (selectedWord, setSelectedWord) = React.useState(() => None)

  // Search terms state
  let (searchTerms, setSearchTerms) = React.useState(() => [])

  // Load modules on mount
  React.useEffect0(() => {
    let fetchData = async () => {
      let result = await ParabibleApi.fetchModules()
      switch result {
      | Ok(modules) => {
          setAvailableModules(_ => modules)

          // Set default modules if none are selected (first load)
          if selectedModuleIds->Array.length == 0 {
            let defaultAbbreviations = ["BHSA", "NET", "NA1904", "CAFE", "APF"]
            let defaultIds = defaultAbbreviations->Array.filterMap(abbr => {
              modules->Array.find(m => m.abbreviation == abbr)->Belt.Option.map(m => m.moduleId)
            })
            if defaultIds->Array.length > 0 {
              setSelectedModuleIds(_ => defaultIds)
            }
          }
        }
      | Error(_) => () // Silently fail, use empty array
      }
    }
    let _ = fetchData()
    None
  })

  // Save selected modules to localStorage whenever they change
  React.useEffect1(() => {
    let moduleString = selectedModuleIds->Array.map(id => id->Int.toString)->Array.join(",")
    setLocalStorage("selectedModules", moduleString)
    None
  }, [selectedModuleIds])

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

  let pageFor = (~idx) =>
    switch idx {
    | 0 => <Read selectedModuleIds availableModules onWordClick={handleWordClick} selectedWord />
    | 1 =>
      <Tools
        selectedWord
        onAddSearchTerms={handleAddSearchTerms}
        hasExistingSearchTerms={searchTerms->Array.length > 0}
      />
    | 2 =>
      <Search
        searchTerms
        selectedModuleIds
        availableModules
        onUpdateSearchTerm={handleUpdateSearchTerm}
        onDeleteSearchTerm={handleDeleteSearchTerm}
        onWordClick={handleWordClick}
      />
    | 3 =>
      <Settings
        onToggle={_ => ()}
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
      />
    | _ => <Read selectedModuleIds availableModules onWordClick={handleWordClick} selectedWord />
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
    replaceHistory(Belt.List.get(routes, index)->Belt.Option.getWithDefault("/r/"))
    None
  }, [index])

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
