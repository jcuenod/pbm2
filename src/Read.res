@module("./jsHelpers.js")
external getScrollTop: JsxEvent.UI.t => int = "getScrollTop"

type chapterData = {
  chapter: int,
  data: ParabibleApi.textEndpointResult,
}

type scrollMetrics = {
  previousHeight: float,
  previousTop: float,
}

@module("react")
external useLayoutEffect1: (unit => option<unit => unit>, 'a) => unit = "useLayoutEffect"

@react.component
let make = (
  ~selectedModuleIds,
  ~availableModules,
  ~onWordClick: (int, int) => unit,
  ~selectedWord: option<(int, int)>,
) => {
  let (collapsed, setCollapsed) = React.useState(() => false)
  let (showSelector, setShowSelector) = React.useState(() => false)
  let (currentBook, setCurrentBook) = React.useState(() => "Matt")
  let (currentChapter, setCurrentChapter) = React.useState(() => 1)

  let (chapters, setChapters) = React.useState(() => [])

  let (loading, setLoading) = React.useState(() => false)
  let (error, setError) = React.useState(() => None)
  let (loadingPrev, setLoadingPrev) = React.useState(() => false)
  let (loadingNext, setLoadingNext) = React.useState(() => false)
  let (prevLoadFailed, setPrevLoadFailed) = React.useState(() => false)
  let (nextLoadFailed, setNextLoadFailed) = React.useState(() => false)
  let (visibleChapter, setVisibleChapter) = React.useState(() => 1)
  let lastY = React.useRef(0)
  let accumulatedDy = React.useRef(0) // Track accumulated scroll for smoother header behavior
  let scrollContainerRef = React.useRef(Nullable.null)
  let scrollAdjustmentRef = React.useRef((None: option<scrollMetrics>))
  let isInitialLoadRef = React.useRef(false)
  let (scrollToChapterAfterLoad, setScrollToChapterAfterLoad) = React.useState(() => None)

  let isProgrammaticScrollRef = React.useRef(false)

  let scrollToChapter = (chapterNum: int) => {
    switch scrollContainerRef.current->Nullable.toOption {
    | Some(container) => {
        let element = container->Obj.magic
        let chapterElement = element["querySelector"](`#chapter-${chapterNum->Int.toString}`)
        if chapterElement !== Nullable.null->Obj.magic {
           isProgrammaticScrollRef.current = true
           let _ = chapterElement["scrollIntoView"]({"behavior": "smooth"})
           // Reset after a delay to allow smooth scroll to complete
           let _ = setTimeout(() => { isProgrammaticScrollRef.current = false }, 1000)
        }
      }
    | None => ()
    }
  }

  // Refs to avoid stale closures in onScroll
  let chaptersRef = React.useRef([])
  let loadingPrevRef = React.useRef(false)
  let loadingNextRef = React.useRef(false)
  let currentBookRef = React.useRef(currentBook)
  let captureScrollMetrics = () => {
    switch scrollAdjustmentRef.current {
    | Some(_) => ()
    | None =>
      switch scrollContainerRef.current->Nullable.toOption {
      | Some(container) => {
          let element = container->Obj.magic
          let previousHeight: float = element["scrollHeight"]
          let previousTop: float = element["scrollTop"]
          scrollAdjustmentRef.current = Some({previousHeight, previousTop})
        }
      | None => ()
      }
    }
  }

  React.useEffect1(() => {
    chaptersRef.current = chapters
    setLoadingPrev(_ => false)
    setLoadingNext(_ => false)
    None
  }, [chapters])

  useLayoutEffect1(() => {
    switch scrollAdjustmentRef.current {
    | Some(metrics) =>
      switch scrollContainerRef.current->Nullable.toOption {
      | Some(container) => {
          let element = container->Obj.magic
          let newHeight: float = element["scrollHeight"]
          let delta = newHeight -. metrics.previousHeight
          let nextTop = metrics.previousTop +. delta
          element["scrollTop"] = nextTop
        }
      | None => ()
      }
      scrollAdjustmentRef.current = None
      None
    | None => None
    }
  }, [chapters])

  React.useEffect1(() => {
    currentBookRef.current = currentBook
    None
  }, [currentBook])

  React.useEffect1(() => {
    loadingPrevRef.current = loadingPrev
    None
  }, [loadingPrev])

  React.useEffect1(() => {
    loadingNextRef.current = loadingNext
    None
  }, [loadingNext])

  React.useEffect1(() => {
    switch scrollToChapterAfterLoad {
    | Some(chapter) => {
        // Check if chapter exists in DOM
        // If yes, scroll and clear state
        // We use a small timeout to ensure DOM is ready
        let _ = setTimeout(() => {
          scrollToChapter(chapter)
          setScrollToChapterAfterLoad(_ => None)
        }, 100)
      }
    | None => ()
    }
    None
  }, [chapters])

  let maxChaptersForBook = React.useMemo1(() => {
    BibleData.books
    ->Array.find(b => b.id == currentBook)
    ->Option.map(b => b.chapters)
    ->Option.getOr(1)
  }, [currentBook])

  let fetchChapterData = async (book: string, chapter: int): result<
    ParabibleApi.textEndpointResult,
    string,
  > => {
    let reference = `${book}${chapter->Int.toString}`
    let modulesString =
      selectedModuleIds
      ->Array.filterMap(id => {
        availableModules
        ->Array.find((m: ParabibleApi.moduleInfo) => m.moduleId == id)
        ->Option.map((m: ParabibleApi.moduleInfo) => m.abbreviation)
      })
      ->Array.join(",")

    await ParabibleApi.fetchText(modulesString, reference)
  }

  let onScroll = e => {
    let st = getScrollTop(e)
    let dy = st - lastY.current
    lastY.current = st
    
    if !isProgrammaticScrollRef.current {
      // Accumulate scroll distance for smoother header behavior
      // Reset accumulator when direction changes
      if (dy > 0 && accumulatedDy.current < 0) || (dy < 0 && accumulatedDy.current > 0) {
        accumulatedDy.current = dy
      } else {
        accumulatedDy.current = accumulatedDy.current + dy
      }
      
      // Use larger threshold (50px) for more stable header behavior
      if accumulatedDy.current > 50 {
        setCollapsed(_ => true)
        accumulatedDy.current = 0
      } else if accumulatedDy.current < -50 {
        setCollapsed(_ => false)
        accumulatedDy.current = 0
      }
    }

    let target = e->JsxEvent.UI.target
    let container = target->Obj.magic

    // Update visible chapter
    let containerElement: {..} = container
    let chapterSections = containerElement["querySelectorAll"](".chapter-section")
    let sectionsArray: array<{..}> = chapterSections

    let visibleChapterNum = ref(visibleChapter)

    // Skip visible chapter detection during initial load to prevent race conditions
    if !isInitialLoadRef.current {
      // If we are at the very top (or overscrolled), force the first chapter
      if target["scrollTop"] <= 50 {
        switch chaptersRef.current[0] {
        | Some(c) => visibleChapterNum := c.chapter
        | None => ()
        }
      } else {
        sectionsArray->Array.forEach(section => {
          let heading = section["querySelector"](".chapter-heading")
          if heading !== Nullable.null->Obj.magic {
            let rect = heading["getBoundingClientRect"]()

            // Threshold needs to be > 64 (header 48 + padding 16) to catch the first chapter at the top
            // Increased to 150 to account for potential margins and ensure we catch the chapter even if it's pushed down slightly
            if rect["top"] <= 150. {
              let sectionId = section["id"]
              let chapterStr = sectionId->String.replace("chapter-", "")
              switch chapterStr->Int.fromString {
              | Some(num) => visibleChapterNum := num
              | None => ()
              }
            }
          }
        })
      }
      setVisibleChapter(_ => visibleChapterNum.contents)
    }

    // Infinite scroll
    let scrollTop = target["scrollTop"]
    let scrollHeight = target["scrollHeight"]
    let clientHeight = target["clientHeight"]

    let currentChapters = chaptersRef.current

    // Skip infinite scroll during initial load
    if currentChapters->Array.length > 0 && !isInitialLoadRef.current {
      switch (currentChapters[0], currentChapters[currentChapters->Array.length - 1]) {
      | (Some(firstChapter), Some(lastChapter)) => {
          // Load previous
          if (
            scrollTop < 2000 &&
            !loadingPrevRef.current &&
            !prevLoadFailed &&
            firstChapter.chapter > 1
          ) {
            setLoadingPrev(_ => true)
            loadingPrevRef.current = true

            let prevChapter = firstChapter.chapter - 1
            let bookAtStart = currentBookRef.current
            let fetchData = async () => {
              let result = await fetchChapterData(currentBook, prevChapter)
              if bookAtStart == currentBookRef.current {
                switch result {
                | Ok(data) => {
                    captureScrollMetrics()
                    setChapters(prev => {
                      if prev->Array.some(c => c.chapter == prevChapter) {
                        prev
                      } else {
                        Array.concat([{chapter: prevChapter, data}], prev)
                      }
                    })
                    // Loading state is cleared in useEffect when chapters update
                    setPrevLoadFailed(_ => false)
                  }
                | Error(_) => {
                    setLoadingPrev(_ => false)
                    setPrevLoadFailed(_ => true)
                  }
                }
              } else {
                setLoadingPrev(_ => false)
              }
            }
            let _ = fetchData()
          }

          // Load next
          if (
            scrollTop + clientHeight > scrollHeight - 2000 &&
            !loadingNextRef.current &&
            !nextLoadFailed &&
            lastChapter.chapter < maxChaptersForBook
          ) {
            setLoadingNext(_ => true)
            loadingNextRef.current = true
            let nextChapter = lastChapter.chapter + 1
            let bookAtStart = currentBookRef.current
            let fetchData = async () => {
              let result = await fetchChapterData(currentBook, nextChapter)
              if bookAtStart == currentBookRef.current {
                switch result {
                | Ok(data) => {
                    setChapters(prev => {
                      if prev->Array.some(c => c.chapter == nextChapter) {
                        prev
                      } else {
                        Array.concat(prev, [{chapter: nextChapter, data}])
                      }
                    })
                    // Loading state is cleared in useEffect when chapters update
                    setNextLoadFailed(_ => false)
                  }
                | Error(_) => {
                    setLoadingNext(_ => false)
                    setNextLoadFailed(_ => true)
                  }
                }
              } else {
                setLoadingNext(_ => false)
              }
            }
            let _ = fetchData()
          }
        }
      | _ => ()
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

  let handleNextChapter = () => {
    let nextChapter = visibleChapter + 1
    if nextChapter <= maxChaptersForBook {
      if chapters->Array.some(c => c.chapter == nextChapter) {
        scrollToChapter(nextChapter)
      } else {
        setLoadingNext(_ => true)
        loadingNextRef.current = true
        let bookAtStart = currentBookRef.current
        let fetchData = async () => {
          let result = await fetchChapterData(currentBook, nextChapter)
          if bookAtStart == currentBookRef.current {
            switch result {
            | Ok(data) => {
                setChapters(prev => {
                  if prev->Array.some(c => c.chapter == nextChapter) {
                    prev
                  } else {
                    Array.concat(prev, [{chapter: nextChapter, data}])
                  }
                })
                setNextLoadFailed(_ => false)
                setScrollToChapterAfterLoad(_ => Some(nextChapter))
              }
            | Error(_) => {
                setLoadingNext(_ => false)
                setNextLoadFailed(_ => true)
              }
            }
          } else {
            setLoadingNext(_ => false)
          }
        }
        let _ = fetchData()
      }
    }
  }

  let handlePrevChapter = () => {
    let prevChapter = visibleChapter - 1
    if prevChapter >= 1 {
      if chapters->Array.some(c => c.chapter == prevChapter) {
        scrollToChapter(prevChapter)
      } else {
        setLoadingPrev(_ => true)
        loadingPrevRef.current = true
        let bookAtStart = currentBookRef.current
        let fetchData = async () => {
          let result = await fetchChapterData(currentBook, prevChapter)
          if bookAtStart == currentBookRef.current {
            switch result {
            | Ok(data) => {
                // Important: Do NOT set scrollAdjustmentRef here because we want to jump to the new chapter
                setChapters(prev => {
                  if prev->Array.some(c => c.chapter == prevChapter) {
                    prev
                  } else {
                    Array.concat([{chapter: prevChapter, data}], prev)
                  }
                })
                setPrevLoadFailed(_ => false)
                setScrollToChapterAfterLoad(_ => Some(prevChapter))
              }
            | Error(_) => {
                setLoadingPrev(_ => false)
                setPrevLoadFailed(_ => true)
              }
            }
          } else {
            setLoadingPrev(_ => false)
          }
        }
        let _ = fetchData()
      }
    }
  }

  let handleBookChapterSelect = (book: BibleData.book, chapter: int) => {
    setCurrentBook(_ => book.id)
    setCurrentChapter(_ => chapter)
    setVisibleChapter(_ => chapter) // Reset visible chapter immediately to prevent stale display
    setPrevLoadFailed(_ => false)
    setNextLoadFailed(_ => false)
    setChapters(_ => [])
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

    // Base module ID is the first selected module
    let baseModuleId = selectedModuleIds[0]->Option.getOr(0)

    <div key={chapterNum->Int.toString} id={chapterId} className="chapter-section">
      <div className="py-2 mb-4 chapter-heading">
        <div className="text-lg font-semibold text-gray-400 dark:text-gray-400 text-center">
          {React.string(`Chapter ${chapterNum->Int.toString}`)}
        </div>
      </div>
      {data
      ->Array.mapWithIndex((verseGroup, idx) => {
        let baseMatch = verseGroup->Array.find(m => m.moduleId == baseModuleId)

        <div
          key={`${chapterNum->Int.toString}-${idx->Int.toString}`}
          className="mb-6 border-b border-gray-200 dark:border-stone-700 pb-4"
        >
          <div
            className="grid gap-4"
            style={{
              gridTemplateColumns: `repeat(${activeModuleIds
                ->Array.length
                ->Int.toString}, minmax(0, 1fr))`,
            }}
          >
            {activeModuleIds
            ->Array.map(moduleIdStr => {
              let moduleId = moduleIdStr->Int.fromString->Option.getOr(0)
              let matchForModule = verseGroup->Array.find(m => m.moduleId == moduleId)

              let moduleAbbrev =
                availableModules
                ->Array.find(m => m.ParabibleApi.moduleId == moduleId)
                ->Option.map(m => m.ParabibleApi.abbreviation)
                ->Option.getOr("")

              <VerseColumn
                key={moduleIdStr}
                match={matchForModule}
                baseMatch={baseMatch}
                moduleId={moduleId}
                moduleAbbrev={moduleAbbrev}
                selectedWord={selectedWord}
                onWordClick={onWordClick}
              />
            })
            ->React.array}
          </div>
        </div>
      })
      ->React.array}
    </div>
  }

  React.useEffect4(() => {
    let cancelled = ref(false)
    if selectedModuleIds->Array.length > 0 && availableModules->Array.length > 0 {
      isInitialLoadRef.current = true
      setLoading(_ => true)
      setError(_ => None)
      setVisibleChapter(_ => currentChapter)
      setChapters(_ => [])

      let fetchData = async () => {
        let result = await fetchChapterData(currentBook, currentChapter)
        if !cancelled.contents {
          switch result {
          | Ok(data) => {
              setChapters(_ => [{chapter: currentChapter, data}])
              setLoading(_ => false)

              if currentChapter < maxChaptersForBook {
                let nextResult = await fetchChapterData(currentBook, currentChapter + 1)
                if !cancelled.contents {
                  switch nextResult {
                  | Ok(nextData) =>
                    setChapters(prev => {
                      if prev->Array.some(c => c.chapter == currentChapter + 1) {
                        prev
                      } else {
                        Array.concat(prev, [{chapter: currentChapter + 1, data: nextData}])
                      }
                    })
                  | _ => ()
                  }
                }
              }

              if currentChapter <= 1 {
                // No previous chapter to load, clear initial load flag
                let _ = setTimeout(() => {
                  isInitialLoadRef.current = false
                }, 100)
              } else {
                let prevResult = await fetchChapterData(currentBook, currentChapter - 1)
                if !cancelled.contents {
                  switch prevResult {
                  | Ok(prevData) => {
                      captureScrollMetrics()
                      setChapters(prev => {
                        if prev->Array.some(c => c.chapter == currentChapter - 1) {
                          prev
                        } else {
                          Array.concat([{chapter: currentChapter - 1, data: prevData}], prev)
                        }
                      })

                      // Adjust scroll to keep current chapter in view
                      // We need to do this after render, but since we can't easily use useLayoutEffect with async data in this structure
                      // we rely on the fact that this is the initial load and we can scroll to the specific element
                      let _ = setTimeout(() => {
                        if !cancelled.contents {
                          switch scrollContainerRef.current->Nullable.toOption {
                          | Some(container) => {
                              let element = container->Obj.magic
                              let chapterId = `chapter-${currentChapter->Int.toString}`
                              let chapterElement = element["querySelector"](`#${chapterId}`)
                              if chapterElement !== Nullable.null->Obj.magic {
                                chapterElement["scrollIntoView"]({
                                  "behavior": "instant",
                                  "block": "start",
                                })
                              }
                              // Clear initial load flag after scroll adjustment
                              let _ = setTimeout(() => {
                                isInitialLoadRef.current = false
                              }, 100)
                            }
                          | None => isInitialLoadRef.current = false
                          }
                        } else {
                          isInitialLoadRef.current = false
                        }
                      }, 0)
                    }
                  | _ => isInitialLoadRef.current = false
                  }
                }
              }
            }
          | Error(err) => {
              isInitialLoadRef.current = false
              setError(_ => Some(err))
              setLoading(_ => false)
            }
          }
        }
      }
      let _ = fetchData()
    }
    Some(() => {cancelled := true})
  }, (currentBook, currentChapter, selectedModuleIds, availableModules))

  let reference = {
    let bookName =
      BibleData.books
      ->Array.find(b => b.id == currentBook)
      ->Option.map(b => b.name)
      ->Option.getOr("Matthew")
    bookName ++ " " ++ visibleChapter->Int.toString
  }

  <div className="flex flex-col h-full">
    <Header 
      collapsed={collapsed} 
      onClick={handleHeaderClick} 
      reference={reference}
      onNext=?{visibleChapter < maxChaptersForBook ? Some(handleNextChapter) : None}
      onPrev=?{visibleChapter > 1 ? Some(handlePrevChapter) : None}
    />
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
      style={ReactDOMStyle._dictToStyle(Dict.fromArray([("overflowAnchor", "auto")]))}
    >
      {switch (loading, error, chapters->Array.length > 0) {
      | (true, _, false) => <div className="text-center py-8"> {React.string("Loading...")} </div>
      | (_, Some(err), _) =>
        <div className="text-center py-8 text-red-600 dark:text-red-400">
          {React.string(`Error: ${err}`)}
        </div>
      | (false, None, true) =>
        <React.Fragment>
          {switch (loadingPrev, prevLoadFailed) {
          | (true, _) =>
            <div
              className="text-center py-4 text-gray-500 flex items-center justify-center gap-2"
              style={{minHeight: "100vh"}}
            >
              <svg
                className="animate-spin h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                >
                </circle>
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 814 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                >
                </path>
              </svg>
              {React.string("Loading previous chapter...")}
            </div>
          | (false, true) =>
            <div className="text-center py-4 text-orange-500 dark:text-orange-400">
              {React.string("⚠ Could not load previous chapter")}
            </div>
          | _ => React.null
          }}

          {chapters
          ->Array.map(chapter => {
            renderChapterContent(chapter.chapter, chapter.data)
          })
          ->React.array}

          {switch (loadingNext, nextLoadFailed, chapters[chapters->Array.length - 1]) {
          | (true, _, _) =>
            <div className="text-center py-4 text-gray-500 flex items-center justify-center gap-2">
              <svg
                className="animate-spin h-4 w-4"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                >
                </circle>
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                >
                </path>
              </svg>
              {React.string("Loading next chapter...")}
            </div>
          | (false, true, _) =>
            <div className="text-center py-4 text-orange-500 dark:text-orange-400">
              {React.string("⚠ Failed to load next chapter")}
            </div>
          | (false, false, Some(last)) if last.chapter >= maxChaptersForBook =>
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
