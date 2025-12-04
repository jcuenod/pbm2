@react.component
let make = (~searchTerms: array<ParabibleApi.searchTermData>, ~selectedModuleIds: array<int>, ~availableModules: array<ParabibleApi.moduleInfo>) => {
  let (searchResults, setSearchResults) = React.useState(() => None)
  let (loading, setLoading) = React.useState(() => false)
  let (error, setError) = React.useState(() => None)
  let (resultCount, setResultCount) = React.useState(() => 0)

  // Fetch search results when searchTerms or selectedModuleIds change
  React.useEffect2(() => {
    if searchTerms->Array.length > 0 && selectedModuleIds->Array.length > 0 {
      setLoading(_ => true)
      setError(_ => None)
      
      let fetchData = async () => {
        let modulesStr = selectedModuleIds
          ->Array.filterMap(id => {
            availableModules->Array.find((m: ParabibleApi.moduleInfo) => m.moduleId == id)
              ->Option.map((m: ParabibleApi.moduleInfo) => m.abbreviation)
          })
          ->Array.join(",")
        let result = await ParabibleApi.fetchTermSearch(searchTerms, modulesStr)
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
  }, (searchTerms, selectedModuleIds))

  <div className="flex flex-col h-full">
    <div className="p-4 border-b border-gray-200 dark:border-stone-800">
      <h1 className="text-2xl font-bold mb-2">{React.string("Search Results")}</h1>
      {searchTerms->Array.length > 0 ? (
        <div className="space-y-2">
          <div className="text-sm text-gray-600 dark:text-gray-400">
            {React.string(`${resultCount->Int.toString} results found`)}
          </div>
          <div className="text-xs space-y-1">
            {searchTerms->Array.mapWithIndex((term, idx) => {
              <div key={idx->Int.toString} className="bg-gray-100 dark:bg-stone-800 p-2 rounded">
                <div className="font-semibold">
                  {React.string(`Term ${(idx + 1)->Int.toString}${term.inverted ? " (NOT)" : ""}:`)}
                </div>
                <div className="ml-2 space-y-0.5">
                  {term.attributes->Array.map(((key, value)) => {
                    <div key={`${key}-${value}`}>
                      {React.string(`${key}: ${value}`)}
                    </div>
                  })->React.array}
                </div>
              </div>
            })->React.array}
          </div>
        </div>
      ) : (
        <div className="text-sm text-gray-600 dark:text-gray-400">
          {React.string("No search terms. Select word attributes in Tools to begin.")}
        </div>
      )}
    </div>

    <div className="flex-1 overflow-auto p-4">
      {switch (loading, error, searchResults) {
      | (true, _, _) => 
          <div className="text-center py-8"> {React.string("Loading...")} </div>
      | (_, Some(err), _) => 
          <div className="text-center py-8 text-red-600 dark:text-red-400"> 
            {React.string(`Error: ${err}`)} 
          </div>
      | (false, None, Some(results)) => 
          <div className="space-y-4">
            {results.matchingText->Array.mapWithIndex((row, rowIdx) => {
              <div key={rowIdx->Int.toString} className="border border-gray-200 dark:border-stone-800 rounded-lg p-4">
                {row->Array.mapWithIndex((moduleResults, moduleIdx) => {
                  <div key={`${rowIdx->Int.toString}-${moduleIdx->Int.toString}`} className="mb-3 last:mb-0">
                    {moduleResults->Array.map(textResult => {
                      <div key={`${textResult.rid->Int.toString}-${textResult.moduleId->Int.toString}`} className="mb-2">
                        {switch textResult.type_ {
                        | "html" => 
                            switch textResult.html {
                            | Some(htmlContent) => 
                                <div 
                                  className="text-base leading-relaxed"
                                  dangerouslySetInnerHTML={{"__html": htmlContent}}
                                />
                            | None => React.null
                            }
                        | "wordArray" =>
                            switch textResult.wordArray {
                            | Some(words) => 
                                <div className="text-base leading-relaxed">
                                  {words->Array.map(word => {
                                    let isMatching = results.matchingWords->Array.some(mw => 
                                      mw.wid == word.wid && mw.moduleId == textResult.moduleId
                                    )
                                    let className = isMatching 
                                      ? "font-bold text-blue-600 dark:text-blue-400" 
                                      : ""
                                    
                                    <React.Fragment key={word.wid->Int.toString}>
                                      {switch word.leader {
                                      | Some(leader) => React.string(leader)
                                      | None => React.null
                                      }}
                                      <span className={className}>
                                        {React.string(word.text)}
                                      </span>
                                      {switch word.trailer {
                                      | Some(trailer) => React.string(trailer)
                                      | None => React.null
                                      }}
                                    </React.Fragment>
                                  })->React.array}
                                </div>
                            | None => React.null
                            }
                        | _ => React.null
                        }}
                      </div>
                    })->React.array}
                  </div>
                })->React.array}
              </div>
            })->React.array}
          </div>
      | _ => 
          <div className="text-center py-8 text-gray-500"> 
            {React.string("Select search terms in the Tools view to begin searching")} 
          </div>
      }}
    </div>
  </div>
}
