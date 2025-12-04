type bookCategory = 
  | Pentateuch
  | Historical
  | Writings
  | Prophets
  | Gospels
  | PaulineEpistles
  | GeneralEpistles
  | Revelation
  | ApostolicFathers

type book = {
  id: string,
  sbl: string,
  name: string,
  chapters: int,
  category: bookCategory,
}

let getCategoryColor = (category: bookCategory) => {
  switch category {
  | Pentateuch => "border-b-4 border-amber-500"
  | Historical => "border-b-4 border-sky-500"
  | Writings => "border-b-4 border-violet-500"
  | Prophets => "border-b-4 border-emerald-500"
  | Gospels => "border-b-4 border-blue-600"
  | PaulineEpistles => "border-b-4 border-indigo-600"
  | GeneralEpistles => "border-b-4 border-purple-600"
  | Revelation => "border-b-4 border-rose-600"
  | ApostolicFathers => "border-b-4 border-slate-500"
  }
}

let getCategoryBgColor = (category: bookCategory) => {
  switch category {
  | Pentateuch => "bg-amber-500/5 dark:bg-amber-500/10"
  | Historical => "bg-sky-500/5 dark:bg-sky-500/10"
  | Writings => "bg-violet-500/5 dark:bg-violet-500/10"
  | Prophets => "bg-emerald-500/5 dark:bg-emerald-500/10"
  | Gospels => "bg-blue-600/5 dark:bg-blue-600/10"
  | PaulineEpistles => "bg-indigo-600/5 dark:bg-indigo-600/10"
  | GeneralEpistles => "bg-purple-600/5 dark:bg-purple-600/10"
  | Revelation => "bg-rose-600/5 dark:bg-rose-600/10"
  | ApostolicFathers => "bg-slate-500/5 dark:bg-slate-500/10"
  }
}

let books = [
  // Pentateuch
  {id: "Gen", sbl: "Gen", name: "Genesis", chapters: 50, category: Pentateuch},
  {id: "Exod", sbl: "Exod", name: "Exodus", chapters: 40, category: Pentateuch},
  {id: "Lev", sbl: "Lev", name: "Leviticus", chapters: 27, category: Pentateuch},
  {id: "Num", sbl: "Num", name: "Numbers", chapters: 36, category: Pentateuch},
  {id: "Deut", sbl: "Deut", name: "Deuteronomy", chapters: 34, category: Pentateuch},
  
  // Historical Books
  {id: "Josh", sbl: "Josh", name: "Joshua", chapters: 24, category: Historical},
  {id: "Judg", sbl: "Judg", name: "Judges", chapters: 21, category: Historical},
  {id: "Ruth", sbl: "Ruth", name: "Ruth", chapters: 4, category: Historical},
  {id: "1Sam", sbl: "1 Sam", name: "1 Samuel", chapters: 31, category: Historical},
  {id: "2Sam", sbl: "2 Sam", name: "2 Samuel", chapters: 24, category: Historical},
  {id: "1Kgs", sbl: "1 Kgs", name: "1 Kings", chapters: 22, category: Historical},
  {id: "2Kgs", sbl: "2 Kgs", name: "2 Kings", chapters: 25, category: Historical},
  {id: "1Chr", sbl: "1 Chr", name: "1 Chronicles", chapters: 29, category: Historical},
  {id: "2Chr", sbl: "2 Chr", name: "2 Chronicles", chapters: 36, category: Historical},
  {id: "Ezra", sbl: "Ezra", name: "Ezra", chapters: 10, category: Historical},
  {id: "Neh", sbl: "Neh", name: "Nehemiah", chapters: 13, category: Historical},
  {id: "Esth", sbl: "Esth", name: "Esther", chapters: 10, category: Historical},
  
  // Writings
  {id: "Job", sbl: "Job", name: "Job", chapters: 42, category: Writings},
  {id: "Ps", sbl: "Ps", name: "Psalms", chapters: 150, category: Writings},
  {id: "Prov", sbl: "Prov", name: "Proverbs", chapters: 31, category: Writings},
  {id: "Eccl", sbl: "Eccl", name: "Ecclesiastes", chapters: 12, category: Writings},
  {id: "Song", sbl: "Song", name: "Song of Songs", chapters: 8, category: Writings},
  {id: "Lam", sbl: "Lam", name: "Lamentations", chapters: 5, category: Writings},
  
  // Prophets
  {id: "Isa", sbl: "Isa", name: "Isaiah", chapters: 66, category: Prophets},
  {id: "Jer", sbl: "Jer", name: "Jeremiah", chapters: 52, category: Prophets},
  {id: "Ezek", sbl: "Ezek", name: "Ezekiel", chapters: 48, category: Prophets},
  {id: "Dan", sbl: "Dan", name: "Daniel", chapters: 12, category: Prophets},
  {id: "Hos", sbl: "Hos", name: "Hosea", chapters: 14, category: Prophets},
  {id: "Joel", sbl: "Joel", name: "Joel", chapters: 3, category: Prophets},
  {id: "Amos", sbl: "Amos", name: "Amos", chapters: 9, category: Prophets},
  {id: "Obad", sbl: "Obad", name: "Obadiah", chapters: 1, category: Prophets},
  {id: "Jonah", sbl: "Jonah", name: "Jonah", chapters: 4, category: Prophets},
  {id: "Mic", sbl: "Mic", name: "Micah", chapters: 7, category: Prophets},
  {id: "Nah", sbl: "Nah", name: "Nahum", chapters: 3, category: Prophets},
  {id: "Hab", sbl: "Hab", name: "Habakkuk", chapters: 3, category: Prophets},
  {id: "Zeph", sbl: "Zeph", name: "Zephaniah", chapters: 3, category: Prophets},
  {id: "Hag", sbl: "Hag", name: "Haggai", chapters: 2, category: Prophets},
  {id: "Zech", sbl: "Zech", name: "Zechariah", chapters: 14, category: Prophets},
  {id: "Mal", sbl: "Mal", name: "Malachi", chapters: 4, category: Prophets},
  
  // New Testament - Gospels & Acts
  {id: "Matt", sbl: "Matt", name: "Matthew", chapters: 28, category: Gospels},
  {id: "Mark", sbl: "Mark", name: "Mark", chapters: 16, category: Gospels},
  {id: "Luke", sbl: "Luke", name: "Luke", chapters: 24, category: Gospels},
  {id: "John", sbl: "John", name: "John", chapters: 21, category: Gospels},
  {id: "Acts", sbl: "Acts", name: "Acts", chapters: 28, category: Gospels},
  
  // Pauline Epistles
  {id: "Rom", sbl: "Rom", name: "Romans", chapters: 16, category: PaulineEpistles},
  {id: "1Cor", sbl: "1 Cor", name: "1 Corinthians", chapters: 16, category: PaulineEpistles},
  {id: "2Cor", sbl: "2 Cor", name: "2 Corinthians", chapters: 13, category: PaulineEpistles},
  {id: "Gal", sbl: "Gal", name: "Galatians", chapters: 6, category: PaulineEpistles},
  {id: "Eph", sbl: "Eph", name: "Ephesians", chapters: 6, category: PaulineEpistles},
  {id: "Phil", sbl: "Phil", name: "Philippians", chapters: 4, category: PaulineEpistles},
  {id: "Col", sbl: "Col", name: "Colossians", chapters: 4, category: PaulineEpistles},
  {id: "1Thess", sbl: "1 Thess", name: "1 Thessalonians", chapters: 5, category: PaulineEpistles},
  {id: "2Thess", sbl: "2 Thess", name: "2 Thessalonians", chapters: 3, category: PaulineEpistles},
  {id: "1Tim", sbl: "1 Tim", name: "1 Timothy", chapters: 6, category: PaulineEpistles},
  {id: "2Tim", sbl: "2 Tim", name: "2 Timothy", chapters: 4, category: PaulineEpistles},
  {id: "Titus", sbl: "Titus", name: "Titus", chapters: 3, category: PaulineEpistles},
  {id: "Phlm", sbl: "Phlm", name: "Philemon", chapters: 1, category: PaulineEpistles},
  
  // General Epistles
  {id: "Heb", sbl: "Heb", name: "Hebrews", chapters: 13, category: GeneralEpistles},
  {id: "Jas", sbl: "Jas", name: "James", chapters: 5, category: GeneralEpistles},
  {id: "1Pet", sbl: "1 Pet", name: "1 Peter", chapters: 5, category: GeneralEpistles},
  {id: "2Pet", sbl: "2 Pet", name: "2 Peter", chapters: 3, category: GeneralEpistles},
  {id: "1John", sbl: "1 John", name: "1 John", chapters: 5, category: GeneralEpistles},
  {id: "2John", sbl: "2 John", name: "2 John", chapters: 1, category: GeneralEpistles},
  {id: "3John", sbl: "3 John", name: "3 John", chapters: 1, category: GeneralEpistles},
  {id: "Jude", sbl: "Jude", name: "Jude", chapters: 1, category: GeneralEpistles},
  
  // Revelation
  {id: "Rev", sbl: "Rev", name: "Revelation", chapters: 22, category: Revelation},
  
  // Apostolic Fathers
  {id: "1Clem", sbl: "1 Clem", name: "1 Clement", chapters: 65, category: ApostolicFathers},
  {id: "2Clem", sbl: "2 Clem", name: "2 Clement", chapters: 20, category: ApostolicFathers},
  {id: "Ign", sbl: "Ign", name: "Ignatius", chapters: 7, category: ApostolicFathers},
  {id: "Pol", sbl: "Pol", name: "Polycarp", chapters: 14, category: ApostolicFathers},
  {id: "Barn", sbl: "Barn", name: "Barnabas", chapters: 21, category: ApostolicFathers},
  {id: "Did", sbl: "Did", name: "Didache", chapters: 16, category: ApostolicFathers},
  {id: "Herm", sbl: "Herm", name: "Shepherd of Hermas", chapters: 114, category: ApostolicFathers},
]

let groupBooksByRow = (books: array<book>) => {
  let rows = []
  let currentRow = []
  let lastCategory = ref(None)
  
  books->Array.forEach(book => {
    let needNewRow = switch lastCategory.contents {
    | None => false
    | Some(cat) => {
        // Start new row when:
        // 1. Transitioning into NT (from OT to Gospels)
        // 2. Transitioning into Apostolic Fathers
        // 3. Current row has 4 books (wrapping)
        (cat != Gospels && book.category == Gospels) ||
        (cat != ApostolicFathers && book.category == ApostolicFathers) ||
        currentRow->Array.length >= 4
      }
    }
    
    if needNewRow && currentRow->Array.length > 0 {
      rows->Array.push(currentRow->Array.copy)
      currentRow->Array.splice(~start=0, ~remove=currentRow->Array.length, ~insert=[])
    }
    
    currentRow->Array.push(book)
    lastCategory := Some(book.category)
  })
  
  if currentRow->Array.length > 0 {
    rows->Array.push(currentRow)
  }
  
  rows
}
