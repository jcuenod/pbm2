@module("./jsHelpers.js")
external getScrollTop: JsxEvent.UI.t => int = "getScrollTop"

type chapterData = {
  chapter: int,
  data: ParabibleApi.textEndpointResult,
}

type loadedChapters = {
  previous: option<chapterData>,
  current: option<chapterData>,
  next: option<chapterData>,
}

@react.component
let make = (~selectedModuleIds, ~availableModules, ~onWordClick: (int, int) => unit, ~selectedWord: option<(int, int)>) => {
  let (collapsed, setCollapsed) = React.useState(() => false)
  let (showSelector, setShowSelector) = React.useState(() => false)
  let (currentBook, setCurrentBook) = React.useState(() => "Matt")
  let (currentChapter, setCurrentChapter) = React.useState(() => 1)
  let (loadedChapters, setLoadedChapters) = React.useState(() => {
    previous: None,
    current: None,
    next: None,
  })
  let (loading, setLoading) = React.useState(() => false)
  let (error, setError) = React.useState(() => None)
  let (loadingPrev, setLoadingPrev) = React.useState(() => false)
  let (loadingNext, setLoadingNext) = React.useState(() => false)
  let (prevLoadFailed, setPrevLoadFailed) = React.useState(() => false)
  let (nextLoadFailed, setNextLoadFailed) = React.useState(() => false)
  let (visibleChapter, setVisibleChapter) = React.useState(() => 1)
  let lastY = React.useRef(0)
  let scrollContainerRef = React.useRef(Nullable.null)
  let previousScrollHeight = React.useRef(0)
  let isInitialPreload = React.useRef(false)

  let maxChaptersForBook = React.useMemo1(() => {
    BibleData.books
      ->Array.find(b => b.id == currentBook)
      ->Option.map(b => b.chapters)
      ->Option.getOr(1)
  }, [currentBook])

  let fetchChapterData = async (book: string, chapter: int): result<ParabibleApi.textEndpointResult, string> => {
    let reference = `${book}${chapter->Int.toString}`
    let modulesString = selectedModuleIds
      ->Array.filterMap(id => {
        availableModules->Array.find((m: ParabibleApi.moduleInfo) => m.moduleId == id)
          ->Option.map((m: ParabibleApi.moduleInfo) => m.abbreviation)
      })
      ->Array.join(",")
    
    await ParabibleApi.fetchText(modulesString, reference)
  }

  let onScroll = e => {
    let st = getScrollTop(e)
    let dy = st - lastY.current
    lastY.current = st
    if dy > 5 {
      // scrolling down
      setCollapsed(_ => true)
    } else if dy < -5 {
      // scrolling up
      setCollapsed(_ => false)
    }
    
    // Update visible chapter based on which chapter heading is at or above the top of viewport
    let target = e->JsxEvent.UI.target
    let container = target->Obj.magic
    
    // Get all chapter section elements and find which one's heading is at the top
    let containerElement: {..} = container
    let chapterSections = containerElement["querySelectorAll"](".chapter-section")
    let sectionsArray: array<{..}> = chapterSections
    
    // Find the last chapter whose heading is at or above the viewport top
    let visibleChapterNum = ref(visibleChapter)
    sectionsArray->Array.forEach(section => {
      let heading = section["querySelector"](".chapter-heading")
      if heading !== Nullable.null->Obj.magic {
        let rect = heading["getBoundingClientRect"]()
        // If the heading is at or above the top of the viewport (with small buffer for header)
        if rect["top"] <= 60. {
          // Extract chapter number from id (format: "chapter-N")
          let sectionId = section["id"]
          let chapterStr = sectionId->String.replace("chapter-", "")
          switch chapterStr->Int.fromString {
          | Some(num) => visibleChapterNum := num
          | None => ()
          }
        }
      }
    })
    setVisibleChapter(_ => visibleChapterNum.contents)

    // Check scroll position for infinite scroll
    let target = e->JsxEvent.UI.target
    let scrollTop = target["scrollTop"]
    let scrollHeight = target["scrollHeight"]
    let clientHeight = target["clientHeight"]
    
    // Determine the lowest loaded chapter number
    let lowestLoadedChapter = switch loadedChapters.previous {
    | Some(prev) => prev.chapter
    | None => switch loadedChapters.current {
      | Some(curr) => curr.chapter
      | None => currentChapter
      }
    }
    
    // Determine the highest loaded chapter number
    let highestLoadedChapter = switch loadedChapters.next {
    | Some(next) => next.chapter
    | None => switch loadedChapters.current {
      | Some(curr) => curr.chapter
      | None => currentChapter
      }
    }
    
    // Load previous chapter if scrolling near top
    if scrollTop < 200 && !loadingPrev && lowestLoadedChapter > 1 {
      switch loadedChapters.previous {
      | None => 
          setLoadingPrev(_ => true)
          // Save current scroll height before loading
          previousScrollHeight.current = scrollHeight
          
          let prevChapter = lowestLoadedChapter - 1
          let fetchData = async () => {
            let result = await fetchChapterData(currentBook, prevChapter)
            switch result {
            | Ok(data) => {
                setLoadedChapters(prev => {
                  previous: Some({chapter: prevChapter, data: data}),
                  current: prev.current,
                  next: prev.next,
                })
                setLoadingPrev(_ => false)
                setPrevLoadFailed(_ => false)
              }
            | Error(_) => {
                setLoadingPrev(_ => false)
                setPrevLoadFailed(_ => true)
              }
            }
          }
          let _ = fetchData()
      | Some(_prevData) => 
          // If previous chapter is already loaded and we're at top, shift chapters backward
          if scrollTop < 100 {
            setLoadedChapters(prev => {
              previous: None,
              current: prev.previous,
              next: prev.current,
            })
          }
      }
    }
    
    // Load next chapter if scrolling near bottom
    if scrollTop + clientHeight > scrollHeight - 200 && !loadingNext && highestLoadedChapter < maxChaptersForBook {
      switch loadedChapters.next {
      | None => 
          setLoadingNext(_ => true)
          let nextChapter = highestLoadedChapter + 1
          let fetchData = async () => {
            let result = await fetchChapterData(currentBook, nextChapter)
            switch result {
            | Ok(data) => {
                setLoadedChapters(prev => {
                  previous: prev.previous,
                  current: prev.current,
                  next: Some({chapter: nextChapter, data: data}),
                })
                setLoadingNext(_ => false)
                setNextLoadFailed(_ => false)
              }
            | Error(_) => {
                setLoadingNext(_ => false)
                setNextLoadFailed(_ => true)
              }
            }
          }
          let _ = fetchData()
      | Some(_nextData) => 
          // If next chapter is already loaded and we're at bottom, shift chapters forward
          if scrollTop + clientHeight > scrollHeight - 100 {
            setLoadedChapters(prev => {
              previous: prev.current,
              current: prev.next,
              next: None,
            })
          }
      }
    }
  }

  let handleHeaderClick = () => {
    if !collapsed {
      setShowSelector(_ => true)
    } else {
      setCollapsed(_ => false)
    }
  }

  let handleBookChapterSelect = (book: BibleData.book, chapter: int) => {
    setCurrentBook(_ => book.id)
    setCurrentChapter(_ => chapter)
    setPrevLoadFailed(_ => false)
    setNextLoadFailed(_ => false)
  }

  let renderChapterContent = (chapterNum: int, data: ParabibleApi.textEndpointResult) => {
    // Determine which columns have any content
    let hasContent = data->Array.reduce(Dict.make(), (acc, verseGroup) => {
      verseGroup->Array.forEach(match => {
        let moduleIdStr = match.moduleId->Int.toString
        let hasData = switch match.type_ {
        | "html" => match.html->Option.isSome
        | "wordArray" => match.wordArray->Option.isSome
        | _ => false
        }
        if hasData {
          acc->Dict.set(moduleIdStr, true)
        }
      })
      acc
    })
    
    let activeModuleIds = hasContent->Dict.keysToArray
    let chapterId = `chapter-${chapterNum->Int.toString}`
    
    <div 
      key={chapterNum->Int.toString} 
      id={chapterId}
      className="chapter-section"
    >
      <div className="py-2 mb-4 chapter-heading">
        <div className="text-lg font-semibold text-gray-400 dark:text-gray-400 text-center">{React.string(`Chapter ${chapterNum->Int.toString}`)}</div>
      </div>
      {data->Array.mapWithIndex((verseGroup, idx) => {
        <div key={`${chapterNum->Int.toString}-${idx->Int.toString}`} className="mb-6 border-b border-gray-200 dark:border-stone-700 pb-4">
          <div className="grid gap-4" style={{gridTemplateColumns: `repeat(${activeModuleIds->Array.length->Int.toString}, minmax(0, 1fr))`}}>
            {activeModuleIds->Array.map(moduleIdStr => {
              let moduleId = moduleIdStr->Int.fromString->Option.getOr(0)
              let matchForModule = verseGroup->Array.find(m => m.moduleId == moduleId)
              
              // Calculate verse number for this module
              let verseDisplay = switch matchForModule {
              | Some(match) => {
                  let verse = match.rid % 1000
                  verse->Int.toString
                }
              | None => ""
              }
              
              // Get module abbreviation for styling
              let moduleAbbrev = availableModules
                ->Array.find(m => m.ParabibleApi.moduleId == moduleId)
                ->Option.map(m => m.ParabibleApi.abbreviation)
                ->Option.getOr("")
              
              // Determine styling based on module abbreviation
              let (isRtl, fontClass, sizeClass) = switch moduleAbbrev {
              | "BHSA" => (true, "font-['SBL_BibLit']", "text-2xl")
              | "APF" | "LXXR" | "NA1904" => (false, "font-['SBL_BibLit']", "text-lg")
              | _ => (false, "", "text-md")
              }
              
              let dirClass = isRtl ? " rtl" : ""
              let columnClass = `min-w-0${dirClass} ${fontClass}`
              
              <div key={moduleIdStr} className={columnClass}>
                <span className="text-orange-500 dark:text-orange-400 font-bold mb-1 -top-1 relative pe-1 font-sans" style={ReactDOMStyle._dictToStyle({fontSize: "12px"})}>
                  {React.string(verseDisplay)}
                </span>
                {switch matchForModule {
                | Some(match) =>
                    <span className="mb-2">
                      {switch match.type_ {
                      | "html" => 
                          switch match.html {
                          | Some(htmlContent) => 
                              <span dangerouslySetInnerHTML={"__html": htmlContent} className={sizeClass} />
                          | None => React.null
                          }
                      | "wordArray" =>
                          switch match.wordArray {
                          | Some(words) =>
                              <span className={sizeClass}>
                                {words->Array.map(word => {
                                  let isSelected = switch selectedWord {
                                  | Some((selectedWid, selectedModuleId)) => 
                                      word.wid == selectedWid && moduleId == selectedModuleId
                                  | None => false
                                  }
                                  let highlightClass = isSelected 
                                    ? " text-blue-600 dark:text-blue-400" 
                                    : ""
                                  <React.Fragment key={word.wid->Int.toString}>{
                                    switch word.leader {
                                    | Some(leader) => React.string(leader)
                                    | None => React.null
                                    }}<span
                                      className={"cursor-pointer hover:text-blue-500 dark:hover:text-blue-300" ++ highlightClass}
                                      onClick={_ => onWordClick(word.wid, moduleId)}
                                    >{React.string(word.text)}</span>{
                                    switch word.trailer {
                                    | Some(trailer) => React.string(trailer)
                                    | None => React.string(" ")
                                    }}</React.Fragment>
                                })->React.array}
                              </span>
                          | None => React.null
                          }
                      | _ => React.null
                      }}
                    </span>
                | None => 
                    <div className="text-gray-400 dark:text-stone-600 text-sm italic">
                      {React.string("—")}
                    </div>
                }}
              </div>
            })->React.array}
          </div>
        </div>
      })->React.array}
    </div>
  }

  // Fetch chapter text when book, chapter, or modules change
  React.useEffect4(() => {
    // Only fetch if we have modules selected and available modules loaded
    if selectedModuleIds->Array.length > 0 && availableModules->Array.length > 0 {
      setLoading(_ => true)
      setError(_ => None)
      setVisibleChapter(_ => currentChapter)
      
      let fetchData = async () => {
        let result = await fetchChapterData(currentBook, currentChapter)
        switch result {
        | Ok(data) => {
            setLoadedChapters(_ => {
              previous: None,
              current: Some({chapter: currentChapter, data: data}),
              next: None,
            })
            setLoading(_ => false)
            
            // Preload previous chapter if not on chapter 1
            if currentChapter > 1 {
              isInitialPreload.current = true
              setLoadingPrev(_ => true)
              let prevResult = await fetchChapterData(currentBook, currentChapter - 1)
              switch prevResult {
              | Ok(prevData) => {
                  setLoadedChapters(prev => {
                    previous: Some({chapter: currentChapter - 1, data: prevData}),
                    current: prev.current,
                    next: prev.next,
                  })
                  setLoadingPrev(_ => false)
                  setPrevLoadFailed(_ => false)
                  
                  // Scroll to current chapter after preload
                  let _ = Promise.make((resolve, _reject) => {
                    let _ = setTimeout(() => {
                      switch scrollContainerRef.current->Nullable.toOption {
                      | Some(container) => {
                          let element = container->Obj.magic
                          let chapterId = `chapter-${currentChapter->Int.toString}`
                          let chapterElement = element["querySelector"](`#${chapterId}`)
                          if chapterElement !== Nullable.null->Obj.magic {
                            chapterElement["scrollIntoView"]({"behavior": "instant", "block": "start"})
                          }
                          resolve()
                        }
                      | None => resolve()
                      }
                    }, 0)
                  })
                }
              | Error(_) => {
                  setLoadingPrev(_ => false)
                  setPrevLoadFailed(_ => true)
                }
              }
            }
          }
        | Error(err) => {
            setError(_ => Some(err))
            setLoading(_ => false)
          }
        }
      }
      
      let _ = fetchData()
    }
    None
  }, (currentBook, currentChapter, selectedModuleIds, availableModules))

  // Restore scroll position after loading previous chapter
  React.useEffect1(() => {
    switch scrollContainerRef.current->Nullable.toOption {
    | Some(container) => {
        let element = container->Obj.magic
        let currentScrollHeight = element["scrollHeight"]
        let oldHeight = previousScrollHeight.current
        
        // Only adjust scroll if this was a user-initiated load (not initial preload)
        if !isInitialPreload.current && oldHeight > 0 && currentScrollHeight > oldHeight {
          // Content was added at the top, adjust scroll position
          let heightDifference = currentScrollHeight - oldHeight
          element["scrollTop"] = element["scrollTop"] + heightDifference
          previousScrollHeight.current = 0
        }
        
        // Clear the initial preload flag after first render with previous chapter
        if isInitialPreload.current {
          isInitialPreload.current = false
        }
      }
    | None => ()
    }
    None
  }, [loadedChapters.previous])

  let reference = {
    let bookName = BibleData.books
      ->Array.find(b => b.id == currentBook)
      ->Option.map(b => b.name)
      ->Option.getOr("Matthew")
    bookName ++ " " ++ visibleChapter->Int.toString
  }

  <div className="flex flex-col h-full">
    <Header collapsed={collapsed} onClick={handleHeaderClick} reference={reference} />
    <BookChapterSelector 
      isOpen={showSelector}
      onClose={() => setShowSelector(_ => false)}
      currentBook={currentBook}
      currentChapter={currentChapter}
      onSelect={handleBookChapterSelect}
    />
    <div 
      ref={scrollContainerRef->Obj.magic}
      onScroll={onScroll} 
      className="overflow-auto p-4 prose max-w-none h-full scrollbar-hide"
    >
      {switch (loading, error, loadedChapters.current) {
      | (true, _, _) => <div className="text-center py-8"> {React.string("Loading...")} </div>
      | (_, Some(err), _) => 
          <div className="text-center py-8 text-red-600 dark:text-red-400"> 
            {React.string(`Error: ${err}`)} 
          </div>
      | (false, None, Some(currentData)) => 
          <React.Fragment>
            // Top overscroll indicator
            {switch (loadedChapters.previous, loadingPrev, prevLoadFailed) {
            | (None, true, _) => 
                <div className="text-center py-4 text-gray-500 flex items-center justify-center gap-2">
                  <svg className="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 814 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  {React.string("Loading previous chapter...")}
                </div>
            | (None, false, true) => 
                <div className="text-center py-4 text-orange-500 dark:text-orange-400">
                  {React.string("⚠ Could not load previous chapter")}
                </div>
            | _ => React.null
            }}
            {switch loadedChapters.previous {
            | Some(prevData) => renderChapterContent(prevData.chapter, prevData.data)
            | None => React.null
            }}
            {renderChapterContent(currentData.chapter, currentData.data)}
            {switch loadedChapters.next {
            | Some(nextData) => renderChapterContent(nextData.chapter, nextData.data)
            | None => React.null
            }}
            // Bottom overscroll indicator
            {switch (loadedChapters.next, loadingNext, nextLoadFailed, currentData.chapter >= maxChaptersForBook) {
            | (None, true, _, _) => 
                <div className="text-center py-4 text-gray-500 flex items-center justify-center gap-2">
                  <svg className="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  {React.string("Loading next chapter...")}
                </div>
            | (None, false, true, _) => 
                <div className="text-center py-4 text-orange-500 dark:text-orange-400">
                  {React.string("⚠ Failed to load next chapter")}
                </div>
            | (None, false, false, true) => 
                <div className="text-center py-4 text-gray-400 dark:text-gray-600 text-sm">
                  {React.string("⬇ End of book")}
                </div>
            | _ => React.null
            }}
          </React.Fragment>
      | _ => 
          <div className="text-center py-8 text-gray-500"> 
            {React.string("Select a book and chapter to begin reading")} 
          </div>
      }}
    </div>
  </div>
}
