@react.component
let make = (~availableModules, ~selectedModuleIds, ~onModuleToggle, ~onReorder, ~onBack) => {
  let (draggingIndex, setDraggingIndex) = React.useState(() => None)
  
  // Sort selected modules by their current order
  let selectedModules = selectedModuleIds->Array.filterMap(id => {
    availableModules->Array.find((m: ParabibleApi.moduleInfo) => m.moduleId == id)
  })
  
  let unselectedModules = availableModules->Array.filter((m: ParabibleApi.moduleInfo) => {
    !(selectedModuleIds->Array.includes(m.moduleId))
  })
  
  let handleDragStart = (index, _e) => {
    setDraggingIndex(_ => Some(index))
  }
  
  let handleDragOver = (e) => {
    ReactEvent.Mouse.preventDefault(e)
  }
  
  let handleDrop = (targetIndex, e) => {
    ReactEvent.Mouse.preventDefault(e)
    switch draggingIndex {
    | Some(fromIndex) if fromIndex != targetIndex => {
        let newOrder = selectedModuleIds->Array.copy
        let item = newOrder->Array.get(fromIndex)
        
        switch item {
        | Some(moduleId) => {
            // Remove from old position
            let _ = newOrder->Array.splice(~start=fromIndex, ~remove=1, ~insert=[])
            // Insert at new position
            let insertIndex = if fromIndex < targetIndex { targetIndex - 1 } else { targetIndex }
            let _ = newOrder->Array.splice(~start=insertIndex, ~remove=0, ~insert=[moduleId])
            onReorder(newOrder)
          }
        | None => ()
        }
        setDraggingIndex(_ => None)
      }
    | _ => setDraggingIndex(_ => None)
    }
  }
  
  let handleDragEnd = (_e) => {
    setDraggingIndex(_ => None)
  }
  
  <div className="flex flex-col h-full bg-white dark:bg-stone-900">
    // Header
    <div className="flex items-center gap-4 p-4 border-b border-gray-200 dark:border-stone-700">
      <button
        onClick={_ => onBack()}
        className="p-2 hover:bg-gray-100 dark:hover:bg-stone-800 rounded-lg transition-colors"
        ariaLabel="Back">
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <h2 className="text-xl font-semibold">{React.string("Module Settings")}</h2>
    </div>
    
    <div className="flex-1 overflow-auto p-4">
      // Selected modules (draggable)
      <div className="mb-6">
        <h3 className="text-sm font-semibold text-gray-600 dark:text-gray-400 mb-3 uppercase tracking-wide">
          {React.string("Active Modules")}
        </h3>
        <div className="space-y-2">
          {selectedModules->Array.length == 0
            ? <div className="text-gray-500 dark:text-gray-400 text-sm italic p-4 text-center">
                {React.string("No modules selected. Add some from below.")}
              </div>
            : selectedModules->Array.mapWithIndex((module_, index) => {
                let isDragging = draggingIndex == Some(index)
                <div
                  key={module_.moduleId->Int.toString}
                  draggable={true}
                  onDragStart={e => handleDragStart(index, e)}
                  onDragOver={handleDragOver}
                  onDrop={e => handleDrop(index, e)}
                  onDragEnd={handleDragEnd}
                  className={
                    "flex items-center gap-3 p-3 bg-gray-50 dark:bg-stone-800 rounded-lg border-2 " ++
                    (isDragging 
                      ? "border-blue-500 opacity-50" 
                      : "border-transparent hover:border-gray-300 dark:hover:border-stone-600") ++
                    " cursor-move transition-all"
                  }>
                  <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 8h16M4 16h16" />
                  </svg>
                  <span className="flex-1 font-medium">{React.string(module_.abbreviation)}</span>
                  <button
                    onClick={_ => onModuleToggle(module_.moduleId)}
                    className="p-1 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded transition-colors"
                    ariaLabel="Remove">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              })->React.array}
        </div>
      </div>
      
      // Available modules
      <div>
        <h3 className="text-sm font-semibold text-gray-600 dark:text-gray-400 mb-3 uppercase tracking-wide">
          {React.string("Available Modules")}
        </h3>
        <div className="space-y-2">
          {unselectedModules->Array.length == 0
            ? <div className="text-gray-500 dark:text-gray-400 text-sm italic p-4 text-center">
                {React.string("All modules are active")}
              </div>
            : unselectedModules->Array.map(module_ => {
                <button
                  key={module_.moduleId->Int.toString}
                  onClick={_ => onModuleToggle(module_.moduleId)}
                  className="w-full flex items-center gap-3 p-3 bg-white dark:bg-stone-900 border border-gray-300 dark:border-stone-700 rounded-lg hover:bg-gray-50 dark:hover:bg-stone-800 transition-colors">
                  <span className="flex-1 text-left font-medium">{React.string(module_.abbreviation)}</span>
                  <svg className="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4v16m8-8H4" />
                  </svg>
                </button>
              })->React.array}
        </div>
      </div>
    </div>
  </div>
}
