@react.component
let make = (
  ~show: bool,
  ~header: option<React.element>=?,
  ~showCloseButton: bool=true,
  ~closeOnOverlayClick: bool=true,
  ~onClose: unit => unit,
  ~children: React.element,
) => {
  let (shouldRender, setShouldRender) = React.useState(() => show)

  React.useEffect1(() => {
    if show {
      setShouldRender(_ => true)
      None
    } else {
      let timeoutId = setTimeout(() => {
        setShouldRender(_ => false)
      }, 200)
      Some(() => clearTimeout(timeoutId))
    }
  }, [show])

  if shouldRender {
    let animationClass = if show { "animate-dialog-enter" } else { "animate-dialog-exit" }
    let backdropClass = if show { "animate-fade-in" } else { "animate-fade-out" }

    <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
      <div
        className={"absolute inset-0 bg-black/60 " ++ backdropClass}
        onClick={_ =>
          if closeOnOverlayClick {
            onClose()
          }}
      />
      <div
        className={"relative bg-white dark:bg-stone-900 p-6 shadow-2xl max-w-md w-full rounded-lg " ++ animationClass}
      >
        {switch (header, showCloseButton) {
        | (None, false) => React.null
        | _ =>
          <div className="flex items-center justify-between mb-4">
            {switch header {
            | Some(h) =>
              <h3 className="text-lg font-semibold text-stone-900 dark:text-stone-100"> h </h3>
            | None => <div />
            }}
            {if showCloseButton {
              <button
                className="w-8 h-8 rounded-full bg-stone-100 dark:bg-stone-800 text-stone-500 dark:text-stone-300 flex items-center justify-center"
                onClick={_ => onClose()}
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            } else {
              React.null
            }}
          </div>
        }}
        children
      </div>
    </div>
  } else {
    React.null
  }
}
