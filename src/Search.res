type featureDef = {
  key: string,
  value: string,
  enum: bool,
}

type featureValueDef = {
  feature: string,
  key: string,
  value: string,
}

type featuresData = {
  features: array<featureDef>,
  values: array<featureValueDef>,
}

@module("./assets/features.json")
external featuresData: featuresData = "default"

let formatReference = (match: option<ParabibleApi.matchingText>): option<string> =>
  switch match {
  | Some(m) =>
    let bookIndex = m.rid / 1_000_000
    let chapterNum = (m.rid / 1000)->mod(1000)
    let verseNum = m.rid->mod(1000)
    let bookName = switch BibleData.getBookByIndex(bookIndex) {
    | Some(book) => book.name
    | None => "Unknown book"
    }
    let chapterVerse = if verseNum > 0 {
      `${chapterNum->Int.toString}:${verseNum->Int.toString}`
    } else {
      chapterNum->Int.toString
    }
    Some(`${bookName} ${chapterVerse}`)
  | None => None
  }

type section = OT | NT | ApostolicFathers | Unknown

let getSection = (bookIndex: int) => {
  if bookIndex >= 1 && bookIndex <= 39 {
    OT
  } else if bookIndex >= 40 && bookIndex <= 66 {
    NT
  } else if bookIndex >= 99 {
    ApostolicFathers
  } else {
    Unknown
  }
}

let getSectionName = (section: section) => {
  switch section {
  | OT => "Old Testament"
  | NT => "New Testament"
  | ApostolicFathers => "Apostolic Fathers"
  | Unknown => "Other"
  }
}

let getRowBookIndex = (row: array<array<ParabibleApi.matchingText>>) => {
  row
  ->Array.find(moduleMatches => moduleMatches->Array.length > 0)
  ->Option.flatMap(moduleMatches => moduleMatches->Array.get(0))
  ->Option.map(match => match.rid / 1_000_000)
  ->Option.getOr(0)
}

@react.component
let make = (
  ~searchTerms: array<ParabibleApi.searchTermData>,
  ~selectedModuleIds: array<int>,
  ~availableModules: array<ParabibleApi.moduleInfo>,
  ~onUpdateSearchTerm: (int, ParabibleApi.searchTermData) => unit,
  ~onDeleteSearchTerm: int => unit,
  ~onWordClick: (int, int) => unit,
  ~selectedWord: option<(int, int)>,
  ~baseModuleId: option<int>,
  ~syntaxRange: string,
  ~setSyntaxRange: (string => string) => unit,
  ~corpusFilter: string,
  ~setCorpusFilter: (string => string) => unit,
) => {
  let (searchResults, setSearchResults) = React.useState(() => None)
  let (loading, setLoading) = React.useState(() => false)
  let (error, setError) = React.useState(() => None)
  let (resultCount, setResultCount) = React.useState(() => 0)
  let (currentPage, setCurrentPage) = React.useState(() => 0)

  let (editingTermIndex, setEditingTermIndex) = React.useState(() => None)
  let (editingDraft, setEditingDraft) = React.useState(() => None)
  let (isClosing, setIsClosing) = React.useState(() => false)
  let (showAddAttrDialog, setShowAddAttrDialog) = React.useState(() => false)
  let (showDeleteConfirmDialog, setShowDeleteConfirmDialog) = React.useState(() => false)
  let (newAttrKey, setNewAttrKey) = React.useState(() => "")
  let (newAttrValue, setNewAttrValue) = React.useState(() => "")
  let (isAtScrollEnd, setIsAtScrollEnd) = React.useState(() => false)
  let (isScrollable, setIsScrollable) = React.useState(() => false)
  
  let (collapsed, setCollapsed) = React.useState(() => false)
  let lastY = React.useRef(0)
  let accumulatedDy = React.useRef(0)

  // Search settings
  let (showSettingsDialog, setShowSettingsDialog) = React.useState(() => false)
  let (isSettingsClosing, setIsSettingsClosing) = React.useState(() => false)
  let (expandedSetting, setExpandedSetting) = React.useState(() => None)
  let (infoDialog, setInfoDialog) = React.useState(() => None)

  let closeSettings = () => {
    setIsSettingsClosing(_ => true)
    let _ = setTimeout(() => {
      setShowSettingsDialog(_ => false)
      setIsSettingsClosing(_ => false)
      setExpandedSetting(_ => None)
    }, 300)
  }
  
  let pageSize = 20

  let clearEditingState = () => {
    setIsClosing(_ => true)
    let _ = setTimeout(() => {
      setEditingTermIndex(_ => None)
      setEditingDraft(_ => None)
      setShowAddAttrDialog(_ => false)
      setNewAttrKey(_ => "")
      setNewAttrValue(_ => "")
      setIsClosing(_ => false)
    }, 300)
  }

  let startEditingTerm = (idx: int) => {
    switch searchTerms->Array.get(idx) {
    | Some(term) => {
        setEditingTermIndex(_ => Some(idx))
        setEditingDraft(_ => Some(term))
        setShowAddAttrDialog(_ => false)
        setNewAttrKey(_ => "")
        setNewAttrValue(_ => "")
      }
    | None => ()
    }
  }

  let updateDraftAttributes = (~index: int, ~key: option<string>=?, ~value: option<string>=?) => {
    setEditingDraft(current =>
      switch current {
      | Some(term) => {
          let updated = term.attributes->Array.mapWithIndex((attr, attrIdx) => {
            let (attrKey, attrValue) = attr
            if attrIdx == index {
              let nextKey = switch key {
              | Some(k) => k
              | None => attrKey
              }
              let nextValue = switch value {
              | Some(v) => v
              | None => attrValue
              }
              (nextKey, nextValue)
            } else {
              (attrKey, attrValue)
            }
          })
          Some({inverted: term.inverted, attributes: updated})
        }
      | None => None
      }
    )
  }

  let removeDraftAttribute = (attrIdx: int) => {
    setEditingDraft(current =>
      switch current {
      | Some(term) => {
          let filtered = term.attributes->Belt.Array.keepWithIndex((_, idx) => idx != attrIdx)
          Some({inverted: term.inverted, attributes: filtered})
        }
      | None => None
      }
    )
  }

  let addDraftAttribute = () => {
    let keyTrimmed = String.trim(newAttrKey)
    let valueTrimmed = String.trim(newAttrValue)
    if keyTrimmed == "" || valueTrimmed == "" {
      ()
    } else {
      setEditingDraft(current =>
        switch current {
        | Some(term) => {
            let appended = Array.concat(term.attributes, [(keyTrimmed, valueTrimmed)])
            Some({inverted: term.inverted, attributes: appended})
          }
        | None => None
        }
      )
      setNewAttrKey(_ => "")
      setNewAttrValue(_ => "")
      setShowAddAttrDialog(_ => false)
    }
  }

  let toggleDraftInverted = () => {
    setEditingDraft(current =>
      switch current {
      | Some(term) => Some({inverted: !term.inverted, attributes: term.attributes})
      | None => None
      }
    )
  }

  let saveDraft = () => {
    switch (editingTermIndex, editingDraft) {
    | (Some(idx), Some(term)) => {
        if term.attributes->Array.length == 0 {
          setShowDeleteConfirmDialog(_ => true)
        } else {
          onUpdateSearchTerm(idx, term)
          clearEditingState()
        }
      }
    | _ => ()
    }
  }

  let deleteTerm = idx => {
    onDeleteSearchTerm(idx)
    switch editingTermIndex {
    | Some(editIdx) if editIdx == idx => clearEditingState()
    | _ => ()
    }
  }

  let draftIsValid = switch editingDraft {
  | Some(term) =>
    term.attributes->Array.every(((key, value)) =>
      String.trim(key) != "" && String.trim(value) != ""
    )
  | None => false
  }
  let canAddNewAttr = String.trim(newAttrKey) != "" && String.trim(newAttrValue) != ""

  let getModuleAbbrev = (moduleId: int) =>
    availableModules
    ->Array.find(m => m.moduleId == moduleId)
    ->Option.map(m => m.abbreviation)
    ->Option.getOr("")

  let hasRenderableContent = (match: ParabibleApi.matchingText) =>
    switch match.type_ {
    | "html" => match.html->Option.isSome
    | "wordArray" => match.wordArray->Option.isSome
    | _ => false
    }

  let totalPages = if resultCount <= 0 {
    0
  } else {
    (resultCount + pageSize - 1) / pageSize
  }

  let goToPage = (page: int) =>
    if page >= 0 && (totalPages == 0 || page < totalPages) {
      setCurrentPage(_ => page)
    } else {
      ()
    }

  React.useEffect2(() => {
    setCurrentPage(_ => 0)
    None
  }, (searchTerms, selectedModuleIds))

  // Fetch search results when searchTerms, selectedModuleIds, or availableModules change
  React.useEffect7(() => {
    if searchTerms->Array.length > 0 && selectedModuleIds->Array.length > 0 && availableModules->Array.length > 0 {
      setLoading(_ => true)
      setError(_ => None)

      let fetchData = async () => {
        // Reorder modules: base module first, then others in selected order
        let orderedModuleIds = switch baseModuleId {
        | Some(baseId) => 
          let others = selectedModuleIds->Array.filter(id => id != baseId)
          [baseId]->Array.concat(others)
        | None => selectedModuleIds
        }

        let modulesStr =
          orderedModuleIds
          ->Array.filterMap(id => {
            availableModules
            ->Array.find((m: ParabibleApi.moduleInfo) => m.moduleId == id)
            ->Option.map((m: ParabibleApi.moduleInfo) => m.abbreviation)
          })
          ->Array.join(",")
        
        let reference = switch corpusFilter {
        | "ot" => Some("Gen-Mal")
        | "nt" => Some("Mat-Rev")
        | _ => None
        }

        let result = await ParabibleApi.fetchTermSearch(
          searchTerms,
          modulesStr,
          ~pageSize,
          ~pageNumber=currentPage,
          ~treeNodeType=syntaxRange,
          ~reference=?reference,
        )
        switch result {
        | Ok(data) => {
            setSearchResults(_ => Some(data))
            setResultCount(_ => data.count)
            setLoading(_ => false)
          }
        | Error(err) => {
            setError(_ => Some(err))
            setLoading(_ => false)
          }
        }
      }

      let _ = fetchData()
    } else {
      setSearchResults(_ => None)
      setResultCount(_ => 0)
    }
    None
  }, (searchTerms, selectedModuleIds, currentPage, availableModules, baseModuleId, syntaxRange, corpusFilter))

  let renderSettingItem = (id, label, currentValue, options, onSelect) => {
    let isExpanded = expandedSetting == Some(id)
    let currentValueLabel = options->Array.find(((v, _)) => v == currentValue)->Option.map(((_, l)) => l)->Option.getOr(currentValue)
    
    <div className="border-b border-stone-200 dark:border-stone-800 last:border-0">
      <button 
        className="w-full flex items-center justify-between p-4 text-left"
        onClick={_ => setExpandedSetting(prev => prev == Some(id) ? None : Some(id))}
      >
        <div>
          <div className="flex items-center gap-2">
            <span className="font-semibold text-stone-900 dark:text-stone-100">{React.string(label)}</span>
            <div 
              className="text-stone-400 hover:text-stone-600 dark:hover:text-stone-200 p-1 -m-1"
              onClick={e => {
                ReactEvent.Mouse.stopPropagation(e)
                setInfoDialog(_ => Some(id))
              }}
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
          </div>
          <div className="text-sm text-stone-500 dark:text-stone-400 mt-0.5">
            {React.string(currentValueLabel)}
          </div>
        </div>
        <svg 
          className={"w-5 h-5 text-stone-400 transition-transform " ++ (isExpanded ? "rotate-180" : "")} 
          fill="none" stroke="currentColor" viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
        </svg>
      </button>
      
      <div className={"overflow-hidden transition-all " ++ (isExpanded ? "max-h-96" : "max-h-0")}>
        <div className="p-4 pt-0 space-y-1 max-h-60">
          {options->Array.map(((val, txt)) => 
            <button
              key={val}
              className={"w-full flex items-center justify-between px-3 py-3 rounded-lg text-sm font-medium transition-colors " ++ (
                val == currentValue ? "bg-teal-50 dark:bg-teal-900/20 text-teal-700 dark:text-teal-300" : "text-stone-700 dark:text-stone-300 hover:bg-stone-100 dark:hover:bg-stone-800"
              )}
              onClick={_ => {
                onSelect(val)
              }}
              disabled={val == "current"}
            >
              <span className={val == "current" ? "opacity-50" : ""}>{React.string(txt)}</span>
              {if val == currentValue {
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7" />
                </svg>
              } else {
                React.null
              }}
            </button>
          )->React.array}
        </div>
      </div>
    </div>
  }

  let getInfoContent = (id) => {
    switch id {
    | "syntax" => "Determines the scope in which search terms must be found. 'Parallel' allows terms to be found across different Bible versions within the same verse. Other options (Verse, Sentence, etc.) require all terms to be found within that specific unit in a single version."
    | "corpus" => "Filters the search results to a specific collection of books, such as the Old Testament or New Testament."
    | _ => ""
    }
  }

  let scrollContainerRef = React.useRef(Nullable.null)

  let checkScrollEnd = () => {
    switch scrollContainerRef.current->Nullable.toOption {
    | Some(element) =>
      let el = element->Obj.magic
      let scrollLeft = el["scrollLeft"]
      let scrollWidth = el["scrollWidth"]
      let clientWidth = el["clientWidth"]
      let scrollable = scrollWidth > clientWidth
      let atEnd = scrollLeft + clientWidth >= scrollWidth - 1
      setIsScrollable(_ => scrollable)
      setIsAtScrollEnd(_ => atEnd)
    | None => ()
    }
  }

  let scrollToEnd = () => {
    switch scrollContainerRef.current->Nullable.toOption {
    | Some(element) =>
      let el = element->Obj.magic
      let scrollWidth = el["scrollWidth"]
      el["scrollTo"]({"left": scrollWidth, "behavior": "smooth"})
    | None => ()
    }
  }

  let handleScroll = e => {
    let target = e->JsxEvent.UI.target
    let scrollTop = target["scrollTop"]
    let dy = scrollTop - lastY.current
    lastY.current = scrollTop

    if (dy > 0 && accumulatedDy.current < 0) || (dy < 0 && accumulatedDy.current > 0) {
      accumulatedDy.current = dy
    } else {
      accumulatedDy.current = accumulatedDy.current + dy
    }

    if accumulatedDy.current > 50 {
      setCollapsed(_ => true)
      accumulatedDy.current = 0
    } else if accumulatedDy.current < -50 {
      setCollapsed(_ => false)
      accumulatedDy.current = 0
    }
  }

  React.useEffect1(() => {
    checkScrollEnd()
    None
  }, [searchTerms])

  <div className="flex flex-col h-full">
    <div className="p-4 border-b border-gray-200 dark:border-stone-800">
      <div className="flex items-center justify-between mb-2">
        <h1 className="text-2xl font-bold"> {React.string("Search Results")} </h1>
        <button
          className="p-2 rounded-full hover:bg-stone-100 dark:hover:bg-stone-800 text-stone-500 dark:text-stone-400 transition-colors"
          onClick={_ => setShowSettingsDialog(_ => true)}
          ariaLabel="Search settings"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth="2"
              d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"
            />
          </svg>
        </button>
      </div>
      {searchTerms->Array.length > 0
        ? <div className="space-y-4">
            <div
              className={"transition-all duration-300 overflow-hidden space-y-4 " ++ (
                collapsed ? "max-h-0 opacity-0 -mb-4" : "max-h-40 opacity-100"
              )}
            >
              <div className="text-sm text-gray-600 dark:text-gray-400">
                <span className="mr-2">
                  {React.string(`${resultCount->Int.toString} results`)}
                </span>
                {React.string("·")}
                <span className="ml-2">
                  {React.string(`${searchTerms->Array.length->Int.toString} search terms`)}
                </span>
              </div>
              <div className="relative -mx-4">
                <div
                  ref={ReactDOM.Ref.domRef(scrollContainerRef)}
                  className="flex overflow-x-auto gap-2 pb-2 px-4 scrollbar-hide"
                  onScroll={_ => checkScrollEnd()}
                >
                  {searchTerms
                  ->Array.mapWithIndex((term, idx) => {
                    let primaryAttr = term.attributes->Array.get(0)
                    let summary = switch primaryAttr {
                    | Some((key, value)) => `${String.replaceAll(key, "_", " ")}: ${value}`
                    | None => "No attributes"
                    }
                    let extraCount = term.attributes->Array.length - 1
                    let summaryText = if extraCount > 0 {
                      summary ++ " (+" ++ extraCount->Int.toString ++ ")"
                    } else {
                      summary
                    }

                    <div
                      key={idx->Int.toString}
                      className="shrink-0 group flex items-center bg-stone-100 dark:bg-stone-800 border border-stone-200 dark:border-stone-700 overflow-hidden transition-all active:scale-95"
                    >
                      <button
                        className="px-3 py-2 text-sm font-medium text-stone-900 dark:text-stone-100 hover:bg-stone-200 dark:hover:bg-stone-700 flex items-center gap-2"
                        onClick={_ => startEditingTerm(idx)}
                      >
                        {if term.inverted {
                          <span
                            className="text-xs font-bold text-rose-600 bg-rose-100 dark:bg-rose-900/30 px-1.5 py-0.5"
                          >
                            {React.string("NOT")}
                          </span>
                        } else {
                          React.null
                        }}
                        <span> {React.string(summaryText)} </span>
                      </button>
                      <div className="w-px h-4 bg-stone-300 dark:bg-stone-600" />
                      <button
                        className="px-2 py-2 hover:bg-rose-100 dark:hover:bg-rose-900/30 text-stone-400 hover:text-rose-600 transition-colors"
                        onClick={_ => deleteTerm(idx)}
                        ariaLabel="Remove term"
                      >
                        <svg
                          className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth="2"
                            d="M6 18L18 6M6 6l12 12"
                          />
                        </svg>
                      </button>
                    </div>
                  })
                  ->React.array}
                  <div className="w-12 shrink-0" />
                </div>
                {if isScrollable {
                  <div className="absolute right-0 -top-1 bottom-1 flex">
                    <div
                      className="w-5 h-full bg-gradient-to-l from-white dark:from-black to-transparent pointer-events-none"
                    >
                    </div>
                    <button
                      className={"w-10 h-full flex items-center justify-center bg-white dark:bg-black transition-colors " ++ (
                        isAtScrollEnd
                          ? "text-stone-300 dark:text-stone-700 cursor-default"
                          : "text-teal-600 hover:text-teal-800 dark:hover:text-teal-200"
                      )}
                      onClick={_ =>
                        if !isAtScrollEnd {
                          scrollToEnd()
                        }}
                      disabled={isAtScrollEnd}
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                          strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7"
                        />
                      </svg>
                    </button>
                  </div>
                } else {
                  React.null
                }}
              </div>
            </div>
            {totalPages > 0
              ? <div className="space-y-2">
                  <Pagination totalPages currentPage onPageChange={goToPage} />
                </div>
              : React.null}
          </div>
        : React.null}
    </div>

    <div className="flex-1 overflow-auto p-4" onScroll={handleScroll}>
      {switch (loading, error, searchResults) {
      | (true, _, _) => <div className="text-center py-8"> {React.string("Loading...")} </div>
      | (_, Some(err), _) =>
        <div className="text-center py-8 text-red-600 dark:text-red-400">
          {React.string(`Error: ${err}`)}
        </div>
      | (false, None, Some(results)) => {
          let highlightPairs = results.matchingWords->Array.map(mw => (mw.wid, mw.moduleId))
          
          let groupedRows = results.matchingText->Array.reduce([], (acc, row) => {
            let rowBookIndex = getRowBookIndex(row)
            let rowSection = getSection(rowBookIndex)
            
            switch acc->Array.get(acc->Array.length - 1) {
            | Some((lastSection, lastRows)) if lastSection == rowSection =>
                lastRows->Array.push(row)
                acc
            | _ =>
                acc->Array.push((rowSection, [row]))
                acc
            }
          })

          <div className="space-y-8">
            {groupedRows
            ->Array.map(((section, rows)) => {
              let presentModuleIds = rows->Array.reduce([], (acc, row) => {
                row->Array.forEach(moduleResults => {
                  let matches = moduleResults->Array.filter(hasRenderableContent)
                  switch matches->Array.get(0) {
                  | Some(firstMatch) =>
                    let id = firstMatch.moduleId
                    if !(acc->Array.includes(id)) {
                      acc->Array.push(id)
                    }
                  | None => ()
                  }
                })
                acc
              })

              let sectionModuleIds =
                selectedModuleIds->Array.filter(id => presentModuleIds->Array.includes(id))
              
              let columnCount = sectionModuleIds->Array.length

              if columnCount == 0 {
                React.null
              } else {
                <div key={getSectionName(section)}>
                  <h2 className="text-xl font-bold mb-4 px-4 text-stone-800 dark:text-stone-200">
                    {React.string(getSectionName(section))}
                  </h2>
                  <div className="space-y-4">
                    {rows
                    ->Array.mapWithIndex((row, rowIdx) => {
                      let effectiveBaseModuleId =
                        baseModuleId
                        ->Option.flatMap(id =>
                          if selectedModuleIds->Array.includes(id) {
                            Some(id)
                          } else {
                            None
                          }
                        )
                        ->Option.orElse(selectedModuleIds->Array.get(0))
                        ->Option.orElse(sectionModuleIds->Array.get(0))

                      let baseMatch =
                        effectiveBaseModuleId
                        ->Option.flatMap(baseId =>
                          row
                          ->Array.find(moduleResults =>
                            moduleResults->Array.some(m => m.moduleId == baseId)
                          )
                          ->Option.flatMap(matches => matches->Array.get(0))
                        )
                        ->Option.orElse(
                          row
                          ->Array.find(moduleResults => moduleResults->Array.length > 0)
                          ->Option.flatMap(matches => matches->Array.get(0))
                        )

                      let referenceLabel = formatReference(baseMatch)

                      <div
                        key={rowIdx->Int.toString}
                        className="border border-gray-200 dark:border-stone-800 p-4"
                      >
                        {switch referenceLabel {
                        | Some(label) =>
                          <div
                            className="text-sm font-semibold text-gray-700 dark:text-gray-200 mb-3"
                          >
                            {React.string(label)}
                          </div>
                        | None => React.null
                        }}
                        <div
                          className="grid gap-4"
                          style={{
                            gridTemplateColumns: `repeat(${columnCount->Int.toString}, minmax(0, 1fr))`,
                          }}
                        >
                          {sectionModuleIds
                          ->Array.map(moduleId => {
                            let moduleAbbrev = getModuleAbbrev(moduleId)
                            let matches =
                              row
                              ->Array.find(moduleResults =>
                                moduleResults->Array.some(m => m.moduleId == moduleId)
                              )
                              ->Option.map(ms => ms->Array.filter(hasRenderableContent))
                              ->Option.getOr([])

                            <div
                              key={`${rowIdx->Int.toString}-${moduleId->Int.toString}`}
                              className="space-y-3"
                            >
                              {if matches->Array.length > 0 {
                                matches
                                ->Array.map(match => {
                                  <VerseColumn
                                    key={`${moduleId->Int.toString}-${match.rid->Int.toString}`}
                                    match={Some(match)}
                                    baseMatch={baseMatch}
                                    moduleId
                                    moduleAbbrev
                                    selectedWord
                                    onWordClick
                                    highlightWords=?Some(highlightPairs)
                                  />
                                })
                                ->React.array
                              } else {
                                <VerseColumn
                                  key={`${moduleId->Int.toString}-empty`}
                                  match={None}
                                  baseMatch={baseMatch}
                                  moduleId
                                  moduleAbbrev
                                  selectedWord
                                  onWordClick
                                  highlightWords=?Some(highlightPairs)
                                />
                              }}
                            </div>
                          })
                          ->React.array}
                        </div>
                      </div>
                    })
                    ->React.array}
                  </div>
                </div>
              }
            })
            ->React.array}
          </div>
        }
      | _ =>
        <div className="text-center py-8 text-gray-500">
          {React.string("Select search terms in the Tools view to begin searching")}
        </div>
      }}
    </div>

    {switch (editingTermIndex, editingDraft) {
    | (Some(idx), Some(draft)) =>
      let animationClass = isClosing ? "animate-slide-down" : "animate-slide-up"
      let backdropClass = isClosing ? "animate-fade-out" : "animate-fade-in"
      <React.Fragment>
        <div className="fixed inset-0 z-40 flex items-end">
          <div
            className={"absolute inset-0 bg-black/40 " ++ backdropClass}
            onClick={_ => clearEditingState()}
          />
          <div
            className={"relative w-full flex flex-col bg-white dark:bg-stone-900 p-5 shadow-2xl max-h-[85vh] overflow-hidden " ++
            animationClass}
          >
            <div className="flex items-center justify-between gap-3">
              <div>
                <div className="text-xs uppercase tracking-wide text-stone-500 dark:text-stone-400">
                  {React.string("Editing search term")}
                </div>
                <div className="text-lg font-semibold text-stone-900 dark:text-stone-100">
                  {React.string(`Term ${(idx + 1)->Int.toString}${draft.inverted ? " (NOT)" : ""}`)}
                </div>
              </div>
              <button
                className="w-10 h-10 rounded-full bg-stone-100 dark:bg-stone-800 text-stone-500 dark:text-stone-300 flex items-center justify-center"
                onClick={_ => clearEditingState()}
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <button
              className={"mt-4 w-full px-4 py-3 text-sm font-semibold text-center transition-colors " ++ (
                draft.inverted
                  ? "bg-rose-600 text-white"
                  : "bg-stone-100 dark:bg-stone-800 text-stone-800 dark:text-stone-100"
              )}
              onClick={_ => toggleDraftInverted()}
            >
              {React.string(
                draft.inverted
                  ? "Term is inverted (NOT). Tap to revert."
                  : "Tap to invert this term (NOT)",
              )}
            </button>

            <div className="flex-0 mt-4 space-y-3 max-h-[45vh] overflow-auto">
              {switch draft.attributes->Array.length {
              | 0 =>
                <div className="text-sm text-stone-600 dark:text-stone-300">
                  {React.string("Add at least one attribute key/value pair")}
                </div>
              | _ =>
                draft.attributes
                ->Array.mapWithIndex((attr, attrIdx) => {
                  let (key, value) = attr
                  let featureDef = featuresData.features->Array.find(f => f.key == key)

                  <div
                    key={`${key}-${attrIdx->Int.toString}`}
                    className="flex items-center gap-2 w-full"
                  >
                    <select
                      className="flex-1 min-w-0 h-10 border border-stone-200 dark:border-stone-700 bg-transparent px-3 py-2 text-sm"
                      value={key}
                      onChange={e =>
                        updateDraftAttributes(
                          ~index=attrIdx,
                          ~key=?Some(ReactEvent.Form.target(e)["value"]),
                        )}
                    >
                      <option value=""> {React.string("Select attribute")} </option>
                      {featuresData.features
                      ->Array.map(f =>
                        <option key={f.key} value={f.key}> {React.string(f.value)} </option>
                      )
                      ->React.array}
                      {if key != "" && !(featuresData.features->Array.some(f => f.key == key)) {
                        <option value={key}> {React.string(key)} </option>
                      } else {
                        React.null
                      }}
                    </select>
                    {switch featureDef {
                    | Some(def) if def.enum =>
                      let possibleValues = featuresData.values->Array.filter(v => v.feature == key)
                      <select
                        className="flex-1 min-w-0 h-10 border border-stone-200 dark:border-stone-700 bg-transparent px-3 py-2 text-sm"
                        value={value}
                        onChange={e =>
                          updateDraftAttributes(
                            ~index=attrIdx,
                            ~value=?Some(ReactEvent.Form.target(e)["value"]),
                          )}
                      >
                        <option value=""> {React.string("Select value")} </option>
                        {possibleValues
                        ->Array.map(v =>
                          <option key={v.key} value={v.key}> {React.string(v.value)} </option>
                        )
                        ->React.array}
                        {if value != "" && !(possibleValues->Array.some(v => v.key == value)) {
                          <option value={value}> {React.string(value)} </option>
                        } else {
                          React.null
                        }}
                      </select>
                    | _ =>
                      <input
                        className="flex-1 min-w-0 h-10 border border-stone-200 dark:border-stone-700 bg-transparent px-3 py-2 text-sm"
                        type_="text"
                        value={value}
                        onChange={e =>
                          updateDraftAttributes(
                            ~index=attrIdx,
                            ~value=?Some(ReactEvent.Form.target(e)["value"]),
                          )}
                        placeholder="Attribute value"
                      />
                    }}
                    <button
                      className="w-10 h-10 flex items-center justify-center shrink-0 bg-rose-100 dark:bg-rose-900/40 text-rose-700 dark:text-rose-300"
                      onClick={_ => removeDraftAttribute(attrIdx)}
                      ariaLabel="Remove attribute"
                    >
                      <svg
                        className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth="2"
                          d="M6 18L18 6M6 6l12 12"
                        />
                      </svg>
                    </button>
                  </div>
                })
                ->React.array
              }}
            </div>

            <div className="mt-4">
              <button
                className="w-full h-11 bg-stone-900 text-white dark:bg-stone-100 dark:text-stone-900 font-semibold text-sm transition-all active:scale-95"
                onClick={_ => setShowAddAttrDialog(_ => true)}
              >
                {React.string("Add attribute")}
              </button>
            </div>

            <div className="mt-5 flex gap-3">
              <button
                className="flex-1 h-12 border border-stone-300 dark:border-stone-700 text-stone-700 dark:text-stone-200 font-semibold"
                onClick={_ => clearEditingState()}
              >
                {React.string("Cancel")}
              </button>
              <button
                className={"flex-1 h-12 font-semibold text-white transition-all active:scale-95 " ++ (
                  draftIsValid ? "bg-teal-600 hover:bg-teal-700" : "bg-teal-300 cursor-not-allowed"
                )}
                disabled={!draftIsValid}
                onClick={_ => saveDraft()}
              >
                {React.string("Save term")}
              </button>
            </div>
          </div>
        </div>

        <Dialog
          show=showAddAttrDialog
          header={React.string("Add Attribute")}
          showCloseButton=true
          closeOnOverlayClick=true
          onClose={_ => {
            setShowAddAttrDialog(_ => false)
            setNewAttrKey(_ => "")
            setNewAttrValue(_ => "")
          }}>
          <div className="space-y-3">
            <div>
              <label className="block text-sm font-medium text-stone-700 dark:text-stone-300 mb-1">
                {React.string("Attribute Key")}
              </label>
              <select
                className="w-full border border-stone-200 dark:border-stone-700 bg-transparent px-3 py-2 text-sm"
                value={newAttrKey}
                onChange={e => {
                  let val = ReactEvent.Form.target(e)["value"]
                  setNewAttrKey(_ => val)
                  setNewAttrValue(_ => "")
                }}>
                <option value=""> {React.string("Select attribute")} </option>
                {featuresData.features
                ->Array.map(f =>
                  <option key={f.key} value={f.key}> {React.string(f.value)} </option>
                )
                ->React.array}
              </select>
            </div>
            {if newAttrKey != "" {
              <div>
                <label className="block text-sm font-medium text-stone-700 dark:text-stone-300 mb-1">
                  {React.string("Attribute Value")}
                </label>
                {let featureDef = featuresData.features->Array.find(f => f.key == newAttrKey)
                switch featureDef {
                | Some(def) if def.enum =>
                  let possibleValues = featuresData.values->Array.filter(v => v.feature == newAttrKey)
                  <select
                    className="w-full border border-stone-200 dark:border-stone-700 bg-transparent px-3 py-2 text-sm"
                    value={newAttrValue}
                    onChange={e => setNewAttrValue(_ => ReactEvent.Form.target(e)["value"])}>
                    <option value=""> {React.string("Select value")} </option>
                    {possibleValues
                    ->Array.map(v =>
                      <option key={v.key} value={v.key}> {React.string(v.value)} </option>
                    )
                    ->React.array}
                  </select>
                | _ =>
                  <input
                    className="w-full border border-stone-200 dark:border-stone-700 bg-transparent px-3 py-2 text-sm"
                    type_="text"
                    value={newAttrValue}
                    onChange={e => setNewAttrValue(_ => ReactEvent.Form.target(e)["value"])}
                    placeholder="Enter value"
                  />
                }}
              </div>
            } else {
              React.null
            }}
          </div>
          <div className="mt-6 flex gap-3">
            <button
              className="flex-1 h-10 border border-stone-300 dark:border-stone-700 text-stone-700 dark:text-stone-200 font-semibold text-sm"
              onClick={_ => {
                setShowAddAttrDialog(_ => false)
                setNewAttrKey(_ => "")
                setNewAttrValue(_ => "")
              }}>
              {React.string("Cancel")}
            </button>
            <button
              className={"flex-1 h-10 font-semibold text-sm text-white transition-all active:scale-95 " ++ (
                canAddNewAttr ? "bg-teal-600 hover:bg-teal-700" : "bg-teal-300 cursor-not-allowed"
              )}
              disabled={!canAddNewAttr}
              onClick={_ => addDraftAttribute()}>
              {React.string("Confirm")}
            </button>
          </div>
        </Dialog>
          <Dialog
            show=showDeleteConfirmDialog
            header={React.string("Delete term?")}
            showCloseButton=false
            closeOnOverlayClick=true
            onClose={_ => setShowDeleteConfirmDialog(_ => false)}>
            <div className="mb-4">
              <p className="text-sm text-stone-600 dark:text-stone-300 mt-2">
                {React.string(
                  "This term has no attributes — saving will remove it. Cancel will exit without saving. Do you want to delete the term?",
                )}
              </p>
            </div>
            <div className="flex gap-3">
              <button
                className="flex-1 h-10 border border-stone-300 dark:border-stone-700 text-stone-700 dark:text-stone-200 font-semibold text-sm"
                onClick={_ => {
                  setShowDeleteConfirmDialog(_ => false)
                }}>
                {React.string("Cancel")}
              </button>
              <button
                className="flex-1 h-10 font-semibold text-sm text-white bg-rose-600 hover:bg-rose-700"
                onClick={_ => {
                  setShowDeleteConfirmDialog(_ => false)
                  deleteTerm(idx)
                }}>
                {React.string("Delete term")}
              </button>
            </div>
          </Dialog>
      </React.Fragment>
    | _ => React.null
    }}

    {if showSettingsDialog {
      let animationClass = isSettingsClosing ? "animate-slide-down" : "animate-slide-up"
      let backdropClass = isSettingsClosing ? "animate-fade-out" : "animate-fade-in"
      
      <React.Fragment>
        <div className="fixed inset-0 z-50 flex items-end">
          <div
            className={"absolute inset-0 bg-black/40 " ++ backdropClass}
            onClick={_ => closeSettings()}
          />
          <div className={"relative w-full bg-white dark:bg-stone-900 shadow-2xl max-h-[85vh] flex flex-col overflow-hidden " ++ animationClass}>
            <div className="flex items-center justify-between p-5 border-b border-stone-200 dark:border-stone-800">
              <h3 className="text-lg font-semibold text-stone-900 dark:text-stone-100">
                {React.string("Search Settings")}
              </h3>
              <button
                className="w-8 h-8 rounded-full bg-stone-100 dark:bg-stone-800 text-stone-500 dark:text-stone-300 flex items-center justify-center"
                onClick={_ => closeSettings()}
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div className="pb-8 overflow-y-auto">
              {renderSettingItem(
                "syntax",
                "Syntax Range",
                syntaxRange,
                [
                  ("parallel", "Parallel"),
                  ("verse", "Verse"),
                  ("sentence", "Sentence"),
                  ("clause", "Clause"),
                  ("phrase", "Phrase"),
                ],
                val => setSyntaxRange(_ => val)
              )}
              
              {renderSettingItem(
                "corpus",
                "Corpus Filter",
                corpusFilter,
                [
                  ("none", "No Filter"),
                  ("ot", "Old Testament"),
                  ("nt", "New Testament"),
                  ("current", "Current Book"),
                ],
                val => setCorpusFilter(_ => val)
              )}
            </div>
          </div>
        </div>
        
        <Dialog
          show={infoDialog == Some("syntax")}
          header={React.string("Syntax Range")}
          showCloseButton=true
          closeOnOverlayClick=true
          onClose={_ => setInfoDialog(_ => None)}>
          <p className="text-stone-600 dark:text-stone-300 leading-relaxed">
            {React.string(getInfoContent("syntax"))}
          </p>
        </Dialog>
        <Dialog
          show={infoDialog == Some("corpus")}
          header={React.string("Corpus Filter")}
          showCloseButton=true
          closeOnOverlayClick=true
          onClose={_ => setInfoDialog(_ => None)}>
          <p className="text-stone-600 dark:text-stone-300 leading-relaxed">
            {React.string(getInfoContent("corpus"))}
          </p>
        </Dialog>
      </React.Fragment>
    } else {
      React.null
    }}
  </div>
}