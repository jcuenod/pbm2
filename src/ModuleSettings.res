@module("./jsHelpers.js")
external getElementIndexFromId: (float, float, string) => Nullable.t<int> = "getElementIndexFromId"

@module("react")
external createElement: (string, {..}, array<React.element>) => React.element = "createElement"

@val external assign: ({..}, {..}) => {..} = "Object.assign"
external toObj: 'a => {..} = "%identity"

@obj external makeStyle: (
  ~transform: string=?,
  ~transition: string=?,
  ~opacity: string=?,
  ~zIndex: string=?,
  ~position: string=?,
  ~touchAction: string=?,
  unit
) => ReactDOM.Style.t = ""

module SortableItem = {
  @react.component
  let make = (~id, ~children) => {
    let {
      attributes,
      listeners,
      setNodeRef,
      transform,
      transition,
      isDragging,
    } = DndKit.Sortable.useSortable({"id": id})

    let style = makeStyle(
      ~transform=DndKit.Utilities.CSS.transformToString(transform),
      ~transition=transition->Nullable.toOption->Option.getOr(""),
      ~opacity=isDragging ? "0.5" : "1",
      ~zIndex=isDragging ? "1000" : "auto",
      ~position="relative",
      ~touchAction="none",
      (),
    )
    
    let props = Dict.make()->toObj
    let _ = assign(props, attributes->toObj)
    let _ = assign(props, listeners->toObj)
    let _ = assign(props, {
      "ref": setNodeRef,
      "style": style,
      "className": "touch-none mb-2"
    })

    createElement("div", props, [children])
  }
}

@react.component
let make = (~availableModules, ~selectedModuleIds, ~onModuleToggle, ~onReorder, ~onBack, ~baseModuleId, ~onBaseModuleChange) => {
  let (activeId, setActiveId) = React.useState(() => None)

  let sensors = DndKit.Core.useSensors([
    DndKit.Core.useSensor(DndKit.Core.mouseSensor, ~options={
      "activationConstraint": {
        "distance": 10
      }
    }),
    DndKit.Core.useSensor(DndKit.Core.touchSensor, ~options={
      "activationConstraint": {
        "delay": 10,
        "tolerance": 5
      }
    }),
    DndKit.Core.useSensor(DndKit.Core.keyboardSensor, ~options={
      "coordinateGetter": DndKit.Sortable.sortableKeyboardCoordinates
    }),
  ])

  let handleDragStart = (event: DndKit.Core.dragStartEvent) => {
    setActiveId(_ => Some(event.active.id))
  }

  let handleDragEnd = (event: DndKit.Core.dragEndEvent) => {
    setActiveId(_ => None)
    let {active, over} = event
    
    switch over->Nullable.toOption {
    | Some(over) if active.id != over.id =>
      let activeIdInt = active.id->Int.fromString->Option.getOr(0)
      let overIdInt = over.id->Int.fromString->Option.getOr(0)
      
      let oldIndex = selectedModuleIds->Array.indexOf(activeIdInt)
      let newIndex = selectedModuleIds->Array.indexOf(overIdInt)
      
      if (oldIndex != -1 && newIndex != -1) {
        let newOrder = DndKit.Sortable.arrayMove(selectedModuleIds, oldIndex, newIndex)
        onReorder(newOrder)
      }
    | _ => ()
    }
  }

  // Sort selected modules by their current order
  let selectedModules = selectedModuleIds->Array.filterMap(id => {
    availableModules->Array.find((m: ParabibleApi.moduleInfo) => m.moduleId == id)
  })

  let unselectedModules = availableModules->Array.filter((m: ParabibleApi.moduleInfo) => {
    !(selectedModuleIds->Array.includes(m.moduleId))
  })
  
  let renderModuleItem = (module_: ParabibleApi.moduleInfo, ~isOverlay=false) => {
    <div
      className={"flex items-center gap-3 p-3 bg-gray-50 dark:bg-stone-800 rounded-lg border-2 touch-manipulation " ++
      (isOverlay
        ? "border-blue-500 shadow-lg"
        : "border-transparent hover:border-gray-300 dark:hover:border-stone-600") ++ " transition-all"}
    >
      <div className="cursor-move text-gray-400">
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M4 8h16M4 16h16"
          />
        </svg>
      </div>
      <span className="flex-1 font-medium"> {React.string(module_.abbreviation)} </span>
      <button
        onClick={_ => onBaseModuleChange(module_.moduleId)}
        className={"p-1 rounded transition-colors " ++ (
          baseModuleId == Some(module_.moduleId)
            ? "text-teal-600"
            : "text-gray-300 hover:text-teal-600 active:scale-80 transition-transform"
        )}
        ariaLabel="Set as base module"
      >
        <svg
          className="w-5 h-5"
          stroke="currentColor"
          strokeWidth="0"
          strokeLinecap="round"
          strokeLinejoin="round"
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          ><path fill="currentColor" d="M12 22.5q-.325 0-.625-.1t-.575-.3l-6-4.5q-.375-.275-.587-.7T4 16V4q0-.825.588-1.412T6 2h12q.825 0 1.413.588T20 4v12q0 .475-.213.9t-.587.7l-6 4.5q-.275.2-.575.3t-.625.1m-1.05-10.35l-1.4-1.4q-.3-.3-.7-.287t-.7.287q-.3.3-.312.713t.287.712L10.25 14.3q.3.3.7.3t.7-.3l4.25-4.25q.3-.3.287-.7t-.287-.7q-.3-.3-.712-.312t-.713.287z"/></svg>
      </button>
      <button
        onClick={_ => onModuleToggle(module_.moduleId)}
        className="p-1 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded transition-colors"
        ariaLabel="Remove"
      >
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M6 18L18 6M6 6l12 12"
          />
        </svg>
      </button>
    </div>
  }

  <div className="flex flex-col h-full bg-white dark:bg-stone-900">
    // Header
    <div className="flex items-center gap-4 p-4 border-b border-gray-200 dark:border-stone-700">
      <button
        onClick={_ => onBack()}
        className="p-2 hover:bg-gray-100 dark:hover:bg-stone-800 rounded-lg transition-colors"
        ariaLabel="Back"
      >
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <h2 className="text-xl font-semibold"> {React.string("Module Settings")} </h2>
    </div>

    <div className="flex-1 overflow-auto p-4">
      // Selected modules (draggable)
      <div className="mb-6">
        <h3
          className="text-sm font-semibold text-gray-600 dark:text-gray-400 mb-3 uppercase tracking-wide"
        >
          {React.string("Active Modules")}
        </h3>
        
        <DndKit.Core.DndContext
          sensors
          collisionDetection={DndKit.Core.closestCenter}
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
        >
          <DndKit.Sortable.SortableContext
            items={selectedModuleIds->Array.map(id => id->Int.toString)}
            strategy={DndKit.Sortable.verticalListSortingStrategy}
          >
            <div className="space-y-2">
              {selectedModules->Array.length == 0
                ? <div className="text-gray-500 dark:text-gray-400 text-sm italic p-4 text-center">
                    {React.string("No modules selected. Add some from below.")}
                  </div>
                : selectedModules
                  ->Array.map(module_ => {
                    <SortableItem key={module_.moduleId->Int.toString} id={module_.moduleId->Int.toString}>
                      {renderModuleItem(module_)}
                    </SortableItem>
                  })
                  ->React.array}
            </div>
          </DndKit.Sortable.SortableContext>
          
          <DndKit.Core.DragOverlay>
            {switch activeId {
            | Some(id) => 
                let module_ = availableModules->Array.find(m => m.moduleId->Int.toString == id)
                switch module_ {
                | Some(m) => renderModuleItem(m, ~isOverlay=true)
                | None => React.null
                }
            | None => React.null
            }}
          </DndKit.Core.DragOverlay>
        </DndKit.Core.DndContext>
      </div>

      // Available modules
      <div>
        <h3
          className="text-sm font-semibold text-gray-600 dark:text-gray-400 mb-3 uppercase tracking-wide"
        >
          {React.string("Available Modules")}
        </h3>
        <div className="space-y-2">
          {unselectedModules->Array.length == 0
            ? <div className="text-gray-500 dark:text-gray-400 text-sm italic p-4 text-center">
                {React.string("All modules are active")}
              </div>
            : unselectedModules
              ->Array.map(module_ => {
                <button
                  key={module_.moduleId->Int.toString}
                  onClick={_ => onModuleToggle(module_.moduleId)}
                  className="w-full flex items-center gap-3 p-3 bg-white dark:bg-stone-900 border border-gray-300 dark:border-stone-700 rounded-lg hover:bg-gray-50 dark:hover:bg-stone-800 transition-colors"
                >
                  <span className="flex-1 text-left font-medium">
                    {React.string(module_.abbreviation)}
                  </span>
                  <svg
                    className="w-5 h-5 text-green-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M12 4v16m8-8H4"
                    />
                  </svg>
                </button>
              })
              ->React.array}
        </div>
      </div>
    </div>
  </div>
}
