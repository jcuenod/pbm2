@module("./jsHelpers.js")
external getLocalStorage: string => option<string> = "getLocalStorage"
@module("./jsHelpers.js")
external setLocalStorage: (string, string) => unit = "setLocalStorage"
@module("./jsHelpers.js")
external setHtmlDark: bool => unit = "setHtmlDark"

@react.component
let make = (
  ~onToggle=_ => (),
  ~availableModules,
  ~selectedModuleIds,
  ~onModuleToggle,
  ~onModuleReorder,
) => {
  let (showModuleSettings, setShowModuleSettings) = React.useState(() => false)
  let (dark, setDark) = React.useState(() =>
    switch getLocalStorage("dark") {
    | Some("1") => true
    | _ => false
    }
  )

  // Initialize dark mode on mount
  React.useEffect1(() => {
    setHtmlDark(dark)
    None
  }, [dark])

  if showModuleSettings {
    <ModuleSettings
      availableModules
      selectedModuleIds
      onModuleToggle
      onReorder={onModuleReorder}
      onBack={() => setShowModuleSettings(_ => false)}
    />
  } else {
    <div className="p-6">
      <div className="space-y-6">
        <div
          className="flex items-center justify-between p-4 bg-gray-50 dark:bg-stone-800 rounded-lg"
        >
          <span className="font-medium text-gray-900 dark:text-gray-100">
            {React.string("Dark mode")}
          </span>
          <button
            onClick={_ => {
              setDark(prev => {
                let next = !prev
                setLocalStorage(
                  "dark",
                  if next {
                    "1"
                  } else {
                    "0"
                  },
                )
                setHtmlDark(next)
                onToggle(next)
                next
              })
            }}
            className={"relative inline-flex items-center h-8 rounded-full w-14 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-teal-500 " ++ if (
              dark
            ) {
              "bg-teal-600"
            } else {
              "bg-gray-300"
            }}
          >
            <span
              className={"transform transition-transform duration-200 inline-block w-6 h-6 bg-white rounded-full shadow-md " ++ if (
                dark
              ) {
                "translate-x-7"
              } else {
                "translate-x-1"
              }}
            >
            </span>
          </button>
        </div>

        <button
          onClick={_ => setShowModuleSettings(_ => true)}
          className="w-full flex items-center justify-between p-4 bg-gray-50 dark:bg-stone-800 rounded-lg hover:bg-gray-100 dark:hover:bg-stone-700 transition-colors"
        >
          <span className="font-medium"> {React.string("Module Settings")} </span>
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </div>
    </div>
  }
}
