module Core = {
  type uniqueId = string

  type active = {id: uniqueId}
  type over = {id: uniqueId}

  type dragEndEvent = {
    active: active,
    over: Nullable.t<over>,
  }

  type sensor
  type sensors

  @module("@dnd-kit/core")
  external useSensor: ('a, ~options: 'b=?) => sensor = "useSensor"
  
  @module("@dnd-kit/core")
  external useSensorWithOptions: ('a, 'b) => sensor = "useSensor"

  @module("@dnd-kit/core") @variadic
  external useSensors: array<sensor> => sensors = "useSensors"

  @module("@dnd-kit/core")
  external pointerSensor: 'a = "PointerSensor"

  @module("@dnd-kit/core")
  external mouseSensor: 'a = "MouseSensor"
  
  @module("@dnd-kit/core")
  external touchSensor: 'a = "TouchSensor"

  @module("@dnd-kit/core")
  external keyboardSensor: 'a = "KeyboardSensor"

  type collisionDetection

  @module("@dnd-kit/core")
  external closestCenter: collisionDetection = "closestCenter"
  
  @module("@dnd-kit/core")
  external closestCorners: collisionDetection = "closestCorners"

  type dragStartEvent = {
    active: active,
  }

  module DndContext = {
    @module("@dnd-kit/core") @react.component
    external make: (
      ~sensors: sensors=?,
      ~collisionDetection: collisionDetection=?,
      ~onDragStart: dragStartEvent => unit=?,
      ~onDragEnd: dragEndEvent => unit=?,
      ~children: React.element,
    ) => React.element = "DndContext"
  }
  
  module DragOverlay = {
    @module("@dnd-kit/core") @react.component
    external make: (
      ~children: React.element,
    ) => React.element = "DragOverlay"
  }
}

module Sortable = {
  type strategy

  @module("@dnd-kit/sortable")
  external verticalListSortingStrategy: strategy = "verticalListSortingStrategy"
  
  @module("@dnd-kit/sortable")
  external sortableKeyboardCoordinates: 'a = "sortableKeyboardCoordinates"

  @module("@dnd-kit/sortable")
  external arrayMove: (array<'a>, int, int) => array<'a> = "arrayMove"

  module SortableContext = {
    @module("@dnd-kit/sortable") @react.component
    external make: (
      ~items: array<string>,
      ~strategy: strategy=?,
      ~children: React.element,
    ) => React.element = "SortableContext"
  }

  type transform = {
    x: float,
    y: float,
    scaleX: float,
    scaleY: float,
  }

  type useSortableResult = {
    attributes: Dict.t<string>,
    listeners: Dict.t<unknown>, 
    setNodeRef: ReactDOM.domRef => unit,
    transform: Nullable.t<transform>,
    transition: Nullable.t<string>,
    isDragging: bool,
  }

  @module("@dnd-kit/sortable")
  external useSortable: { "id": string } => useSortableResult = "useSortable"
}

module Utilities = {
  module CSS = {
    @module("@dnd-kit/utilities") @scope(("CSS", "Transform"))
    external transformToString: Nullable.t<Sortable.transform> => string = "toString"
  }
}
