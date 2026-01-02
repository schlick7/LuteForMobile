# Lute v3 API Endpoints Documentation

This document provides a comprehensive list of all API endpoints available in Lute v3, including their methods, parameters, and functionality.

## Main Application Routes (`/`)

### `GET /`
- **Description**: Main index page showing available books and languages
- **Parameters**:
  - None
- **Response**: HTML template with book and language listings
- **Data Exposed**: Books, languages, backup settings, tutorial information

### `GET /refresh_all_stats`
- **Description**: Marks all book stats as stale to trigger recalculation
- **Parameters**: None
- **Response**: Redirect to main page
- **Data Used**: All books (non-archived)

### `GET /wipe_database`
- **Description**: Deletes all data if in demo mode
- **Parameters**: None
- **Response**: Flash message and redirect to main page
- **Data Affected**: All tables (when demo flag is set)

### `GET /remove_demo_flag`
- **Description**: Removes the demo flag to deactivate demo mode
- **Parameters**: None
- **Response**: Flash message and redirect to main page
- **Data Affected**: Demo flag in database

### `GET /version`
- **Description**: Shows application version information
- **Parameters**: None
- **Response**: HTML template with version, data path, and database info
- **Data Exposed**: App version, data path, database filename, Docker status

### `GET /info`
- **Description**: JSON endpoint for version and data information
- **Parameters**: None
- **Response**: JSON object with version, data path, and database info
- **Data Exposed**: App version, data path, database

### `GET /static/js/never_cache/<path:filename>`
- **Description**: Serves JavaScript files with no caching headers
- **Parameters**: `filename` - path to the JS file
- **Response**: JS file with no-cache headers
- **Data Used**: JavaScript files in static/js directory

---

## Book Routes (`/book`)

### `GET /book/datatables/active`
- **Description**: DataTables JSON response for active books
- **Parameters**: DataTables parameters in POST request
- **Response**: JSON with book data for DataTables
- **Data Exposed**: All active books with metadata

### `GET /book/archived`
- **Description**: Archived books listing page
- **Parameters**: None
- **Response**: HTML template with archived book listing
- **Data Exposed**: Language choices, current language ID

### `POST /book/datatables/Archived`
- **Description**: DataTables JSON response for archived books
- **Parameters**: DataTables parameters in POST request
- **Response**: JSON with archived book data for DataTables
- **Data Exposed**: All archived books with metadata

### `GET /book/new`
- **Description**: Create new book page
- **Parameters**: 
  - `importurl` (optional) - URL to import from
- **Response**: HTML form for creating a new book
- **Data Exposed**: Available languages, book tags

### `POST /book/new`
- **Description**: Create new book
- **Parameters**: Book data from form submission
- **Response**: Redirect to reading page
- **Data Used**: Book parameters (title, text, language, etc.)

### `GET /book/edit/<int:bookid>`
- **Description**: Edit book page
- **Parameters**: `bookid` - ID of the book to edit
- **Response**: HTML form for editing a book
- **Data Exposed**: Book details, available languages, book tags

### `POST /book/edit/<int:bookid>`
- **Description**: Update book
- **Parameters**: `bookid` - ID of the book to update
- **Response**: Flash message and redirect to main page
- **Data Used**: Updated book parameters from form

### `GET /book/import_webpage`
- **Description**: Page for importing a webpage
- **Parameters**: None
- **Response**: HTML template for webpage import
- **Data Used**: None

### `POST /book/archive/<int:bookid>`
- **Description**: Archive a book
- **Parameters**: `bookid` - ID of the book to archive
- **Response**: Redirect to main page
- **Data Used**: Book to be archived

### `POST /book/unarchive/<int:bookid>`
- **Description**: Unarchive a book
- **Parameters**: `bookid` - ID of the book to unarchive
- **Response**: Redirect to main page
- **Data Used**: Book to be unarchived

### `POST /book/delete/<int:bookid>`
- **Description**: Delete a book
- **Parameters**: `bookid` - ID of the book to delete
- **Response**: Redirect to main page
- **Data Used**: Book to be deleted

### `GET /book/table_stats/<int:bookid>`
- **Description**: Get statistics for a book via JSON
- **Parameters**: `bookid` - ID of the book
- **Response**: JSON with book statistics
- **Data Exposed**: Book statistics (distinct terms, unknowns, percent, status distribution)

---

## Language Routes (`/language`)

### `GET /language/index`
- **Description**: List all languages with book and term counts
- **Parameters**: None
- **Response**: HTML template with language data
- **Data Exposed**: Languages with associated book and term counts

### `GET /language/edit/<int:langid>`
- **Description**: Edit language page
- **Parameters**: `langid` - ID of the language to edit
- **Response**: HTML form for editing a language
- **Data Exposed**: Language details, available parsers

### `POST /language/edit/<int:langid>`
- **Description**: Update language
- **Parameters**: `langid` - ID of the language to update
- **Response**: Flash message and redirect to main page
- **Data Used**: Updated language parameters from form

### `GET /language/new`
- **Description**: Create new language page
- **Parameters**: None
- **Response**: HTML form for creating a new language
- **Data Exposed**: Available predefined languages, available parsers

### `POST /language/new`
- **Description**: Create new language
- **Parameters**: None
- **Response**: Flash message and redirect to main page
- **Data Used**: Language parameters from form

### `GET /language/new/<string:langname>`
- **Description**: Create new language from predefined template
- **Parameters**: `langname` - Name of the predefined language
- **Response**: HTML form with predefined language settings
- **Data Exposed**: Predefined language template

### `POST /language/new/<string:langname>`
- **Description**: Create new language from predefined template
- **Parameters**: `langname` - Name of the predefined language
- **Response**: Flash message and redirect to main page
- **Data Used**: Predefined language settings and form data

### `POST /language/delete/<int:langid>`
- **Description**: Delete a language
- **Parameters**: `langid` - ID of the language to delete
- **Response**: Redirect to language index
- **Data Used**: Language to be deleted

### `GET /language/list_predefined`
- **Description**: List predefined languages not already in database
- **Parameters**: None
- **Response**: HTML template with predefined languages
- **Data Exposed**: Predefined languages not currently in the system

### `GET /language/load_predefined/<langname>`
- **Description**: Load a predefined language with sample stories
- **Parameters**: `langname` - Name of the predefined language to load
- **Response**: Flash message and redirect to main page
- **Data Used**: Predefined language definition

---

## Term Routes (`/term`)

### `GET /term/index`
- **Description**: Term management index page
- **Parameters**: None
- **Response**: HTML template with term management interface
- **Data Exposed**: Available languages, statuses, term tags

### `GET /term/index/<search>`
- **Description**: Term management index page with initial search
- **Parameters**: `search` - Initial search term
- **Response**: HTML template with term management interface
- **Data Exposed**: Available languages, statuses, term tags

### `POST /term/datatables`
- **Description**: DataTables JSON response for terms
- **Parameters**: DataTables parameters in POST request, filter parameters
- **Response**: JSON with term data for DataTables
- **Data Exposed**: Terms with filtering options

### `POST /term/bulk_edit_from_index`
- **Description**: Bulk edit terms from index page
- **Parameters**: Various parameters from bulk edit form
- **Response**: Redirect to term index
- **Data Used**: Term IDs and update parameters

### `POST /term/bulk_edit_from_reading_pane`
- **Description**: Bulk edit terms from reading pane
- **Parameters**: Various parameters from bulk edit form
- **Response**: HTML template for updated term
- **Data Used**: Term IDs and update parameters

### `POST /term/ajax_edit_from_index`
- **Description**: Ajax term update from index page
- **Parameters**: JSON with term_id, update_type, and values
- **Response**: JSON with updated status or error
- **Data Used**: Term ID and update parameters

### `POST /term/export_terms`
- **Description**: Export terms to CSV file
- **Parameters**: DataTables parameters in POST request, filter parameters
- **Response**: CSV file attachment
- **Data Exposed**: Term data in CSV format

### `GET /term/edit/<int:termid>`
- **Description**: Edit term page
- **Parameters**: `termid` - ID of the term to edit
- **Response**: HTML form for editing a term
- **Data Exposed**: Term details and available languages

### `POST /term/edit/<int:termid>`
- **Description**: Update term
- **Parameters**: `termid` - ID of the term to update
- **Response**: Redirect to term index
- **Data Used**: Updated term parameters from form

### `GET /term/editbytext/<int:langid>/<text>`
- **Description**: Edit term by language and text
- **Parameters**: 
  - `langid` - Language ID
  - `text` - Text content of the term
- **Response**: HTML form for editing/creating a term
- **Data Exposed**: Term details and language dictionaries

### `POST /term/editbytext/<int:langid>/<text>`
- **Description**: Create or update term by language and text
- **Parameters**: 
  - `langid` - Language ID 
  - `text` - Text content of the term
- **Response**: Redirect to term index
- **Data Used**: Form data for term creation/update

### `GET /term/new`
- **Description**: Create new term page
- **Parameters**: None
- **Response**: HTML form for creating a new term
- **Data Exposed**: Available languages and dictionaries

### `POST /term/new`
- **Description**: Create new term
- **Parameters**: None
- **Response**: Redirect to term new page
- **Data Used**: Term parameters from form

### `GET /term/search/<text>/<int:langid>`
- **Description**: Search for terms by text in a specific language
- **Parameters**: 
  - `text` - Text to search for
  - `langid` - Language ID to search in
- **Response**: JSON with matching terms
- **Data Exposed**: Terms matching the text in the specified language

### `GET /term/sentences/<int:langid>/<text>`
- **Description**: Get sentences for a term
- **Parameters**: 
  - `langid` - Language ID
  - `text` - Term text
- **Response**: HTML template with sentence references
- **Data Exposed**: Sentences containing the term and its parents/children

### `POST /term/bulk_update_status`
- **Description**: Bulk update term statuses
- **Parameters**: JSON with update information
- **Response**: JSON confirmation
- **Data Used**: Term IDs and new status values

### `POST /term/bulk_delete`
- **Description**: Bulk delete terms
- **Parameters**: JSON with word IDs to delete
- **Response**: JSON confirmation
- **Data Used**: Term IDs for deletion

### `POST /term/delete/<int:termid>`
- **Description**: Delete a term
- **Parameters**: `termid` - ID of the term to delete
- **Response**: Redirect to term index
- **Data Used**: Term to be deleted

---

## Reading Routes (`/read`)

### `GET /read/<int:bookid>`
- **Description**: Read a book starting at current/last reading position (defaults to page 1)
- **Parameters**: `bookid` - ID of the book to read
- **Response**: Full HTML template for reading interface
- **Data Exposed**: Full page structure with metadata (title, page count, audio settings), navigation elements, and language settings
- **Note**: The `<div id="thetext">` placeholder is empty. Use `/read/start_reading/...` to get actual text content

### `GET /read/<int:bookid>/page/<int:pagenum>`
- **Description**: Get full HTML page structure for a specific book page (for metadata extraction)
- **Parameters**:
  - `bookid` - ID of the book
  - `pagenum` - Page number to read
- **Response**: Full HTML template for reading interface
- **Data Exposed**: Full page structure with metadata (title, page count, audio settings), navigation elements, and language settings
- **Note**: The `<div id="thetext">` placeholder is empty. Use `/read/start_reading/...` to get actual text content. This endpoint is used to extract page metadata like title, page count, and audio information.

### `GET /read/<int:bookid>/peek/<int:pagenum>`
- **Description**: Peek at a page without tracking as read
- **Parameters**:
  - `bookid` - ID of the book
  - `pagenum` - Page number to peek at
- **Response**: HTML template for reading interface
- **Data Exposed**: Book page content, language settings

### `GET /read/start_reading/<int:bookid>/<int:pagenum>`
- **Description**: Start reading a page (set start date and return actual parsed text content)
- **Parameters**:
  - `bookid` - ID of the book
  - `pagenum` - Page number to start reading
- **Response**: HTML fragment containing the parsed page text with word status classes (not a full HTML page)
- **Data Used**: Page start date tracking
- **Usage**: Used for page navigation (next/previous) to track reading. Returns the actual text content that should be loaded into the `<div id="thetext">` element from the full page structure.

### `GET /read/refresh_page/<int:bookid>/<int:pagenum>`
- **Description**: Refresh page content without changing start date
- **Parameters**:
  - `bookid` - ID of the book
  - `pagenum` - Page number to refresh
- **Response**: HTML template with parsed page content
- **Data Exposed**: Page content without updating start date
- **Usage**: Used for page navigation when not tracking (e.g., peeking)

### `POST /read/page_done`
- **Description**: Mark page as read
- **Parameters**: JSON with bookid, pagenum, and restknown
- **Response**: JSON confirmation
- **Data Used**: Book page completion data
- **restknown**:
  - If `false`: Mark page as read only (call `markPageRead`)
  - If `true`: Mark page as read AND set all unknown words (status 0) on the page to Well-Known (status 99) (call `markPageKnown`)

### `GET /read/delete_page/<int:bookid>/<int:pagenum>`
- **Description**: Delete a page from a book
- **Parameters**: 
  - `bookid` - ID of the book
  - `pagenum` - Page number to delete
- **Response**: Redirect to the same page (after deletion)
- **Data Used**: Book and page

### `GET /read/new_page/<int:bookid>/<position>/<int:pagenum>`
- **Description**: Create a new page in a book
- **Parameters**: 
  - `bookid` - ID of the book
  - `position` - Position to insert page ("before" or "after")
  - `pagenum` - Reference page number
- **Response**: HTML form for creating page or redirect after creation

### `POST /read/new_page/<int:bookid>/<position>/<int:pagenum>`
- **Description**: Create a new page in a book
- **Parameters**: 
  - `bookid` - ID of the book
  - `position` - Position to insert page ("before" or "after")
  - `pagenum` - Reference page number
- **Response**: Redirect to reading page after creation
- **Data Used**: New page text from form

### `POST /read/save_player_data`
- **Description**: Save audio player position and bookmarks
- **Parameters**: JSON with bookid, position, and bookmarks
- **Response**: JSON confirmation
- **Data Used**: Audio playback data

### `GET /read/start_reading/<int:bookid>/<int:pagenum>`
- **Description**: Start reading a page (set start date and render content)
- **Parameters**: 
  - `bookid` - ID of the book
  - `pagenum` - Page number to start reading
- **Response**: HTML template with parsed page content
- **Data Used**: Page start date tracking

### `GET /read/refresh_page/<int:bookid>/<int:pagenum>`
- **Description**: Refresh page content without changing start date
- **Parameters**: 
  - `bookid` - ID of the book
  - `pagenum` - Page number to refresh
- **Response**: HTML template with parsed page content
- **Data Exposed**: Page content without updating start date

### `GET /read/empty`
- **Description**: Return an empty page
- **Parameters**: None
- **Response**: Empty string
- **Data Used**: None

### `GET /read/termform/<int:langid>/<text>`
- **Description**: Create term form for reading interface
- **Parameters**: 
  - `langid` - Language ID
  - `text` - Term text (may contain "LUTESLASH" to represent "/")
- **Response**: HTML term form
- **Data Exposed**: Term details, language dictionaries

### `POST /read/termform/<int:langid>/<text>`
- **Description**: Submit term form for reading interface
- **Parameters**: 
  - `langid` - Language ID
  - `text` - Term text (may contain "LUTESLASH" to represent "/")
- **Response**: HTML template with updated term
- **Data Used**: Term form data

### `GET /read/edit_term/<int:term_id>`
- **Description**: Edit term form in reading interface
- **Parameters**: `term_id` - ID of the term to edit
- **Response**: HTML term form
- **Data Exposed**: Term details, language dictionaries

### `POST /read/edit_term/<int:term_id>`
- **Description**: Submit term edit in reading interface
- **Parameters**: `term_id` - ID of the term to edit
- **Response**: HTML template with updated term
- **Data Used**: Term form data

### `GET /read/term_bulk_edit_form`
- **Description**: Show bulk term edit form in reading interface
- **Parameters**: None
- **Response**: HTML bulk edit form
- **Data Exposed**: Available term tags

### `GET /read/termpopup/<int:termid>`
- **Description**: Get term popup HTML for a specific term
- **Parameters**: `termid` - ID of the term
- **Response**: HTML template with term information
- **Data Exposed**: Term details, parent/children, sentences

### `GET /read/flashcopied`
- **Description**: Show flash notification for copied text
- **Parameters**: None
- **Response**: HTML template for flash notification

### `GET /read/editpage/<int:bookid>/<int:pagenum>`
- **Description**: Edit text of a page
- **Parameters**: 
  - `bookid` - ID of the book
  - `pagenum` - Page number to edit
- **Response**: HTML form for editing page text
- **Data Exposed**: Page content

### `POST /read/editpage/<int:bookid>/<int:pagenum>`
- **Description**: Update text of a page
- **Parameters**: 
  - `bookid` - ID of the book
  - `pagenum` - Page number to update
- **Response**: Redirect to reading page
- **Data Used**: Updated page text from form

---

## Settings Routes (`/settings`)

### `GET /settings/index`
- **Description**: Edit user settings page
- **Parameters**: None
- **Response**: HTML form for user settings
- **Data Exposed**: Current user settings

### `POST /settings/index`
- **Description**: Update user settings
- **Parameters**: None
- **Response**: Flash message and redirect to main page
- **Data Used**: Settings form data

### `GET /settings/test_mecab`
- **Description**: Test MeCab parser with provided path
- **Parameters**: `mecab_path` - Path to MeCab executable
- **Response**: JSON result of test
- **Data Used**: MeCab path for testing

### `POST /settings/set/<key>/<value>`
- **Description**: Set a specific user setting key to value
- **Parameters**: 
  - `key` - Setting key
  - `value` - Setting value
- **Response**: JSON confirmation
- **Data Used**: Setting key-value pair

### `GET /settings/shortcuts`
- **Description**: Edit keyboard shortcuts
- **Parameters**: None
- **Response**: HTML form for editing shortcuts
- **Data Exposed**: Current shortcut settings

### `POST /settings/shortcuts`
- **Description**: Update keyboard shortcuts
- **Parameters**: None
- **Response**: Flash message and redirect to main page
- **Data Used**: Shortcut form data

---

## Backup Routes (`/backup`)

### `GET /backup/index`
- **Description**: List available backups
- **Parameters**: None
- **Response**: HTML template with backup listing
- **Data Exposed**: Available backup files

### `GET /backup/download/<filename>`
- **Description**: Download a backup file
- **Parameters**: `filename` - Name of the backup file
- **Response**: File download
- **Data Exposed**: Backup file

### `GET /backup/backup`
- **Description**: Backup creation page
- **Parameters**: `type` (optional) - Type of backup ("manual")
- **Response**: HTML template for backup creation
- **Data Exposed**: Backup folder path

### `POST /backup/do_backup`
- **Description**: Create backup
- **Parameters**: Form data with backup type
- **Response**: JSON with backup filename or error
- **Data Used**: Backup settings and database

### `GET /backup/skip_this_backup`
- **Description**: Skip current backup and update settings
- **Parameters**: None
- **Response**: Redirect to main page
- **Data Used**: Backup settings

---

## Theme Routes (`/theme`)

### `GET /theme/current`
- **Description**: Get current theme CSS
- **Parameters**: None
- **Response**: CSS content for current theme
- **Data Exposed**: Current theme CSS

### `GET /theme/custom_styles`
- **Description**: Get custom user styles
- **Parameters**: None
- **Response**: CSS content for custom styles
- **Data Exposed**: Custom styles from user settings

### `POST /theme/next`
- **Description**: Cycle to next theme
- **Parameters**: None
- **Response**: JSON confirmation
- **Data Used**: Theme settings

### `POST /theme/toggle_highlight`
- **Description**: Toggle text highlighting
- **Parameters**: None
- **Response**: JSON confirmation
- **Data Used**: Highlight setting

---

## Stats Routes (`/stats`)

### `GET /stats/`
- **Description**: Statistics main page
- **Parameters**: None
- **Response**: HTML template with statistics
- **Data Exposed**: Reading statistics table data

### `GET /stats/data`
- **Description**: Statistics chart data
- **Parameters**: None
- **Response**: JSON with chart data
- **Data Exposed**: Reading statistics chart data

---

## Bookmark Routes (`/bookmarks`)

### `POST /bookmarks/<int:bookid>/datatables`
- **Description**: DataTables JSON response for bookmarks
- **Parameters**: 
  - `bookid` - ID of the book
  - DataTables parameters in POST request
- **Response**: JSON with bookmark data for DataTables
- **Data Exposed**: Bookmarks for the specified book

### `GET /bookmarks/<int:bookid>`
- **Description**: List all bookmarks for a book
- **Parameters**: `bookid` - ID of the book
- **Response**: HTML template with bookmark listing
- **Data Exposed**: Bookmarks for the specified book

### `POST /bookmarks/add`
- **Description**: Add a new bookmark
- **Parameters**: JSON with book_id, page_num, and title
- **Response**: JSON confirmation
- **Data Used**: Bookmark information

### `POST /bookmarks/delete`
- **Description**: Delete a bookmark
- **Parameters**: JSON with bookmark_id
- **Response**: JSON confirmation
- **Data Used**: Bookmark to be deleted

### `POST /bookmarks/edit`
- **Description**: Edit a bookmark
- **Parameters**: JSON with bookmark_id and new_title
- **Response**: JSON confirmation
- **Data Used**: Bookmark to be updated

---

## Term Tag Routes (`/termtag`)

### `GET /termtag/index`
- **Description**: Term tag management index page
- **Parameters**: None
- **Response**: HTML template with term tag management interface
- **Data Exposed**: Available term tags

### `GET /termtag/index/<search>`
- **Description**: Term tag management index page with initial search
- **Parameters**: `search` - Initial search term
- **Response**: HTML template with term tag management interface
- **Data Exposed**: Available term tags

### `POST /termtag/datatables`
- **Description**: DataTables JSON response for term tags
- **Parameters**: DataTables parameters in POST request
- **Response**: JSON with term tag data for DataTables
- **Data Exposed**: Term tags

### `GET /termtag/edit/<int:termtagid>`
- **Description**: Edit term tag page
- **Parameters**: `termtagid` - ID of the term tag to edit
- **Response**: HTML form for editing a term tag
- **Data Exposed**: Term tag details

### `POST /termtag/edit/<int:termtagid>`
- **Description**: Update term tag
- **Parameters**: `termtagid` - ID of the term tag to update
- **Response**: Redirect to term tag index
- **Data Used**: Updated term tag parameters from form

### `GET /termtag/new`
- **Description**: Create new term tag page
- **Parameters**: None
- **Response**: HTML form for creating a new term tag
- **Data Used**: None

### `POST /termtag/new`
- **Description**: Create new term tag
- **Parameters**: None
- **Response**: Redirect to term tag index
- **Data Used**: Term tag parameters from form

### `POST /termtag/delete/<int:termtagid>`
- **Description**: Delete a term tag
- **Parameters**: `termtagid` - ID of the term tag to delete
- **Response**: Redirect to term tag index
- **Data Used**: Term tag to be deleted

---

## Term Import Routes (`/termimport`)

### `GET /termimport/index`
- **Description**: Term import page
- **Parameters**: None
- **Response**: HTML form for importing terms
- **Data Used**: None

### `POST /termimport/index`
- **Description**: Process term import file
- **Parameters**: Form data with file and import options
- **Response**: Flash message and redirect to term index
- **Data Used**: Term import file and options

---

## Anki Export Routes (`/ankiexport`)

### `GET /ankiexport/index`
- **Description**: List Anki export configurations
- **Parameters**: None
- **Response**: HTML template with export configurations
- **Data Exposed**: Export specifications

### `GET /ankiexport/spec/edit/<int:spec_id>`
- **Description**: Edit Anki export specification
- **Parameters**: `spec_id` - ID of the export spec to edit
- **Response**: HTML form for editing export spec
- **Data Exposed**: Export specification details

### `POST /ankiexport/spec/edit/<int:spec_id>`
- **Description**: Update Anki export specification
- **Parameters**: `spec_id` - ID of the export spec to update
- **Response**: Redirect to export index
- **Data Used**: Updated export specification from form

### `GET /ankiexport/spec/new`
- **Description**: Create new Anki export specification
- **Parameters**: None
- **Response**: HTML form for creating new export spec
- **Data Used**: None

### `POST /ankiexport/spec/new`
- **Description**: Create new Anki export specification
- **Parameters**: None
- **Response**: Redirect to export index
- **Data Used**: Export specification from form

### `GET /ankiexport/spec/delete/<int:spec_id>`
- **Description**: Delete Anki export specification
- **Parameters**: `spec_id` - ID of the export spec to delete
- **Response**: Flash message and redirect to export index
- **Data Used**: Export specification to be deleted

### `POST /ankiexport/get_card_post_data`
- **Description**: Get data for Anki Connect post request
- **Parameters**: JSON with term IDs, sentences, and settings
- **Response**: JSON with Anki Connect post data
- **Data Used**: Term IDs, sentence data, and export specifications

### `POST /ankiexport/validate_export_specs`
- **Description**: Validate export specifications
- **Parameters**: JSON with deck names and note types
- **Response**: JSON validation results or error
- **Data Used**: Export specifications

---

## User Image Routes (`/userimages`)

### `GET /userimages/<int:lgid>/<path:f>`
- **Description**: Serve user image files
- **Parameters**: 
  - `lgid` - Language ID
  - `f` - Path to the image file
- **Response**: Image file
- **Data Exposed**: User image files

---

## User Audio Routes (`/useraudio`)

### `GET /useraudio/stream/<int:bookid>`
- **Description**: Stream audio file for a book
- **Parameters**: `bookid` - ID of the book
- **Response**: Audio file stream
- **Data Exposed**: Audio file from the specified book

---

## Bing Routes (`/bing`)

### `GET /bing/search_page/<int:langid>/<string:text>/<string:searchstring>`
- **Description**: Load initial image search page
- **Parameters**: 
  - `langid` - Language ID
  - `text` - Text to search for
  - `searchstring` - Search string pattern
- **Response**: HTML template with search interface
- **Data Exposed**: Search URL for AJAX calls

### `GET /bing/search/<int:langid>/<string:text>/<string:searchstring>`
- **Description**: Perform Bing image search
- **Parameters**: 
  - `langid` - Language ID
  - `text` - Text to search for
  - `searchstring` - Search string pattern
- **Response**: JSON with image search results
- **Data Exposed**: Bing image search results

### `POST /bing/save`
- **Description**: Save image from Bing search
- **Parameters**: Form data with src, text, and langid
- **Response**: JSON with saved image URL and filename
- **Data Used**: Image source URL

### `POST /bing/manual_image_post`
- **Description**: Save manually uploaded image
- **Parameters**: Form data with text, langid, and image file
- **Response**: JSON with saved image URL and filename
- **Data Used**: Uploaded image file

---

## CLI Routes (`/cli`)

### `cli hello`
- **Description**: CLI command to print a greeting
- **Parameters**: None
- **Response**: Greeting message
- **Data Used**: None

### `cli language_export <language> <output_path>`
- **Description**: CLI command to export terms from a language
- **Parameters**: 
  - `language` - Name of the language
  - `output_path` - Output file path
- **Response**: Export file with term frequencies
- **Data Exposed**: Terms in the specified language

### `cli book_term_export <bookid> <output_path>`
- **Description**: CLI command to export terms from a book
- **Parameters**: 
  - `bookid` - ID of the book
  - `output_path` - Output file path
- **Response**: Export file with term frequencies
- **Data Exposed**: Terms in the specified book

### `cli import_books_from_csv [OPTIONS] <file>`
- **Description**: CLI command to import books from CSV
- **Parameters**: 
  - `file` - Path to the CSV file
  - `--commit` - Flag to commit changes
  - `--tags` - Comma-separated tags to apply
  - `--language` - Default language for books
- **Response**: Import results
- **Data Used**: CSV file with book data

---

## Development API Routes (`/dev_api`) [Test DBs only]

### `GET /dev_api/wipe_db`
- **Description**: Wipe the entire database
- **Parameters**: None
- **Response**: Flash message and redirect to main page
- **Data Used**: All database tables (deletion)

### `GET /dev_api/load_demo`
- **Description**: Load demo data after wiping
- **Parameters**: None
- **Response**: Flash message and redirect to main page
- **Data Used**: Demo data

### `GET /dev_api/load_demo_languages`
- **Description**: Load demo languages with dummy dictionaries
- **Parameters**: None
- **Response**: Redirect to main page
- **Data Used**: Demo language definitions

### `GET /dev_api/load_demo_stories`
- **Description**: Load demo stories only
- **Parameters**: None
- **Response**: Flash message and redirect to main page
- **Data Used**: Demo stories

### `GET /dev_api/language_ids`
- **Description**: Get IDs of all languages
- **Parameters**: None
- **Response**: JSON with language names and IDs
- **Data Exposed**: Language IDs

### `GET /dev_api/delete_all_terms`
- **Description**: Delete all terms only
- **Parameters**: None
- **Response**: Flash message and redirect to main page
- **Data Used**: All terms (deletion)

### `GET /dev_api/sqlresult/<string:sql>`
- **Description**: Execute SQL and return results as JSON
- **Parameters**: `sql` - SQL query string
- **Response**: JSON with SQL results
- **Data Exposed**: Results of SQL query

### `GET /dev_api/execsql/<string:sql>`
- **Description**: Execute arbitrary SQL (with no validation)
- **Parameters**: `sql` - SQL command string
- **Response**: JSON confirmation
- **Data Used**: SQL command execution

### `GET /dev_api/dummy_language_dict/<string:langname>/<string:term>`
- **Description**: Fake language dictionary lookup
- **Parameters**: 
  - `langname` - Language name
  - `term` - Term to look up
- **Response**: Dummy dictionary content
- **Data Used**: None (dummy response)

### `GET /dev_api/disable_parser/<string:parsername>/<string:renameto>`
- **Description**: Hack to rename parser in registry
- **Parameters**: 
  - `parsername` - Parser to rename
  - `renameto` - New name for parser
- **Response**: JSON with parser information
- **Data Exposed**: Parser information

### `GET /dev_api/disable_backup`
- **Description**: Disable backup feature
- **Parameters**: None
- **Response**: Flash message and redirect to main page
- **Data Used**: Backup settings

### `GET /dev_api/throw_error/<message>`
- **Description**: Throw an error to test error handling
- **Parameters**: `message` - Error message
- **Response**: RuntimeError with specified message
- **Data Used**: None (just raises error)

### `GET /dev_api/fake_story.html`
- **Description**: Return a fake story for testing
- **Parameters**: None
- **Response**: HTML content of a fake story
- **Data Used**: None

### `GET /dev_api/temp_file_content/<filename>`
- **Description**: Get content of a temporary file
- **Parameters**: `filename` - Name of the temp file
- **Response**: Content of the temporary file
- **Data Exposed**: Temporary file content




# Regex Usage in Lute v3 API Endpoints

## Overview
Lute v3 uses regular expressions in multiple places throughout its codebase, particularly in parsing and text processing functionality. This document identifies all endpoints and components that either currently use regex or would require regex to properly extract information.

## Endpoints that require regex for response parsing

### 1. `/bing/search/<int:langid>/<string:text>/<string:searchstring>`
- **Current regex usage**:
  - `re.findall(r"(<img .*?>)", content, re.I)` - Finds all img tags in Bing search results
  - `re.search(r'src=\"(.*?)\"', normalized_source)` - Extracts src attribute from img tags
  - `re.search(r'src=\"(.*?)\"', normalized_source)` - Used to extract image URLs from HTML

- **Why regex is needed**: The endpoint returns HTML content that needs to be parsed to extract image URLs. The Bing search results contain various HTML elements that need to be processed to extract the relevant information.

### 2. Language-specific parsing functionality
Several endpoints rely on parsing functionality that uses regex, particularly:

- `/read/<int:bookid>/page/<int:pagenum>` - When reading pages, the text is parsed which uses language-specific regex
- `/term/sentences/<int:langid>/<text>` - Sentence extraction uses parsing that may involve regex
- `/read/start_reading/<int:bookid>/<int:pagenum>` - Page content is parsed using language-specific parsing

**Current regex usage in parsing**:
- Language character substitution patterns: `´='|`='|’='|‘='|...=…|..=‥`
- Sentence splitting patterns: `.!?`
- Word character patterns: `a-zA-ZÀ-ÖØ-öø-ȳáéíóúÁÉÍÓÚñÑ` and language-specific ranges

## Components that use regex but aren't direct endpoints

### 3. Language definition parsing
- **File**: `lute/models/language.py`
- **Regex**: Used to convert old PHP regex patterns to Python: 
  - Converting `\\x{XXXX}` to `\\uXXXX` patterns
  - Example: `x{0600}-x{06FF}x{FE70}-x{FEFC}` becomes `u0600-u06FFuFE70-uFEFC`

### 4. Text tokenization
- **File**: `lute/parse/base.py` (base parsing functionality)
- **Usage**: Tokenization of text based on language-specific patterns
- **Regex**: Word character patterns for different languages

### 5. Term processing in database
- **File**: `lute/models/term.py`
- **Regex**: Used when processing text to remove special characters:
  - `zws = "\\u200B"` (zero-width space) - though not exactly regex, it's string processing
  - `nbsp = "\\u00A0"` (non-breaking space)

## Endpoints that could benefit from regex for data extraction

### 6. `/stats/` and `/stats/data`
- While these endpoints return structured data, if you need to extract specific patterns from the statistics, regex could be useful
- The HTML response from `/stats/` might require regex if parsing for specific patterns

### 7. `/term/index` data processing
- When processing the DataTables response, you might need regex to:
  - Extract specific term patterns
  - Process tag lists
  - Parse complex term data for display

### 8. HTML response parsing for any endpoint
Many endpoints return HTML templates. If you need to extract specific data from these HTML responses, you would use regex:
- `/read/<int:bookid>` - extract term data from reading interface
- `/term/form` - extract term details from forms
- `/language/new` - extract available language options

## Examples of regex patterns used in Lute v3

### Character substitution patterns:
- `´='|`='|’='|‘='|...=…|..=‥` (in Language.character_substitutions)

### Sentence splitting patterns:
- Default: `.!?`
- Can be customized per language

### Word character patterns:
- Default: `a-zA-ZÀ-ÖØ-öø-ȳáéíóúÁÉÍÓÚñÑ`
- Language-specific patterns using unicode ranges like `\\u0600-\\u06FF`

### Python conversion from PHP patterns:
```python
def _get_python_regex_pattern(self, s):
    def convert_match(match):
        # Convert backslash-x{XXXX} to backslash-uXXXX
        hex_value = match.group(1)
        return f"\\\\u{hex_value}"

    ret = re.sub(r"\\\\x{([0-9A-Fa-f]+)}", convert_match, s)
    return ret
```

## Conclusion

While many endpoints return structured JSON or HTML, Lute v3 uses regex extensively in its core functionality, particularly in:
1. Text parsing and tokenization
2. HTML content extraction (especially for Bing image search)
3. Language-specific character processing
4. Database data cleanup and processing

If you're consuming Lute's API from an external application, you'll likely need regex to:
- Parse HTML responses to extract specific elements
- Process the raw HTML from Bing search results
- Handle language-specific text processing
- Extract specific patterns from textual data
