@react.component
let make = (~isOpen, ~onClose, ~currentBook, ~currentChapter, ~onSelect) => {
  let (searchText, setSearchText) = React.useState(() => "")
  let (expandedBookId, setExpandedBookId) = React.useState(() => None)
  let touchStartPos = React.useRef(None)
  let handlingEvent = React.useRef(false)

  let filteredBooks = if searchText == "" {
    BibleData.books
  } else {
    BibleData.books->Array.filter(book => {
      let search = searchText->String.toLowerCase
      book.name->String.toLowerCase->String.includes(search) ||
        book.sbl->String.toLowerCase->String.includes(search)
    })
  }

  let bookRows = BibleData.groupBooksByRow(filteredBooks)

  let handleTouchStart = e => {
    let getTouchCoords = %raw(`(e) => {
      const touch = e.touches[0];
      return touch ? { x: touch.clientX, y: touch.clientY } : null;
    }`)

    let coords = getTouchCoords(e)
    if coords !== Nullable.null {
      let x: float = %raw(`coords.x`)
      let y: float = %raw(`coords.y`)
      touchStartPos.current = Some((x, y))
    }
  }

  let handleTouchEnd = (callback, e) => {
    if !handlingEvent.current {
      let getTouchCoords = %raw(`(e) => {
        const touch = e.changedTouches[0];
        return touch ? { x: touch.clientX, y: touch.clientY } : null;
      }`)

      let coords = getTouchCoords(e)

      if coords !== Nullable.null && touchStartPos.current !== None {
        switch touchStartPos.current {
        | Some((startX, startY)) => {
            let endX: float = %raw(`coords.x`)
            let endY: float = %raw(`coords.y`)
            let deltaX = Math.abs(endX -. startX)
            let deltaY = Math.abs(endY -. startY)

            // Only trigger if movement is less than 10 pixels (not a scroll)
            if deltaX < 10.0 && deltaY < 10.0 {
              handlingEvent.current = true
              ReactEvent.Touch.preventDefault(e)
              callback()
              let _ = setTimeout(() => handlingEvent.current = false, 300)
            }
          }
        | None => ()
        }
      }
      touchStartPos.current = None
    }
  }

  let handleClick = (callback, e) => {
    if !handlingEvent.current {
      handlingEvent.current = true
      ReactEvent.Mouse.stopPropagation(e)
      callback()
      let _ = setTimeout(() => handlingEvent.current = false, 300)
    }
  }

  let handleBookClick = (bookId: string) => {
    setExpandedBookId(current =>
      switch current {
      | Some(id) if id == bookId => None
      | _ => Some(bookId)
      }
    )
  }

  let handleChapterClick = (book: BibleData.book, chapter: int) => {
    onSelect(book, chapter)
    onClose()
  }

  if !isOpen {
    React.null
  } else {
    <div className={"fixed inset-0 z-50 bg-white dark:bg-stone-900 flex flex-col animate-slide-in"}>
      // Header with search and close button
      <div className="flex items-center gap-2 p-4 border-b border-stone-200 dark:border-stone-800">
        <div className="flex-1 relative group">
          <div className="absolute inset-y-0 left-3 flex items-center pointer-events-none">
            <svg
              className="w-5 h-5 text-stone-400 dark:text-stone-500 group-focus-within:text-teal-600 transition-colors"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
          </div>
          <input
            type_="text"
            value={searchText}
            onChange={e => setSearchText(ReactEvent.Form.target(e)["value"])}
            placeholder="Search books..."
            className="w-full pl-10 pr-10 py-2 border border-stone-300 dark:border-stone-700 rounded-lg bg-white dark:bg-stone-800 text-stone-900 dark:text-stone-100 placeholder-stone-400 dark:placeholder-stone-500 focus:outline-none focus:border-teal-600 transition-colors"
          />
          {searchText != ""
            ? <button
                type_="button"
                onClick={e => handleClick(() => setSearchText(_ => ""), e)}
                onTouchStart={handleTouchStart}
                onTouchEnd={e => handleTouchEnd(() => setSearchText(_ => ""), e)}
                className="absolute inset-y-0 right-2 flex items-center p-1 hover:bg-stone-200 dark:hover:bg-stone-700 rounded transition-colors active:scale-95"
                ariaLabel="Clear search"
              >
                <svg
                  className="w-4 h-4 text-stone-500 dark:text-stone-400"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fillRule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                    clipRule="evenodd"
                  />
                </svg>
              </button>
            : React.null}
        </div>
        <button
          type_="button"
          onClick={e => handleClick(onClose, e)}
          onTouchStart={handleTouchStart}
          onTouchEnd={e => handleTouchEnd(onClose, e)}
          className="p-2 hover:bg-stone-100 dark:hover:bg-stone-800 rounded-lg transition-colors active:scale-95"
          ariaLabel="Close"
        >
          <svg
            className="w-6 h-6 text-stone-500 dark:text-stone-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      </div>

      // Scrollable content area
      <div className="flex-1 overflow-auto p-4">
        {bookRows
        ->Array.mapWithIndex((row, rowIndex) => {
          let firstBook = row->Array.get(0)

          // Check if this is the first row of a major section - only NT and Apostolic Fathers
          let isNewSection = switch firstBook {
          | Some(book) =>
            rowIndex > 0 &&
              {
                switch bookRows->Array.get(rowIndex - 1) {
                | Some(prevRow) =>
                  switch prevRow->Array.get(0) {
                  | Some(
                      prevBook,
                    ) => // Only add spacing when transitioning to NT or Apostolic Fathers
                    prevBook.category != book.category &&
                      (book.category == Gospels || book.category == ApostolicFathers)
                  | None => false
                  }
                | None => false
                }
              }

          | None => false
          }

          <div
            key={rowIndex->Int.toString}
            className={isNewSection
              ? "mb-3 mt-6 border-t border-stone-200 dark:border-stone-800 pt-6"
              : "mb-3"}
          >
            // Book buttons row
            <div className="grid grid-cols-4 gap-2 items-stretch"> // 1. items-stretch to align heights
              {row
              ->Array.map(book => {
                let underlineColor = switch book.category {
                | Pentateuch => "border-amber-500"
                | Historical => "border-cyan-500"
                | Writings => "border-purple-500"
                | Prophets => "border-emerald-500"
                | Gospels => "border-blue-500"
                | PaulineEpistles => "border-amber-500"
                | GeneralEpistles => "border-violet-500"
                | Revelation => "border-rose-500"
                | ApostolicFathers => "border-stone-400"
                }

                let isExpanded = switch expandedBookId {
                | Some(id) => id == book.id
                | None => false
                }
                let isCurrentBook = currentBook == book.id

                <button
                  type_="button"
                  key={book.id}
                  onClick={e => handleClick(() => handleBookClick(book.id), e)}
                  onTouchStart={handleTouchStart}
                  onTouchEnd={e => handleTouchEnd(() => handleBookClick(book.id), e)}
                  // 2. Button is set to relative and h-full. 
                  className={"relative h-full min-h-[2.25rem] w-full group focus:outline-none transition-transform active:scale-95 " ++ 
                    (isExpanded ? "z-10" : "z-0")
                  }
                >
                  // 3. BACKGROUND LAYER (The "Physical" Tab)
                  // This div handles the background color and the shape.
                  // If expanded, it uses negative bottom (-bottom-4) to hang down WITHOUT stretching the grid row.
                  <div 
                    className={"absolute inset-x-0 top-0 transition-all duration-200 rounded-sm " ++ 
                      (isCurrentBook ? " bg-stone-200 dark:bg-stone-700 " : " bg-stone-100 dark:bg-stone-800 hover:bg-stone-200 dark:hover:bg-stone-700 ") ++
                      (isExpanded ? "-bottom-4 shadow-sm" : "bottom-0")
                    }
                  >
                     // The colored underline is now part of this background layer
                     // It stays pinned to the bottom of the visual shape
                     // Note: --spacing = 0.25rem so p-4 = 1rem
                     <div
                      className={"absolute border-b-2 transition-all duration-120 " ++ underlineColor ++ (isExpanded ? " left-0 right-0 bottom-0" : " left-[1rem] right-[1rem] bottom-[0.25rem]")}
                    />
                  </div>

                  // 4. CONTENT LAYER
                  // This sits on top of the background. 
                  // flex/justify-center ensures text is centered regardless of how tall wrapping neighbors are.
                  <div className="relative z-20 flex flex-col items-center justify-center h-full px-2 py-2">
                    <span className="text-xs font-semibold text-stone-900 dark:text-stone-100 text-center leading-tight">
                      {React.string(book.sbl)}
                    </span>
                  </div>
                  
                  // Indicator dot stays absolute relative to the main button container
                  {isCurrentBook
                    ? <div
                        className="absolute top-1 right-1 z-30 w-1.5 h-1.5 bg-teal-600 rounded-full"
                      />
                    : React.null}
                </button>
              })
              ->React.array}
            </div>

            // Chapter buttons (expanded)
            {row
            ->Array.map(book => {
              switch expandedBookId {
              | Some(id) if id == book.id =>
                <div
                  key={book.id ++ "-chapters"}
                  className="grid gap-2 px-3 py-3 mt-4 border-t-0 overflow-hidden animate-slide-down bg-stone-100 dark:bg-stone-800"
                  style={
                    gridTemplateColumns: "repeat(auto-fit, minmax(3rem, 1fr))",
                  }
                >
                  {// Create array of chapters, prepending 0 (Prologue) if book has one
                  let hasPrologue = book.hasPrologue == Some(true)
                  let chapters = Array.fromInitializer(
                    ~length=book.chapters + (hasPrologue ? 1 : 0),
                    i => hasPrologue ? i : i + 1
                  )
                  chapters
                  ->Array.map(
                    chapter => {
                      let isSelected = currentBook == book.id && currentChapter == chapter
                      <button
                        type_="button"
                        key={chapter->Int.toString}
                        onClick={e => handleClick(() => handleChapterClick(book, chapter), e)}
                        onTouchStart={handleTouchStart}
                        onTouchEnd={e => handleTouchEnd(() => handleChapterClick(book, chapter), e)}
                        className={(
                          isSelected
                            ? "bg-teal-600 text-white scale-105"
                            : "bg-white dark:bg-stone-700 text-stone-700 dark:text-stone-200 hover:bg-stone-100 dark:hover:bg-stone-600"
                        ) ++ " h-12 text-sm font-medium transition-all duration-200 flex items-center justify-center active:scale-95"}
                      >
                        {React.string(chapter == 0 ? "Pr" : chapter->Int.toString)}
                      </button>
                    },
                  )
                  ->React.array}
                </div>
              | _ => React.null
              }
            })
            ->React.array}
          </div>
        })
        ->React.array}
      </div>

      <style>
        {React.string(`
          @keyframes slideIn {
            from {
              transform: translateY(100%);
              opacity: 0;
            }
            to {
              transform: translateY(0);
              opacity: 1;
            }
          }
          @keyframes slideDown {
            from {
              opacity: 0;
              max-height: 0;
              transform: translateY(-10px);
            }
            to {
              opacity: 1;
              max-height: 1000px;
              transform: translateY(0);
            }
          }
          .animate-slide-in {
            animation: slideIn 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          }
          .animate-slide-down {
            animation: slideDown 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          }
        `)}
      </style>
    </div>
  }
}
