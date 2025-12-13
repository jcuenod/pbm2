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
  hasPrologue: option<bool>,
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

// This array preserves the exact indices from bookDetails.json for API rid decoding
// where rid = bookIndex * 1_000_000 + chapter * 1000 + verse
let booksWithIndices: array<option<book>> = [
  // Pentateuch
  Some({id: "Gen", sbl: "Gen", name: "Genesis", chapters: 50, category: Pentateuch, hasPrologue: None}), // index 0
  Some({id: "Exod", sbl: "Exod", name: "Exodus", chapters: 40, category: Pentateuch, hasPrologue: None}), // index 1
  Some({id: "Lev", sbl: "Lev", name: "Leviticus", chapters: 27, category: Pentateuch, hasPrologue: None}), // index 2
  Some({id: "Num", sbl: "Num", name: "Numbers", chapters: 36, category: Pentateuch, hasPrologue: None}), // index 3
  Some({id: "Deut", sbl: "Deut", name: "Deuteronomy", chapters: 34, category: Pentateuch, hasPrologue: None}), // index 4

  // Historical
  Some({id: "Josh", sbl: "Josh", name: "Joshua", chapters: 24, category: Historical, hasPrologue: None}), // index 5
  Some({id: "Judg", sbl: "Judg", name: "Judges", chapters: 21, category: Historical, hasPrologue: None}), // index 6
  Some({id: "Ruth", sbl: "Ruth", name: "Ruth", chapters: 4, category: Historical, hasPrologue: None}), // index 7
  Some({id: "1Sam", sbl: "1 Sam", name: "1 Samuel", chapters: 31, category: Historical, hasPrologue: None}), // index 8
  Some({id: "2Sam", sbl: "2 Sam", name: "2 Samuel", chapters: 24, category: Historical, hasPrologue: None}), // index 9
  Some({id: "1Kgs", sbl: "1 Kgs", name: "1 Kings", chapters: 22, category: Historical, hasPrologue: None}), // index 10
  Some({id: "2Kgs", sbl: "2 Kgs", name: "2 Kings", chapters: 25, category: Historical, hasPrologue: None}), // index 11
  Some({id: "1Chr", sbl: "1 Chr", name: "1 Chronicles", chapters: 29, category: Historical, hasPrologue: None}), // index 12
  Some({id: "2Chr", sbl: "2 Chr", name: "2 Chronicles", chapters: 36, category: Historical, hasPrologue: None}), // index 13
  Some({id: "Ezra", sbl: "Ezra", name: "Ezra", chapters: 10, category: Historical, hasPrologue: None}), // index 14
  Some({id: "Neh", sbl: "Neh", name: "Nehemiah", chapters: 13, category: Historical, hasPrologue: None}), // index 15
  Some({id: "Esth", sbl: "Est", name: "Esther", chapters: 10, category: Historical, hasPrologue: None}), // index 16

  // Writings
  Some({id: "Job", sbl: "Job", name: "Job", chapters: 42, category: Writings, hasPrologue: None}), // index 17
  Some({id: "Ps", sbl: "Ps", name: "Psalms", chapters: 150, category: Writings, hasPrologue: None}), // index 18
  Some({id: "Prov", sbl: "Prov", name: "Proverbs", chapters: 31, category: Writings, hasPrologue: None}), // index 19
  Some({id: "Eccl", sbl: "Eccl", name: "Ecclesiastes", chapters: 12, category: Writings, hasPrologue: None}), // index 20
  Some({id: "Song", sbl: "Songs", name: "Song of Songs", chapters: 8, category: Writings, hasPrologue: None}), // index 21

  // Prophets
  Some({id: "Isa", sbl: "Isa", name: "Isaiah", chapters: 66, category: Prophets, hasPrologue: None}), // index 22
  Some({id: "Jer", sbl: "Jer", name: "Jeremiah", chapters: 52, category: Prophets, hasPrologue: None}), // index 23
  Some({id: "Lam", sbl: "Lam", name: "Lamentations", chapters: 5, category: Prophets, hasPrologue: None}), // index 24
  Some({id: "Ezek", sbl: "Ezek", name: "Ezekiel", chapters: 48, category: Prophets, hasPrologue: None}), // index 25
  Some({id: "Dan", sbl: "Dan", name: "Daniel", chapters: 12, category: Prophets, hasPrologue: None}), // index 26
  Some({id: "Hos", sbl: "Hos", name: "Hosea", chapters: 14, category: Prophets, hasPrologue: None}), // index 27
  Some({id: "Joel", sbl: "Joel", name: "Joel", chapters: 4, category: Prophets, hasPrologue: None}), // index 28
  Some({id: "Amos", sbl: "Amos", name: "Amos", chapters: 9, category: Prophets, hasPrologue: None}), // index 29
  Some({id: "Obad", sbl: "Obad", name: "Obadiah", chapters: 1, category: Prophets, hasPrologue: None}), // index 30
  Some({id: "Jonah", sbl: "Jonah", name: "Jonah", chapters: 4, category: Prophets, hasPrologue: None}), // index 31
  Some({id: "Mic", sbl: "Mic", name: "Micah", chapters: 7, category: Prophets, hasPrologue: None}), // index 32
  Some({id: "Nah", sbl: "Nah", name: "Nahum", chapters: 3, category: Prophets, hasPrologue: None}), // index 33
  Some({id: "Hab", sbl: "Hab", name: "Habakkuk", chapters: 3, category: Prophets, hasPrologue: None}), // index 34
  Some({id: "Zeph", sbl: "Zeph", name: "Zephaniah", chapters: 3, category: Prophets, hasPrologue: None}), // index 35
  Some({id: "Hag", sbl: "Hag", name: "Haggai", chapters: 2, category: Prophets, hasPrologue: None}), // index 36
  Some({id: "Zech", sbl: "Zech", name: "Zechariah", chapters: 14, category: Prophets, hasPrologue: None}), // index 37
  Some({id: "Mal", sbl: "Mal", name: "Malachi", chapters: 3, category: Prophets, hasPrologue: None}), // index 38

  // Gospels
  Some({id: "Matt", sbl: "Matt", name: "Matthew", chapters: 28, category: Gospels, hasPrologue: None}), // index 39
  Some({id: "Mark", sbl: "Mark", name: "Mark", chapters: 16, category: Gospels, hasPrologue: None}), // index 40
  Some({id: "Luke", sbl: "Luke", name: "Luke", chapters: 24, category: Gospels, hasPrologue: None}), // index 41
  Some({id: "John", sbl: "John", name: "John", chapters: 21, category: Gospels, hasPrologue: None}), // index 42
  Some({id: "Acts", sbl: "Acts", name: "Acts", chapters: 28, category: Gospels, hasPrologue: None}), // index 43

  // PaulineEpistles
  Some({id: "Rom", sbl: "Rom", name: "Romans", chapters: 16, category: PaulineEpistles, hasPrologue: None}), // index 44
  Some({id: "1Cor", sbl: "1 Cor", name: "1 Corinthians", chapters: 16, category: PaulineEpistles, hasPrologue: None}), // index 45
  Some({id: "2Cor", sbl: "2 Cor", name: "2 Corinthians", chapters: 13, category: PaulineEpistles, hasPrologue: None}), // index 46
  Some({id: "Gal", sbl: "Gal", name: "Galatians", chapters: 6, category: PaulineEpistles, hasPrologue: None}), // index 47
  Some({id: "Eph", sbl: "Eph", name: "Ephesians", chapters: 6, category: PaulineEpistles, hasPrologue: None}), // index 48
  Some({id: "Phil", sbl: "Phil", name: "Philippians", chapters: 4, category: PaulineEpistles, hasPrologue: None}), // index 49
  Some({id: "Col", sbl: "Col", name: "Colossians", chapters: 4, category: PaulineEpistles, hasPrologue: None}), // index 50
  Some({id: "1Thess", sbl: "1 Thess", name: "1 Thessalonians", chapters: 5, category: PaulineEpistles, hasPrologue: None}), // index 51
  Some({id: "2Thess", sbl: "2 Thess", name: "2 Thessalonians", chapters: 3, category: PaulineEpistles, hasPrologue: None}), // index 52
  Some({id: "1Tim", sbl: "1 Tim", name: "1 Timothy", chapters: 6, category: PaulineEpistles, hasPrologue: None}), // index 53
  Some({id: "2Tim", sbl: "2 Tim", name: "2 Timothy", chapters: 4, category: PaulineEpistles, hasPrologue: None}), // index 54
  Some({id: "Titus", sbl: "Titus", name: "Titus", chapters: 3, category: PaulineEpistles, hasPrologue: None}), // index 55
  Some({id: "Phlm", sbl: "Phlm", name: "Philemon", chapters: 1, category: PaulineEpistles, hasPrologue: None}), // index 56

  // GeneralEpistles
  Some({id: "Heb", sbl: "Heb", name: "Hebrews", chapters: 13, category: GeneralEpistles, hasPrologue: None}), // index 57
  Some({id: "Jas", sbl: "Jas", name: "James", chapters: 5, category: GeneralEpistles, hasPrologue: None}), // index 58
  Some({id: "1Pet", sbl: "1 Pet", name: "1 Peter", chapters: 5, category: GeneralEpistles, hasPrologue: None}), // index 59
  Some({id: "2Pet", sbl: "2 Pet", name: "2 Peter", chapters: 3, category: GeneralEpistles, hasPrologue: None}), // index 60
  Some({id: "1John", sbl: "1 John", name: "1 John", chapters: 5, category: GeneralEpistles, hasPrologue: None}), // index 61
  Some({id: "2John", sbl: "2 John", name: "2 John", chapters: 1, category: GeneralEpistles, hasPrologue: None}), // index 62
  Some({id: "3John", sbl: "3 John", name: "3 John", chapters: 1, category: GeneralEpistles, hasPrologue: None}), // index 63
  Some({id: "Jude", sbl: "Jude", name: "Jude", chapters: 1, category: GeneralEpistles, hasPrologue: None}), // index 64

  // Revelation
  Some({id: "Rev", sbl: "Rev", name: "Revelation", chapters: 22, category: Revelation, hasPrologue: None}), // index 65
  None, // index 66
  None, // index 67
  None, // index 68
  None, // index 69
  None, // index 70
  None, // index 71
  None, // index 72
  None, // index 73
  None, // index 74
  None, // index 75
  None, // index 76
  None, // index 77
  None, // index 78
  None, // index 79
  None, // index 80
  None, // index 81
  None, // index 82
  None, // index 83
  None, // index 84
  None, // index 85
  None, // index 86
  None, // index 87
  None, // index 88
  None, // index 89
  None, // index 90
  None, // index 91
  None, // index 92
  None, // index 93
  None, // index 94
  None, // index 95
  None, // index 96
  None, // index 97
  None, // index 98
  None, // index 99
  None, // index 100
  None, // index 101
  None, // index 102
  None, // index 103
  None, // index 104
  None, // index 105
  None, // index 106
  None, // index 107
  None, // index 108
  None, // index 109

  // ApostolicFathers
  Some({id: "Barn", sbl: "Barn.", name: "Barnabas", chapters: 21, category: ApostolicFathers, hasPrologue: Some(false)}), // index 110
  Some({id: "1Clem", sbl: "1 Clem.", name: "1 Clement", chapters: 65, category: ApostolicFathers, hasPrologue: Some(true)}), // index 111
  Some({id: "2Clem", sbl: "2 Clem.", name: "2 Clement", chapters: 20, category: ApostolicFathers, hasPrologue: Some(false)}), // index 112
  Some({id: "Did", sbl: "Did.", name: "Didache", chapters: 16, category: ApostolicFathers, hasPrologue: Some(true)}), // index 113
  Some({id: "Diogn", sbl: "Diogn.", name: "Diognetus", chapters: 12, category: ApostolicFathers, hasPrologue: Some(false)}), // index 114
  None, // index 115 Shepherd of Hermas
  Some({id: "IgnEph", sbl: "Ign. Eph.", name: "Ign. Eph.", chapters: 21, category: ApostolicFathers, hasPrologue: Some(true)}), // index 116
  Some({id: "IgnMagn", sbl: "Ign. Magn.", name: "Ign. Magn.", chapters: 15, category: ApostolicFathers, hasPrologue: Some(true)}), // index 117
  Some({id: "IgnPhild", sbl: "Ign. Phild.", name: "Ign. Phild.", chapters: 11, category: ApostolicFathers, hasPrologue: Some(true)}), // index 118
  Some({id: "IgnPol", sbl: "Ign. Pol.", name: "Ign. Pol.", chapters: 8, category: ApostolicFathers, hasPrologue: Some(true)}), // index 119
  Some({id: "IgnRom", sbl: "Ign. Rom.", name: "Ign. Rom.", chapters: 10, category: ApostolicFathers, hasPrologue: Some(true)}), // index 120
  Some({id: "IgnSmyrn", sbl: "Ign. Smyrn.", name: "Ign. Smyrn.", chapters: 13, category: ApostolicFathers, hasPrologue: Some(true)}), // index 121
  Some({id: "IgnTrall", sbl: "Ign. Trall.", name: "Ign. Trall.", chapters: 13, category: ApostolicFathers, hasPrologue: Some(true)}), // index 122
  Some({id: "MartPol", sbl: "Mart. Pol.", name: "Mart. Pol.", chapters: 22, category: ApostolicFathers, hasPrologue: Some(true)}), // index 123
  Some({id: "PolPhil", sbl: "Pol. Phil.", name: "Pol. Phil.", chapters: 14, category: ApostolicFathers, hasPrologue: Some(true)}), // index 124
]

// Helper array containing only non-null books (for backward compatibility)
let books: array<book> = booksWithIndices->Array.filterMap(x => x)

// Get book by array index (for API rid decoding where bookIndex = rid / 1_000_000)
// Note: bookIndex in API is 1-based, so index 1 = first book (Genesis at array index 0)
let getBookByIndex = (bookIndex: int): option<book> =>
  if bookIndex <= 0 {
    None
  } else {
    booksWithIndices->Array.get(bookIndex - 1)->Option.flatMap(x => x)
  }

let getBookById = (bookId: string): option<book> =>
  books->Array.find(book => book.id == bookId)

let groupBooksByRow = (books: array<book>) => {
  let rows = []
  let currentRow = []
  let lastCategory = ref(None)

  books->Array.forEach(book => {
    let needNewRow = switch lastCategory.contents {
    | None => false
    | Some(cat) => // Start new row when:
      // 1. Transitioning into NT (from OT to Gospels)
      // 2. Transitioning into Apostolic Fathers
      // 3. Current row has 4 books (wrapping)
      (cat != Gospels && book.category == Gospels) ||
      cat != ApostolicFathers && book.category == ApostolicFathers ||
      currentRow->Array.length >= 4
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
