@react.component
let make = (~collapsed, ~onClick, ~reference="Matthew 1") => {
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
  
  <div 
    onClick={handleInteraction}
    onTouchEnd={handleInteraction}
    className={"bg-white dark:bg-stone-900 shadow flex items-center justify-center cursor-pointer transition-all duration-300 " ++ (collapsed ? "h-0 py-0 opacity-0 overflow-hidden pointer-events-none" : "h-12 py-3")}>
    <h2 className="font-semibold text-lg"> 
      {React.string(reference)} 
    </h2>
  </div>
}
