// Helper to find attribute value by key
let findAttr = (attrs: array<ParabibleApi.wordAttribute>, key: string): option<string> => {
  attrs->Array.find(attr => attr.key == key)->Option.map(attr => attr.value)
}

// Helper to get attribute value or empty string
let getAttr = (attrs: array<ParabibleApi.wordAttribute>, key: string): string => {
  findAttr(attrs, key)->Option.getOr("")
}

// Check if text contains Hebrew characters
let isHebrew = (str: string): bool => {
  %re("/[\u0590-\u05FF]/")->RegExp.test(str)
}

// Format word details into primary and secondary display data
let formatWordDetails = (attrs: array<ParabibleApi.wordAttribute>): (array<string>, array<string>) => {
  let lexeme = getAttr(attrs, "lexeme")
  let gloss = getAttr(attrs, "gloss")
  let pos = getAttr(attrs, "part_of_speech")
  
  // Primary data: lexeme and gloss
  let primary = [lexeme, gloss]->Array.filter(s => s != "")
  
  // Secondary data: morphological details
  let secondary = if lexeme != "" && isHebrew(lexeme) {
    // Hebrew
    if pos == "verb" {
      let tense = getAttr(attrs, "tense")
      if tense == "ptca" || tense == "ptcp" {
        // Participle
        [
          getAttr(attrs, "stem"),
          tense,
          getAttr(attrs, "gender"),
          getAttr(attrs, "number")
        ]
      } else if tense == "infa" || tense == "infc" {
        // Infinitive
        [
          getAttr(attrs, "stem"),
          tense
        ]
      } else {
        // Finite verb
        let person = getAttr(attrs, "person")
        let gender = getAttr(attrs, "gender")
        let number = getAttr(attrs, "number")
        let pgn = if person != "" && gender != "" && number != "" {
          person ++ String.charAt(gender, 0) ++ String.charAt(number, 0)
        } else {
          ""
        }
        [
          getAttr(attrs, "stem"),
          tense,
          pgn
        ]
      }
    } else {
      // Not a verb
      [
        getAttr(attrs, "gender"),
        getAttr(attrs, "number")
      ]
    }
  } else if lexeme != "" {
    // Greek (assumption: not Hebrew but has lexeme)
    if pos == "verb" {
      let mood = getAttr(attrs, "mood")
      if mood == "ptc" {
        // Participle
        [
          getAttr(attrs, "tense"),
          getAttr(attrs, "voice"),
          mood,
          getAttr(attrs, "case_"),
          getAttr(attrs, "gender"),
          getAttr(attrs, "number")
        ]
      } else {
        // Other verb forms
        let person = getAttr(attrs, "person")
        let number = getAttr(attrs, "number")
        let pn = if person != "" && number != "" {
          person ++ number
        } else {
          ""
        }
        [
          getAttr(attrs, "tense"),
          getAttr(attrs, "voice"),
          mood,
          pn
        ]
      }
    } else {
      // Not a verb
      [
        getAttr(attrs, "case_"),
        getAttr(attrs, "gender"),
        getAttr(attrs, "number")
      ]
    }
  } else {
    []
  }
  
  let filteredSecondary = secondary->Array.filter(s => s != "")
  let finalSecondary = if filteredSecondary->Array.length > 0 {
    filteredSecondary
  } else {
    [pos]->Array.filter(s => s != "")
  }
  
  (primary, finalSecondary)
}

@react.component
let make = (~selectedWord: option<(int, int)>, ~onAddSearchTerms: (array<ParabibleApi.searchTermData>, bool) => unit, ~hasExistingSearchTerms: bool) => {
  let (wordDetails, setWordDetails) = React.useState(() => None)
  let (loading, setLoading) = React.useState(() => false)
  let (error, setError) = React.useState(() => None)
  let (selectedAttributes, setSelectedAttributes) = React.useState(() => [])
  let (showMenu, setShowMenu) = React.useState(() => false)

  // Fetch word details when selectedWord changes
  React.useEffect1(() => {
    switch selectedWord {
    | Some((wid, moduleId)) => {
        setLoading(_ => true)
        setError(_ => None)
        
        let fetchData = async () => {
          let result = await ParabibleApi.fetchWordDetails(wid, moduleId)
          switch result {
          | Ok(data) => {
              setWordDetails(_ => Some(data))
              setLoading(_ => false)
            }
          | Error(err) => {
              setError(_ => Some(err))
              setLoading(_ => false)
            }
          }
        }
        
        let _ = fetchData()
      }
    | None => {
        setWordDetails(_ => None)
        setLoading(_ => false)
        setError(_ => None)
        setSelectedAttributes(_ => [])
      }
    }
    None
  }, [selectedWord])
  
  // Close menu when clicking outside
  React.useEffect1(() => {
    if showMenu {
      let handleClickOutside = (e: Dom.event) => {
        let target = e->Webapi.Dom.Event.target->Webapi.Dom.EventTarget.unsafeAsElement
        // Check if click is outside the FAB container
        let fabContainer = Webapi.Dom.document->Webapi.Dom.Document.querySelector(".fab-container")
        switch fabContainer {
        | Some(container) => {
            if !(container->Webapi.Dom.Element.contains(~child=target)) {
              setShowMenu(_ => false)
            }
          }
        | None => ()
        }
      }
      
      Webapi.Dom.document
        ->Webapi.Dom.Document.asEventTarget
        ->Webapi.Dom.EventTarget.addEventListener("click", handleClickOutside)
      
      Some(() => {
        Webapi.Dom.document
          ->Webapi.Dom.Document.asEventTarget
          ->Webapi.Dom.EventTarget.removeEventListener("click", handleClickOutside)
      })
    } else {
      None
    }
  }, [showMenu])

  <div className="flex flex-col h-full">
    {switch (loading, error, wordDetails, selectedWord) {
    | (true, _, _, _) => 
        <div className="text-center py-8"> {React.string("Loading...")} </div>
    | (_, Some(err), _, _) => 
        <div className="text-center py-8 text-red-600 dark:text-red-400"> 
          {React.string(`Error: ${err}`)} 
        </div>
    | (false, None, Some(details), Some((_wid, _moduleId))) => {
        let (primary, secondary) = formatWordDetails(details)
        
        <div className="flex flex-col h-full">
          // Primary information (lexeme and gloss)
          <div className="bg-blue-50 dark:bg-blue-950 border-b-2 border-blue-200 dark:border-blue-800 p-4 flex items-center justify-center gap-4">
            {primary->Array.mapWithIndex((d, i) => {
              let fontFamily = if i == 0 {
                "font-['SBL_BibLit']"
              } else {
                ""
              }
              <div 
                key={Int.toString(i)} 
                className={`text-center font-bold text-xl ${fontFamily}`}
              >
                {React.string(d)}
              </div>
            })->React.array}
          </div>
          
          // Secondary information (morphology)
          <div className="bg-gray-50 dark:bg-stone-900 border-b border-gray-200 dark:border-stone-700 p-3 text-center text-sm">
            {React.string(secondary->Array.join(" ")->String.toLowerCase)}
          </div>
          
          // Full attribute list
          <div className="flex-1 overflow-auto p-4 pb-24">
            <h2 className="text-lg font-semibold mb-3 text-gray-700 dark:text-gray-300">
              {React.string("All Attributes")}
            </h2>
            <div className="space-y-2">
              {details->Array.map(attr => {
                let isSelected = selectedAttributes->Array.some(((k, v)) => k == attr.key && v == attr.value)
                let bgColor = isSelected 
                  ? "bg-blue-100 dark:bg-blue-900 border-blue-500" 
                  : "bg-white dark:bg-stone-800 border-gray-200 dark:border-stone-700"
                
                <div 
                  key={attr.key} 
                  className={`border rounded p-3 cursor-pointer transition-colors ${bgColor}`}
                  onClick={_ => {
                    setSelectedAttributes(current => {
                      let attrTuple = (attr.key, attr.value)
                      if current->Array.some(a => a == attrTuple) {
                        current->Array.filter(a => a != attrTuple)
                      } else {
                        Array.concat(current, [attrTuple])
                      }
                    })
                  }}
                >
                  <div className="font-semibold text-xs text-gray-500 dark:text-gray-400 uppercase tracking-wide">
                    {React.string(attr.key)}
                  </div>
                  <div className="mt-1 text-gray-900 dark:text-gray-100">
                    {React.string(attr.value)}
                  </div>
                </div>
              })->React.array}
            </div>
          </div>
          
          // FAB Button
          <div className="fab-container fixed bottom-[1.5rem] right-6 flex flex-col items-end gap-0">
              // Backdrop overlay when menu is open
              {showMenu ? <div 
                className="fixed inset-0 z-10"
                onClick={_ => setShowMenu(_ => false)}
              /> : React.null}
              
              // Menu with arrow
              {showMenu 
              ? <div className="relative transition-all duration-200 mb-3 opacity-100 translate-y-0 z-20">
                <div className="bg-white dark:bg-stone-800 rounded-lg shadow-lg overflow-hidden border border-gray-200 dark:border-stone-700">
                  <button
                    onClick={_ => {
                      let attributes = if selectedAttributes->Array.length > 0 {
                        selectedAttributes
                      } else {
                        [("lexeme", getAttr(details, "lexeme"))]
                      }
                      let newTerm: ParabibleApi.searchTermData = {
                        inverted: false,
                        attributes: attributes,
                      }
                      onAddSearchTerms([newTerm], false)
                      setSelectedAttributes(_ => [])
                      setShowMenu(_ => false)
                    }}
                    className="w-full px-4 py-3 text-left hover:bg-gray-100 dark:hover:bg-stone-700 transition-colors border-b border-gray-200 dark:border-stone-700"
                  >
                    <div className="font-semibold text-sm">{React.string("Add to Search")}</div>
                    <div className="text-xs text-gray-600 dark:text-gray-400 mt-0.5">
                      {React.string("Keep existing search terms")}
                    </div>
                  </button>
                  <button
                    onClick={_ => {
                      let attributes = if selectedAttributes->Array.length > 0 {
                        selectedAttributes
                      } else {
                        [("lexeme", getAttr(details, "lexeme"))]
                      }
                      let newTerm: ParabibleApi.searchTermData = {
                        inverted: false,
                        attributes: attributes,
                      }
                      onAddSearchTerms([newTerm], true)
                      setSelectedAttributes(_ => [])
                      setShowMenu(_ => false)
                    }}
                    className="w-full px-4 py-3 text-left hover:bg-gray-100 dark:hover:bg-stone-700 transition-colors"
                  >
                    <div className="font-semibold text-sm">{React.string("Clear & Search")}</div>
                    <div className="text-xs text-gray-600 dark:text-gray-400 mt-0.5">
                      {React.string("Replace all search terms")}
                    </div>
                  </button>
                </div>
                // Arrow pointing down to FAB
                <div className="absolute -bottom-1.5 right-5 w-0 h-0 border-l-8 border-r-8 border-t-8 border-l-transparent border-r-transparent border-t-white dark:border-t-stone-800" />
              </div>
              : React.null}
              
              // FAB
              <button
                onClick={_ => {
                  if hasExistingSearchTerms {
                    setShowMenu(show => !show)
                  } else {
                    // No existing search terms, add directly and navigate
                    let attributes = if selectedAttributes->Array.length > 0 {
                      selectedAttributes
                    } else {
                      [("lexeme", getAttr(details, "lexeme"))]
                    }
                    let newTerm: ParabibleApi.searchTermData = {
                      inverted: false,
                      attributes: attributes,
                    }
                    onAddSearchTerms([newTerm], false)
                    setSelectedAttributes(_ => [])
                  }
                }}
                className="w-14 h-14 bg-blue-600 hover:bg-blue-700 text-white rounded-full shadow-lg flex items-center justify-center transition-all transform hover:scale-110 z-20 relative"
                title="Search"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </button>
            </div>
        </div>
      }
    | _ => 
        <div className="flex items-center justify-center h-full text-gray-500 dark:text-gray-400 p-8 text-center"> 
          {React.string("Click on a word in the Read view to see its details")} 
        </div>
    }}
  </div>
}
