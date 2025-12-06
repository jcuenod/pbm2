@react.component
let make = (~totalPages: int, ~currentPage: int, ~onPageChange: int => unit) => {
  let windowSize = 5
  let startPage =
    if totalPages <= 0 {
      0
    } else {
      let startCandidate = currentPage - 2
      let fromLower = if startCandidate < 0 { 0 } else { startCandidate }
      let maxStart = if totalPages - windowSize > 0 { totalPages - windowSize } else { 0 }
      if fromLower > maxStart { maxStart } else { fromLower }
    }

  let pageSlots = Belt.Array.make(windowSize, None)
  for i in 0 to windowSize - 1 {
    let pageIndex = startPage + i
    switch pageIndex < totalPages {
    | true => {
        let _ = Belt.Array.set(pageSlots, i, Some(pageIndex))
        ()
      }
    | false => ()
    }
  }

  let goToPage = page => {
    if totalPages > 0 && page >= 0 && page < totalPages {
      onPageChange(page)
    } else {
      ()
    }
  }

  let goToFirst = () => goToPage(0)
  let goToLast = () => goToPage(if totalPages > 0 { totalPages - 1 } else { 0 })

  let canGoFirst = totalPages > 0 && currentPage > 0
  let canGoLast = totalPages > 0 && currentPage < totalPages - 1

  let navButtonClass = enabled =>
    "h-10 w-10 rounded text-sm font-semibold transition-all active:scale-95 flex items-center justify-center border border-stone-200 dark:border-stone-700 " ++
    if enabled {
      "bg-white text-stone-900 dark:bg-stone-800 dark:text-stone-100 hover:bg-stone-100 dark:hover:bg-stone-700"
    } else {
      "bg-stone-100 dark:bg-stone-900 text-stone-400 dark:text-stone-600 cursor-not-allowed"
    }

  let slotClass = isActive =>
    "h-10 min-w-[2.75rem] rounded text-sm font-semibold transition-all active:scale-95 flex items-center justify-center " ++
    if isActive {
      "bg-teal-600 text-white shadow-lg scale-105"
    } else {
      "bg-stone-100 dark:bg-stone-800 text-stone-800 dark:text-stone-100 hover:bg-stone-200 dark:hover:bg-stone-700"
    }

  let placeholderClass =
    "h-10 min-w-[2.75rem] rounded text-sm font-semibold transition-all flex items-center justify-center border border-transparent opacity-0 cursor-default"

  <div className="flex items-center justify-center gap-2">
    <button
      className={navButtonClass(canGoFirst)}
      disabled={!canGoFirst}
      onClick={_ => goToFirst()}
      ariaLabel="Go to first page"
    >
      {React.string("«")}
    </button>
    {pageSlots
    ->Belt.Array.mapWithIndex((idx, slot) =>
      switch slot {
      | Some(page) =>
        let isActive = page == currentPage
        <button
          key={idx->Int.toString}
          className={slotClass(isActive)}
          onClick={_ => goToPage(page)}
        >
          {React.string((page + 1)->Int.toString)}
        </button>
      | None =>
        <button key={idx->Int.toString} className={placeholderClass} disabled=true>
          {React.null}
        </button>
      }
    )
    ->React.array}
    <button
      className={navButtonClass(canGoLast)}
      disabled={!canGoLast}
      onClick={_ => goToLast()}
      ariaLabel="Go to last page"
    >
      {React.string("»")}
    </button>
  </div>
}
