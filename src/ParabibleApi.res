// API types based on parabible-server-2 /api/v2/text endpoint

type word = {
  wid: int,
  leader?: string,
  text: string,
  trailer?: string,
  temp?: string,
}

type matchingText = {
  parallelId: int,
  moduleId: int,
  rid: int,
  @as("type") type_: string, // "wordArray" | "html"
  html?: string,
  wordArray?: array<word>,
}

type textEndpointResult = array<array<matchingText>>

// Module types
type moduleInfo = {
  moduleId: int,
  abbreviation: string,
}

type moduleResponse = {data: array<moduleInfo>}

// Word details types
type wordAttribute = {
  key: string,
  value: string,
}

type wordDetailsResponse = {data: array<wordAttribute>}

// Term search types
type searchTermData = {
  inverted: bool,
  attributes: array<(string, string)>,
}

type matchingWord = {
  wid: int,
  moduleId: int,
}

type warmWordSet = {
  moduleId: int,
  wids: array<int>,
}

type termSearchResult = {
  count: int,
  matchingText: array<array<array<matchingText>>>,
  matchingWords: array<matchingWord>,
  warmWords: array<warmWordSet>,
}

// Dictionary types
type dictionaryEntry = {
  id: string,
  uri: string,
  xmlContent: string,
}

type dictionaryEntriesResponse = {
  data: {dictionaryEntries: array<dictionaryEntry>},
}

// Fetch available modules from the Parabible API
let fetchModules = async (): result<array<moduleInfo>, string> => {
  try {
    let url = `https://dev.parabible.com/api/v2/module`
    let response = await Webapi.Fetch.fetch(url)

    if response->Webapi.Fetch.Response.ok {
      let json = await response->Webapi.Fetch.Response.json
      let obj = JSON.Decode.object(json)

      switch obj {
      | Some(o) => {
          let dataArray = o->Dict.get("data")->Option.flatMap(JSON.Decode.array)
          switch dataArray {
          | Some(arr) => {
              let modules = arr->Array.filterMap(moduleJson => {
                let moduleObj = JSON.Decode.object(moduleJson)
                switch moduleObj {
                | Some(mo) => {
                    let moduleId =
                      mo
                      ->Dict.get("moduleId")
                      ->Option.flatMap(JSON.Decode.float)
                      ->Option.map(Float.toInt)
                      ->Option.getOr(0)
                    let abbreviation =
                      mo
                      ->Dict.get("abbreviation")
                      ->Option.flatMap(JSON.Decode.string)
                      ->Option.getOr("")
                    Some({moduleId, abbreviation})
                  }
                | None => None
                }
              })
              Ok(modules)
            }
          | None => Error("Failed to parse modules data")
          }
        }
      | None => Error("Failed to parse response")
      }
    } else {
      Error(`HTTP error: ${response->Webapi.Fetch.Response.status->Int.toString}`)
    }
  } catch {
  | _ => Error("Fetch error")
  }
}

// Fetch text from the Parabible API
let fetchText = async (modules: string, reference: string): result<textEndpointResult, string> => {
  try {
    let url = `https://dev.parabible.com/api/v2/text?modules=${modules}&reference=${reference}`
    let response = await Webapi.Fetch.fetch(url)

    if response->Webapi.Fetch.Response.ok {
      let json = await response->Webapi.Fetch.Response.json
      let data = JSON.Decode.array(json)

      switch data {
      | Some(arr) => {
          // Parse the JSON into our types
          let result = arr->Array.map(innerArr => {
            switch JSON.Decode.array(innerArr) {
            | Some(matches) =>
              matches->Array.map(matchJson => {
                let obj = JSON.Decode.object(matchJson)
                switch obj {
                | Some(o) => {
                    let parallelId =
                      o
                      ->Dict.get("parallelId")
                      ->Option.flatMap(JSON.Decode.float)
                      ->Option.map(Float.toInt)
                      ->Option.getOr(0)
                    let moduleId =
                      o
                      ->Dict.get("moduleId")
                      ->Option.flatMap(JSON.Decode.float)
                      ->Option.map(Float.toInt)
                      ->Option.getOr(0)
                    let rid =
                      o
                      ->Dict.get("rid")
                      ->Option.flatMap(JSON.Decode.float)
                      ->Option.map(Float.toInt)
                      ->Option.getOr(0)
                    let type_ =
                      o->Dict.get("type")->Option.flatMap(JSON.Decode.string)->Option.getOr("html")
                    let html = o->Dict.get("html")->Option.flatMap(JSON.Decode.string)
                    let wordArray =
                      o
                      ->Dict.get("wordArray")
                      ->Option.flatMap(JSON.Decode.array)
                      ->Option.map(
                        arr => {
                          arr->Array.filterMap(
                            wordJson => {
                              let wordObj = JSON.Decode.object(wordJson)
                              switch wordObj {
                              | Some(wo) => {
                                  let wid =
                                    wo
                                    ->Dict.get("wid")
                                    ->Option.flatMap(JSON.Decode.float)
                                    ->Option.map(Float.toInt)
                                    ->Option.getOr(0)
                                  let text =
                                    wo
                                    ->Dict.get("text")
                                    ->Option.flatMap(JSON.Decode.string)
                                    ->Option.getOr("")
                                  let leader =
                                    wo->Dict.get("leader")->Option.flatMap(JSON.Decode.string)
                                  let trailer =
                                    wo->Dict.get("trailer")->Option.flatMap(JSON.Decode.string)
                                  let temp =
                                    wo->Dict.get("temp")->Option.flatMap(JSON.Decode.string)
                                  Some({wid, text, ?leader, ?trailer, ?temp})
                                }
                              | None => None
                              }
                            },
                          )
                        },
                      )

                    {parallelId, moduleId, rid, type_, ?html, ?wordArray}
                  }
                | None => {parallelId: 0, moduleId: 0, rid: 0, type_: "html"}
                }
              })
            | None => []
            }
          })
          Ok(result)
        }
      | None => Error("Failed to parse response")
      }
    } else {
      Error(`HTTP error: ${response->Webapi.Fetch.Response.status->Int.toString}`)
    }
  } catch {
  | _ => Error("Fetch error")
  }
}

// Fetch word details from the Parabible API
let fetchWordDetails = async (wid: int, moduleId: int): result<array<wordAttribute>, string> => {
  try {
    let url = `https://dev.parabible.com/api/v2/word?wid=${wid->Int.toString}&moduleId=${moduleId->Int.toString}`
    let response = await Webapi.Fetch.fetch(url)

    if response->Webapi.Fetch.Response.ok {
      let json = await response->Webapi.Fetch.Response.json
      let obj = JSON.Decode.object(json)

      switch obj {
      | Some(o) => {
          let dataArray = o->Dict.get("data")->Option.flatMap(JSON.Decode.array)
          switch dataArray {
          | Some(arr) => {
              let attributes = arr->Array.filterMap(attrJson => {
                let attrObj = JSON.Decode.object(attrJson)
                switch attrObj {
                | Some(ao) => {
                    let key =
                      ao->Dict.get("key")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
                    let value =
                      ao->Dict.get("value")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
                    Some({key, value})
                  }
                | None => None
                }
              })
              Ok(attributes)
            }
          | None => Error("Failed to parse word details data")
          }
        }
      | None => Error("Failed to parse response")
      }
    } else {
      Error(`HTTP error: ${response->Webapi.Fetch.Response.status->Int.toString}`)
    }
  } catch {
  | _ => Error("Fetch error")
  }
}

// Encode search terms for URL
let encodeSearchTerms = (terms: array<searchTermData>): string => {
  terms
  ->Array.mapWithIndex((term, idx) => {
    let invertedParam = term.inverted ? `t.${idx->Int.toString}.inverted=true&` : ""
    let attributeParams =
      term.attributes
      ->Array.map(((key, value)) => {
        let encodedKey = encodeURIComponent(key)
        let encodedValue = encodeURIComponent(value)
        `t.${idx->Int.toString}.data.${encodedKey}=${encodedValue}`
      })
      ->Array.join("&")
    `${invertedParam}${attributeParams}`
  })
  ->Array.join("&")
}

// Fetch term search results from the Parabible API
let fetchTermSearch = async (
  searchTerms: array<searchTermData>,
  modules: string,
  ~treeNodeType: string="parallel",
  ~reference: option<string>,
  ~pageSize: int=20,
  ~pageNumber: int=0,
): result<termSearchResult, string> => {
  try {
    let termParams = encodeSearchTerms(searchTerms)
    let refParam = switch reference {
    | Some(ref) => `&corpusFilter=${encodeURIComponent(ref)}`
    | None => ""
    }

    let url = `https://dev.parabible.com/api/v2/termSearch?${termParams}&modules=${modules}&treeNodeType=${treeNodeType}${refParam}&pageSize=${pageSize->Int.toString}&page=${pageNumber->Int.toString}`

    let response = await Webapi.Fetch.fetch(url)

    if response->Webapi.Fetch.Response.ok {
      let json = await response->Webapi.Fetch.Response.json
      let obj = JSON.Decode.object(json)

      switch obj {
      | Some(o) => {
          let count =
            o
            ->Dict.get("count")
            ->Option.flatMap(JSON.Decode.float)
            ->Option.map(Float.toInt)
            ->Option.getOr(0)

          // Parse matchingText (triple nested array)
          let matchingTextArray =
            o->Dict.get("matchingText")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
          let matchingText = matchingTextArray->Array.map(row => {
            switch JSON.Decode.array(row) {
            | Some(modules) =>
              modules->Array.map(moduleData => {
                switch JSON.Decode.array(moduleData) {
                | Some(verses) =>
                  verses->Array.filterMap(
                    verseJson => {
                      let verseObj = JSON.Decode.object(verseJson)
                      switch verseObj {
                      | Some(vo) => {
                          let parallelId =
                            vo
                            ->Dict.get("parallelId")
                            ->Option.flatMap(JSON.Decode.float)
                            ->Option.map(Float.toInt)
                            ->Option.getOr(0)
                          let moduleId =
                            vo
                            ->Dict.get("moduleId")
                            ->Option.flatMap(JSON.Decode.float)
                            ->Option.map(Float.toInt)
                            ->Option.getOr(0)
                          let rid =
                            vo
                            ->Dict.get("rid")
                            ->Option.flatMap(JSON.Decode.float)
                            ->Option.map(Float.toInt)
                            ->Option.getOr(0)
                          let type_ =
                            vo
                            ->Dict.get("type")
                            ->Option.flatMap(JSON.Decode.string)
                            ->Option.getOr("html")
                          let html = vo->Dict.get("html")->Option.flatMap(JSON.Decode.string)
                          let wordArray =
                            vo
                            ->Dict.get("wordArray")
                            ->Option.flatMap(JSON.Decode.array)
                            ->Option.map(
                              arr => {
                                arr->Array.filterMap(
                                  wordJson => {
                                    let wordObj = JSON.Decode.object(wordJson)
                                    switch wordObj {
                                    | Some(wo) => {
                                        let wid =
                                          wo
                                          ->Dict.get("wid")
                                          ->Option.flatMap(JSON.Decode.float)
                                          ->Option.map(Float.toInt)
                                          ->Option.getOr(0)
                                        let text =
                                          wo
                                          ->Dict.get("text")
                                          ->Option.flatMap(JSON.Decode.string)
                                          ->Option.getOr("")
                                        let leader =
                                          wo->Dict.get("leader")->Option.flatMap(JSON.Decode.string)
                                        let trailer =
                                          wo
                                          ->Dict.get("trailer")
                                          ->Option.flatMap(JSON.Decode.string)
                                        let temp =
                                          wo->Dict.get("temp")->Option.flatMap(JSON.Decode.string)
                                        Some({wid, text, ?leader, ?trailer, ?temp})
                                      }
                                    | None => None
                                    }
                                  },
                                )
                              },
                            )
                          Some({parallelId, moduleId, rid, type_, ?html, ?wordArray})
                        }
                      | None => None
                      }
                    },
                  )
                | None => []
                }
              })
            | None => []
            }
          })

          // Parse matchingWords
          let matchingWordsArray =
            o->Dict.get("matchingWords")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
          let matchingWords = matchingWordsArray->Array.filterMap(wordJson => {
            let wordObj = JSON.Decode.object(wordJson)
            switch wordObj {
            | Some(wo) => {
                let wid =
                  wo
                  ->Dict.get("wid")
                  ->Option.flatMap(JSON.Decode.float)
                  ->Option.map(Float.toInt)
                  ->Option.getOr(0)
                let moduleId =
                  wo
                  ->Dict.get("moduleId")
                  ->Option.flatMap(JSON.Decode.float)
                  ->Option.map(Float.toInt)
                  ->Option.getOr(0)
                Some({wid, moduleId})
              }
            | None => None
            }
          })

          // Parse warmWords
          let warmWordsArray =
            o->Dict.get("warmWords")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
          let warmWords = warmWordsArray->Array.filterMap(setJson => {
            let setObj = JSON.Decode.object(setJson)
            switch setObj {
            | Some(so) => {
                let moduleId =
                  so
                  ->Dict.get("moduleId")
                  ->Option.flatMap(JSON.Decode.float)
                  ->Option.map(Float.toInt)
                  ->Option.getOr(0)
                let widsArray =
                  so->Dict.get("wids")->Option.flatMap(JSON.Decode.array)->Option.getOr([])
                let wids = widsArray->Array.filterMap(widJson => {
                  JSON.Decode.float(widJson)->Option.map(Float.toInt)
                })
                Some({moduleId, wids})
              }
            | None => None
            }
          })

          Ok({count, matchingText, matchingWords, warmWords})
        }
      | None => Error("Failed to parse response")
      }
    } else {
      Error(`HTTP error: ${response->Webapi.Fetch.Response.status->Int.toString}`)
    }
  } catch {
  | _ => Error("Fetch error")
  }
}

// Fetch dictionary entries for a lexeme
let fetchDictionaryEntry = async (lexeme: string): result<array<dictionaryEntry>, string> => {
  try {
    let url = "https://symphony-atlas-svc-prod.fly.dev/graphql/"
    
    // Build the GraphQL query
    let query = "query DictionaryEntries($filters: DictionaryEntryFilter!) {
  dictionaryEntries(filters: $filters) {
    id
    uri
    xmlContent
    __typename
  }
}
"
    
    // Build the request body
    let body = {
      "operationName": "DictionaryEntries",
      "variables": {
        "filters": {
          "headword": {
            "iExact": lexeme,
          },
          "dictionary": {
            "uri": {
              "exact": "dictionaries:abbott-smith-lexicon",
            },
          },
        },
      },
      "query": query,
    }
    
    let bodyString = JSON.stringifyAny(body)->Option.getOr("{}")
    
    let response = await Webapi.Fetch.fetchWithInit(
      url,
      Webapi.Fetch.RequestInit.make(
        ~method_=Post,
        ~headers=Webapi.Fetch.HeadersInit.make({
          "content-type": "application/json",
        }),
        ~body=Webapi.Fetch.BodyInit.make(bodyString),
        (),
      ),
    )

    if response->Webapi.Fetch.Response.ok {
      let json = await response->Webapi.Fetch.Response.json
      let obj = JSON.Decode.object(json)

      switch obj {
      | Some(o) => {
          let dataObj = o->Dict.get("data")->Option.flatMap(JSON.Decode.object)
          switch dataObj {
          | Some(d) => {
              let entriesArray = d->Dict.get("dictionaryEntries")->Option.flatMap(JSON.Decode.array)
              switch entriesArray {
              | Some(arr) => {
                  let entries = arr->Array.filterMap(entryJson => {
                    let entryObj = JSON.Decode.object(entryJson)
                    switch entryObj {
                    | Some(e) => {
                        let id = e->Dict.get("id")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
                        let uri = e->Dict.get("uri")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
                        let xmlContent = e->Dict.get("xmlContent")->Option.flatMap(JSON.Decode.string)->Option.getOr("")
                        Some({id, uri, xmlContent})
                      }
                    | None => None
                    }
                  })
                  Ok(entries)
                }
              | None => Error("Failed to parse dictionary entries")
              }
            }
          | None => Error("Failed to parse data object")
          }
        }
      | None => Error("Failed to parse response")
      }
    } else {
      Error(`HTTP error: ${response->Webapi.Fetch.Response.status->Int.toString}`)
    }
  } catch {
  | _ => Error("Fetch error")
  }
}
