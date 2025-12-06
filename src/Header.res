@react.component
let make = (~collapsed, ~onClick, ~reference="Matthew 1", ~onNext=?, ~onPrev=?) => {
  let handlingEvent = React.useRef(false)
  
  let handleInteraction = (e) => {
    if !handlingEvent.current {
      handlingEvent.current = true
      ReactEvent.Synthetic.stopPropagation(e)
      onClick()
      // Reset after a small delay
      let _ = setTimeout(() => handlingEvent.current = false, 300)
    }
  }

  let handleNavClick = (e, callback) => {
    ReactEvent.Synthetic.stopPropagation(e)
    switch callback {
    | Some(cb) => cb()
    | None => ()
    }
  }

  let stopPropagation = (e) => {
    ReactEvent.Synthetic.stopPropagation(e)
  }
  
  <div 
    onClick={handleInteraction}
    onTouchEnd={handleInteraction}
    className={"bg-white dark:bg-stone-900 shadow flex items-center justify-center cursor-pointer transition-all duration-300 relative " ++ (collapsed ? "h-0 py-0 opacity-0 overflow-hidden pointer-events-none" : "h-12 py-3")}>
    
    <div className="flex items-center gap-4">
      <button
        disabled={onPrev->Option.isNone}
        onClick={e => handleNavClick(e, onPrev)}
        onTouchEnd={stopPropagation}
        className={"p-1 rounded-full transition-colors " ++ (
          onPrev->Option.isSome 
            ? "hover:bg-gray-100 dark:hover:bg-stone-800 text-gray-500 dark:text-gray-400" 
            : "text-gray-300 dark:text-stone-700 cursor-not-allowed"
        )}
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <polyline points="15 18 9 12 15 6"></polyline>
        </svg>
      </button>

      <h2 className="font-semibold text-lg select-none"> 
        {React.string(reference)} 
      </h2>

      <button
        disabled={onNext->Option.isNone}
        onClick={e => handleNavClick(e, onNext)}
        onTouchEnd={stopPropagation}
        className={"p-1 rounded-full transition-colors " ++ (
          onNext->Option.isSome 
            ? "hover:bg-gray-100 dark:hover:bg-stone-800 text-gray-500 dark:text-gray-400" 
            : "text-gray-300 dark:text-stone-700 cursor-not-allowed"
        )}
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <polyline points="9 18 15 12 9 6"></polyline>
        </svg>
      </button>
    </div>
  </div>
}
