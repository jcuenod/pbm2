// Import features data
@module("./assets/features.json") external featuresData: {..} = "default"

type featureInfo = {
  key: string,
  value: string,
  @as("enum") enum_: bool,
}

type featureValue = {
  feature: string,
  key: string,
  value: string,
}

let features: array<featureInfo> = featuresData["features"]
let values: array<featureValue> = featuresData["values"]

// Translate feature key to readable label
let translateFeatureKey = (key: string): string => {
  features
  ->Array.find(f => f.key == key)
  ->Option.map(f => f.value)
  ->Option.getOr(String.replaceAll(key, "_", " "))
}

// Translate feature value to readable label
let translateFeatureValue = (featureKey: string, valueKey: string): string => {
  values
  ->Array.find(v => v.feature == featureKey && v.key == valueKey)
  ->Option.map(v => v.value)
  ->Option.getOr(valueKey)
}

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
  /[\u0590-\u05FF]/->RegExp.test(str)
}

let isGreek = (str: string): bool => {
  /[\u0370-\u03FF\u1F00-\u1FFF]/->RegExp.test(str)
}

// Format word details into primary and secondary display data
let formatWordDetails = (attrs: array<ParabibleApi.wordAttribute>): (
  array<string>,
  array<string>,
) => {
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
        [getAttr(attrs, "stem"), tense, getAttr(attrs, "gender"), getAttr(attrs, "number")]
      } else if tense == "infa" || tense == "infc" {
        // Infinitive
        [getAttr(attrs, "stem"), tense]
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
        [getAttr(attrs, "stem"), tense, pgn]
      }
    } else {
      // Not a verb
      [getAttr(attrs, "gender"), getAttr(attrs, "number")]
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
          getAttr(attrs, "number"),
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
        [getAttr(attrs, "tense"), getAttr(attrs, "voice"), mood, pn]
      }
    } else {
      // Not a verb
      [getAttr(attrs, "case_"), getAttr(attrs, "gender"), getAttr(attrs, "number")]
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

type toolTab =
  | WordDetails
  | Dictionaries
  | Commentaries

@react.component
let make = (
  ~selectedWord: option<(int, int)>,
  ~onAddSearchTerms: (array<ParabibleApi.searchTermData>, bool) => unit,
  ~hasExistingSearchTerms: bool,
) => {
  let (activeTab, setActiveTab) = React.useState(() => WordDetails)
  let tabIndex = switch activeTab {
  | WordDetails => 0
  | Dictionaries => 1
  | Commentaries => 2
  }
  let (wordDetails, setWordDetails) = React.useState(() => None)
  let (loading, setLoading) = React.useState(() => false)
  let (error, setError) = React.useState(() => None)
  let (selectedAttributes, setSelectedAttributes) = React.useState(() => [])
  let (showMenu, setShowMenu) = React.useState(() => false)

  // // Dictionary state
  // let (dictionaryEntries, setDictionaryEntries) = React.useState(() => None)
  // let (dictionaryLoading, setDictionaryLoading) = React.useState(() => false)
  // let (dictionaryError, setDictionaryError) = React.useState(() => None)

  // Switch to WordDetails tab when a new word is selected
  React.useEffect1(() => {
    switch selectedWord {
    | Some(_) => setActiveTab(_ => WordDetails)
    | None => ()
    }
    None
  }, [selectedWord])

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

  // Fetch dictionary entries when activeTab changes to Dictionaries
  // React.useEffect2(() => {
  //   if activeTab == Dictionaries {
  //     switch wordDetails {
  //     | Some(details) => {
  //         let lexeme = getAttr(details, "lexeme")
  //         if lexeme != "" {
  //           setDictionaryLoading(_ => true)
  //           setDictionaryError(_ => None)

  //           let fetchData = async () => {
  //             let result = await ParabibleApi.fetchDictionaryEntry(lexeme)
  //             switch result {
  //             | Ok(entries) => {
  //                 setDictionaryEntries(_ => Some(entries))
  //                 setDictionaryLoading(_ => false)
  //               }
  //             | Error(err) => {
  //                 setDictionaryError(_ => Some(err))
  //                 setDictionaryLoading(_ => false)
  //               }
  //             }
  //           }

  //           let _ = fetchData()
  //         }
  //       }
  //     | None => ()
  //     }
  //   }
  //   None
  // }, (activeTab, wordDetails))

  // Close menu when clicking outside
  React.useEffect1(() => {
    if showMenu {
      let handleClickOutside = (e: Dom.event) => {
        let target = e->Webapi.Dom.Event.target->Webapi.Dom.EventTarget.unsafeAsElement
        // Check if click is outside the FAB container
        let fabContainer = Webapi.Dom.document->Webapi.Dom.Document.querySelector(".fab-container")
        switch fabContainer {
        | Some(container) =>
          if !(container->Webapi.Dom.Element.contains(~child=target)) {
            setShowMenu(_ => false)
          }
        | None => ()
        }
      }

      Webapi.Dom.document
      ->Webapi.Dom.Document.asEventTarget
      ->Webapi.Dom.EventTarget.addEventListener("click", handleClickOutside)

      Some(
        () => {
          Webapi.Dom.document
          ->Webapi.Dom.Document.asEventTarget
          ->Webapi.Dom.EventTarget.removeEventListener("click", handleClickOutside)
        },
      )
    } else {
      None
    }
  }, [showMenu])

  <div className="flex flex-col h-full bg-white dark:bg-stone-950">
    <div className="p-4 bg-white dark:bg-stone-900">
      <h1 className="text-2xl font-bold mb-4 text-gray-900 dark:text-gray-100">
        {React.string("Tools")}
      </h1>
      <div className="relative flex border-b border-gray-200 dark:border-stone-700">
        <div
          className="absolute bottom-0 h-0.5 bg-teal-600 dark:bg-teal-400 transition-all duration-300 ease-in-out"
          style={{
            left: `calc(100% / 3 * ${Int.toString(tabIndex)})`,
            width: "calc(100% / 3)",
          }}
        />
        <button
          className={`flex-1 pb-3 text-sm font-medium transition-colors ${activeTab == WordDetails
              ? "text-teal-600 dark:text-teal-400"
              : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"}`}
          onClick={_ => setActiveTab(_ => WordDetails)}
        >
          {React.string("Word Details")}
        </button>
        <button
          className={`flex-1 pb-3 text-sm font-medium transition-colors ${activeTab == Dictionaries
              ? "text-teal-600 dark:text-teal-400"
              : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"}`}
          onClick={_ => setActiveTab(_ => Dictionaries)}
        >
          {React.string("Dictionaries")}
        </button>
        <button
          className={`flex-1 pb-3 text-sm font-medium transition-colors ${activeTab == Commentaries
              ? "text-teal-600 dark:text-teal-400"
              : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"}`}
          onClick={_ => setActiveTab(_ => Commentaries)}
        >
          {React.string("Commentaries")}
        </button>
      </div>
    </div>
    <div className="flex-1 overflow-hidden flex flex-col relative">
      {switch activeTab {
      | WordDetails =>
        switch (loading, error, wordDetails, selectedWord) {
        | (true, _, _, _) => <div className="text-center py-8"> {React.string("Loading...")} </div>
        | (_, Some(err), _, _) =>
          <div className="text-center py-8 text-red-600 dark:text-red-400">
            {React.string(`Error: ${err}`)}
          </div>
        | (false, None, Some(details), Some((_wid, _moduleId))) => {
            let (primary, secondary) = formatWordDetails(details)

            <div className="flex flex-col h-full">
              // Primary information (lexeme and gloss)
              <div
                className="bg-teal-50 dark:bg-teal-950 border-t-2 border-b-2 border-teal-200 dark:border-teal-800 p-4 flex items-center justify-center gap-4"
              >
                {primary
                ->Array.mapWithIndex((d, i) => {
                  let fontFamily = if i == 0 {
                    "font-['SBL_BibLit']"
                  } else {
                    ""
                  }
                  <div
                    key={Int.toString(i)} className={`text-center font-bold text-xl ${fontFamily}`}
                  >
                    {React.string(d)}
                  </div>
                })
                ->React.array}
              </div>

              // Secondary information (morphology)
              <div
                className="bg-gray-50 dark:bg-stone-900 border-b border-gray-200 dark:border-stone-700 p-3 text-center text-sm"
              >
                {React.string(secondary->Array.join(" ")->String.toLowerCase)}
              </div>

              // Full attribute list
              <div className="flex-1 overflow-auto p-4 pb-24">
                <h2 className="text-lg font-semibold mb-3 text-gray-700 dark:text-gray-300">
                  {React.string("All Attributes")}
                </h2>
                <div className="space-y-2">
                  {details
                  ->Array.map(attr => {
                    let isSelected =
                      selectedAttributes->Array.some(((k, v)) => k == attr.key && v == attr.value)
                    let bgColor = isSelected
                      ? "bg-teal-100 dark:bg-teal-900 border-teal-500"
                      : "bg-white dark:bg-stone-800 border-gray-200 dark:border-stone-700"
                    let langClass = if isHebrew(attr.value) {
                      "font-['SBL_BibLit'] text-xl rtl text-right"
                    } else if isGreek(attr.value) {
                      "font-['SBL_BibLit'] text-lg tracking-wide"
                    } else {
                      ""
                    }

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
                      <div
                        className="font-semibold text-xs text-gray-500 dark:text-gray-400 uppercase tracking-wide"
                      >
                        {translateFeatureKey(attr.key)->React.string}
                      </div>
                      <div className={`mt-1 text-gray-900 dark:text-gray-100 ${langClass}`}>
                        {translateFeatureValue(attr.key, attr.value)->React.string}
                      </div>
                    </div>
                  })
                  ->React.array}
                </div>
              </div>

              // FAB Button
              <div
                className="fab-container fixed bottom-[1rem] right-6 flex flex-col items-end gap-0 pointer-events-none"
              >
                // Backdrop overlay when menu is open (semi-transparent, click to close)
                <div
                  className={"fixed inset-0 transition-opacity duration-120 bg-black/40 dark:bg-black/50 z-10 " ++ (
                    showMenu ? "pointer-events-auto" : "opacity-0"
                  )}
                  role="presentation"
                  ariaHidden={true}
                  onClick={_ => setShowMenu(_ => false)}
                />
                // Menu with arrow
                <div
                  className={"relative w-[80vw] transition-all duration-120 mb-3 z-30 " ++ (
                    showMenu ? "pointer-events-auto" : "-translate-y-3 opacity-0"
                  )}
                >
                  <div
                    className="bg-white dark:bg-stone-800 rounded-lg shadow-lg overflow-hidden border border-gray-200 dark:border-stone-700"
                  >
                    <button
                      onClick={_ => {
                        let attributes = if selectedAttributes->Array.length > 0 {
                          selectedAttributes
                        } else {
                          [("lexeme", getAttr(details, "lexeme"))]
                        }
                        let newTerm: ParabibleApi.searchTermData = {
                          inverted: false,
                          attributes,
                        }
                        onAddSearchTerms([newTerm], false)
                        setSelectedAttributes(_ => [])
                        setShowMenu(_ => false)
                      }}
                      className="w-full px-4 py-3 text-left hover:bg-gray-100 dark:hover:bg-stone-700 transition-colors border-b border-gray-200 dark:border-stone-700"
                    >
                      <div className="font-semibold text-sm"> {React.string("Add to Search")} </div>
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
                          attributes,
                        }
                        onAddSearchTerms([newTerm], true)
                        setSelectedAttributes(_ => [])
                        setShowMenu(_ => false)
                      }}
                      className="w-full px-4 py-3 text-left hover:bg-gray-100 dark:hover:bg-stone-700 transition-colors"
                    >
                      <div className="font-semibold text-sm">
                        {React.string("Clear & Search")}
                      </div>
                      <div className="text-xs text-gray-600 dark:text-gray-400 mt-0.5">
                        {React.string("Replace all search terms")}
                      </div>
                    </button>
                  </div>
                  // Arrow pointing down to FAB
                  <div
                    className="absolute -bottom-1.5 right-5 w-0 h-0 border-l-8 border-r-8 border-t-8 border-l-transparent border-r-transparent border-t-white dark:border-t-stone-800"
                  />
                </div>

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
                        attributes,
                      }
                      onAddSearchTerms([newTerm], false)
                      setSelectedAttributes(_ => [])
                    }
                  }}
                  className="w-14 h-14 bg-teal-600 hover:bg-teal-700 text-white rounded-full shadow-lg flex items-center justify-center transition-all transform hover:scale-110 z-40 relative pointer-events-auto"
                  title="Search"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                    />
                  </svg>
                </button>
              </div>
            </div>
          }
        | _ =>
          <div
            className="flex items-center justify-center h-full text-gray-500 dark:text-gray-400 p-8 text-center"
          >
            {React.string("Click on a word in the Read view to see its details")}
          </div>
        }
      | Dictionaries =>
        <div
          className="flex items-center justify-center h-full text-gray-500 dark:text-gray-400 p-8 text-center"
        >
          {React.string("Dictionaries is just a dream right now...")}
        </div>
      // switch (dictionaryLoading, dictionaryError, dictionaryEntries, wordDetails) {
      // | (true, _, _, _) =>
      //   <div className="flex items-center justify-center h-full p-8">
      //     <div className="text-center">
      //       <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600 mx-auto mb-4" />
      //       <div className="text-gray-600 dark:text-gray-400">{React.string("Loading dictionary entry...")}</div>
      //     </div>
      //   </div>
      // | (_, Some(err), _, _) =>
      //   <div className="flex items-center justify-center h-full text-red-600 dark:text-red-400 p-8 text-center">
      //     {React.string(`Error loading dictionary: ${err}`)}
      //   </div>
      // | (false, None, Some(entries), Some(details)) =>
      //   if entries->Array.length > 0 {
      //     <div className="flex-1 overflow-auto p-4">
      //       {entries->Array.mapWithIndex((entry, idx) => {
      //         <div key={entry.id} className="mb-6">
      //           {idx == 0 ? React.null : <hr className="mb-6 border-gray-200 dark:border-stone-700" />}
      //           <div className="bg-white dark:bg-stone-900 rounded-lg border border-gray-200 dark:border-stone-700 p-4">
      //             <div className="mb-2 text-xs text-gray-500 dark:text-gray-400 font-mono">
      //               {React.string("Abbot Smith")}
      //               // {React.string(entry.uri)}
      //             </div>
      //             <div
      //               className="prose prose-sm dark:prose-invert max-w-none"
      //               dangerouslySetInnerHTML={{"__html": entry.xmlContent}}
      //             />
      //           </div>
      //         </div>
      //       })->React.array}
      //     </div>
      //   } else {
      //     let lexeme = getAttr(details, "lexeme")
      //     <div className="flex items-center justify-center h-full text-gray-500 dark:text-gray-400 p-8 text-center">
      //       <div>
      //         <div className="text-lg mb-2">{React.string("No dictionary entries found")}</div>
      //         {lexeme != ""
      //           ? <div className="text-sm font-['SBL_BibLit']">{React.string(`for "${lexeme}"`)}</div>
      //           : React.null
      //         }
      //       </div>
      //     </div>
      //   }
      // | _ =>
      //   <div className="flex items-center justify-center h-full text-gray-500 dark:text-gray-400 p-8 text-center">
      //     {React.string("Select a word to view dictionary entries")}
      //   </div>
      // }
      | Commentaries =>
        <div
          className="flex items-center justify-center h-full text-gray-500 dark:text-gray-400 p-8 text-center"
        >
          {React.string("Commentaries is just a dream right now...")}
        </div>
      }}
    </div>
  </div>
}
