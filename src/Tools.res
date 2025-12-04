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
        setSelectedAttributes(_ => []) // Clear selections when word changes
      }
    }
    None
  }, [selectedWord])
  
  let toggleAttribute = (key: string, value: string) => {
    setSelectedAttributes(current => {
      let attrTuple = (key, value)
      if current->Array.some(attr => attr == attrTuple) {
        current->Array.filter(attr => attr != attrTuple)
      } else {
        Array.concat(current, [attrTuple])
      }
    })
  }
  
  let handleFabClick = () => {
    if hasExistingSearchTerms {
      setShowMenu(show => !show)
    } else {
      // No existing search terms, add directly and navigate
      let newTerm: ParabibleApi.searchTermData = {
        inverted: false,
        attributes: selectedAttributes,
      }
      onAddSearchTerms([newTerm], false)
      setSelectedAttributes(_ => [])
    }
  }
  
  let handleAddToSearch = () => {
    let newTerm: ParabibleApi.searchTermData = {
      inverted: false,
      attributes: selectedAttributes,
    }
    onAddSearchTerms([newTerm], false)
    setSelectedAttributes(_ => [])
    setShowMenu(_ => false)
  }
  
  let handleClearAndSearch = () => {
    let newTerm: ParabibleApi.searchTermData = {
      inverted: false,
      attributes: selectedAttributes,
    }
    onAddSearchTerms([newTerm], true)
    setSelectedAttributes(_ => [])
    setShowMenu(_ => false)
  }

  <div className="flex flex-col h-full p-4">
    <h1 className="text-2xl font-bold mb-4">{React.string("Word Details")}</h1>
    {switch (loading, error, wordDetails, selectedWord) {
    | (true, _, _, _) => 
        <div className="text-center py-8"> {React.string("Loading...")} </div>
    | (_, Some(err), _, _) => 
        <div className="text-center py-8 text-red-600 dark:text-red-400"> 
          {React.string(`Error: ${err}`)} 
        </div>
    | (false, None, Some(details), Some((wid, moduleId))) => 
        <div className="overflow-auto relative">
          <div className="mb-4 text-sm text-gray-600 dark:text-gray-400">
            {React.string(`Word ID: ${wid->Int.toString}, Module ID: ${moduleId->Int.toString}`)}
          </div>
          <div className="space-y-2 pb-20">
            {details->Array.map(attr => {
              let isSelected = selectedAttributes->Array.some(((k, v)) => k == attr.key && v == attr.value)
              let bgColor = isSelected 
                ? "bg-blue-200 dark:bg-blue-900 border-2 border-blue-500" 
                : "bg-gray-100 dark:bg-stone-800"
              
              <div 
                key={attr.key} 
                className={`p-3 rounded cursor-pointer transition-colors ${bgColor}`}
                onClick={_ => toggleAttribute(attr.key, attr.value)}
              >
                <div className="font-semibold text-sm text-gray-600 dark:text-gray-400">
                  {React.string(attr.key)}
                </div>
                <div className="mt-1">
                  {React.string(attr.value)}
                </div>
              </div>
            })->React.array}
          </div>
          
          // FAB Button
          {selectedAttributes->Array.length > 0 ? (
            <div className="fixed bottom-20 right-6 flex flex-col items-end gap-0">
              // Menu with arrow
              <div className={
                "relative transition-all duration-200 mb-3 " ++
                (showMenu 
                  ? "opacity-100 translate-y-0" 
                  : "opacity-0 translate-y-2 pointer-events-none")
              }>
                <div className="bg-white dark:bg-stone-800 rounded-lg shadow-lg overflow-hidden border border-gray-200 dark:border-stone-700">
                  <button
                    onClick={_ => handleAddToSearch()}
                    className="w-full px-4 py-3 text-left hover:bg-gray-100 dark:hover:bg-stone-700 transition-colors border-b border-gray-200 dark:border-stone-700"
                  >
                    <div className="font-semibold text-sm">{React.string("Add to Search")}</div>
                    <div className="text-xs text-gray-600 dark:text-gray-400 mt-0.5">
                      {React.string("Keep existing search terms")}
                    </div>
                  </button>
                  <button
                    onClick={_ => handleClearAndSearch()}
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
              
              // FAB
              <button
                onClick={_ => handleFabClick()}
                className="w-14 h-14 bg-blue-600 hover:bg-blue-700 text-white rounded-full shadow-lg flex items-center justify-center transition-all transform hover:scale-110"
                title="Search"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </button>
            </div>
          ) : React.null}
        </div>
    | _ => 
        <div className="text-center py-8 text-gray-500"> 
          {React.string("Click on a word in the Read view to see its details")} 
        </div>
    }}
  </div>
}
