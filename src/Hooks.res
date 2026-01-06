@react.hook
let useCollapsibleHeader = (~disabled=?) => {
  let (collapsed, setCollapsed) = React.useState(() => false)
  let lastY = React.useRef(0)
  let accumulatedDy = React.useRef(0)
  let lastToggleTime = React.useRef(Date.now())

  let onScroll = (e) => {
    let target = e->JsxEvent.UI.target
    let scrollTop = target["scrollTop"]
    let scrollHeight = target["scrollHeight"]
    let clientHeight = target["clientHeight"]
    
    let dy = scrollTop - lastY.current
    lastY.current = scrollTop

    let isDisabled = switch disabled {
    | Some(r: React.ref<bool>) => r.current
    | None => false
    }

    if !isDisabled && scrollHeight > clientHeight {
      if (dy > 0 && accumulatedDy.current < 0) || (dy < 0 && accumulatedDy.current > 0) {
        accumulatedDy.current = dy
      } else {
        accumulatedDy.current = accumulatedDy.current + dy
      }

      let now = Date.now()
      if now -. lastToggleTime.current > 1000.0 {
        if accumulatedDy.current > 50 {
          setCollapsed(_ => true)
          accumulatedDy.current = 0
          lastToggleTime.current = now
        } else if accumulatedDy.current < -50 {
          setCollapsed(_ => false)
          accumulatedDy.current = 0
          lastToggleTime.current = now
        }
      }
    } else {
      accumulatedDy.current = 0
    }
  }

  (collapsed, setCollapsed, onScroll)
}
