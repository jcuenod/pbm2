type indicatorStyle = {left: string}

@react.component
let make = (~index, ~onSelect) => {
  let items = [
    ("Read", <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
    </svg>),
    ("Tools", <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4M4 10h16v11H4V10z"></path>
    </svg>),
    ("Search", <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
    </svg>),
    ("Settings", <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"></path>
    </svg>),
  ]
  
  let buttonRefs = React.useRef(Belt.Array.make(Belt.Array.length(items), None))
  let (indicatorStyle, setIndicatorStyle) = React.useState(() => {left: "0px"})
  
  let indicatorWidthPercent = 20.0
  
  React.useEffect1(() => {
    let refs = buttonRefs.current
    switch Belt.Array.get(refs, index) {
    | Some(Some(element)) => {
        let rect = Webapi.Dom.Element.getBoundingClientRect(element)
        let parent = Webapi.Dom.Element.parentElement(element)
        switch parent {
        | Some(parentEl) => {
            let parentRect = Webapi.Dom.Element.getBoundingClientRect(parentEl)
            let buttonLeft = Webapi.Dom.DomRect.left(rect) -. Webapi.Dom.DomRect.left(parentRect)
            let buttonWidth = Webapi.Dom.DomRect.width(rect)
            let parentWidth = Webapi.Dom.DomRect.width(parentRect)
            let indicatorWidthPx = parentWidth *. (indicatorWidthPercent /. 100.0)
            let centerOffset = (buttonWidth -. indicatorWidthPx) /. 2.0
            setIndicatorStyle(_ => {
              left: Float.toString(buttonLeft +. centerOffset + 6.0) ++ "px"
            })
          }
        | None => ()
        }
      }
    | _ => ()
    }
    None
  }, [index])
  
  <nav className="bg-white dark:bg-stone-900 border-t border-stone-200 dark:border-stone-800 p-2 relative">
    <div className="flex justify-around">
      <div 
        className="absolute top-1 bottom-1 bg-stone-100 dark:bg-stone-800 rounded-lg transition-all duration-300 ease-in-out pointer-events-none"
        style={
          width: "20%",
          left: indicatorStyle.left,
        }
      />
      {items->Belt.Array.mapWithIndex((i, (label, icon)) =>
        <button 
          key={label} 
          ref={ReactDOM.Ref.callbackDomRef(el => {
            let refs = buttonRefs.current
            let _ = Belt.Array.set(refs, i, Nullable.toOption(el))
            None
          })}
          onClick={_ => onSelect(i)} 
          className={"relative w-[24%] pt-1 pb-1 z-10 flex flex-col items-center text-sm transition-transform duration-200 ease-in-out " ++ (if i == index {"text-teal-600 scale-100"} else {"text-stone-500 scale-90"})}>
          {icon}
          <span> {React.string(label)} </span>
        </button>
      )->React.array}
    </div>
  </nav>
}
