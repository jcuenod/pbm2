// StateService - Centralized state persistence and restoration
// Manages app state including reading position, selected word, search terms, dark mode, and modules

@module("./jsHelpers.js")
external getLocalStorage: string => Nullable.t<string> = "getLocalStorage"
@module("./jsHelpers.js")
external setLocalStorage: (string, string) => unit = "setLocalStorage"
@module("./jsHelpers.js")
external getSystemDarkModePreference: unit => bool = "getSystemDarkModePreference"

// Types for persisted state
type readingPosition = {
  book: string,
  chapter: int,
  verse: int,
}

type selectedWord = (int, int) // (wid, moduleId)

type appState = {
  readingPosition: option<readingPosition>,
  selectedWord: option<selectedWord>,
  searchTerms: array<ParabibleApi.searchTermData>,
  darkMode: bool,
  selectedModuleIds: array<int>,
  baseModuleId: option<int>,
  syntaxRange: string,
  corpusFilter: string,
}

// Keys for localStorage
let keyReadingPosition = "readingPosition"
let keySelectedWord = "selectedWord"
let keySearchTerms = "searchTerms"
let keyDarkMode = "darkMode"
let keySelectedModules = "selectedModules"
let keyBaseModuleId = "baseModuleId"
let keySyntaxRange = "syntaxRange"
let keyCorpusFilter = "corpusFilter"

// Parse JSON helpers
let parseReadingPosition = (jsonStr: string): option<readingPosition> => {
  try {
    let json = JSON.parseOrThrow(jsonStr)
    switch json->JSON.Decode.object {
    | Some(obj) =>
      switch (obj->Dict.get("book")->Option.flatMap(JSON.Decode.string), 
              obj->Dict.get("chapter")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt),
              obj->Dict.get("verse")->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)) {
      | (Some(book), Some(chapter), Some(verse)) => Some({book, chapter, verse})
      | (Some(book), Some(chapter), None) => Some({book, chapter, verse: 1}) // Backwards compatibility
      | _ => None
      }
    | None => None
    }
  } catch {
  | _ => None
  }
}

let parseSelectedWord = (jsonStr: string): option<selectedWord> => {
  try {
    let json = JSON.parseOrThrow(jsonStr)
    switch json->JSON.Decode.array {
    | Some(arr) if arr->Array.length == 2 =>
      switch (arr->Array.get(0)->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt), 
              arr->Array.get(1)->Option.flatMap(JSON.Decode.float)->Option.map(Float.toInt)) {
      | (Some(wid), Some(moduleId)) => Some((wid, moduleId))
      | _ => None
      }
    | _ => None
    }
  } catch {
  | _ => None
  }
}

let parseSearchTerms = (jsonStr: string): array<ParabibleApi.searchTermData> => {
  try {
    let json = JSON.parseOrThrow(jsonStr)
    switch json->JSON.Decode.array {
    | Some(arr) =>
      arr->Array.filterMap(item =>
        switch item->JSON.Decode.object {
        | Some(obj) => {
            let inverted = obj->Dict.get("inverted")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
            let attributes = switch obj->Dict.get("attributes")->Option.flatMap(JSON.Decode.array) {
            | Some(attrArr) =>
              attrArr->Array.filterMap(attrItem =>
                switch attrItem->JSON.Decode.array {
                | Some(tuple) if tuple->Array.length == 2 =>
                  switch (tuple->Array.get(0)->Option.flatMap(JSON.Decode.string),
                          tuple->Array.get(1)->Option.flatMap(JSON.Decode.string)) {
                  | (Some(key), Some(value)) => Some((key, value))
                  | _ => None
                  }
                | _ => None
                }
              )
            | None => []
            }
            Some({
              inverted: inverted,
              attributes: attributes,
            }: ParabibleApi.searchTermData)
          }
        | None => None
        }
      )
    | None => []
    }
  } catch {
  | _ => []
  }
}

let parseModuleIds = (jsonStr: string): array<int> => {
  // Support both comma-separated format and JSON array
  if jsonStr->String.includes("[") {
    try {
      let json = JSON.parseOrThrow(jsonStr)
      switch json->JSON.Decode.array {
      | Some(arr) => arr->Array.filterMap(v => v->JSON.Decode.float->Option.map(Float.toInt))
      | None => []
      }
    } catch {
    | _ => []
    }
  } else {
    // Legacy comma-separated format
    jsonStr->String.split(",")->Array.filterMap(idStr => Int.fromString(idStr))
  }
}

// Load state from localStorage
let loadReadingPosition = (): option<readingPosition> => {
  getLocalStorage(keyReadingPosition)
  ->Nullable.toOption
  ->Option.flatMap(parseReadingPosition)
}

let loadSelectedWord = (): option<selectedWord> => {
  getLocalStorage(keySelectedWord)
  ->Nullable.toOption
  ->Option.flatMap(parseSelectedWord)
}

let loadSearchTerms = (): array<ParabibleApi.searchTermData> => {
  getLocalStorage(keySearchTerms)
  ->Nullable.toOption
  ->Option.map(parseSearchTerms)
  ->Option.getOr([])
}

let loadDarkMode = (): bool => {
  // First check localStorage for explicit preference
  switch getLocalStorage(keyDarkMode)->Nullable.toOption {
  | Some("true") => true
  | Some("false") => false
  | Some("1") => true
  | Some("0") => false
  // If no stored preference, use system preference
  | _ => getSystemDarkModePreference()
  }
}

let loadSelectedModuleIds = (): array<int> => {
  getLocalStorage(keySelectedModules)
  ->Nullable.toOption
  ->Option.map(parseModuleIds)
  ->Option.getOr([])
}

let loadBaseModuleId = (): option<int> => {
  getLocalStorage(keyBaseModuleId)
  ->Nullable.toOption
  ->Option.flatMap(str => Int.fromString(str))
}

let loadSyntaxRange = (): string => {
  getLocalStorage(keySyntaxRange)
  ->Nullable.toOption
  ->Option.getOr("parallel")
}

let loadCorpusFilter = (): string => {
  getLocalStorage(keyCorpusFilter)
  ->Nullable.toOption
  ->Option.getOr("none")
}

// Save state to localStorage
let saveReadingPosition = (position: readingPosition): unit => {
  let json = JSON.stringifyAny({
    "book": position.book,
    "chapter": position.chapter,
    "verse": position.verse,
  })
  switch json {
  | Some(str) => setLocalStorage(keyReadingPosition, str)
  | None => ()
  }
}

let saveSelectedWord = (word: option<selectedWord>): unit => {
  switch word {
  | Some((wid, moduleId)) =>
    let json = JSON.stringifyAny([wid, moduleId])
    switch json {
    | Some(str) => setLocalStorage(keySelectedWord, str)
    | None => ()
    }
  | None => setLocalStorage(keySelectedWord, "")
  }
}

let saveSearchTerms = (terms: array<ParabibleApi.searchTermData>): unit => {
  let jsonTerms = terms->Array.map(term => {
    {
      "inverted": term.inverted,
      "attributes": term.attributes,
    }
  })
  
  let json = JSON.stringifyAny(jsonTerms)
  switch json {
  | Some(str) => setLocalStorage(keySearchTerms, str)
  | None => ()
  }
}

let saveDarkMode = (dark: bool): unit => {
  setLocalStorage(keyDarkMode, dark ? "true" : "false")
}

let saveSelectedModuleIds = (ids: array<int>): unit => {
  let json = JSON.stringifyAny(ids)
  switch json {
  | Some(str) => setLocalStorage(keySelectedModules, str)
  | None => ()
  }
}

let saveBaseModuleId = (id: option<int>): unit => {
  switch id {
  | Some(val) => setLocalStorage(keyBaseModuleId, val->Int.toString)
  | None => setLocalStorage(keyBaseModuleId, "")
  }
}

let saveSyntaxRange = (range: string): unit => {
  setLocalStorage(keySyntaxRange, range)
}

let saveCorpusFilter = (filter: string): unit => {
  setLocalStorage(keyCorpusFilter, filter)
}

// Load entire app state
let loadAppState = (): appState => {
  {
    readingPosition: loadReadingPosition(),
    selectedWord: loadSelectedWord(),
    searchTerms: loadSearchTerms(),
    darkMode: loadDarkMode(),
    selectedModuleIds: loadSelectedModuleIds(),
    baseModuleId: loadBaseModuleId(),
    syntaxRange: loadSyntaxRange(),
    corpusFilter: loadCorpusFilter(),
  }
}
