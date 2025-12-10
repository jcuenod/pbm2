@react.component
let make = (
  ~match: option<ParabibleApi.matchingText>,
  ~baseMatch: option<ParabibleApi.matchingText>,
  ~moduleId: int,
  ~moduleAbbrev: string,
  ~selectedWord: option<(int, int)>,
  ~onWordClick: (int, int) => unit,
  ~highlightWords: option<array<(int, int)>>=?,
) => {
  let highlightWordsArr = switch highlightWords {
  | Some(hw) => hw
  | None => []
  }

  let (isRtl, fontClass, sizeClass) = switch moduleAbbrev {
  | "BHSA" => (true, "font-['SBL_BibLit']", "text-2xl")
  | "APF" | "LXXR" | "NA1904" => (false, "font-['SBL_BibLit']", "text-lg")
  | _ => (false, "", "text-md")
  }

  let dirClass = isRtl ? " rtl" : ""
  let columnClass = `min-w-0${dirClass} ${fontClass}`

  let (verseNum, chapterNum) = switch match {
  | Some(m) => (m.rid->mod(1000), (m.rid / 1000)->mod(1000))
  | None => (0, 0)
  }

  let (baseVerseNum, baseChapterNum) = switch baseMatch {
  | Some(m) => (m.rid->mod(1000), (m.rid / 1000)->mod(1000))
  | None => (0, 0)
  }

  let isVerseDiff = baseMatch->Option.isSome && match->Option.isSome && verseNum != baseVerseNum
  let isChapterDiff =
    baseMatch->Option.isSome && match->Option.isSome && chapterNum != baseChapterNum

  let verseDisplay = switch match {
  | Some(_) =>
    if isChapterDiff {
      `${chapterNum->Int.toString}:${verseNum->Int.toString}`
    } else {
      verseNum->Int.toString
    }
  | None => ""
  }

  let verseNumClass = if isChapterDiff {
    "text-orange-500 dark:text-orange-400 border-2 border-orange-500 dark:border-orange-400 rounded-full px-1.5 py-0.5 text-xs font-bold mb-1 inline-block align-middle me-1"
  } else if isVerseDiff {
    "text-white bg-orange-500 dark:bg-orange-600 rounded-full px-1.5 py-0.5 text-xs font-bold mb-1 inline-block align-middle me-1"
  } else {
    "text-orange-500 dark:text-orange-400 font-bold mb-1 -top-1 relative pe-1 font-sans text-xs"
  }

  <div key={moduleId->Int.toString} className={columnClass}>
    <span className={verseNumClass}> {React.string(verseDisplay)} </span>
    {switch match {
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
              {words
              ->Array.map(word => {
                let isSelected = switch selectedWord {
                | Some((selectedWid, selectedModuleId)) =>
                  word.wid == selectedWid && moduleId == selectedModuleId
                | None => false
                }
                let isHighlighted =
                  highlightWordsArr->Array.some(((wid, mid)) => wid == word.wid && mid == moduleId)
                let highlightClass = if isSelected {
                  " text-blue-600 dark:text-blue-400"
                } else {
                  switch word.temp {
                  | Some("hot") => " text-red-700 dark:text-red-400"
                  | Some("warm") => " text-amber-400 dark:text-amber-300"
                  | _ =>
                    if isHighlighted {
                      " text-teal-600 dark:text-teal-400"
                    } else {
                      ""
                    }
                  }
                }
                <React.Fragment key={word.wid->Int.toString}>
                  {switch word.leader {
                  | Some(leader) => React.string(leader)
                  | None => React.null
                  }}
                  <span
                    className={"cursor-pointer hover:text-blue-500 dark:hover:text-blue-300" ++
                    highlightClass}
                    onClick={_ => onWordClick(word.wid, moduleId)}
                  >
                    {React.string(word.text)}
                  </span>
                  {switch word.trailer {
                  | Some(trailer) => React.string(trailer)
                  | None => React.string(" ")
                  }}
                </React.Fragment>
              })
              ->React.array}
            </span>
          | None => React.null
          }
        | _ => React.null
        }}
      </span>
    | None => React.null
    }}
  </div>
}
