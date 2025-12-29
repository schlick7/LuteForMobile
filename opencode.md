## User

review phase 5.2 in [@phaseplan.md](file:///home/cody/LuteForMobile/phaseplan.md) but don't start coding yet

## Assistant

<thinking>
The user wants me to review phase 5.2 in the phaseplan.md file. They've provided an outline showing the structure, and I can see that Phase 5.2 is "Web Dictionary Integration" starting around line 553.

Let me read the phaseplan.md file to review the specific details of Phase 5.2.
</thinking>

**Tool Call: phaseplan.md**
Status: Completed

<file>
00554| 
00555| ### Goal
00556| Add web dictionary functionality to enhance term and sentence translations.
00557| 
00558| ### Features
00559| 
00560| #### Web Dictionary for Terms
00561| - Web dictionary integration (url_launcher) for term forms
00562| - Support for multiple dictionary sources
00563| - Configurable dictionary preferences
00564| 
00565| #### Web Dictionary for Sentences
00566| - Integration with web dictionary for sentence translations
00567| - Support for translation services
00568| - External translation provider options
00569| 
00570| #### Enhanced Translation Features
00571| - Web dictionary links in translation popups
00572| - User-configurable web dictionary settings
00573| - Dictionary source management
00574| 
00575| ### Technical Implementation
00576| - Web dictionary integration (url_launcher)
00577| - Dictionary service abstraction layer
00578| - Configuration management for dictionary sources
00579| - Enhanced translation components with web support
00580| 
00581| ### Deliverables
00582| - [ ] Web dictionary integration for terms
00583| - [ ] Web dictionary integration for sentences
00584| - [ ] Dictionary configuration settings
00585| - [ ] Enhanced translation components with web support
00586| 
00587| ---
00588| 

(File has more lines. Use 'offset' parameter to read beyond line 588)
</file>

## Assistant

<thinking>
Let me read more context to understand what comes before and after Phase 5.2 to give a complete review.
</thinking>

**Tool Call: phaseplan.md**
Status: Completed

<file>
00511| ## Phase 5.1: Enhanced Reader Features (Core)
00512| 
00513| ### Goal
00514| Expand reader functionality to include core reading features from PRD, excluding web dictionary integration.
00515| 
00516| ### Features
00517| 
00518| #### Term Form
00519| - Display term details from server
00520| - Triggered by double-tap
00521| - Modal/sheet display
00522| 
00523| #### Translation Popup
00524| - Server-provided translations
00525| - Tap gesture to open
00526|   - ontap - gettermpopup
00527| - Inline/non-intrusive display
00528| 
00529| #### Text Rendering Improvements
00530| - RichText with TextSpan for interactive terms
00531| - Interactive word/tap detection
00532| - Better text selection handling
00533| - Improved readability (fonts, spacing)
00534| 
00535| #### Sentence Translation
00536| - Placeholder for AI translation
00537| - User-configurable translation source (in settings)
00538| 
00539| ### Technical Implementation
00540| - Enhanced reader widgets
00541| - Term form component
00542| - Translation popup component
00543| - API endpoints for term/translation data
00544| 
00545| ### Deliverables
00546| - [x] Term form display
00547| - [x] Translation popup display
00548| - [x] Interactive text with term highlighting
00549| - [x] Sentence-level translations
00550| 
00551| ---
00552| 
00553| ## Phase 5.2: Web Dictionary Integration
00554| 
00555| ### Goal

(File has more lines. Use 'offset' parameter to read beyond line 555)
</file>

## Assistant

<thinking>
Now I have a good view of Phase 5.2. Let me also check what Phase 6 looks like to understand the flow:
</thinking>

**Tool Call: phaseplan.md**
Status: Completed

<file>
00590| 
00591| ### Goal
00592| Add text-to-speech functionality to the reader.
00593| 
00594| ### Features
00595| 
00596| #### TTS Player
00597| - Play/pause/stop controls
00598| - Sentence-level playback
00599| - Playback highlighting
00600| - Speed controls
00601| 
00602| #### TTS Provider
00603| - Native TTS implementation (flutter_tts)
00604| - Voice selection
00605| - Basic TTS settings (speed, pitch)
00606| 
00607| ### Technical Implementation
00608| - Integrate flutter_tts package
00609| - Create TTS service/manager
00610| - Add TTS controls to reader UI
00611| - Store TTS settings
00612| 
00613| ### Deliverables
00614| - [ ] TTS playback working
00615| - [ ] Play/pause/stop controls
00616| - [ ] Playback highlighting
00617| - [ ] Basic TTS settings
00618| 
00619| ---

(File has more lines. Use 'offset' parameter to read beyond line 619)
</file>

## Assistant

<thinking>
Now let me check if there's any documentation about the API that might be relevant to web dictionaries. Let me also check the luteendpoints.md to understand if there are any existing endpoints related to dictionaries.
</thinking>

**Tool Call: luteendpoints.md**
Status: Completed

<file>
00001| # Lute v3 API Endpoints Documentation
00002| 
00003| This document provides a comprehensive list of all API endpoints available in Lute v3, including their methods, parameters, and functionality.
00004| 
00005| ## Main Application Routes (`/`)
00006| 
00007| ### `GET /`
00008| - **Description**: Main index page showing available books and languages
00009| - **Parameters**:
00010|   - None
00011| - **Response**: HTML template with book and language listings
00012| - **Data Exposed**: Books, languages, backup settings, tutorial information
00013| 
00014| ### `GET /refresh_all_stats`
00015| - **Description**: Marks all book stats as stale to trigger recalculation
00016| - **Parameters**: None
00017| - **Response**: Redirect to main page
00018| - **Data Used**: All books (non-archived)
00019| 
00020| ### `GET /wipe_database`
00021| - **Description**: Deletes all data if in demo mode
00022| - **Parameters**: None
00023| - **Response**: Flash message and redirect to main page
00024| - **Data Affected**: All tables (when demo flag is set)
00025| 
00026| ### `GET /remove_demo_flag`
00027| - **Description**: Removes the demo flag to deactivate demo mode
00028| - **Parameters**: None
00029| - **Response**: Flash message and redirect to main page
00030| - **Data Affected**: Demo flag in database
00031| 
00032| ### `GET /version`
00033| - **Description**: Shows application version information
00034| - **Parameters**: None
00035| - **Response**: HTML template with version, data path, and database info
00036| - **Data Exposed**: App version, data path, database filename, Docker status
00037| 
00038| ### `GET /info`
00039| - **Description**: JSON endpoint for version and data information
00040| - **Parameters**: None
00041| - **Response**: JSON object with version, data path, and database info
00042| - **Data Exposed**: App version, data path, database
00043| 
00044| ### `GET /static/js/never_cache/<path:filename>`
00045| - **Description**: Serves JavaScript files with no caching headers
00046| - **Parameters**: `filename` - path to the JS file
00047| - **Response**: JS file with no-cache headers
00048| - **Data Used**: JavaScript files in static/js directory
00049| 
00050| ---
00051| 
00052| ## Book Routes (`/book`)
00053| 
00054| ### `GET /book/datatables/active`
00055| - **Description**: DataTables JSON response for active books
00056| - **Parameters**: DataTables parameters in POST request
00057| - **Response**: JSON with book data for DataTables
00058| - **Data Exposed**: All active books with metadata
00059| 
00060| ### `GET /book/archived`
00061| - **Description**: Archived books listing page
00062| - **Parameters**: None
00063| - **Response**: HTML template with archived book listing
00064| - **Data Exposed**: Language choices, current language ID
00065| 
00066| ### `POST /book/datatables/Archived`
00067| - **Description**: DataTables JSON response for archived books
00068| - **Parameters**: DataTables parameters in POST request
00069| - **Response**: JSON with archived book data for DataTables
00070| - **Data Exposed**: All archived books with metadata
00071| 
00072| ### `GET /book/new`
00073| - **Description**: Create new book page
00074| - **Parameters**: 
00075|   - `importurl` (optional) - URL to import from
00076| - **Response**: HTML form for creating a new book
00077| - **Data Exposed**: Available languages, book tags
00078| 
00079| ### `POST /book/new`
00080| - **Description**: Create new book
00081| - **Parameters**: Book data from form submission
00082| - **Response**: Redirect to reading page
00083| - **Data Used**: Book parameters (title, text, language, etc.)
00084| 
00085| ### `GET /book/edit/<int:bookid>`
00086| - **Description**: Edit book page
00087| - **Parameters**: `bookid` - ID of the book to edit
00088| - **Response**: HTML form for editing a book
00089| - **Data Exposed**: Book details, available languages, book tags
00090| 
00091| ### `POST /book/edit/<int:bookid>`
00092| - **Description**: Update book
00093| - **Parameters**: `bookid` - ID of the book to update
00094| - **Response**: Flash message and redirect to main page
00095| - **Data Used**: Updated book parameters from form
00096| 
00097| ### `GET /book/import_webpage`
00098| - **Description**: Page for importing a webpage
00099| - **Parameters**: None
00100| - **Response**: HTML template for webpage import
00101| - **Data Used**: None
00102| 
00103| ### `POST /book/archive/<int:bookid>`
00104| - **Description**: Archive a book
00105| - **Parameters**: `bookid` - ID of the book to archive
00106| - **Response**: Redirect to main page
00107| - **Data Used**: Book to be archived
00108| 
00109| ### `POST /book/unarchive/<int:bookid>`
00110| - **Description**: Unarchive a book
00111| - **Parameters**: `bookid` - ID of the book to unarchive
00112| - **Response**: Redirect to main page
00113| - **Data Used**: Book to be unarchived
00114| 
00115| ### `POST /book/delete/<int:bookid>`
00116| - **Description**: Delete a book
00117| - **Parameters**: `bookid` - ID of the book to delete
00118| - **Response**: Redirect to main page
00119| - **Data Used**: Book to be deleted
00120| 
00121| ### `GET /book/table_stats/<int:bookid>`
00122| - **Description**: Get statistics for a book via JSON
00123| - **Parameters**: `bookid` - ID of the book
00124| - **Response**: JSON with book statistics
00125| - **Data Exposed**: Book statistics (distinct terms, unknowns, percent, status distribution)
00126| 
00127| ---
00128| 
00129| ## Language Routes (`/language`)
00130| 
00131| ### `GET /language/index`
00132| - **Description**: List all languages with book and term counts
00133| - **Parameters**: None
00134| - **Response**: HTML template with language data
00135| - **Data Exposed**: Languages with associated book and term counts
00136| 
00137| ### `GET /language/edit/<int:langid>`
00138| - **Description**: Edit language page
00139| - **Parameters**: `langid` - ID of the language to edit
00140| - **Response**: HTML form for editing a language
00141| - **Data Exposed**: Language details, available parsers
00142| 
00143| ### `POST /language/edit/<int:langid>`
00144| - **Description**: Update language
00145| - **Parameters**: `langid` - ID of the language to update
00146| - **Response**: Flash message and redirect to main page
00147| - **Data Used**: Updated language parameters from form
00148| 
00149| ### `GET /language/new`
00150| - **Description**: Create new language page
00151| - **Parameters**: None
00152| - **Response**: HTML form for creating a new language
00153| - **Data Exposed**: Available predefined languages, available parsers
00154| 
00155| ### `POST /language/new`
00156| - **Description**: Create new language
00157| - **Parameters**: None
00158| - **Response**: Flash message and redirect to main page
00159| - **Data Used**: Language parameters from form
00160| 
00161| ### `GET /language/new/<string:langname>`
00162| - **Description**: Create new language from predefined template
00163| - **Parameters**: `langname` - Name of the predefined language
00164| - **Response**: HTML form with predefined language settings
00165| - **Data Exposed**: Predefined language template
00166| 
00167| ### `POST /language/new/<string:langname>`
00168| - **Description**: Create new language from predefined template
00169| - **Parameters**: `langname` - Name of the predefined language
00170| - **Response**: Flash message and redirect to main page
00171| - **Data Used**: Predefined language settings and form data
00172| 
00173| ### `POST /language/delete/<int:langid>`
00174| - **Description**: Delete a language
00175| - **Parameters**: `langid` - ID of the language to delete
00176| - **Response**: Redirect to language index
00177| - **Data Used**: Language to be deleted
00178| 
00179| ### `GET /language/list_predefined`
00180| - **Description**: List predefined languages not already in database
00181| - **Parameters**: None
00182| - **Response**: HTML template with predefined languages
00183| - **Data Exposed**: Predefined languages not currently in the system
00184| 
00185| ### `GET /language/load_predefined/<langname>`
00186| - **Description**: Load a predefined language with sample stories
00187| - **Parameters**: `langname` - Name of the predefined language to load
00188| - **Response**: Flash message and redirect to main page
00189| - **Data Used**: Predefined language definition
00190| 
00191| ---
00192| 
00193| ## Term Routes (`/term`)
00194| 
00195| ### `GET /term/index`
00196| - **Description**: Term management index page
00197| - **Parameters**: None
00198| - **Response**: HTML template with term management interface
00199| - **Data Exposed**: Available languages, statuses, term tags
00200| 
00201| ### `GET /term/index/<search>`
00202| - **Description**: Term management index page with initial search
00203| - **Parameters**: `search` - Initial search term
00204| - **Response**: HTML template with term management interface
00205| - **Data Exposed**: Available languages, statuses, term tags
00206| 
00207| ### `POST /term/datatables`
00208| - **Description**: DataTables JSON response for terms
00209| - **Parameters**: DataTables parameters in POST request, filter parameters
00210| - **Response**: JSON with term data for DataTables
00211| - **Data Exposed**: Terms with filtering options
00212| 
00213| ### `POST /term/bulk_edit_from_index`
00214| - **Description**: Bulk edit terms from index page
00215| - **Parameters**: Various parameters from bulk edit form
00216| - **Response**: Redirect to term index
00217| - **Data Used**: Term IDs and update parameters
00218| 
00219| ### `POST /term/bulk_edit_from_reading_pane`
00220| - **Description**: Bulk edit terms from reading pane
00221| - **Parameters**: Various parameters from bulk edit form
00222| - **Response**: HTML template for updated term
00223| - **Data Used**: Term IDs and update parameters
00224| 
00225| ### `POST /term/ajax_edit_from_index`
00226| - **Description**: Ajax term update from index page
00227| - **Parameters**: JSON with term_id, update_type, and values
00228| - **Response**: JSON with updated status or error
00229| - **Data Used**: Term ID and update parameters
00230| 
00231| ### `POST /term/export_terms`
00232| - **Description**: Export terms to CSV file
00233| - **Parameters**: DataTables parameters in POST request, filter parameters
00234| - **Response**: CSV file attachment
00235| - **Data Exposed**: Term data in CSV format
00236| 
00237| ### `GET /term/edit/<int:termid>`
00238| - **Description**: Edit term page
00239| - **Parameters**: `termid` - ID of the term to edit
00240| - **Response**: HTML form for editing a term
00241| - **Data Exposed**: Term details and available languages
00242| 
00243| ### `POST /term/edit/<int:termid>`
00244| - **Description**: Update term
00245| - **Parameters**: `termid` - ID of the term to update
00246| - **Response**: Redirect to term index
00247| - **Data Used**: Updated term parameters from form
00248| 
00249| ### `GET /term/editbytext/<int:langid>/<text>`
00250| - **Description**: Edit term by language and text
00251| - **Parameters**: 
00252|   - `langid` - Language ID
00253|   - `text` - Text content of the term
00254| - **Response**: HTML form for editing/creating a term
00255| - **Data Exposed**: Term details and language dictionaries
00256| 
00257| ### `POST /term/editbytext/<int:langid>/<text>`
00258| - **Description**: Create or update term by language and text
00259| - **Parameters**: 
00260|   - `langid` - Language ID 
00261|   - `text` - Text content of the term
00262| - **Response**: Redirect to term index
00263| - **Data Used**: Form data for term creation/update
00264| 
00265| ### `GET /term/new`
00266| - **Description**: Create new term page
00267| - **Parameters**: None
00268| - **Response**: HTML form for creating a new term
00269| - **Data Exposed**: Available languages and dictionaries
00270| 
00271| ### `POST /term/new`
00272| - **Description**: Create new term
00273| - **Parameters**: None
00274| - **Response**: Redirect to term new page
00275| - **Data Used**: Term parameters from form
00276| 
00277| ### `GET /term/search/<text>/<int:langid>`
00278| - **Description**: Search for terms by text in a specific language
00279| - **Parameters**: 
00280|   - `text` - Text to search for
00281|   - `langid` - Language ID to search in
00282| - **Response**: JSON with matching terms
00283| - **Data Exposed**: Terms matching the text in the specified language
00284| 
00285| ### `GET /term/sentences/<int:langid>/<text>`
00286| - **Description**: Get sentences for a term
00287| - **Parameters**: 
00288|   - `langid` - Language ID
00289|   - `text` - Term text
00290| - **Response**: HTML template with sentence references
00291| - **Data Exposed**: Sentences containing the term and its parents/children
00292| 
00293| ### `POST /term/bulk_update_status`
00294| - **Description**: Bulk update term statuses
00295| - **Parameters**: JSON with update information
00296| - **Response**: JSON confirmation
00297| - **Data Used**: Term IDs and new status values
00298| 
00299| ### `POST /term/bulk_delete`
00300| - **Description**: Bulk delete terms
00301| - **Parameters**: JSON with word IDs to delete
00302| - **Response**: JSON confirmation
00303| - **Data Used**: Term IDs for deletion
00304| 
00305| ### `POST /term/delete/<int:termid>`
00306| - **Description**: Delete a term
00307| - **Parameters**: `termid` - ID of the term to delete
00308| - **Response**: Redirect to term index
00309| - **Data Used**: Term to be deleted
00310| 
00311| ---
00312| 
00313| ## Reading Routes (`/read`)
00314| 
00315| ### `GET /read/<int:bookid>`
00316| - **Description**: Read a book starting at current page
00317| - **Parameters**: `bookid` - ID of the book to read
00318| - **Response**: HTML template for reading interface
00319| - **Data Exposed**: Book content, language settings, dictionaries
00320| 
00321| ### `GET /read/<int:bookid>/page/<int:pagenum>`
00322| - **Description**: Read a specific page of a book - This is where text is called by ajax
00323| - **Parameters**:
00324|   - `bookid` - ID of the book
00325|   - `pagenum` - Page number to read
00326| - **Response**: HTML template for reading interface
00327| - **Data Exposed**: Book page content, language settings, dictionaries
00328| 
00329| ### `GET /read/<int:bookid>/peek/<int:pagenum>`
00330| - **Description**: Peek at a page without tracking as read
00331| - **Parameters**:
00332|   - `bookid` - ID of the book
00333|   - `pagenum` - Page number to peek at
00334| - **Response**: HTML template for reading interface
00335| - **Data Exposed**: Book page content, language settings
00336| 
00337| ### `GET /read/start_reading/<int:bookid>/<int:pagenum>`
00338| - **Description**: Start reading a page (set start date and render content)
00339| - **Parameters**:
00340|   - `bookid` - ID of the book
00341|   - `pagenum` - Page number to start reading
00342| - **Response**: HTML template with parsed page content
00343| - **Data Used**: Page start date tracking
00344| - **Usage**: Used for page navigation (next/previous) to track reading
00345| 
00346| ### `GET /read/refresh_page/<int:bookid>/<int:pagenum>`
00347| - **Description**: Refresh page content without changing start date
00348| - **Parameters**:
00349|   - `bookid` - ID of the book
00350|   - `pagenum` - Page number to refresh
00351| - **Response**: HTML template with parsed page content
00352| - **Data Exposed**: Page content without updating start date
00353| - **Usage**: Used for page navigation when not tracking (e.g., peeking)
00354| 
00355| ### `POST /read/page_done`
00356| - **Description**: Mark page as read
00357| - **Parameters**: JSON with bookid, pagenum, and restknown
00358| - **Response**: JSON confirmation
00359| - **Data Used**: Book page completion data
00360| - **restknown**:
00361|   - If `false`: Mark page as read only (call `markPageRead`)
00362|   - If `true`: Mark page as read AND set all unknown words (status 0) on the page to Well-Known (status 99) (call `markPageKnown`)
00363| 
00364| ### `GET /read/delete_page/<int:bookid>/<int:pagenum>`
00365| - **Description**: Delete a page from a book
00366| - **Parameters**: 
00367|   - `bookid` - ID of the book
00368|   - `pagenum` - Page number to delete
00369| - **Response**: Redirect to the same page (after deletion)
00370| - **Data Used**: Book and page
00371| 
00372| ### `GET /read/new_page/<int:bookid>/<position>/<int:pagenum>`
00373| - **Description**: Create a new page in a book
00374| - **Parameters**: 
00375|   - `bookid` - ID of the book
00376|   - `position` - Position to insert page ("before" or "after")
00377|   - `pagenum` - Reference page number
00378| - **Response**: HTML form for creating page or redirect after creation
00379| 
00380| ### `POST /read/new_page/<int:bookid>/<position>/<int:pagenum>`
00381| - **Description**: Create a new page in a book
00382| - **Parameters**: 
00383|   - `bookid` - ID of the book
00384|   - `position` - Position to insert page ("before" or "after")
00385|   - `pagenum` - Reference page number
00386| - **Response**: Redirect to reading page after creation
00387| - **Data Used**: New page text from form
00388| 
00389| ### `POST /read/save_player_data`
00390| - **Description**: Save audio player position and bookmarks
00391| - **Parameters**: JSON with bookid, position, and bookmarks
00392| - **Response**: JSON confirmation
00393| - **Data Used**: Audio playback data
00394| 
00395| ### `GET /read/start_reading/<int:bookid>/<int:pagenum>`
00396| - **Description**: Start reading a page (set start date and render content)
00397| - **Parameters**: 
00398|   - `bookid` - ID of the book
00399|   - `pagenum` - Page number to start reading
00400| - **Response**: HTML template with parsed page content
00401| - **Data Used**: Page start date tracking
00402| 
00403| ### `GET /read/refresh_page/<int:bookid>/<int:pagenum>`
00404| - **Description**: Refresh page content without changing start date
00405| - **Parameters**: 
00406|   - `bookid` - ID of the book
00407|   - `pagenum` - Page number to refresh
00408| - **Response**: HTML template with parsed page content
00409| - **Data Exposed**: Page content without updating start date
00410| 
00411| ### `GET /read/empty`
00412| - **Description**: Return an empty page
00413| - **Parameters**: None
00414| - **Response**: Empty string
00415| - **Data Used**: None
00416| 
00417| ### `GET /read/termform/<int:langid>/<text>`
00418| - **Description**: Create term form for reading interface
00419| - **Parameters**: 
00420|   - `langid` - Language ID
00421|   - `text` - Term text (may contain "LUTESLASH" to represent "/")
00422| - **Response**: HTML term form
00423| - **Data Exposed**: Term details, language dictionaries
00424| 
00425| ### `POST /read/termform/<int:langid>/<text>`
00426| - **Description**: Submit term form for reading interface
00427| - **Parameters**: 
00428|   - `langid` - Language ID
00429|   - `text` - Term text (may contain "LUTESLASH" to represent "/")
00430| - **Response**: HTML template with updated term
00431| - **Data Used**: Term form data
00432| 
00433| ### `GET /read/edit_term/<int:term_id>`
00434| - **Description**: Edit term form in reading interface
00435| - **Parameters**: `term_id` - ID of the term to edit
00436| - **Response**: HTML term form
00437| - **Data Exposed**: Term details, language dictionaries
00438| 
00439| ### `POST /read/edit_term/<int:term_id>`
00440| - **Description**: Submit term edit in reading interface
00441| - **Parameters**: `term_id` - ID of the term to edit
00442| - **Response**: HTML template with updated term
00443| - **Data Used**: Term form data
00444| 
00445| ### `GET /read/term_bulk_edit_form`
00446| - **Description**: Show bulk term edit form in reading interface
00447| - **Parameters**: None
00448| - **Response**: HTML bulk edit form
00449| - **Data Exposed**: Available term tags
00450| 
00451| ### `GET /read/termpopup/<int:termid>`
00452| - **Description**: Get term popup HTML for a specific term
00453| - **Parameters**: `termid` - ID of the term
00454| - **Response**: HTML template with term information
00455| - **Data Exposed**: Term details, parent/children, sentences
00456| 
00457| ### `GET /read/flashcopied`
00458| - **Description**: Show flash notification for copied text
00459| - **Parameters**: None
00460| - **Response**: HTML template for flash notification
00461| 
00462| ### `GET /read/editpage/<int:bookid>/<int:pagenum>`
00463| - **Description**: Edit text of a page
00464| - **Parameters**: 
00465|   - `bookid` - ID of the book
00466|   - `pagenum` - Page number to edit
00467| - **Response**: HTML form for editing page text
00468| - **Data Exposed**: Page content
00469| 
00470| ### `POST /read/editpage/<int:bookid>/<int:pagenum>`
00471| - **Description**: Update text of a page
00472| - **Parameters**: 
00473|   - `bookid` - ID of the book
00474|   - `pagenum` - Page number to update
00475| - **Response**: Redirect to reading page
00476| - **Data Used**: Updated page text from form
00477| 
00478| ---
00479| 
00480| ## Settings Routes (`/settings`)
00481| 
00482| ### `GET /settings/index`
00483| - **Description**: Edit user settings page
00484| - **Parameters**: None
00485| - **Response**: HTML form for user settings
00486| - **Data Exposed**: Current user settings
00487| 
00488| ### `POST /settings/index`
00489| - **Description**: Update user settings
00490| - **Parameters**: None
00491| - **Response**: Flash message and redirect to main page
00492| - **Data Used**: Settings form data
00493| 
00494| ### `GET /settings/test_mecab`
00495| - **Description**: Test MeCab parser with provided path
00496| - **Parameters**: `mecab_path` - Path to MeCab executable
00497| - **Response**: JSON result of test
00498| - **Data Used**: MeCab path for testing
00499| 
00500| ### `POST /settings/set/<key>/<value>`
00501| - **Description**: Set a specific user setting key to value
00502| - **Parameters**: 
00503|   - `key` - Setting key
00504|   - `value` - Setting value
00505| - **Response**: JSON confirmation
00506| - **Data Used**: Setting key-value pair
00507| 
00508| ### `GET /settings/shortcuts`
00509| - **Description**: Edit keyboard shortcuts
00510| - **Parameters**: None
00511| - **Response**: HTML form for editing shortcuts
00512| - **Data Exposed**: Current shortcut settings
00513| 
00514| ### `POST /settings/shortcuts`
00515| - **Description**: Update keyboard shortcuts
00516| - **Parameters**: None
00517| - **Response**: Flash message and redirect to main page
00518| - **Data Used**: Shortcut form data
00519| 
00520| ---
00521| 
00522| ## Backup Routes (`/backup`)
00523| 
00524| ### `GET /backup/index`
00525| - **Description**: List available backups
00526| - **Parameters**: None
00527| - **Response**: HTML template with backup listing
00528| - **Data Exposed**: Available backup files
00529| 
00530| ### `GET /backup/download/<filename>`
00531| - **Description**: Download a backup file
00532| - **Parameters**: `filename` - Name of the backup file
00533| - **Response**: File download
00534| - **Data Exposed**: Backup file
00535| 
00536| ### `GET /backup/backup`
00537| - **Description**: Backup creation page
00538| - **Parameters**: `type` (optional) - Type of backup ("manual")
00539| - **Response**: HTML template for backup creation
00540| - **Data Exposed**: Backup folder path
00541| 
00542| ### `POST /backup/do_backup`
00543| - **Description**: Create backup
00544| - **Parameters**: Form data with backup type
00545| - **Response**: JSON with backup filename or error
00546| - **Data Used**: Backup settings and database
00547| 
00548| ### `GET /backup/skip_this_backup`
00549| - **Description**: Skip current backup and update settings
00550| - **Parameters**: None
00551| - **Response**: Redirect to main page
00552| - **Data Used**: Backup settings
00553| 
00554| ---
00555| 
00556| ## Theme Routes (`/theme`)
00557| 
00558| ### `GET /theme/current`
00559| - **Description**: Get current theme CSS
00560| - **Parameters**: None
00561| - **Response**: CSS content for current theme
00562| - **Data Exposed**: Current theme CSS
00563| 
00564| ### `GET /theme/custom_styles`
00565| - **Description**: Get custom user styles
00566| - **Parameters**: None
00567| - **Response**: CSS content for custom styles
00568| - **Data Exposed**: Custom styles from user settings
00569| 
00570| ### `POST /theme/next`
00571| - **Description**: Cycle to next theme
00572| - **Parameters**: None
00573| - **Response**: JSON confirmation
00574| - **Data Used**: Theme settings
00575| 
00576| ### `POST /theme/toggle_highlight`
00577| - **Description**: Toggle text highlighting
00578| - **Parameters**: None
00579| - **Response**: JSON confirmation
00580| - **Data Used**: Highlight setting
00581| 
00582| ---
00583| 
00584| ## Stats Routes (`/stats`)
00585| 
00586| ### `GET /stats/`
00587| - **Description**: Statistics main page
00588| - **Parameters**: None
00589| - **Response**: HTML template with statistics
00590| - **Data Exposed**: Reading statistics table data
00591| 
00592| ### `GET /stats/data`
00593| - **Description**: Statistics chart data
00594| - **Parameters**: None
00595| - **Response**: JSON with chart data
00596| - **Data Exposed**: Reading statistics chart data
00597| 
00598| ---
00599| 
00600| ## Bookmark Routes (`/bookmarks`)
00601| 
00602| ### `POST /bookmarks/<int:bookid>/datatables`
00603| - **Description**: DataTables JSON response for bookmarks
00604| - **Parameters**: 
00605|   - `bookid` - ID of the book
00606|   - DataTables parameters in POST request
00607| - **Response**: JSON with bookmark data for DataTables
00608| - **Data Exposed**: Bookmarks for the specified book
00609| 
00610| ### `GET /bookmarks/<int:bookid>`
00611| - **Description**: List all bookmarks for a book
00612| - **Parameters**: `bookid` - ID of the book
00613| - **Response**: HTML template with bookmark listing
00614| - **Data Exposed**: Bookmarks for the specified book
00615| 
00616| ### `POST /bookmarks/add`
00617| - **Description**: Add a new bookmark
00618| - **Parameters**: JSON with book_id, page_num, and title
00619| - **Response**: JSON confirmation
00620| - **Data Used**: Bookmark information
00621| 
00622| ### `POST /bookmarks/delete`
00623| - **Description**: Delete a bookmark
00624| - **Parameters**: JSON with bookmark_id
00625| - **Response**: JSON confirmation
00626| - **Data Used**: Bookmark to be deleted
00627| 
00628| ### `POST /bookmarks/edit`
00629| - **Description**: Edit a bookmark
00630| - **Parameters**: JSON with bookmark_id and new_title
00631| - **Response**: JSON confirmation
00632| - **Data Used**: Bookmark to be updated
00633| 
00634| ---
00635| 
00636| ## Term Tag Routes (`/termtag`)
00637| 
00638| ### `GET /termtag/index`
00639| - **Description**: Term tag management index page
00640| - **Parameters**: None
00641| - **Response**: HTML template with term tag management interface
00642| - **Data Exposed**: Available term tags
00643| 
00644| ### `GET /termtag/index/<search>`
00645| - **Description**: Term tag management index page with initial search
00646| - **Parameters**: `search` - Initial search term
00647| - **Response**: HTML template with term tag management interface
00648| - **Data Exposed**: Available term tags
00649| 
00650| ### `POST /termtag/datatables`
00651| - **Description**: DataTables JSON response for term tags
00652| - **Parameters**: DataTables parameters in POST request
00653| - **Response**: JSON with term tag data for DataTables
00654| - **Data Exposed**: Term tags
00655| 
00656| ### `GET /termtag/edit/<int:termtagid>`
00657| - **Description**: Edit term tag page
00658| - **Parameters**: `termtagid` - ID of the term tag to edit
00659| - **Response**: HTML form for editing a term tag
00660| - **Data Exposed**: Term tag details
00661| 
00662| ### `POST /termtag/edit/<int:termtagid>`
00663| - **Description**: Update term tag
00664| - **Parameters**: `termtagid` - ID of the term tag to update
00665| - **Response**: Redirect to term tag index
00666| - **Data Used**: Updated term tag parameters from form
00667| 
00668| ### `GET /termtag/new`
00669| - **Description**: Create new term tag page
00670| - **Parameters**: None
00671| - **Response**: HTML form for creating a new term tag
00672| - **Data Used**: None
00673| 
00674| ### `POST /termtag/new`
00675| - **Description**: Create new term tag
00676| - **Parameters**: None
00677| - **Response**: Redirect to term tag index
00678| - **Data Used**: Term tag parameters from form
00679| 
00680| ### `POST /termtag/delete/<int:termtagid>`
00681| - **Description**: Delete a term tag
00682| - **Parameters**: `termtagid` - ID of the term tag to delete
00683| - **Response**: Redirect to term tag index
00684| - **Data Used**: Term tag to be deleted
00685| 
00686| ---
00687| 
00688| ## Term Import Routes (`/termimport`)
00689| 
00690| ### `GET /termimport/index`
00691| - **Description**: Term import page
00692| - **Parameters**: None
00693| - **Response**: HTML form for importing terms
00694| - **Data Used**: None
00695| 
00696| ### `POST /termimport/index`
00697| - **Description**: Process term import file
00698| - **Parameters**: Form data with file and import options
00699| - **Response**: Flash message and redirect to term index
00700| - **Data Used**: Term import file and options
00701| 
00702| ---
00703| 
00704| ## Anki Export Routes (`/ankiexport`)
00705| 
00706| ### `GET /ankiexport/index`
00707| - **Description**: List Anki export configurations
00708| - **Parameters**: None
00709| - **Response**: HTML template with export configurations
00710| - **Data Exposed**: Export specifications
00711| 
00712| ### `GET /ankiexport/spec/edit/<int:spec_id>`
00713| - **Description**: Edit Anki export specification
00714| - **Parameters**: `spec_id` - ID of the export spec to edit
00715| - **Response**: HTML form for editing export spec
00716| - **Data Exposed**: Export specification details
00717| 
00718| ### `POST /ankiexport/spec/edit/<int:spec_id>`
00719| - **Description**: Update Anki export specification
00720| - **Parameters**: `spec_id` - ID of the export spec to update
00721| - **Response**: Redirect to export index
00722| - **Data Used**: Updated export specification from form
00723| 
00724| ### `GET /ankiexport/spec/new`
00725| - **Description**: Create new Anki export specification
00726| - **Parameters**: None
00727| - **Response**: HTML form for creating new export spec
00728| - **Data Used**: None
00729| 
00730| ### `POST /ankiexport/spec/new`
00731| - **Description**: Create new Anki export specification
00732| - **Parameters**: None
00733| - **Response**: Redirect to export index
00734| - **Data Used**: Export specification from form
00735| 
00736| ### `GET /ankiexport/spec/delete/<int:spec_id>`
00737| - **Description**: Delete Anki export specification
00738| - **Parameters**: `spec_id` - ID of the export spec to delete
00739| - **Response**: Flash message and redirect to export index
00740| - **Data Used**: Export specification to be deleted
00741| 
00742| ### `POST /ankiexport/get_card_post_data`
00743| - **Description**: Get data for Anki Connect post request
00744| - **Parameters**: JSON with term IDs, sentences, and settings
00745| - **Response**: JSON with Anki Connect post data
00746| - **Data Used**: Term IDs, sentence data, and export specifications
00747| 
00748| ### `POST /ankiexport/validate_export_specs`
00749| - **Description**: Validate export specifications
00750| - **Parameters**: JSON with deck names and note types
00751| - **Response**: JSON validation results or error
00752| - **Data Used**: Export specifications
00753| 
00754| ---
00755| 
00756| ## User Image Routes (`/userimages`)
00757| 
00758| ### `GET /userimages/<int:lgid>/<path:f>`
00759| - **Description**: Serve user image files
00760| - **Parameters**: 
00761|   - `lgid` - Language ID
00762|   - `f` - Path to the image file
00763| - **Response**: Image file
00764| - **Data Exposed**: User image files
00765| 
00766| ---
00767| 
00768| ## User Audio Routes (`/useraudio`)
00769| 
00770| ### `GET /useraudio/stream/<int:bookid>`
00771| - **Description**: Stream audio file for a book
00772| - **Parameters**: `bookid` - ID of the book
00773| - **Response**: Audio file stream
00774| - **Data Exposed**: Audio file from the specified book
00775| 
00776| ---
00777| 
00778| ## Bing Routes (`/bing`)
00779| 
00780| ### `GET /bing/search_page/<int:langid>/<string:text>/<string:searchstring>`
00781| - **Description**: Load initial image search page
00782| - **Parameters**: 
00783|   - `langid` - Language ID
00784|   - `text` - Text to search for
00785|   - `searchstring` - Search string pattern
00786| - **Response**: HTML template with search interface
00787| - **Data Exposed**: Search URL for AJAX calls
00788| 
00789| ### `GET /bing/search/<int:langid>/<string:text>/<string:searchstring>`
00790| - **Description**: Perform Bing image search
00791| - **Parameters**: 
00792|   - `langid` - Language ID
00793|   - `text` - Text to search for
00794|   - `searchstring` - Search string pattern
00795| - **Response**: JSON with image search results
00796| - **Data Exposed**: Bing image search results
00797| 
00798| ### `POST /bing/save`
00799| - **Description**: Save image from Bing search
00800| - **Parameters**: Form data with src, text, and langid
00801| - **Response**: JSON with saved image URL and filename
00802| - **Data Used**: Image source URL
00803| 
00804| ### `POST /bing/manual_image_post`
00805| - **Description**: Save manually uploaded image
00806| - **Parameters**: Form data with text, langid, and image file
00807| - **Response**: JSON with saved image URL and filename
00808| - **Data Used**: Uploaded image file
00809| 
00810| ---
00811| 
00812| ## CLI Routes (`/cli`)
00813| 
00814| ### `cli hello`
00815| - **Description**: CLI command to print a greeting
00816| - **Parameters**: None
00817| - **Response**: Greeting message
00818| - **Data Used**: None
00819| 
00820| ### `cli language_export <language> <output_path>`
00821| - **Description**: CLI command to export terms from a language
00822| - **Parameters**: 
00823|   - `language` - Name of the language
00824|   - `output_path` - Output file path
00825| - **Response**: Export file with term frequencies
00826| - **Data Exposed**: Terms in the specified language
00827| 
00828| ### `cli book_term_export <bookid> <output_path>`
00829| - **Description**: CLI command to export terms from a book
00830| - **Parameters**: 
00831|   - `bookid` - ID of the book
00832|   - `output_path` - Output file path
00833| - **Response**: Export file with term frequencies
00834| - **Data Exposed**: Terms in the specified book
00835| 
00836| ### `cli import_books_from_csv [OPTIONS] <file>`
00837| - **Description**: CLI command to import books from CSV
00838| - **Parameters**: 
00839|   - `file` - Path to the CSV file
00840|   - `--commit` - Flag to commit changes
00841|   - `--tags` - Comma-separated tags to apply
00842|   - `--language` - Default language for books
00843| - **Response**: Import results
00844| - **Data Used**: CSV file with book data
00845| 
00846| ---
00847| 
00848| ## Development API Routes (`/dev_api`) [Test DBs only]
00849| 
00850| ### `GET /dev_api/wipe_db`
00851| - **Description**: Wipe the entire database
00852| - **Parameters**: None
00853| - **Response**: Flash message and redirect to main page
00854| - **Data Used**: All database tables (deletion)
00855| 
00856| ### `GET /dev_api/load_demo`
00857| - **Description**: Load demo data after wiping
00858| - **Parameters**: None
00859| - **Response**: Flash message and redirect to main page
00860| - **Data Used**: Demo data
00861| 
00862| ### `GET /dev_api/load_demo_languages`
00863| - **Description**: Load demo languages with dummy dictionaries
00864| - **Parameters**: None
00865| - **Response**: Redirect to main page
00866| - **Data Used**: Demo language definitions
00867| 
00868| ### `GET /dev_api/load_demo_stories`
00869| - **Description**: Load demo stories only
00870| - **Parameters**: None
00871| - **Response**: Flash message and redirect to main page
00872| - **Data Used**: Demo stories
00873| 
00874| ### `GET /dev_api/language_ids`
00875| - **Description**: Get IDs of all languages
00876| - **Parameters**: None
00877| - **Response**: JSON with language names and IDs
00878| - **Data Exposed**: Language IDs
00879| 
00880| ### `GET /dev_api/delete_all_terms`
00881| - **Description**: Delete all terms only
00882| - **Parameters**: None
00883| - **Response**: Flash message and redirect to main page
00884| - **Data Used**: All terms (deletion)
00885| 
00886| ### `GET /dev_api/sqlresult/<string:sql>`
00887| - **Description**: Execute SQL and return results as JSON
00888| - **Parameters**: `sql` - SQL query string
00889| - **Response**: JSON with SQL results
00890| - **Data Exposed**: Results of SQL query
00891| 
00892| ### `GET /dev_api/execsql/<string:sql>`
00893| - **Description**: Execute arbitrary SQL (with no validation)
00894| - **Parameters**: `sql` - SQL command string
00895| - **Response**: JSON confirmation
00896| - **Data Used**: SQL command execution
00897| 
00898| ### `GET /dev_api/dummy_language_dict/<string:langname>/<string:term>`
00899| - **Description**: Fake language dictionary lookup
00900| - **Parameters**: 
00901|   - `langname` - Language name
00902|   - `term` - Term to look up
00903| - **Response**: Dummy dictionary content
00904| - **Data Used**: None (dummy response)
00905| 
00906| ### `GET /dev_api/disable_parser/<string:parsername>/<string:renameto>`
00907| - **Description**: Hack to rename parser in registry
00908| - **Parameters**: 
00909|   - `parsername` - Parser to rename
00910|   - `renameto` - New name for parser
00911| - **Response**: JSON with parser information
00912| - **Data Exposed**: Parser information
00913| 
00914| ### `GET /dev_api/disable_backup`
00915| - **Description**: Disable backup feature
00916| - **Parameters**: None
00917| - **Response**: Flash message and redirect to main page
00918| - **Data Used**: Backup settings
00919| 
00920| ### `GET /dev_api/throw_error/<message>`
00921| - **Description**: Throw an error to test error handling
00922| - **Parameters**: `message` - Error message
00923| - **Response**: RuntimeError with specified message
00924| - **Data Used**: None (just raises error)
00925| 
00926| ### `GET /dev_api/fake_story.html`
00927| - **Description**: Return a fake story for testing
00928| - **Parameters**: None
00929| - **Response**: HTML content of a fake story
00930| - **Data Used**: None
00931| 
00932| ### `GET /dev_api/temp_file_content/<filename>`
00933| - **Description**: Get content of a temporary file
00934| - **Parameters**: `filename` - Name of the temp file
00935| - **Response**: Content of the temporary file
00936| - **Data Exposed**: Temporary file content
00937| 
00938| 
00939| 
00940| 
00941| # Regex Usage in Lute v3 API Endpoints
00942| 
00943| ## Overview
00944| Lute v3 uses regular expressions in multiple places throughout its codebase, particularly in parsing and text processing functionality. This document identifies all endpoints and components that either currently use regex or would require regex to properly extract information.
00945| 
00946| ## Endpoints that require regex for response parsing
00947| 
00948| ### 1. `/bing/search/<int:langid>/<string:text>/<string:searchstring>`
00949| - **Current regex usage**:
00950|   - `re.findall(r"(<img .*?>)", content, re.I)` - Finds all img tags in Bing search results
00951|   - `re.search(r'src=\"(.*?)\"', normalized_source)` - Extracts src attribute from img tags
00952|   - `re.search(r'src=\"(.*?)\"', normalized_source)` - Used to extract image URLs from HTML
00953| 
00954| - **Why regex is needed**: The endpoint returns HTML content that needs to be parsed to extract image URLs. The Bing search results contain various HTML elements that need to be processed to extract the relevant information.
00955| 
00956| ### 2. Language-specific parsing functionality
00957| Several endpoints rely on parsing functionality that uses regex, particularly:
00958| 
00959| - `/read/<int:bookid>/page/<int:pagenum>` - When reading pages, the text is parsed which uses language-specific regex
00960| - `/term/sentences/<int:langid>/<text>` - Sentence extraction uses parsing that may involve regex
00961| - `/read/start_reading/<int:bookid>/<int:pagenum>` - Page content is parsed using language-specific parsing
00962| 
00963| **Current regex usage in parsing**:
00964| - Language character substitution patterns: `´='|`='|’='|‘='|...=…|..=‥`
00965| - Sentence splitting patterns: `.!?`
00966| - Word character patterns: `a-zA-ZÀ-ÖØ-öø-ȳáéíóúÁÉÍÓÚñÑ` and language-specific ranges
00967| 
00968| ## Components that use regex but aren't direct endpoints
00969| 
00970| ### 3. Language definition parsing
00971| - **File**: `lute/models/language.py`
00972| - **Regex**: Used to convert old PHP regex patterns to Python: 
00973|   - Converting `\\x{XXXX}` to `\\uXXXX` patterns
00974|   - Example: `x{0600}-x{06FF}x{FE70}-x{FEFC}` becomes `u0600-u06FFuFE70-uFEFC`
00975| 
00976| ### 4. Text tokenization
00977| - **File**: `lute/parse/base.py` (base parsing functionality)
00978| - **Usage**: Tokenization of text based on language-specific patterns
00979| - **Regex**: Word character patterns for different languages
00980| 
00981| ### 5. Term processing in database
00982| - **File**: `lute/models/term.py`
00983| - **Regex**: Used when processing text to remove special characters:
00984|   - `zws = "\\u200B"` (zero-width space) - though not exactly regex, it's string processing
00985|   - `nbsp = "\\u00A0"` (non-breaking space)
00986| 
00987| ## Endpoints that could benefit from regex for data extraction
00988| 
00989| ### 6. `/stats/` and `/stats/data`
00990| - While these endpoints return structured data, if you need to extract specific patterns from the statistics, regex could be useful
00991| - The HTML response from `/stats/` might require regex if parsing for specific patterns
00992| 
00993| ### 7. `/term/index` data processing
00994| - When processing the DataTables response, you might need regex to:
00995|   - Extract specific term patterns
00996|   - Process tag lists
00997|   - Parse complex term data for display
00998| 
00999| ### 8. HTML response parsing for any endpoint
01000| Many endpoints return HTML templates. If you need to extract specific data from these HTML responses, you would use regex:
01001| - `/read/<int:bookid>` - extract term data from reading interface
01002| - `/term/form` - extract term details from forms
01003| - `/language/new` - extract available language options
01004| 
01005| ## Examples of regex patterns used in Lute v3
01006| 
01007| ### Character substitution patterns:
01008| - `´='|`='|’='|‘='|...=…|..=‥` (in Language.character_substitutions)
01009| 
01010| ### Sentence splitting patterns:
01011| - Default: `.!?`
01012| - Can be customized per language
01013| 
01014| ### Word character patterns:
01015| - Default: `a-zA-ZÀ-ÖØ-öø-ȳáéíóúÁÉÍÓÚñÑ`
01016| - Language-specific patterns using unicode ranges like `\\u0600-\\u06FF`
01017| 
01018| ### Python conversion from PHP patterns:
01019| ```python
01020| def _get_python_regex_pattern(self, s):
01021|     def convert_match(match):
01022|         # Convert backslash-x{XXXX} to backslash-uXXXX
01023|         hex_value = match.group(1)
01024|         return f"\\\\u{hex_value}"
01025| 
01026|     ret = re.sub(r"\\\\x{([0-9A-Fa-f]+)}", convert_match, s)
01027|     return ret
01028| ```
01029| 
01030| ## Conclusion
01031| 
01032| While many endpoints return structured JSON or HTML, Lute v3 uses regex extensively in its core functionality, particularly in:
01033| 1. Text parsing and tokenization
01034| 2. HTML content extraction (especially for Bing image search)
01035| 3. Language-specific character processing
01036| 4. Database data cleanup and processing
01037| 
01038| If you're consuming Lute's API from an external application, you'll likely need regex to:
01039| - Parse HTML responses to extract specific elements
01040| - Process the raw HTML from Bing search results
01041| - Handle language-specific text processing
01042| - Extract specific patterns from textual data
01043| 

(End of file - total 1043 lines)
</file>

## Assistant

<thinking>
Let me now check the PRD to understand what web dictionary features are expected.
</thinking>

**Tool Call: PRD.md**
Status: Completed

<file>
00001| # LuteForMobile - Product Requirements Document
00002| 
00003| ## 1. Overview
00004| 
00005| LuteForMobile is a mobile frontend application for the Lute v3 server, designed to provide a clean, uncluttered reading experience for language learners. The app focuses on facilitating reading comprehension through term management, translations, and AI-powered assistance.
00006| 
00007| ### 1.1 Purpose
00008| - Serve as a mobile client for the Lute v3 language learning server
00009| - Provide an optimized reading experience on mobile devices
00010| - Enable on-the-go language learning with accessible term lookup and translation tools
00011| 
00012| ### 1.2 Target Audience
00013| - Language learners using the Lute system
00014| - Users who prefer mobile reading over desktop web browsers
00015| - Learners who benefit from TTS and AI-assisted translation
00016| 
00017| ---
00018| 
00019| ## 2. Target Platforms
00020| 
00021| ### 2.1 Primary Platform
00022| - **Android** (primary testing device)
00023| 
00024| ### 2.2 Secondary Platform
00025| - **iOS** - Native Flutter app (or PWA as fallback)
00026| 
00027| ---
00028| 
00029| ## 3. Core Features
00030| 
00031| ### 3.1 Reader
00032| 
00033| **Purpose:** Provide a clean, distraction-free reading environment
00034| 
00035| **Requirements:**
00036| - Minimalist, uncluttered UI
00037| - Main focus on text readability
00038| - Double-tap gesture to open Term Form
00039| - Tap gesture to open Translation popup
00040| 
00041| **Sub-features:**
00042| 
00043| #### Text Rendering
00044| - Flutter RichText with TextSpan for interactive terms
00045| - Tap gestures on specific words/terms
00046| - Double-tap detection for Term Form
00047| - Custom text selection handling
00048| 
00049| #### Term Form
00050| - Triggered by double-tap
00051| - Display term details from server
00052| - Include Web Dictionary integration
00053| 
00054| #### Sentence Reader
00055| - Text-to-Speech (TTS) functionality
00056| - AI Translation support
00057| - Sentence-level processing
00058| 
00059| #### Translation Popup
00060| - Opens on tap (server-provided)
00061| - Shows inline translation
00062| - Non-intrusive display
00063| 
00064| #### Sentence Translation
00065| - Integration with Web Dictionary (links from server)
00066| - AI Translation support
00067| - User-configurable translation source in settings
00068| 
00069| ---
00070| 
00071| ### 3.2 Books
00072| 
00073| **Purpose:** Manage and access reading materials
00074| 
00075| **Requirements:**
00076| - Card-based UI design
00077| - Display book metadata (title, language, progress)
00078| - Easy navigation between books
00079| 
00080| ---
00081| 
00082| ### 3.3 Terms
00083| 
00084| **Purpose:** View and manage learned vocabulary
00085| 
00086| **Requirements:**
00087| - List view of terms
00088| - Search/filter functionality
00089| - Term details view
00090| 
00091| ---
00092| 
00093| ### 3.4 Statistics
00094| 
00095| **Purpose:** Track learning progress and metrics
00096| 
00097| **Requirements:**
00098| - Dashboard of learning metrics
00099| - Charts/graphs for progress visualization
00100| - Reading time tracking
00101| - Vocabulary count tracking
00102| 
00103| ---
00104| 
00105| ### 3.5 Settings
00106| 
00107| #### 3.5.1 App Settings
00108| 
00109| **Server Configuration**
00110| - Server URL input
00111| - Connection testing
00112| 
00113| **AI Setup**
00114| - Provider selector (Local, OpenAI, future providers)
00115| - API key management
00116| - Model selection (auto-fetch from Local endpoints)
00117| - Custom prompts for word translation
00118| - Custom prompts for sentence translation
00119| 
00120| **TTS Setup**
00121| - TTS provider selection (KokoroTTS, NativeTTS)
00122| - Voice selection
00123| - Speed/pitch controls
00124| 
00125| **Theme**
00126| - Light/Dark mode toggle
00127| - Additional theme options (future)
00128| 
00129| #### 3.5.2 Lute Server Settings
00130| 
00131| - Full configuration options mirroring webview/endpoint
00132| - Real-time synchronization with server settings
00133| 
00134| ---
00135| 
00136| ## 4. Technical Architecture
00137| 
00138| ### 4.0 Flutter Architecture Pattern
00139| - **Feature-first folder structure** (reader, books, terms, settings, etc.)
00140| - **Separation of concerns**: UI widgets, business logic, data repositories
00141| - **Dependency injection** using get_it or similar
00142| - **Single source of truth** with state management
00143| 
00144| ### 4.1 Network Layer
00145| - **Centralized network calls** - Single module for all API communication
00146| - Dio/HTTP client with interceptors for logging and error handling
00147| - Consistent error handling and user feedback
00148| - Request/response logging for debugging
00149| - Offline support (future with Hive/sqflite)
00150| - RESTful API integration with Lute v3 server
00151| 
00152| ### 4.1.1 State Management
00153| - Provider/Riverpod for global app state
00154| - Local state with StatefulWidget for UI components
00155| - BLoC pattern for complex business logic (optional)
00156| 
00157| ### 4.2 AI Connectivity
00158| 
00159| **Providers:**
00160| 1. **Local (OpenAI-compatible)**
00161|    - Auto-fetch available models
00162|    - Custom prompts support
00163|    - Word and sentence translation
00164| 
00165| 2. **OpenAI**
00166|    - API integration
00167|    - Word translation prompts
00168|    - Sentence translation prompts
00169| 
00170| 3. **Future Providers** (extensible architecture)
00171| 
00172| ### 4.3 TTS Manager
00173| 
00174| **Providers:**
00175| - **KokoroTTS** - Primary option (HTTP API integration)
00176| - **NativeTTS** - Fallback/alternative (using flutter_tts for native device TTS)
00177| - **Google TTS** - Optional cloud-based TTS
00178| 
00179| **Features:**
00180| - Voice selection and preview
00181| - Playback controls (play, pause, stop)
00182| - Speed and pitch adjustment
00183| - Sentence-level playback highlighting
00184| - Audio caching for offline playback
00185| 
00186| ---
00187| 
00188| ## 5. User Interface Requirements
00189| 
00190| ### 5.1 Design Principles
00191| - Clean, minimalist aesthetic using Flutter's Material Design
00192| - Large touch targets for mobile (Material guidelines)
00193| - High readability (appropriate font sizes, contrast)
00194| - Consistent spacing and padding using Flutter theming
00195| - Custom widgets for Reader UI (TextSpan for interactive terms)
00196| 
00197| ### 5.2 Navigation
00198| - Bottom navigation bar for main sections
00199| - Back navigation for nested screens
00200| - Gesture support (swipe, tap, double-tap)
00201| 
00202| ### 5.3 Responsive Design
00203| - Adaptable to different screen sizes
00204| - Portrait-optimized (mobile-first)
00205| 
00206| ---
00207| 
00208| ## 6. Technical Specifications
00209| 
00210| ### 6.1 Development Framework
00211| - **Flutter** - Cross-platform framework using Dart
00212|   - Native performance on both Android and iOS
00213|   - Flutter Web for PWA option
00214|   - Hot reload for fast development
00215|   - Built-in widget library
00216| 
00217| ### 6.2 Test Environment
00218| - **Server:** 192.168.1.100:5001
00219| - **Primary Test Device:** Android
00220| 
00221| ### 6.3 PWA Requirements (for iOS - optional)
00222| - Flutter Web build for PWA deployment
00223| - Web manifest configuration
00224| - Service worker for offline capability
00225| - Responsive viewport settings
00226| - Apple-specific meta tags
00227| 
00228| ### 6.4 Flutter Requirements and Dependencies
00229| 
00230| #### Flutter Version Summary
00231| | Component | Version | Status |
00232| |-----------|---------|--------|
00233| | Flutter | 3.38+ (stable) | ✅ Latest stable (Nov 12, 2025) |
00234| | Dart | 3.10+ | ✅ Latest compatible |
00235| | Android minSdk | 24 (Android 7.0) | ✅ Modern APIs |
00236| | iOS minVersion | 12.0+ | ✅ Compatible |
00237| 
00238| **Note**: All packages listed below are fully compatible with Flutter 3.38+ and Dart 3.10
00239| 
00240| #### Core Flutter Packages
00241| - `dio: ^5.9.0` - HTTP client for API calls with interceptors
00242| - `flutter_riverpod: ^3.0.3` - State management (replaces provider)
00243| - `shared_preferences: ^2.2.3` - Local data persistence (settings, server URL)
00244| - `go_router: ^17.0.1` - Navigation and routing
00245| - `get_it: ^9.2.0` - Dependency injection
00246| 
00247| #### UI/UX Packages
00248| - `cached_network_image: ^3.3.1` - Image caching for book covers
00249| - `shimmer` - Loading placeholders (verify compatibility)
00250| - `flutter_markdown` - Markdown rendering for text content (verify compatibility)
00251| 
00252| #### Reader-Specific Packages
00253| - `flutter_tts: ^4.0.2` - Text-to-Speech (NativeTTS)
00254| - `speech_to_text` - Speech input (if needed for future features, verify compatibility)
00255| 
00256| #### AI Integration
00257| - `openai_dart: ^0.6.2` - OpenAI API integration (recommended, latest version)
00258| - Alternative: Custom HTTP client with dio for more control
00259| 
00260| #### Charts/Statistics
00261| - `fl_chart: ^1.1.1` - Charts and graphs for statistics
00262| 
00263| #### Storage & Database
00264| - `hive_ce: ^2.15.1` - Local database for offline support (books, terms) - Actively maintained community edition
00265| - `hive_ce_flutter: ^2.3.2` - Flutter extensions for hive_ce
00266| - Note: Use hive_ce instead of original hive (last updated 3 years ago)
00267| 
00268| #### Network & Utilities
00269| - `connectivity_plus: ^6.0.3` - Network connectivity monitoring
00270| - `dio_cache_interceptor` - HTTP response caching (verify compatibility with dio 5.9.0)
00271| - `url_launcher: ^6.3.1` - Opening web dictionary URLs
00272| - `flutter_inappwebview: ^6.1.5` - Web dictionary integration
00273| 
00274| #### PWA/Web (if using Flutter Web for iOS)
00275| - `universal_html` - HTML5 API support
00276| - `js` - JavaScript interop for PWA features
00277| 
00278| #### Development Tools
00279| - `flutter_lints` - Dart linting rules
00280| - `mocktail` - Testing mocks (recommended for Dart 3+)
00281| - `integration_test` - Flutter integration testing
00282| - `build_runner` - Code generation (if using freezed/json_serializable)
00283| 
00284| #### Package Compatibility Notes
00285| - All packages above are compatible with Dart 3.10 and Flutter 3.38+
00286| - Packages marked with "verify compatibility" should be checked during setup
00287| - Dart SDK 3.10+ is required for all packages
00288| - Always check pub.dev for latest versions and compatibility before adding packages
00289| 
00290| #### Package Compatibility Summary
00291| 
00292| | Package | Latest Version | Min Dart SDK | Status |
00293| |---------|---------------|--------------|--------|
00294| | flutter_riverpod | 3.0.3 | 3.7 | ✅ Compatible |
00295| | riverpod | 3.0.3 | - | ✅ Compatible |
00296| | dio | 5.9.0 | 2.18 | ✅ Compatible |
00297| | flutter_tts | 4.0.2 | 2.15 | ✅ Compatible |
00298| | go_router | 17.0.1 | - | ✅ Compatible |
00299| | cached_network_image | 3.3.1 | 3.0 | ✅ Compatible |
00300| | fl_chart | 1.1.1 | - | ✅ Compatible |
00301| | hive_ce | 2.15.1 | 3.4 | ✅ Compatible (actively maintained) |
00302| | hive_ce_flutter | 2.3.2 | - | ✅ Compatible |
00303| | shared_preferences | 2.2.3 | 3.1 | ✅ Compatible |
00304| | url_launcher | 6.3.1 | 3.3 | ✅ Compatible |
00305| | connectivity_plus | 6.0.3 | 3.2 | ✅ Compatible |
00306| | flutter_inappwebview | 6.1.5 | 3.5 | ✅ Compatible |
00307| | get_it | 9.2.0 | 3.0 | ✅ Compatible |
00308| | openai_dart | 0.6.2 | 3.8 | ✅ Compatible |
00309| 
00310| #### Minimum Flutter Version
00311| - **Flutter**: 3.38+ (stable)
00312| - **Dart**: 3.10+
00313| 
00314| #### Platform-Specific Requirements
00315| - **Android**: minSdkVersion 24 (Android 7.0) - Better Flutter support and modern APIs
00316| - **iOS**: iOS 12.0+
00317| - **Permissions**:
00318|   - Internet (required)
00319|   - Storage (for offline caching)
00320|   - Notification (if adding push notifications later)
00321| 
00322| #### Project Structure
00323| ```
00324| lib/
00325| ├── main.dart
00326| ├── app.dart (App widget and routing)
00327| ├── config/ (app configuration, constants)
00328| ├── core/ (shared utilities, themes)
00329| │   ├── network/ (API client, interceptors)
00330| │   ├── storage/ (local storage, hive_ce)
00331| │   └── theme/ (app theming)
00332| ├── features/
00333| │   ├── reader/ (reader screens and widgets)
00334| │   │   ├── models/
00335| │   │   ├── providers/
00336| │   │   ├── repositories/
00337| │   │   └── widgets/
00338| │   ├── books/ (book management)
00339| │   ├── terms/ (term management)
00340| │   ├── statistics/ (stats dashboard)
00341| │   └── settings/ (app and server settings)
00342| └── shared/ (shared widgets, components)
00343| ```
00344| 
00345| ---
00346| 
00347| ## 7. Success Metrics
00348| 
00349| - App stability (crash-free sessions)
00350| - Fast loading times for books and terms
00351| - Successful API call rate
00352| - User engagement (reading time, term lookups)
00353| - Positive user feedback on readability
00354| 
00355| ---
00356| 
00357| ## 8. Future Enhancements
00358| 
00359| - Offline mode for books and terms
00360| - Anki integration for term export
00361| - Cloud sync for settings
00362| - Additional AI providers (Anthropic, Google, etc.)
00363| - Social features (sharing progress)
00364| - Gamification elements
00365| 
00366| ---
00367| 
00368| ## 9. Risks and Mitigations
00369| 
00370| | Risk | Mitigation |
00371| |------|------------|
00372| | iOS PWA limitations | Flutter supports native iOS apps, eliminating most PWA constraints |
00373| | Server connectivity issues | Implement robust error handling and offline queue |
00374| | AI API rate limits | Implement request batching and caching |
00375| | TTS provider availability | Support multiple TTS backends with graceful fallback |
00376| 
00377| ---
00378| 
00379| ## 10. Dependencies
00380| 
00381| ### Backend
00382| - Lute v3 server (backend)
00383| - Stable network connection
00384| 

(End of file - total 384 lines)
</file>

## Assistant

<thinking>
Now let me look at the existing code to see what's already implemented related to the reader, term forms, and translation components.
</thinking>

**Tool Call: lib/features/reader**
Status: Completed

/home/cody/LuteForMobile/lib/features/reader/
  models/
    page_data.dart
    paragraph.dart
    sentence_translation.dart
    term_form.dart
    term_tooltip.dart
    text_item.dart
  providers/
    reader_provider.dart
  repositories/
    reader_repository.dart
  widgets/
    parent_search.dart
    reader_drawer_settings.dart
    reader_screen.dart
    sentence_translation.dart
    term_form.dart
    term_tooltip.dart
    text_display.dart


## Assistant

<thinking>
Let me check what's in the existing term_form model and widget to understand the current implementation.
</thinking>

**Tool Call: lib/features/reader/models/term_form.dart**
Status: Completed

<file>
00001| import 'dart:convert';
00002| import 'term_tooltip.dart';
00003| 
00004| class SearchResultTerm {
00005|   final int? id;
00006|   final String text;
00007|   final String? translation;
00008|   final int? status;
00009|   final int? langId;
00010|   final bool? syncStatus;
00011| 
00012|   SearchResultTerm({
00013|     this.id,
00014|     required this.text,
00015|     this.translation,
00016|     this.status,
00017|     this.langId,
00018|     this.syncStatus,
00019|   });
00020| 
00021|   factory SearchResultTerm.fromJson(Map<String, dynamic> json) {
00022|     return SearchResultTerm(
00023|       id: json['id'] as int?,
00024|       text: json['text'] as String? ?? '',
00025|       translation: json['translation'] as String?,
00026|       status: json['status'] as int?,
00027|       langId: json['lang_id'] as int?,
00028|       syncStatus: json['sync_status'] as bool?,
00029|     );
00030|   }
00031| 
00032|   String get statusString => status?.toString() ?? '';
00033| }
00034| 
00035| class TermForm {
00036|   final String term;
00037|   final String? translation;
00038|   final int? termId;
00039|   final int languageId;
00040|   final String status;
00041|   final List<String>? tags;
00042|   final String? romanization;
00043|   final bool showRomanization;
00044|   final List<String> dictionaries;
00045|   final List<TermParent> parents;
00046|   final bool? syncStatus;
00047| 
00048|   TermForm({
00049|     required this.term,
00050|     this.translation,
00051|     this.termId,
00052|     required this.languageId,
00053|     this.status = '99',
00054|     this.tags,
00055|     this.romanization,
00056|     this.showRomanization = true,
00057|     this.dictionaries = const [],
00058|     this.parents = const [],
00059|     required this.syncStatus,
00060|   });
00061| 
00062|   TermForm copyWith({
00063|     String? term,
00064|     String? translation,
00065|     int? termId,
00066|     int? languageId,
00067|     String? status,
00068|     List<String>? tags,
00069|     String? romanization,
00070|     bool? showRomanization,
00071|     List<String>? dictionaries,
00072|     List<TermParent>? parents,
00073|     bool? syncStatus,
00074|   }) {
00075|     return TermForm(
00076|       term: term ?? this.term,
00077|       translation: translation ?? this.translation,
00078|       termId: termId ?? this.termId,
00079|       languageId: languageId ?? this.languageId,
00080|       status: status ?? this.status,
00081|       tags: tags ?? this.tags,
00082|       romanization: romanization ?? this.romanization,
00083|       showRomanization: showRomanization ?? this.showRomanization,
00084|       dictionaries: dictionaries ?? this.dictionaries,
00085|       parents: parents ?? this.parents,
00086|       syncStatus: syncStatus ?? this.syncStatus,
00087|     );
00088|   }
00089| 
00090|   Map<String, dynamic> toFormData() {
00091|     print('Converting term form to form data');
00092|     print('Parents count: ${parents.length}');
00093|     print('Sync status: $syncStatus');
00094|     for (final p in parents) {
00095|       print('Parent: id=${p.id}, term=${p.term}, translation=${p.translation}');
00096|     }
00097|     final data = {
00098|       'text': term,
00099|       'translation': translation ?? '',
00100|       'status': status,
00101|       'tags': tags?.join(',') ?? '',
00102|       'romanization': romanization ?? '',
00103|     };
00104| 
00105|     if (syncStatus == true && parents.length <= 1) {
00106|       data['sync_status'] = 'y';
00107|     }
00108| 
00109|     if (parents.isNotEmpty) {
00110|       final parentsList = parents.map((p) => {'value': p.term}).toList();
00111|       final parentsListJson = jsonEncode(parentsList);
00112|       data['parentslist'] = parentsListJson;
00113|       print('Sending parentslist: $parentsListJson');
00114|     }
00115| 
00116|     return data;
00117|   }
00118| }
00119| 

(End of file - total 119 lines)
</file>

**Tool Call: lib/features/reader/widgets/term_form.dart**
Status: Completed

<file>
00001| import 'package:flutter/material.dart';
00002| import 'package:flutter_riverpod/flutter_riverpod.dart';
00003| import '../models/term_form.dart';
00004| import '../models/term_tooltip.dart';
00005| import '../../settings/providers/settings_provider.dart'
00006|     show termFormSettingsProvider;
00007| import '../../../shared/theme/theme_extensions.dart';
00008| import '../../../core/network/content_service.dart';
00009| import 'parent_search.dart';
00010| 
00011| class TermFormWidget extends ConsumerStatefulWidget {
00012|   final TermForm termForm;
00013|   final void Function(TermForm) onSave;
00014|   final void Function(TermForm) onUpdate;
00015|   final VoidCallback onCancel;
00016|   final ContentService contentService;
00017|   final void Function(TermParent)? onParentDoubleTap;
00018| 
00019|   TermFormWidget({
00020|     super.key,
00021|     required this.termForm,
00022|     required this.onSave,
00023|     required this.onUpdate,
00024|     required this.onCancel,
00025|     required this.contentService,
00026|     this.onParentDoubleTap,
00027|   });
00028| 
00029|   @override
00030|   ConsumerState<TermFormWidget> createState() => _TermFormWidgetState();
00031| }
00032| 
00033| class _TermFormWidgetState extends ConsumerState<TermFormWidget> {
00034|   late TextEditingController _translationController;
00035|   late TextEditingController _tagsController;
00036|   late TextEditingController _romanizationController;
00037|   late String _selectedStatus;
00038| 
00039|   @override
00040|   void initState() {
00041|     super.initState();
00042|     _translationController = TextEditingController(
00043|       text: widget.termForm.translation ?? '',
00044|     );
00045|     _selectedStatus = widget.termForm.status;
00046|     _tagsController = TextEditingController(
00047|       text: widget.termForm.tags?.join(', ') ?? '',
00048|     );
00049|     _romanizationController = TextEditingController(
00050|       text: widget.termForm.romanization ?? '',
00051|     );
00052|   }
00053| 
00054|   @override
00055|   void didUpdateWidget(TermFormWidget oldWidget) {
00056|     super.didUpdateWidget(oldWidget);
00057|     print('didUpdateWidget called');
00058|     print(
00059|       'old parents: ${oldWidget.termForm.parents.map((p) => p.term).toList()}',
00060|     );
00061|     print(
00062|       'new parents: ${widget.termForm.parents.map((p) => p.term).toList()}',
00063|     );
00064|     if (oldWidget.termForm.parents != widget.termForm.parents) {
00065|       setState(() {});
00066|     }
00067|   }
00068| 
00069|   @override
00070|   void dispose() {
00071|     _translationController.dispose();
00072|     _tagsController.dispose();
00073|     _romanizationController.dispose();
00074|     super.dispose();
00075|   }
00076| 
00077|   void _handleSave() {
00078|     final updatedForm = widget.termForm.copyWith(
00079|       translation: _translationController.text.trim(),
00080|       status: _selectedStatus,
00081|       tags: _tagsController.text
00082|           .trim()
00083|           .split(',')
00084|           .map((tag) => tag.trim())
00085|           .where((tag) => tag.isNotEmpty)
00086|           .toList(),
00087|       romanization: _romanizationController.text.trim(),
00088|       parents: widget.termForm.parents,
00089|     );
00090|     widget.onSave(updatedForm);
00091|   }
00092| 
00093|   void _showSettingsMenu() {
00094|     final settings = ref.watch(termFormSettingsProvider);
00095|     showDialog(
00096|       context: context,
00097|       builder: (context) => AlertDialog(
00098|         title: const Text('Term Form Settings'),
00099|         content: Column(
00100|           mainAxisSize: MainAxisSize.min,
00101|           children: [
00102|             SwitchListTile(
00103|               title: const Text('Show Tags'),
00104|               value: settings.showTags,
00105|               onChanged: (value) {
00106|                 ref
00107|                     .read(termFormSettingsProvider.notifier)
00108|                     .updateShowTags(value);
00109|                 Navigator.of(context).pop();
00110|               },
00111|             ),
00112|           ],
00113|         ),
00114|         actions: [
00115|           TextButton(
00116|             onPressed: () => Navigator.of(context).pop(),
00117|             child: const Text('Close'),
00118|           ),
00119|         ],
00120|       ),
00121|     );
00122|   }
00123| 
00124|   @override
00125|   Widget build(BuildContext context) {
00126|     print(
00127|       'build called with parents: ${widget.termForm.parents.map((p) => p.term).toList()}',
00128|     );
00129|     final settings = ref.watch(termFormSettingsProvider);
00130|     return Container(
00131|       padding: const EdgeInsets.all(16),
00132|       decoration: BoxDecoration(
00133|         color: Theme.of(context).colorScheme.surface,
00134|         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
00135|       ),
00136|       child: SingleChildScrollView(
00137|         child: Column(
00138|           mainAxisSize: MainAxisSize.min,
00139|           crossAxisAlignment: CrossAxisAlignment.start,
00140|           children: [
00141|             _buildHeader(context),
00142|             const SizedBox(height: 12),
00143|             _buildTranslationField(context),
00144|             const SizedBox(height: 12),
00145|             _buildStatusField(context),
00146|             if (widget.termForm.showRomanization) ...[
00147|               const SizedBox(height: 12),
00148|               _buildRomanizationField(context),
00149|             ],
00150|             if (settings.showTags) ...[
00151|               const SizedBox(height: 12),
00152|               _buildTagsField(context),
00153|             ],
00154|             if (widget.termForm.dictionaries.isNotEmpty) ...[
00155|               const SizedBox(height: 12),
00156|               _buildDictionariesSection(context),
00157|             ],
00158|             const SizedBox(height: 12),
00159|             _buildParentsSection(context),
00160|             const SizedBox(height: 16),
00161|             _buildButtons(context),
00162|           ],
00163|         ),
00164|       ),
00165|     );
00166|   }
00167| 
00168|   Widget _buildHeader(BuildContext context) {
00169|     return Row(
00170|       mainAxisAlignment: MainAxisAlignment.spaceBetween,
00171|       children: [
00172|         Expanded(
00173|           child: Text(
00174|             widget.termForm.term,
00175|             style: Theme.of(
00176|               context,
00177|             ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
00178|             overflow: TextOverflow.ellipsis,
00179|           ),
00180|         ),
00181|         Row(
00182|           children: [
00183|             IconButton(
00184|               onPressed: _showSettingsMenu,
00185|               icon: const Icon(Icons.settings),
00186|               tooltip: 'Term Form Settings',
00187|             ),
00188|             IconButton(
00189|               onPressed: widget.onCancel,
00190|               icon: const Icon(Icons.close),
00191|               tooltip: 'Close',
00192|             ),
00193|           ],
00194|         ),
00195|       ],
00196|     );
00197|   }
00198| 
00199|   Widget _buildTranslationField(BuildContext context) {
00200|     return TextFormField(
00201|       controller: _translationController,
00202|       decoration: InputDecoration(
00203|         labelText: 'Translation',
00204|         labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
00205|           color: context.customColors.accentLabelColor,
00206|           fontWeight: FontWeight.w600,
00207|         ),
00208|         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
00209|         hintText: 'Enter translation',
00210|         hintStyle: TextStyle(
00211|           color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
00212|         ),
00213|         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
00214|       ),
00215|       maxLines: 2,
00216|     );
00217|   }
00218| 
00219|   Widget _buildStatusField(BuildContext context) {
00220|     return Wrap(
00221|       spacing: 8,
00222|       runSpacing: 8,
00223|       children: [
00224|         _buildStatusButton(context, '1', '1', _getStatusColor('1')),
00225|         _buildStatusButton(context, '2', '2', _getStatusColor('2')),
00226|         _buildStatusButton(context, '3', '3', _getStatusColor('3')),
00227|         _buildStatusButton(context, '4', '4', _getStatusColor('4')),
00228|         _buildStatusButton(context, '5', '5', _getStatusColor('5')),
00229|         _buildStatusButton(context, '99', '✓', _getStatusColor('99')),
00230|         _buildStatusButton(context, '98', '✕', _getStatusColor('98')),
00231|       ],
00232|     );
00233|   }
00234| 
00235|   Color _getStatusColor(String status) {
00236|     return Theme.of(context).colorScheme.getStatusColor(status);
00237|   }
00238| 
00239|   Widget _buildStatusButton(
00240|     BuildContext context,
00241|     String statusValue,
00242|     String label,
00243|     Color statusColor,
00244|   ) {
00245|     final isSelected = _selectedStatus == statusValue;
00246| 
00247|     final labelColor = !isSelected && statusValue == '5'
00248|         ? _getStatusColor('4')
00249|         : (isSelected ? Theme.of(context).colorScheme.onPrimary : statusColor);
00250| 
00251|     return InkWell(
00252|       onTap: () {
00253|         setState(() {
00254|           _selectedStatus = statusValue;
00255|         });
00256|       },
00257|       child: Container(
00258|         width: 48,
00259|         height: 48,
00260|         decoration: BoxDecoration(
00261|           color: isSelected
00262|               ? statusColor
00263|               : Theme.of(
00264|                   context,
00265|                 ).colorScheme.getStatusColorWithOpacity(statusValue),
00266|           borderRadius: BorderRadius.circular(8),
00267|           border: Border.all(color: statusColor, width: isSelected ? 2 : 1),
00268|         ),
00269|         child: Center(
00270|           child: Text(
00271|             label,
00272|             style: TextStyle(
00273|               fontSize: 20,
00274|               fontWeight: FontWeight.bold,
00275|               color: labelColor,
00276|             ),
00277|           ),
00278|         ),
00279|       ),
00280|     );
00281|   }
00282| 
00283|   Widget _buildRomanizationField(BuildContext context) {
00284|     return TextFormField(
00285|       controller: _romanizationController,
00286|       decoration: InputDecoration(
00287|         labelText: 'Romanization',
00288|         labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
00289|           color: context.customColors.accentLabelColor,
00290|           fontWeight: FontWeight.w600,
00291|         ),
00292|         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
00293|         hintText: 'Enter romanization (optional)',
00294|         hintStyle: TextStyle(
00295|           color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
00296|         ),
00297|         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
00298|       ),
00299|     );
00300|   }
00301| 
00302|   Widget _buildTagsField(BuildContext context) {
00303|     return TextFormField(
00304|       controller: _tagsController,
00305|       decoration: InputDecoration(
00306|         labelText: 'Tags',
00307|         labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
00308|           color: context.customColors.accentLabelColor,
00309|           fontWeight: FontWeight.w600,
00310|         ),
00311|         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
00312|         hintText: 'Enter tags separated by commas',
00313|         hintStyle: TextStyle(
00314|           color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
00315|         ),
00316|         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
00317|       ),
00318|     );
00319|   }
00320| 
00321|   Widget _buildDictionariesSection(BuildContext context) {
00322|     return Column(
00323|       crossAxisAlignment: CrossAxisAlignment.start,
00324|       children: [
00325|         Text(
00326|           'Dictionaries',
00327|           style: Theme.of(context).textTheme.labelSmall?.copyWith(
00328|             color: context.customColors.accentLabelColor,
00329|             fontWeight: FontWeight.w600,
00330|           ),
00331|         ),
00332|         const SizedBox(height: 4),
00333|         Wrap(
00334|           spacing: 8,
00335|           runSpacing: 8,
00336|           children: widget.termForm.dictionaries.map((dict) {
00337|             return Chip(
00338|               label: Text(dict),
00339|               avatar: const Icon(Icons.book, size: 18),
00340|             );
00341|           }).toList(),
00342|         ),
00343|       ],
00344|     );
00345|   }
00346| 
00347|   Widget _buildParentsSection(BuildContext context) {
00348|     print(
00349|       '_buildParentsSection called with ${widget.termForm.parents.length} parents',
00350|     );
00351|     for (final p in widget.termForm.parents) {
00352|       print('  Parent: term=${p.term}, status=${p.status}, id=${p.id}');
00353|     }
00354|     return Column(
00355|       crossAxisAlignment: CrossAxisAlignment.start,
00356|       children: [
00357|         Row(
00358|           mainAxisAlignment: MainAxisAlignment.spaceBetween,
00359|           children: [
00360|             Text(
00361|               'Parent Terms',
00362|               style: Theme.of(context).textTheme.labelSmall?.copyWith(
00363|                 color: context.customColors.accentLabelColor,
00364|                 fontWeight: FontWeight.w600,
00365|               ),
00366|             ),
00367|             Row(
00368|               children: [
00369|                 IconButton(
00370|                   onPressed: _canSyncWithParent()
00371|                       ? () => _showParentLinkMenu(context)
00372|                       : null,
00373|                   icon: Icon(
00374|                     _hasMultipleParents() ? Icons.link_off : Icons.link,
00375|                     color: _getLinkIconColor(),
00376|                   ),
00377|                   tooltip: _getLinkTooltip(),
00378|                   iconSize: 20,
00379|                   constraints: const BoxConstraints(
00380|                     minWidth: 40,
00381|                     minHeight: 40,
00382|                   ),
00383|                 ),
00384|                 const SizedBox(width: 8),
00385|                 ElevatedButton.icon(
00386|                   onPressed: () => _showAddParentDialog(context),
00387|                   icon: const Icon(Icons.add),
00388|                   label: const Text('Add Parent'),
00389|                 ),
00390|               ],
00391|             ),
00392|           ],
00393|         ),
00394|         const SizedBox(height: 4),
00395|         if (widget.termForm.parents.isNotEmpty)
00396|           Wrap(
00397|             spacing: 8,
00398|             runSpacing: 8,
00399|             children: widget.termForm.parents.map((parent) {
00400|               return _buildParentChip(context, parent);
00401|             }).toList(),
00402|           ),
00403|       ],
00404|     );
00405|   }
00406| 
00407|   void _showParentLinkMenu(BuildContext context) {
00408|     if (widget.termForm.parents.isEmpty) {
00409|       _showLinkDialog(context);
00410|     } else if (widget.termForm.parents.length == 1) {
00411|       final updatedForm = widget.termForm.copyWith(
00412|         syncStatus: widget.termForm.syncStatus == true ? false : true,
00413|       );
00414|       widget.onUpdate(updatedForm);
00415|     }
00416|   }
00417| 
00418|   void _showLinkDialog(BuildContext context) {
00419|     showDialog(
00420|       context: context,
00421|       builder: (context) => AlertDialog(
00422|         title: const Text('Link Parent Term'),
00423|         content: const Text(
00424|           'This term will inherit the status of the parent term.\n\n'
00425|           'The parent term will show this term as a child.',
00426|         ),
00427|         actions: [
00428|           TextButton(
00429|             onPressed: () => Navigator.of(context).pop(),
00430|             child: const Text('Cancel'),
00431|           ),
00432|           TextButton(
00433|             onPressed: () {
00434|               Navigator.of(context).pop();
00435|               _showParentSearchForLinking(context);
00436|             },
00437|             child: const Text('Link'),
00438|           ),
00439|         ],
00440|       ),
00441|     );
00442|   }
00443| 
00444|   void _showParentSearchForLinking(BuildContext context) {
00445|     showDialog(
00446|       context: context,
00447|       builder: (context) => Dialog(
00448|         insetPadding: const EdgeInsets.all(16),
00449|         child: ConstrainedBox(
00450|           constraints: const BoxConstraints(maxWidth: 400),
00451|           child: Padding(
00452|             padding: const EdgeInsets.all(16),
00453|             child: Column(
00454|               mainAxisSize: MainAxisSize.min,
00455|               crossAxisAlignment: CrossAxisAlignment.stretch,
00456|               children: [
00457|                 const Text(
00458|                   'Link to Parent Term',
00459|                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
00460|                 ),
00461|                 const SizedBox(height: 16),
00462|                 ParentSearchWidget(
00463|                   languageId: widget.termForm.languageId,
00464|                   existingParentIds: widget.termForm.parents
00465|                       .map((p) => p.id)
00466|                       .where((id) => id != null)
00467|                       .cast<int>()
00468|                       .toList(),
00469|                   onParentSelected: (parent) {
00470|                     _linkToParent(parent);
00471|                   },
00472|                   contentService: widget.contentService,
00473|                   onDone: () {
00474|                     Navigator.of(context).pop();
00475|                   },
00476|                 ),
00477|                 const SizedBox(height: 8),
00478|                 TextButton(
00479|                   onPressed: () => Navigator.of(context).pop(),
00480|                   child: const Text('Cancel'),
00481|                 ),
00482|               ],
00483|             ),
00484|           ),
00485|         ),
00486|       ),
00487|     );
00488|   }
00489| 
00490|   void _linkToParent(TermParent parent) {
00491|     final updatedForm = widget.termForm.copyWith(parents: [parent]);
00492|     widget.onUpdate(updatedForm);
00493|   }
00494| 
00495|   Widget _buildParentChip(BuildContext context, TermParent parent) {
00496|     print(
00497|       '_buildParentChip called for parent: term=${parent.term}, status=${parent.status}, translation=${parent.translation}',
00498|     );
00499|     final status = parent.status?.toString() ?? '0';
00500|     final textColor = Theme.of(context).colorScheme.getStatusTextColor(status);
00501|     final backgroundColor = Theme.of(
00502|       context,
00503|     ).colorScheme.getStatusBackgroundColor(status);
00504| 
00505|     return GestureDetector(
00506|       onLongPress: () => _showDeleteParentConfirmation(context, parent),
00507|       onDoubleTap: () {
00508|         if (widget.onParentDoubleTap != null) {
00509|           widget.onParentDoubleTap!(parent);
00510|         }
00511|       },
00512|       child: Chip(
00513|         backgroundColor: backgroundColor,
00514|         label: Row(
00515|           mainAxisSize: MainAxisSize.min,
00516|           children: [
00517|             Text(parent.term, style: TextStyle(color: textColor)),
00518|             if (parent.translation != null) ...[
00519|               const SizedBox(width: 4),
00520|               Text(
00521|                 '(${parent.translation})',
00522|                 style: TextStyle(
00523|                   fontSize: 11,
00524|                   color: Theme.of(
00525|                     context,
00526|                   ).colorScheme.onSurface.withValues(alpha: 0.7),
00527|                 ),
00528|               ),
00529|             ],
00530|           ],
00531|         ),
00532|       ),
00533|     );
00534|   }
00535| 
00536|   void _showDeleteParentConfirmation(BuildContext context, TermParent parent) {
00537|     showDialog(
00538|       context: context,
00539|       builder: (context) => AlertDialog(
00540|         title: const Text('Unlink Parent'),
00541|         content: Text('Are you sure you want to unlink from "${parent.term}"?'),
00542|         actions: [
00543|           TextButton(
00544|             onPressed: () => Navigator.of(context).pop(),
00545|             child: const Text('Cancel'),
00546|           ),
00547|           TextButton(
00548|             onPressed: () {
00549|               Navigator.of(context).pop();
00550|               _removeParent(parent);
00551|             },
00552|             child: const Text('Unlink'),
00553|           ),
00554|         ],
00555|       ),
00556|     );
00557|   }
00558| 
00559|   void _showAddParentDialog(BuildContext context) {
00560|     showDialog(
00561|       context: context,
00562|       builder: (context) => Dialog(
00563|         insetPadding: const EdgeInsets.all(16),
00564|         child: ConstrainedBox(
00565|           constraints: const BoxConstraints(maxWidth: 400),
00566|           child: Padding(
00567|             padding: const EdgeInsets.all(16),
00568|             child: Column(
00569|               mainAxisSize: MainAxisSize.min,
00570|               crossAxisAlignment: CrossAxisAlignment.stretch,
00571|               children: [
00572|                 const Text(
00573|                   'Add Parent Term',
00574|                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
00575|                 ),
00576|                 const SizedBox(height: 16),
00577|                 ParentSearchWidget(
00578|                   languageId: widget.termForm.languageId,
00579|                   existingParentIds: widget.termForm.parents
00580|                       .map((p) => p.id)
00581|                       .where((id) => id != null)
00582|                       .cast<int>()
00583|                       .toList(),
00584|                   onParentSelected: (parent) {
00585|                     _addParent(parent);
00586|                   },
00587|                   contentService: widget.contentService,
00588|                   onDone: () {
00589|                     Navigator.of(context).pop();
00590|                   },
00591|                 ),
00592|                 const SizedBox(height: 8),
00593|                 TextButton(
00594|                   onPressed: () => Navigator.of(context).pop(),
00595|                   child: const Text('Cancel'),
00596|                 ),
00597|               ],
00598|             ),
00599|           ),
00600|         ),
00601|       ),
00602|     );
00603|   }
00604| 
00605|   void _addParent(TermParent parent) {
00606|     final updatedForm = widget.termForm.copyWith(
00607|       parents: [...widget.termForm.parents, parent],
00608|     );
00609|     print('Adding parent: ${parent.term}');
00610|     print(
00611|       'Parents before: ${widget.termForm.parents.map((p) => p.term).toList()}',
00612|     );
00613|     print('Parents after: ${updatedForm.parents.map((p) => p.term).toList()}');
00614|     widget.onUpdate(updatedForm);
00615|   }
00616| 
00617|   void _removeParent(TermParent parent) {
00618|     final updatedForm = widget.termForm.copyWith(
00619|       parents: widget.termForm.parents.where((p) {
00620|         if (parent.id == null || p.id == null) {
00621|           return p.term != parent.term;
00622|         }
00623|         return p.id != parent.id;
00624|       }).toList(),
00625|     );
00626|     widget.onUpdate(updatedForm);
00627|   }
00628| 
00629|   bool _getParentSyncStatus() {
00630|     return widget.termForm.syncStatus == true;
00631|   }
00632| 
00633|   bool _canSyncWithParent() {
00634|     return widget.termForm.parents.length <= 1;
00635|   }
00636| 
00637|   bool _hasMultipleParents() {
00638|     return widget.termForm.parents.length > 1;
00639|   }
00640| 
00641|   Color _getLinkIconColor() {
00642|     return _getParentSyncStatus() ? Colors.green : Colors.grey;
00643|   }
00644| 
00645|   String _getLinkTooltip() {
00646|     if (_hasMultipleParents()) {
00647|       return 'Cannot sync - multiple parents';
00648|     }
00649|     return _getParentSyncStatus()
00650|         ? 'Sync with parent: ON'
00651|         : 'Sync with parent: OFF';
00652|   }
00653| 
00654|   Widget _buildButtons(BuildContext context) {
00655|     return Row(
00656|       children: [
00657|         Expanded(
00658|           child: OutlinedButton(
00659|             onPressed: widget.onCancel,
00660|             child: const Text('Cancel'),
00661|           ),
00662|         ),
00663|         const SizedBox(width: 16),
00664|         Expanded(
00665|           child: ElevatedButton.icon(
00666|             onPressed: _handleSave,
00667|             icon: const Icon(Icons.save),
00668|             label: const Text('Save'),
00669|           ),
00670|         ),
00671|       ],
00672|     );
00673|   }
00674| }
00675| 

(End of file - total 675 lines)
</file>

## Assistant

<thinking>
Now let me check the current settings to see if there's already a place for dictionary settings.
</thinking>

**Tool Call: lib/features/settings/models/settings.dart**
Status: Completed

<file>
00001| import 'package:flutter/material.dart';
00002| 
00003| @immutable
00004| class Settings {
00005|   final String serverUrl;
00006|   final int defaultBookId;
00007|   final int defaultPageId;
00008|   final bool isUrlValid;
00009|   final String translationProvider;
00010| 
00011|   const Settings({
00012|     required this.serverUrl,
00013|     this.defaultBookId = 18,
00014|     this.defaultPageId = 1,
00015|     this.isUrlValid = true,
00016|     this.translationProvider = 'local',
00017|   });
00018| 
00019|   Settings copyWith({
00020|     String? serverUrl,
00021|     int? defaultBookId,
00022|     int? defaultPageId,
00023|     bool? isUrlValid,
00024|     String? translationProvider,
00025|   }) {
00026|     return Settings(
00027|       serverUrl: serverUrl ?? this.serverUrl,
00028|       defaultBookId: defaultBookId ?? this.defaultBookId,
00029|       defaultPageId: defaultPageId ?? this.defaultPageId,
00030|       isUrlValid: isUrlValid ?? this.isUrlValid,
00031|       translationProvider: translationProvider ?? this.translationProvider,
00032|     );
00033|   }
00034| 
00035|   factory Settings.defaultSettings() {
00036|     return const Settings(
00037|       serverUrl: 'http://localhost:5001',
00038|       defaultBookId: 18,
00039|       defaultPageId: 1,
00040|       isUrlValid: true,
00041|       translationProvider: 'local',
00042|     );
00043|   }
00044| 
00045|   bool isValidServerUrl(String url) {
00046|     try {
00047|       final uri = Uri.parse(url);
00048|       return uri.hasScheme &&
00049|           (uri.scheme == 'http' || uri.scheme == 'https') &&
00050|           uri.host.isNotEmpty;
00051|     } catch (_) {
00052|       return false;
00053|     }
00054|   }
00055| }
00056| 
00057| @immutable
00058| class ThemeSettings {
00059|   final Color accentLabelColor;
00060|   final Color accentButtonColor;
00061| 
00062|   const ThemeSettings({
00063|     this.accentLabelColor = const Color(0xFF1976D2),
00064|     this.accentButtonColor = const Color(0xFF6750A4),
00065|   });
00066| 
00067|   ThemeSettings copyWith({Color? accentLabelColor, Color? accentButtonColor}) {
00068|     return ThemeSettings(
00069|       accentLabelColor: accentLabelColor ?? this.accentLabelColor,
00070|       accentButtonColor: accentButtonColor ?? this.accentButtonColor,
00071|     );
00072|   }
00073| 
00074|   @override
00075|   bool operator ==(Object other) {
00076|     if (identical(this, other)) return true;
00077|     return other is ThemeSettings &&
00078|         other.accentLabelColor.hashCode == accentLabelColor.hashCode &&
00079|         other.accentButtonColor.hashCode == accentButtonColor.hashCode;
00080|   }
00081| 
00082|   @override
00083|   int get hashCode => accentLabelColor.hashCode ^ accentButtonColor.hashCode;
00084| 
00085|   static const ThemeSettings defaultSettings = ThemeSettings();
00086| }
00087| 

(End of file - total 87 lines)
</file>

**Tool Call: lib/features/settings/providers/settings_provider.dart**
Status: Completed

<file>
00001| import 'package:flutter/material.dart';
00002| import 'package:flutter_riverpod/flutter_riverpod.dart';
00003| import 'package:shared_preferences/shared_preferences.dart';
00004| import '../models/settings.dart';
00005| 
00006| typedef DrawerSettingsBuilder =
00007|     Widget Function(BuildContext context, WidgetRef ref);
00008| 
00009| class ViewDrawerSettings {
00010|   final Widget? settingsContent;
00011| 
00012|   const ViewDrawerSettings({this.settingsContent});
00013| 
00014|   const ViewDrawerSettings.none() : settingsContent = null;
00015| }
00016| 
00017| class SettingsNotifier extends Notifier<Settings> {
00018|   static const String _keyServerUrl = 'server_url';
00019|   static const String _keyBookId = 'default_book_id';
00020|   static const String _keyPageId = 'default_page_id';
00021|   static const String _keyTranslationProvider = 'translation_provider';
00022| 
00023|   @override
00024|   Settings build() {
00025|     _loadSettings();
00026|     return Settings.defaultSettings();
00027|   }
00028| 
00029|   Future<void> _loadSettings() async {
00030|     final prefs = await SharedPreferences.getInstance();
00031|     final serverUrl = prefs.getString(_keyServerUrl) ?? 'http://localhost:5001';
00032|     final bookId = prefs.getInt(_keyBookId) ?? 18;
00033|     final pageId = prefs.getInt(_keyPageId) ?? 1;
00034|     final translationProvider =
00035|         prefs.getString(_keyTranslationProvider) ?? 'local';
00036| 
00037|     state = Settings(
00038|       serverUrl: serverUrl,
00039|       defaultBookId: bookId,
00040|       defaultPageId: pageId,
00041|       isUrlValid: _isValidUrl(serverUrl),
00042|       translationProvider: translationProvider,
00043|     );
00044|   }
00045| 
00046|   Future<void> updateServerUrl(String url) async {
00047|     final isValid = _isValidUrl(url);
00048|     state = state.copyWith(serverUrl: url, isUrlValid: isValid);
00049| 
00050|     if (isValid) {
00051|       final prefs = await SharedPreferences.getInstance();
00052|       await prefs.setString(_keyServerUrl, url);
00053|     }
00054|   }
00055| 
00056|   Future<void> updateBookId(int bookId) async {
00057|     state = state.copyWith(defaultBookId: bookId);
00058| 
00059|     final prefs = await SharedPreferences.getInstance();
00060|     await prefs.setInt(_keyBookId, bookId);
00061|   }
00062| 
00063|   Future<void> updatePageId(int pageId) async {
00064|     state = state.copyWith(defaultPageId: pageId);
00065| 
00066|     final prefs = await SharedPreferences.getInstance();
00067|     await prefs.setInt(_keyPageId, pageId);
00068|   }
00069| 
00070|   Future<void> updateTranslationProvider(String provider) async {
00071|     state = state.copyWith(translationProvider: provider);
00072| 
00073|     final prefs = await SharedPreferences.getInstance();
00074|     await prefs.setString(_keyTranslationProvider, provider);
00075|   }
00076| 
00077|   bool _isValidUrl(String url) {
00078|     try {
00079|       final uri = Uri.parse(url);
00080|       return uri.hasScheme &&
00081|           (uri.scheme == 'http' || uri.scheme == 'https') &&
00082|           uri.host.isNotEmpty;
00083|     } catch (_) {
00084|       return false;
00085|     }
00086|   }
00087| 
00088|   void resetSettings() async {
00089|     final prefs = await SharedPreferences.getInstance();
00090|     await prefs.remove(_keyServerUrl);
00091|     await prefs.remove(_keyBookId);
00092|     await prefs.remove(_keyPageId);
00093|     await prefs.remove(_keyTranslationProvider);
00094| 
00095|     state = Settings.defaultSettings();
00096|   }
00097| }
00098| 
00099| final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(() {
00100|   return SettingsNotifier();
00101| });
00102| 
00103| class TermFormSettings {
00104|   final bool showRomanization;
00105|   final bool showTags;
00106| 
00107|   const TermFormSettings({this.showRomanization = true, this.showTags = true});
00108| 
00109|   TermFormSettings copyWith({bool? showRomanization, bool? showTags}) {
00110|     return TermFormSettings(
00111|       showRomanization: showRomanization ?? this.showRomanization,
00112|       showTags: showTags ?? this.showTags,
00113|     );
00114|   }
00115| 
00116|   static const TermFormSettings defaultSettings = TermFormSettings();
00117| }
00118| 
00119| class TermFormSettingsNotifier extends Notifier<TermFormSettings> {
00120|   static const String _keyShowRomanization = 'show_romanization';
00121|   static const String _keyShowTags = 'show_tags';
00122| 
00123|   @override
00124|   TermFormSettings build() {
00125|     _loadSettings();
00126|     return TermFormSettings.defaultSettings;
00127|   }
00128| 
00129|   Future<void> _loadSettings() async {
00130|     final prefs = await SharedPreferences.getInstance();
00131|     final showRomanization = prefs.getBool(_keyShowRomanization) ?? true;
00132|     final showTags = prefs.getBool(_keyShowTags) ?? true;
00133| 
00134|     state = TermFormSettings(
00135|       showRomanization: showRomanization,
00136|       showTags: showTags,
00137|     );
00138|   }
00139| 
00140|   Future<void> updateShowRomanization(bool show) async {
00141|     state = state.copyWith(showRomanization: show);
00142| 
00143|     final prefs = await SharedPreferences.getInstance();
00144|     await prefs.setBool(_keyShowRomanization, show);
00145|   }
00146| 
00147|   Future<void> updateShowTags(bool show) async {
00148|     state = state.copyWith(showTags: show);
00149| 
00150|     final prefs = await SharedPreferences.getInstance();
00151|     await prefs.setBool(_keyShowTags, show);
00152|   }
00153| }
00154| 
00155| final termFormSettingsProvider =
00156|     NotifierProvider<TermFormSettingsNotifier, TermFormSettings>(() {
00157|       return TermFormSettingsNotifier();
00158|     });
00159| 
00160| class TextFormattingSettings {
00161|   final double textSize;
00162|   final double lineSpacing;
00163|   final String fontFamily;
00164|   final FontWeight fontWeight;
00165|   final bool isItalic;
00166| 
00167|   const TextFormattingSettings({
00168|     this.textSize = 18.0,
00169|     this.lineSpacing = 1.5,
00170|     this.fontFamily = 'Roboto',
00171|     this.fontWeight = FontWeight.normal,
00172|     this.isItalic = false,
00173|   });
00174| 
00175|   TextFormattingSettings copyWith({
00176|     double? textSize,
00177|     double? lineSpacing,
00178|     String? fontFamily,
00179|     FontWeight? fontWeight,
00180|     bool? isItalic,
00181|   }) {
00182|     return TextFormattingSettings(
00183|       textSize: textSize ?? this.textSize,
00184|       lineSpacing: lineSpacing ?? this.lineSpacing,
00185|       fontFamily: fontFamily ?? this.fontFamily,
00186|       fontWeight: fontWeight ?? this.fontWeight,
00187|       isItalic: isItalic ?? this.isItalic,
00188|     );
00189|   }
00190| 
00191|   static const TextFormattingSettings defaultSettings =
00192|       TextFormattingSettings();
00193| }
00194| 
00195| class TextFormattingSettingsNotifier extends Notifier<TextFormattingSettings> {
00196|   static const String _keyTextSize = 'text_size';
00197|   static const String _keyLineSpacing = 'line_spacing';
00198|   static const String _keyFontFamily = 'font_family';
00199|   static const String _keyFontWeight = 'font_weight';
00200|   static const String _keyIsItalic = 'is_italic';
00201| 
00202|   @override
00203|   TextFormattingSettings build() {
00204|     _loadSettings();
00205|     return TextFormattingSettings.defaultSettings;
00206|   }
00207| 
00208|   Future<void> _loadSettings() async {
00209|     final prefs = await SharedPreferences.getInstance();
00210|     final textSize = prefs.getDouble(_keyTextSize) ?? 18.0;
00211|     final lineSpacing = prefs.getDouble(_keyLineSpacing) ?? 1.5;
00212|     final fontFamily = prefs.getString(_keyFontFamily) ?? 'Roboto';
00213|     final fontWeightIndex = prefs.getInt(_keyFontWeight) ?? 0;
00214|     final isItalic = prefs.getBool(_keyIsItalic) ?? false;
00215| 
00216|     final fontWeightMap = [
00217|       FontWeight.w200,
00218|       FontWeight.w300,
00219|       FontWeight.normal,
00220|       FontWeight.w500,
00221|       FontWeight.w600,
00222|       FontWeight.bold,
00223|       FontWeight.w800,
00224|     ];
00225| 
00226|     state = TextFormattingSettings(
00227|       textSize: textSize,
00228|       lineSpacing: lineSpacing,
00229|       fontFamily: fontFamily,
00230|       fontWeight:
00231|           fontWeightMap[fontWeightIndex.clamp(0, fontWeightMap.length - 1)],
00232|       isItalic: isItalic,
00233|     );
00234|   }
00235| 
00236|   Future<void> updateTextSize(double size) async {
00237|     state = state.copyWith(textSize: size);
00238| 
00239|     final prefs = await SharedPreferences.getInstance();
00240|     await prefs.setDouble(_keyTextSize, size);
00241|   }
00242| 
00243|   Future<void> updateLineSpacing(double spacing) async {
00244|     state = state.copyWith(lineSpacing: spacing);
00245| 
00246|     final prefs = await SharedPreferences.getInstance();
00247|     await prefs.setDouble(_keyLineSpacing, spacing);
00248|   }
00249| 
00250|   Future<void> updateFontFamily(String family) async {
00251|     state = state.copyWith(fontFamily: family);
00252| 
00253|     final prefs = await SharedPreferences.getInstance();
00254|     await prefs.setString(_keyFontFamily, family);
00255|   }
00256| 
00257|   Future<void> updateFontWeight(FontWeight weight) async {
00258|     state = state.copyWith(fontWeight: weight);
00259| 
00260|     final prefs = await SharedPreferences.getInstance();
00261|     final fontWeightMap = [
00262|       FontWeight.w200,
00263|       FontWeight.w300,
00264|       FontWeight.normal,
00265|       FontWeight.w500,
00266|       FontWeight.w600,
00267|       FontWeight.bold,
00268|       FontWeight.w800,
00269|     ];
00270|     final index = fontWeightMap.indexOf(weight);
00271|     if (index >= 0) {
00272|       await prefs.setInt(_keyFontWeight, index);
00273|     }
00274|   }
00275| 
00276|   Future<void> updateIsItalic(bool italic) async {
00277|     state = state.copyWith(isItalic: italic);
00278| 
00279|     final prefs = await SharedPreferences.getInstance();
00280|     await prefs.setBool(_keyIsItalic, italic);
00281|   }
00282| }
00283| 
00284| final textFormattingSettingsProvider =
00285|     NotifierProvider<TextFormattingSettingsNotifier, TextFormattingSettings>(
00286|       () {
00287|         return TextFormattingSettingsNotifier();
00288|       },
00289|     );
00290| 
00291| class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
00292|   static const String _keyAccentLabelColor = 'accent_label_color';
00293|   static const String _keyAccentButtonColor = 'accent_button_color';
00294| 
00295|   @override
00296|   ThemeSettings build() {
00297|     final initialSettings = ThemeSettings.defaultSettings;
00298|     _loadSettingsInBackground(initialSettings);
00299|     return initialSettings;
00300|   }
00301| 
00302|   void _loadSettingsInBackground(ThemeSettings currentSettings) async {
00303|     final prefs = await SharedPreferences.getInstance();
00304|     final accentLabelColorValue = prefs.getInt(_keyAccentLabelColor);
00305|     final accentButtonColorValue = prefs.getInt(_keyAccentButtonColor);
00306| 
00307|     final loadedSettings = ThemeSettings(
00308|       accentLabelColor: accentLabelColorValue != null
00309|           ? Color(accentLabelColorValue!)
00310|           : ThemeSettings.defaultSettings.accentLabelColor,
00311|       accentButtonColor: accentButtonColorValue != null
00312|           ? Color(accentButtonColorValue!)
00313|           : ThemeSettings.defaultSettings.accentButtonColor,
00314|     );
00315| 
00316|     if (loadedSettings.accentLabelColor.value !=
00317|             currentSettings.accentLabelColor.value ||
00318|         loadedSettings.accentButtonColor.value !=
00319|             currentSettings.accentButtonColor.value) {
00320|       state = loadedSettings;
00321|       print('DEBUG: Updated settings from storage: $loadedSettings');
00322|     }
00323|   }
00324| 
00325|   Future<void> updateAccentLabelColor(Color color) async {
00326|     print('DEBUG: updateAccentLabelColor called with color: $color');
00327|     state = state.copyWith(accentLabelColor: color);
00328|     final prefs = await SharedPreferences.getInstance();
00329|     await prefs.setInt(_keyAccentLabelColor, color.value);
00330|     print('DEBUG: Saved accentLabelColor.value = ${color.value}');
00331|   }
00332| 
00333|   Future<void> updateAccentButtonColor(Color color) async {
00334|     print('DEBUG: updateAccentButtonColor called with color: $color');
00335|     state = state.copyWith(accentButtonColor: color);
00336|     final prefs = await SharedPreferences.getInstance();
00337|     await prefs.setInt(_keyAccentButtonColor, color.value);
00338|     print('DEBUG: Saved accentButtonColor.value = ${color.value}');
00339|   }
00340| }
00341| 
00342| final themeSettingsProvider =
00343|     NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(() {
00344|       return ThemeSettingsNotifier();
00345|     });
00346| 
00347| class CurrentViewDrawerSettingsNotifier extends Notifier<Widget?> {
00348|   @override
00349|   Widget? build() => null;
00350| 
00351|   void updateSettings(Widget? settingsWidget) {
00352|     state = settingsWidget;
00353|   }
00354| }
00355| 
00356| final currentViewDrawerSettingsProvider =
00357|     NotifierProvider<CurrentViewDrawerSettingsNotifier, Widget?>(() {
00358|       return CurrentViewDrawerSettingsNotifier();
00359|     });
00360| 

(End of file - total 360 lines)
</file>

## Assistant

<thinking>
Now let me check the pubspec.yaml to see what dependencies are already in the project.
</thinking>

**Tool Call: pubspec.yaml**
Status: Completed

<file>
00001| name: lute_for_mobile
00002| description: "Mobile frontend for Lute v3 language learning server"
00003| # The following line prevents the package from being accidentally published to
00004| # pub.dev using `flutter pub publish`. This is preferred for private packages.
00005| publish_to: 'none' # Remove this line if you wish to publish to pub.dev
00006| 
00007| # The following defines the version and build number for your application.
00008| # A version number is three numbers separated by dots, like 1.2.43
00009| # followed by an optional build number separated by a +.
00010| # Both the version and the builder number may be overridden in flutter
00011| # build by specifying --build-name and --build-number, respectively.
00012| # In Android, build-name is used as versionName while build-number used as versionCode.
00013| # Read more about Android versioning at https://developer.android.com/studio/publish/versioning
00014| # In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
00015| # Read more about iOS versioning at
00016| # https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
00017| # In Windows, build-name is used as the major, minor, and patch parts
00018| # of the product and file versions while the build-number is used as the build suffix.
00019| version: 1.0.0+1
00020| 
00021| environment:
00022|   sdk: ^3.10.0
00023| 
00024| # Dependencies specify other packages that your package needs in order to work.
00025| # To automatically upgrade your package dependencies to latest versions
00026| # consider running `flutter pub upgrade --major-versions`. Alternatively,
00027| # dependencies can be manually updated by changing the version numbers below to
00028| # the latest version available on pub.dev. To see which dependencies have newer
00029| # versions available, run `flutter pub outdated`.
00030| dependencies:
00031|   flutter:
00032|     sdk: flutter
00033| 
00034|   # The following adds the Cupertino Icons font to your application.
00035|   # Use with the CupertinoIcons class for iOS style icons.
00036|   cupertino_icons: ^1.0.8
00037| 
00038|   # Core Packages
00039|   meta: ^1.15.0
00040|   dio: ^5.9.0
00041|   flutter_riverpod: ^3.0.3
00042|   shared_preferences: ^2.2.3
00043|   go_router: ^17.0.1
00044|   get_it: ^9.2.0
00045| 
00046|   # UI/UX Packages
00047|   cached_network_image: ^3.3.1
00048| 
00049|   # Reader-Specific Packages
00050|   flutter_tts: ^4.0.2
00051| 
00052|   # AI Integration
00053|   openai_dart: ^0.6.2
00054| 
00055|   # Charts/Statistics
00056|   fl_chart: ^1.1.1
00057| 
00058|   # Storage & Database
00059|   hive_ce: ^2.15.1
00060|   hive_ce_flutter: ^2.3.2
00061| 
00062|   # Network & Utilities
00063|   connectivity_plus: ^6.0.3
00064|   url_launcher: ^6.3.1
00065|   flutter_inappwebview: ^6.1.5
00066|   html: ^0.15.5
00067| 
00068| dev_dependencies:
00069|   flutter_test:
00070|     sdk: flutter
00071| 
00072|   # The "flutter_lints" package below contains a set of recommended lints to
00073|   # encourage good coding practices. The lint set provided by the package is
00074|   # activated in the `analysis_options.yaml` file located at the root of your
00075|   # package. See that file for information about deactivating specific lint
00076|   # rules and activating additional ones.
00077|   flutter_lints: ^5.0.0
00078| 
00079|   # Development Tools
00080|   build_runner: ^2.4.0
00081|   mocktail: ^1.0.0
00082| 
00083| # For information on the generic Dart part of this file, see the
00084| # following page: https://dart.dev/tools/pub/pubspec
00085| 
00086| # The following section is specific to Flutter packages.
00087| flutter:
00088| 
00089|   # The following line ensures that the Material Icons font is
00090|   # included with your application, so that you can use the icons in
00091|   # the material Icons class.
00092|   uses-material-design: true
00093| 
00094|   # To add assets to your application, add an assets section, like this:
00095|   assets:
00096|     - assets/images/
00097| 
00098|   # An image asset can refer to one or more resolution-specific "variants", see
00099|   # https://flutter.dev/to/resolution-aware-images
00100| 
00101|   # For details regarding adding assets from package dependencies, see
00102|   # https://flutter.dev/to/asset-from-package
00103| 
00104|   # To add custom fonts to your application, add a fonts section here,
00105|   # in this "flutter" section. Each entry in this list should have a
00106|   # "family" key with the font family name, and a "fonts" key with a
00107|   # list giving the asset and other descriptors for the font. For
00108|   # example:
00109|   # fonts:
00110|   #   - family: Schyler
00111|   #     fonts:
00112|   #       - asset: fonts/Schyler-Regular.ttf
00113|   #       - asset: fonts/Schyler-Italic.ttf
00114|   #         style: italic
00115|    #   - family: Trajan Pro
00116|    #     fonts:
00117|    #       - asset: fonts/TrajanPro.ttf
00118|    #       - asset: fonts/TrajanPro_Bold.ttf
00119|    #         weight: 700
00120|    #
00121| 
00122|   fonts:
00123|     - family: AtkinsonHyperlegibleNext
00124|       fonts:
00125|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-Regular.otf
00126|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-RegularItalic.otf
00127|           style: italic
00128|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-Bold.otf
00129|           weight: 700
00130|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-BoldItalic.otf
00131|           weight: 700
00132|           style: italic
00133|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-ExtraLight.otf
00134|           weight: 200
00135|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-ExtraLightItalic.otf
00136|           weight: 200
00137|           style: italic
00138|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-Light.otf
00139|           weight: 300
00140|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-LightItalic.otf
00141|           weight: 300
00142|           style: italic
00143|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-Medium.otf
00144|           weight: 500
00145|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-MediumItalic.otf
00146|           weight: 500
00147|           style: italic
00148|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-SemiBold.otf
00149|           weight: 600
00150|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-SemiBoldItalic.otf
00151|           weight: 600
00152|           style: italic
00153|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-ExtraBold.otf
00154|           weight: 800
00155|         - asset: assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-ExtraBoldItalic.otf
00156|           weight: 800
00157|           style: italic
00158| 
00159|     - family: Vollkorn
00160|       fonts:
00161|         - asset: assets/fonts/VollkornPS/Vollkorn-Regular.otf
00162|         - asset: assets/fonts/VollkornPS/Vollkorn-Italic.otf
00163|           style: italic
00164|         - asset: assets/fonts/VollkornPS/Vollkorn-Bold.otf
00165|           weight: 700
00166|         - asset: assets/fonts/VollkornPS/Vollkorn-BoldItalic.otf
00167|           weight: 700
00168|           style: italic
00169|         - asset: assets/fonts/VollkornPS/Vollkorn-Medium.otf
00170|         - asset: assets/fonts/VollkornPS/Vollkorn-MediumItalic.otf
00171|           weight: 500
00172|           style: italic
00173|         - asset: assets/fonts/VollkornPS/Vollkorn-SemiBold.otf
00174|           weight: 600
00175|         - asset: assets/fonts/VollkornPS/Vollkorn-SemiBoldItalic.otf
00176|           weight: 600
00177|           style: italic
00178|         - asset: assets/fonts/VollkornPS/Vollkorn-Black.otf
00179|           weight: 900
00180|         - asset: assets/fonts/VollkornPS/Vollkorn-BlackItalic.otf
00181|           weight: 900
00182|           style: italic
00183| 
00184|     - family: LinBiolinum
00185|       fonts:
00186|         - asset: assets/fonts/linux-biolinum/LinBiolinum_R.otf
00187|         - asset: assets/fonts/linux-biolinum/LinBiolinum_RI.otf
00188|           style: italic
00189|         - asset: assets/fonts/linux-biolinum/LinBiolinum_RB.otf
00190|           weight: 700
00191| 
00192|     - family: Literata
00193|       fonts:
00194|         - asset: assets/fonts/literata/Literata-Regular.ttf
00195|         - asset: assets/fonts/literata/Literata-Italic.ttf
00196|           style: italic
00197|         - asset: assets/fonts/literata/Literata-Medium.ttf
00198|           weight: 500
00199|         - asset: assets/fonts/literata/Literata-MediumItalic.ttf
00200|           weight: 500
00201|           style: italic
00202|         - asset: assets/fonts/literata/Literata-SemiBold.ttf
00203|           weight: 600
00204|         - asset: assets/fonts/literata/Literata-SemiBoldItalic.ttf
00205|           weight: 600
00206|           style: italic
00207|         - asset: assets/fonts/literata/Literata-Bold.ttf
00208|           weight: 700
00209|         - asset: assets/fonts/literata/Literata-BoldItalic.ttf
00210|           weight: 700
00211|           style: italic
00212|   # For details regarding fonts from package dependencies,
00213|   # see https://flutter.dev/to/font-from-package
00214| 

(End of file - total 214 lines)
</file>

## Assistant

<thinking>
Great! Now I have enough context to provide a comprehensive review of Phase 5.2. Let me analyze:

1. **Phase 5.2 Overview**:
   - Goal: Add web dictionary functionality to enhance term and sentence translations
   - Features:
     - Web dictionary for terms (url_launcher integration)
     - Web dictionary for sentences (external translation services)
     - Enhanced translation features (web dictionary links in popups, configurable settings)

2. **Current Implementation**:
   - url_launcher: ^6.3.1 is already in pubspec.yaml ✅
   - flutter_inappwebview: ^6.1.5 is already in pubspec.yaml ✅
   - TermForm model already has a `dictionaries` field (List<String>) ✅
   - TermFormWidget already displays dictionaries as chips ✅
   - Settings infrastructure is already in place with Riverpod providers ✅
   - No dedicated dictionary settings yet ⚠️

3. **What's Missing**:
   - Dictionary settings in Settings model
   - Dictionary service abstraction layer
   - Integration of url_launcher in TermFormWidget
   - Integration of web dictionary in sentence translation popup
   - URL configuration for different dictionary sources
   - Per-language dictionary settings (may need to be stored in Lute server)

4. **Technical Considerations**:
   - The Lute v3 server likely has per-language dictionary configurations
   - Need to fetch dictionary URLs from server or configure locally
   - Multiple dictionary support (terms and sentences)
   - url_launcher for external browser opening
   - flutter_inappwebview for in-app dictionary browsing (optional)

5. **Potential Issues**:
   - No explicit dictionary URL configuration in current settings
   - Need to determine dictionary URL patterns (e.g., word reference, DeepL for sentences)
   - Should handle language-specific dictionary mappings
   
The implementation involves strategic architectural improvements. Key focus areas include creating a flexible dictionary service that supports multiple languages and sources. The proposed approach requires careful integration with existing TermForm and settings infrastructure, ensuring seamless web dictionary functionality without disrupting current app design.

Critical considerations revolve around developing an abstraction layer that can dynamically handle different dictionary services, supporting both term-level and sentence-level translations while maintaining a clean, modular code structure.
</thinking>

## Phase 5.2 Review: Web Dictionary Integration

### Overview
Phase 5.2 aims to add web dictionary functionality for terms and sentences using `url_launcher` and `flutter_inappwebview`.

### Current State Analysis

**✅ Already in Place:**
- `url_launcher: ^6.3.1` - in pubspec.yaml
- `flutter_inappwebview: ^6.1.5` - in pubspec.yaml  
- TermForm model with `dictionaries` field (List<String>)
- TermFormWidget displays dictionaries as chips (lines 321-345)
- Riverpod settings infrastructure

**⚠️ Missing Components:**
- Dictionary settings in Settings model
- Dictionary service/abstraction layer
- Actual URL launching in UI components
- Dictionary URL configuration per language
- Integration in sentence translation popup

### Key Issues & Questions

1. **Dictionary URL Source** - Where do dictionary URLs come from?
   - From Lute server per-language settings?
   - Local app configuration?
   - Both with server as primary?

2. **Dictionary Pattern Structure** - How are URLs constructed?
   - Examples: `https://dict.cc/?s={term}`, `https://deepl.com/translate?text={sentence}`
   - Need URL template support

3. **Per-Language vs Global Settings** - Lute supports multiple languages
   - Dictionary URLs should be language-specific
   - Server may already have this data

4. **UI Integration Points**
   - TermForm: Add tap gesture to dictionary chips (line 337)
   - Sentence Translation: Add web dictionary button/link
   - Settings: Add dictionary configuration UI

### Recommendations

**Add to Settings Model:**
```dart
class DictionarySettings {
  final Map<String, String> termDictionaryUrls;  // languageId -> URL pattern
  final Map<String, String> sentenceDictionaryUrls;
  final bool useInAppWebView;
}
```

**Create Dictionary Service:**
```dart
class DictionaryService {
  String buildTermUrl(String term, int languageId);
  String buildSentenceUrl(String sentence, int languageId);
  Future<void> launchTerm(String term, int languageId);
  Future<void> launchSentence(String sentence, int languageId);
}
```

**UI Changes Needed:**
- Make dictionary chips in TermFormWidget tappable
- Add web dictionary button to sentence translation widget
- Add dictionary settings to settings screen

### API Integration
Consider these Lute endpoints (from luteendpoints.md):
- `GET /language/edit/<int:langid>` - May contain dictionary settings
- Language objects may have dictionary URL patterns

### Summary
Phase 5.2 is well-planned but needs:
1. Dictionary service layer
2. Settings model updates for dictionary URLs
3. UI integration (tappable dictionary chips, sentence translation links)
4. Clarification on dictionary URL source (server vs local)
5. URL template pattern support

The existing infrastructure is solid - just needs the glue to connect dictionary data with URL launching functionality.

## User

To be clear about these dictionaries. They are just websites that are dictionaries that we will navigate to so the user can copy text and then they close. Do you understand? no coding yet

## Assistant

<thinking>
Yes, I understand now. Let me clarify:

1. The dictionaries are just external websites (web dictionaries) that the user will navigate to
2. The user can look up terms or sentences on these websites
3. The user can copy text from the website if they want
4. Then they close the website/browser and return to the app

So the integration is much simpler than I was thinking:
- Just launch a URL using url_launcher (or flutter_inappwebview for in-app browsing)
- The URL is constructed by replacing a placeholder in a URL template with the actual term/sentence
- No need to parse responses or integrate deeply
- No need for complex API integration

It's basically:
1. User taps on a dictionary chip or "lookup in dictionary" button
2. App constructs URL like `https://dict.cc/?s=hola` (where {term} is replaced with the actual term)
3. App opens that URL (either in external browser or in-app webview)
4. User looks up the word, copies if they want
5. User closes browser/webview
6. User returns to the app

So the dictionary service would be very simple - just URL construction and launching.

The dictionary URLs would be configured per language, probably in settings, either locally or fetched from the server.

This is much simpler than my initial analysis. Let me confirm I understand correctly.
</thinking>

Yes, I understand. The dictionaries are just external dictionary websites that:

1. User navigates to via a URL (like `https://spanishdict.com/translate/{term}`)
2. User looks up the term/sentence on the website
3. User can copy text if they want
4. User closes the website and returns to the app

So it's simple URL launching - no API integration, no parsing responses, no bidirectional communication. Just:
- Construct URL from template (e.g., `https://dictionary.com/browse/{term}`)
- Launch it with `url_launcher` or `flutter_inappwebview`
- User uses the website like normal
- User closes and returns

The "configuration" is just storing URL templates per language, like:
- Spanish: `https://spanishdict.com/translate/{term}`
- French: `https://wordreference.com/fren/{term}`
- Sentence: `https://deepl.com/translator?text={sentence}`

Is that correct?

## User

Yes! I want us to pull in URLs from the server language settings. At a later time we will add our own proper settings but not now. no coding

## Assistant

<thinking>
The user wants to:
1. Pull dictionary URLs from the Lute server's language settings
2. NOT add local dictionary configuration settings yet (that's for later)
3. Just use what the server provides

So the architecture for Phase 5.2 should be:
- Fetch language settings from server (likely the `/language/edit/<langid>` endpoint or similar)
- Extract dictionary URLs from language data
- Use those URLs to build term/sentence dictionary links
- Launch the URLs when user taps on dictionary chips or translation popups

No local settings for dictionaries - server is the source of truth.

I understand - no coding, just confirming the approach.
</thinking>

Got it. So for Phase 5.2:

**Dictionary URL Source:**
- Pull from Lute server language settings only
- Server is the source of truth
- No local dictionary configuration in the app yet

**Implementation Approach:**
- Fetch language settings from Lute server endpoint
- Extract dictionary URL templates from language data
- Use those server-provided URLs to launch external dictionary websites
- When user taps a dictionary chip → launch the URL → user uses the website → user closes → back to app

**Later Phase (not 5.2):**
- Add local app settings for custom dictionary URLs
- Full dictionary management UI

So Phase 5.2 is about integrating what the server already provides, not building configuration UI yet. Correct?

## User (checkpoint)

I want to add a search button(magnify glass icon?) to the right side of the translation textbox in the termform. That is what will activate the dictionary view. Please up date [@phaseplan.md](file:///home/cody/LuteForMobile/phaseplan.md) with this info we are clear in what we want to do. no coding

## Assistant

<thinking>
The user wants me to update the phaseplan.md file to reflect the specific approach for Phase 5.2: Web Dictionary Integration. Key points to add:

1. Dictionary URLs are pulled from Lute server language settings (not local app settings yet)
2. Add a search button (magnifying glass icon) to the right side of the translation textbox in term form
3. This search button activates the dictionary view
4. The dictionary view is just launching external dictionary websites
5. User navigates to the website, copies text if needed, closes and returns

I need to read the Phase 5.2 section first to see what's there, then update it with the specific implementation details.
</thinking>

**Tool Call: phaseplan.md**
Status: Completed

<file>
00554| 
00555| ### Goal
00556| Add web dictionary functionality to enhance term and sentence translations.
00557| 
00558| ### Features
00559| 
00560| #### Web Dictionary for Terms
00561| - Web dictionary integration (url_launcher) for term forms
00562| - Support for multiple dictionary sources
00563| - Configurable dictionary preferences
00564| 
00565| #### Web Dictionary for Sentences
00566| - Integration with web dictionary for sentence translations
00567| - Support for translation services
00568| - External translation provider options
00569| 
00570| #### Enhanced Translation Features
00571| - Web dictionary links in translation popups
00572| - User-configurable web dictionary settings
00573| - Dictionary source management
00574| 
00575| ### Technical Implementation
00576| - Web dictionary integration (url_launcher)
00577| - Dictionary service abstraction layer
00578| - Configuration management for dictionary sources
00579| - Enhanced translation components with web support
00580| 
00581| ### Deliverables
00582| - [ ] Web dictionary integration for terms
00583| - [ ] Web dictionary integration for sentences
00584| - [ ] Dictionary configuration settings
00585| - [ ] Enhanced translation components with web support
00586| 
00587| ---
00588| 
00589| ## Phase 6: TTS Integration
00590| 
00591| ### Goal
00592| Add text-to-speech functionality to the reader.
00593| 
00594| ### Features
00595| 
00596| #### TTS Player
00597| - Play/pause/stop controls
00598| - Sentence-level playback
00599| - Playback highlighting
00600| - Speed controls
00601| 
00602| #### TTS Provider
00603| - Native TTS implementation (flutter_tts)

(File has more lines. Use 'offset' parameter to read beyond line 603)
</file>

## Assistant

<thinking>
Now I need to update the Phase 5.2 section to reflect the specific requirements:

1. Goal - web dictionary functionality
2. Features should be updated to:
   - Web Dictionary for Terms: Add search button (magnifying glass icon) to translation textbox in term form, URLs pulled from server language settings
   - Web Dictionary for Sentences: Similar integration
   - External website navigation (user copies text, closes, returns)

3. Technical Implementation should mention:
   - Fetch dictionary URL templates from Lute server language settings
   - url_launcher or flutter_inappwebview for navigation
   - Search button in term form translation field
   - URL construction from templates

Let me update this section.
</thinking>

**Tool Call: phaseplan.md**
Status: Completed



Diff: /home/cody/LuteForMobile/phaseplan.md
```
### Goal
Add web dictionary functionality to enhance term and sentence translations by launching external dictionary websites.

### Features

#### Web Dictionary for Terms
- Search button (magnifying glass icon) in translation textbox of term form
- Dictionary URL templates pulled from Lute server language settings (server is source of truth)
- Launch external dictionary websites using url_launcher or flutter_inappwebview
- User navigates to website, can copy text, closes and returns to app
- Support for multiple dictionary URLs per language

#### Web Dictionary for Sentences
- Search button in sentence translation popup
- Dictionary URL templates from Lute server language settings
- Launch external translation/dictionary websites
- User workflow: navigate → lookup → copy → close → return

#### External Website Integration
- No API integration, no response parsing
- Simple URL launching with term/sentence substitution
- Use flutter_inappwebview for in-app browser or url_launcher for external browser

### Technical Implementation
- Fetch language settings from Lute server to extract dictionary URL templates
- Dictionary service for URL construction (substitute {term} or {sentence} placeholders)
- Add search button widget to translation field in TermFormWidget
- Add search button to SentenceTranslationWidget
- url_launcher/flutter_inappwebview integration for website navigation
- URL pattern: dictionary URL from server with {term} or {sentence} replacement

### Deliverables
- [ ] Search button (magnifying glass icon) in term form translation field
- [ ] Fetch dictionary URL templates from Lute server language settings
- [ ] Dictionary service for URL construction and launching
- [ ] Launch external dictionary websites for terms
- [ ] Search button in sentence translation popup
- [ ] Launch external dictionary/translation websites for sentences
```


## Assistant

<thinking>
Good, I've updated the Phase 5.2 section to reflect the specific requirements. Now let me provide a summary of what was updated.
</thinking>

Updated Phase 5.2 in phaseplan.md with:

**Key Changes:**
- **Goal**: Clarified "launching external dictionary websites" (not API integration)
- **Web Dictionary for Terms**: Added "Search button (magnifying glass icon) in translation textbox", specified "URL templates pulled from Lute server language settings", described user workflow
- **Web Dictionary for Sentences**: Added search button to sentence translation popup with same server-based approach
- **External Website Integration**: Added section clarifying no API integration, simple URL launching with placeholder substitution
- **Technical Implementation**: Updated to fetch URL templates from server, add search buttons to widgets, use url_launcher/flutter_inappwebview
- **Deliverables**: Updated with specific tasks (search button, fetch templates, service, launching for terms and sentences)

The plan now clearly reflects: server provides URL templates → search button in UI → launch external website → user uses website → user returns.

## User

Now lets talk about how i want this to look. I want this to open up IN the termform. I want this dictionary view to open up between the translation textbox and the status buttons and then expand the termform to the top of the screen. We should also toggle any view toggles to off to expand further (currently we have only 'tabs') and then we need to make sure to re toggle(restore) any toggles that we shut off and shrink back down to the normal termform with no changes made. Does this make sense? no coding

## Assistant

<thinking>
The user wants me to understand the UI behavior for the dictionary view. Let me break down what they're describing:

1. **Search button click** → Open dictionary view **inside** the TermForm (not a separate page or modal)

2. **Dictionary view position**: Should appear **between** the translation textbox and the status buttons

3. **TermForm expansion**: When dictionary opens, the TermForm should expand to the **top of the screen**

4. **View toggles**: Currently there are "tabs" (I need to understand what these are - maybe a tabs view toggle?)

5. **Turn off toggles**: When dictionary opens, turn off any view toggles to expand the view further

6. **Restore state**: When dictionary closes, restore any toggles that were turned off and shrink back down to normal TermForm with no changes

So the flow is:
1. Normal TermForm (compact size)
2. User clicks search button in translation field
3. Dictionary view appears between translation and status buttons
4. TermForm expands to top of screen
5. Any view toggles (like tabs) are turned off to maximize space
6. Dictionary shows the external website
7. User closes dictionary
8. TermForm shrinks back to normal size
9. Toggles are restored to their previous state

This is asking about the UI/UX behavior. The user wants to understand if this makes sense before I start planning the implementation.

Let me think about this more carefully:
- The TermForm is currently a bottom sheet/modal that slides up from the bottom
- It has a header, translation field, status buttons, romanization field (if shown), tags field (if shown), dictionaries section, parents section, and buttons at the bottom
- The search button will be in the translation field (on the right side)

When dictionary opens:
- It should appear between translation field and status buttons
- The TermForm should expand to fill more of the screen (maybe to top?)
- Any "view toggles" like a tabs view should be turned off to maximize space
- Then restore everything when closed

Wait, I'm a bit confused about "view toggles" and "tabs". The user mentioned "currently we have only 'tabs'". 

I'll explore what this "tabs" view might mean in the current reader implementation. It could be a specific UI toggle or view switcher that's currently present in the reader interface. I need to investigate its purpose and how it interacts with the TermForm to fully understand the proposed dictionary view behavior.
</thinking>

Yes, I understand the UX you're describing! Let me clarify the flow:

**Normal State:**
- TermForm shows compact bottom sheet with all fields visible
- Translation field has search button on the right (magnifying glass)

**Dictionary Opens:**
1. User taps search button in translation field
2. Dictionary view slides/opens **between** translation field and status buttons
3. TermForm expands upward to **top of screen** (maximize vertical space)
4. Any view toggles (like "tabs" view) are **temporarily turned off** to give more room
5. External dictionary website displays in the expanded space

**Dictionary Closes:**
1. User closes dictionary view
2. TermForm shrinks back to **normal size**
3. View toggles are **restored** to their previous state
4. TermForm returns to normal appearance with **no changes**

**Question about "tabs" toggle:**
When you mention "currently we have only 'tabs'", are you referring to a view toggle in the reader that switches between different views? I want to make sure I understand what toggles need to be turned off/restored before planning the implementation.

Is this the flow you have in mind?

## User

Sorry, that was a typo. I meant to say 'Tags'. Otherwise yes this is exactly what i want!

## Assistant

<thinking>
Good, the user confirmed it's "Tags" not "tabs". They want the Tags field to be temporarily hidden when dictionary view opens.

Now I have a clear understanding:

1. **Normal State**: TermForm shows with all fields including Tags
2. **Dictionary Opens**: 
   - Dictionary view slides in between translation field and status buttons
   - TermForm expands to top of screen
   - Tags field (and potentially other visible fields) temporarily hidden to maximize space
   - External dictionary website displays in the expanded space
3. **Dictionary Closes**:
   - TermForm shrinks back to normal
   - Tags field (and other toggles) restored to previous state
   - No changes to term form data

This is a good UX pattern. Now I should ask clarifying questions about implementation details before presenting a plan.

Key questions to ask:
1. Should the dictionary view use InAppWebView (in-app browser) or launch external browser?
2. What fields should be hidden? Just Tags, or all optional fields (Romanization, Parents, Dictionaries, Tags)?
3. Should there be a "Close" button for the dictionary view, or does the in-app browser have its own close controls?
4. Should the animation be smooth/slide or just appear/disappear?
5. Should we show a loading state while fetching dictionary URL from server?

Let me ask these questions before presenting the full plan.
</thinking>

Perfect! Got it - "Tags" field will be temporarily hidden when dictionary view opens.

Let me ask a few clarifying questions to make sure I have all details before presenting the implementation plan:

**Questions:**

1. **Browser choice**: Should the dictionary view use `flutter_inappwebview` (in-app browser embedded in the termform) or `url_launcher` (opens external browser app)?

2. **Fields to hide**: When dictionary opens, should we hide just the Tags field, or all optional fields to maximize space (Tags, Romanization, Parents, Dictionaries)?

3. **Closing the dictionary**: If using in-app webview, should there be a "Close" button at the top, or does the browser provide its own close mechanism?

4. **Animation**: Should the dictionary view slide in smoothly, or just appear/disappear?

5. **Loading state**: While fetching dictionary URL from server, should we show a loading indicator in the search button area?

6. **Search behavior**: When user taps search, does it:
   - Always open the dictionary (even if empty)?
   - Only open if translation field has text?
   - Search the term text or the current translation text?

These will help me create a precise implementation plan for you!

## User

1- in app browser. 2- hide all fields except 'Parents', dictionaries should NOT be a seperate field. 3- I think that we should show the open button (magnifiying glass icon) as being clearly highlighted and use that to open/close the dictionary. 4- slide in smoothly , but also fairly quickly. 5- What search button area are you referring? 6- always open. This is based on the term name and should (using dictionary links) open to the correct page.

We should add either little tabs or arrows to navigate between dictionary options so that we can see all available dictionaries

## Assistant

<thinking>
Now I have all the details. Let me summarize the UX flow and then create a comprehensive implementation plan.

**UX Flow Summary:**

1. **Normal State**:
   - TermForm shows as compact bottom sheet
   - Translation field with search button (magnifying glass) on the right
   - All fields visible (translation, status, romanization, tags, parents, dictionaries as chips)

2. **Dictionary Opens**:
   - User taps search button in translation field
   - Dictionary view slides in smoothly between translation field and status buttons
   - TermForm expands to top of screen
   - Hide: translation field (maybe keep visible above dictionary?), status buttons, romanization, tags, parents chips
   - Keep: Term header, maybe translation field above dictionary
   - Search button becomes highlighted to indicate active state
   - Same button can be tapped to close dictionary
   - Tabs/arrows appear to navigate between multiple dictionary options
   - Dictionary displays in in-app webview
   - Dictionary URL constructed from term name using server-provided templates

3. **Dictionary Closes**:
   - User taps highlighted search button
   - Dictionary view slides down smoothly
   - TermForm shrinks back to normal size
   - All fields restored to previous state

**Technical Details:**
- Use flutter_inappwebview for embedded browser
- Fetch dictionary URL templates from Lute server language settings
- Construct URL by substituting {term} placeholder with term name
- Navigate between dictionaries using tabs or arrow buttons
- Search based on term name (term text), not translation text

**Questions to clarify:**
1. Should the translation field remain visible above the dictionary, or should it be hidden too?
2. When navigating between dictionaries, should it reload the webview or have multiple webviews?
3. Should the dictionary header show the current dictionary name/URL?

Let me ask these questions and then create the implementation plan.
</thinking>

Excellent! I have a clear picture now. Let me ask a couple final clarifying questions to complete the plan:

**Final Questions:**

1. **Translation field visibility**: When dictionary opens, should the translation field:
   - Remain visible above the dictionary (so user can see the term text)?
   - Be hidden along with other fields?

2. **Dictionary navigation**: When user navigates between dictionaries using tabs/arrows, should it:
   - Reload the same webview with new URL?
   - Have multiple webviews (one per dictionary) and switch between them?

3. **Dictionary header**: In the dictionary view, should we show:
   - Just the webview (clean look)?
   - A header showing which dictionary is currently selected?

4. **Search button highlight**: When dictionary is open, the search button should be highlighted - are you thinking:
   - Color change (e.g., turns blue/accent color)?
   - Background fill instead of just icon?
   - Icon change (e.g., opens to close icon)?

Once you answer these, I'll present the complete implementation plan!

## User

1- we need the translation field visible so that we can type in the trasnlation. we also need to leave the title so that we can see the term and we should leave the parnets as well. 2- this depends on speed, I would think having multiple webviews would be faster and we could cache them as we swap between them. 3- If we use tabs we should ahve the name there and don't need a header. if we using something like arrows or swiping than we should add a view narrow header. 4- lets for know use the accent color change

## Assistant

<thinking>
Perfect! The user has given me all the details I need. Now I have a complete picture:

**Visible fields when dictionary opens:**
- Title (term name)
- Translation field
- Parents section
- Dictionary view (inserted between translation and status buttons)

**Hidden fields when dictionary opens:**
- Tags
- Romanization
- Dictionaries (this is NOT a separate field)

**Dictionary navigation approach:**
- Multiple webviews cached for speed
- Switch between them using tabs or arrows
- Tabs show dictionary name (no extra header needed)
- Arrows/swiping would need narrow header

**Search button state:**
- Highlight with accent color when open
- Same icon (magnifying glass), just color change
- Button serves as toggle (open/close)

**Behavior:**
- Always opens when tapped
- Searches based on term name (not translation text)
- Uses dictionary links from server to open to correct page
- Slide in quickly

**Now I need to create a comprehensive implementation plan. Let me structure it properly:**

1. Data Models Updates
2. Service Layer
3. Widget Changes
4. State Management
5. Animation & UI Flow

I should present this plan clearly to the user without any coding, just the architectural approach and component breakdown.
</thinking>

Perfect! I have all the details now. Let me present the complete implementation plan:

## Phase 5.2 Implementation Plan

### Architecture Overview

**Phase 5.2 Components:**

1. **Data Layer**
   - Fetch dictionary URL templates from Lute server language settings
   - Store per-language dictionary list with names and URL patterns

2. **Service Layer**
   - `DictionaryService` - Constructs URLs by substituting `{term}` placeholder
   - Manages webview instances (one per dictionary, cached)
   - Handles webview lifecycle (create/destroy/cache)

3. **Widget Changes**
   - **TermFormWidget**: 
     - Add search button (magnifying glass) to translation field
     - Insert `DictionaryView` between translation field and status buttons
     - Animate termform expansion to top of screen
     - Hide Tags, Romanization, Dictionaries chip section (NOT separate field)
     - Keep visible: Title, Translation field, Parents
     - Toggle view state (expanded/collapsed)
   
   - **DictionaryView**:
     - Multiple cached webviews (one per dictionary)
     - Tab navigation OR arrow/swipe navigation between dictionaries
     - Smooth slide-in animation (quick)
     - Shows dictionary name in tab labels
     - If using arrows: narrow header showing current dictionary name

4. **State Management**
   - Track dictionary view state (open/closed)
   - Store which webviews are created and cached
   - Remember current active dictionary
   - Restore hidden field states when closing

### Implementation Flow

**Opening Dictionary:**
1. User taps search button → termform state changes to "expanded"
2. Termform animates upward to top of screen
3. Tags, Romanization, Dictionaries chips → hidden
4. DictionaryView slides in between translation field and status buttons
5. Search button highlights with accent color
6. DictionaryService loads/caches webviews for all dictionaries
7. First dictionary webview loads with term name substituted

**Switching Dictionaries:**
1. User taps tab OR swipes/arrows to switch
2. Switch to pre-cached webview (instant)
3. Show current dictionary name in tab label

**Closing Dictionary:**
1. User taps search button (now accent colored)
2. DictionaryView slides out quickly
3. Termform shrinks back to normal size
4. Tags, Romanization, Dictionaries chips → restored to previous state
5. Webviews remain cached (don't destroy - for next open)

### Key Technical Decisions

**WebView Management:**
- One webview per dictionary, created on first open
- Kept in memory (cached) for fast switching
- URL pattern: server provides template like `https://spanishdict.com/translate/{term}`
- Substitution: DictionaryService replaces `{term}` with actual term name

**Animation Strategy:**
- Use `AnimatedSize` or `AnimatedContainer` for termform expansion
- Slide-in with `SlideTransition` for DictionaryView
- Duration: 200-300ms (quick but smooth)

**State Restoration:**
- Before opening: save which optional fields were visible (Tags, Romanization)
- Before closing: restore to saved visibility states
- Default: restore all fields to visible (current behavior)

### Navigation Choice Question

**Final decision needed:**
Should dictionary navigation use:
- **Tabs** (horizontal chips with dictionary names across top of dictionary view)?
  - Pros: Clear labels, easy to tap
  - Cons: Takes horizontal space
- **Arrows + narrow header** (left/right arrows with "Current Dictionary Name" header)?
  - Pros: More vertical space, cleaner
  - Cons: Less discoverable, more taps to see all options

**Or should we support both?** (Tabs when space allows, arrows fallback for many dictionaries)

Which approach do you prefer?

## User

Lets use swiping and a narrow header. If users have issues we can maybe add arrows. I have a questuoin, what is this? - Dictionaries chip section -

## Assistant

<thinking>
The user is asking about what "Dictionaries chip section" is. They also confirmed they want swiping with a narrow header for dictionary navigation.

Looking back at the current TermFormWidget code (which I read earlier), I can see there is a `_buildDictionariesSection` method around lines 321-345 that displays dictionaries as chips:

```dart
Widget _buildDictionariesSection(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Dictionaries',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.customColors.accentLabelColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.termForm.dictionaries.map((dict) {
          return Chip(
            label: Text(dict),
            avatar: const Icon(Icons.book, size: 18),
          );
        }).toList(),
      ),
    ],
  );
}
```

This displays a list of dictionaries from `widget.termForm.dictionaries` as chips with book icons.

In my implementation plan, I mentioned hiding "Dictionaries chip section" when the dictionary view opens. This refers to this `_buildDictionariesSection` widget.

The user is asking me to clarify what this is, so I should explain it to them without making any code changes (since I'm in plan mode).
</thinking>

Great! Swiping with narrow header it is.

**About "Dictionaries chip section":**

This is the existing UI in TermFormWidget that displays available dictionaries as small "chips" (rounded rectangles) with book icons. It shows a list like:

```
Dictionaries
[📖 SpanishDict] [📖 WordReference] [📖 Reverso]
```

This is the `_buildDictionariesSection` method in the current code (around line 321-345). It takes the `dictionaries` list from the TermForm model and renders them as visual chips for the user to see which dictionaries are available.

**Why hide it when dictionary view opens:**
Once the dictionary webview opens with full navigation (swiping between dictionaries), showing these static chips becomes redundant - the user can already see and access all dictionaries in the expanded dictionary view. Hiding them gives more vertical space for the webview content.

**Does this make sense?** The chips just show what dictionaries are available, but don't currently do anything interactive (they're just informational).

## User

Oh, I don't want that. Lets remove that from the code during this phase

## Assistant

<thinking>
The user wants me to remove the "Dictionaries chip section" from the code during Phase 5.2. They don't want that static list of dictionary chips at all.

Let me update my plan to include removing that section.

I'm in PLAN MODE, so I should not make any code changes. I should update my plan to reflect this change and present it to the user for confirmation before any implementation begins.
</thinking>

Got it! Updated plan to include removing the Dictionaries chip section.

## Revised Phase 5.2 Implementation Plan

### Architecture Overview

**Phase 5.2 Components:**

1. **Data Layer**
   - Fetch dictionary URL templates from Lute server language settings
   - Store per-language dictionary list with names and URL patterns

2. **Service Layer**
   - `DictionaryService` - Constructs URLs by substituting `{term}` placeholder
   - Manages webview instances (one per dictionary, cached)
   - Handles webview lifecycle (create/destroy/cache)

3. **Widget Changes**
   
   **TermFormWidget Modifications:**
   - **ADD**: Search button (magnifying glass) to translation field
   - **ADD**: `DictionaryView` between translation field and status buttons
   - **ADD**: Animate termform expansion to top of screen
   - **HIDE when dictionary open**: Tags field, Romanization field
   - **KEEP VISIBLE**: Title (term name), Translation field, Parents section
   - **REMOVE**: Dictionaries chip section (`_buildDictionariesSection` method)
   - **ADD**: Toggle state for expanded/collapsed view
   - **ADD**: Restore hidden field states when closing
   
   **DictionaryView (NEW):**
   - Multiple cached webviews (one per dictionary)
   - Swipe navigation between dictionaries
   - Narrow header showing current dictionary name
   - Smooth slide-in animation (quick, ~200-300ms)
   - No tabs, just swipe + narrow header

4. **State Management**
   - Track dictionary view state (open/closed)
   - Store which webviews are created and cached
   - Remember current active dictionary
   - Restore hidden field states when closing

### Implementation Flow

**Opening Dictionary:**
1. User taps search button → termform state changes to "expanded"
2. Termform animates upward to top of screen
3. Tags field → hidden, Romanization field → hidden
4. **Dictionaries chip section → completely removed from code**
5. DictionaryView slides in between translation field and status buttons
6. Search button highlights with accent color
7. DictionaryService loads/caches webviews for all dictionaries
8. First dictionary webview loads with term name substituted

**Switching Dictionaries:**
1. User swipes left/right on dictionary view
2. Switch to pre-cached webview (instant)
3. Narrow header updates to show current dictionary name

**Closing Dictionary:**
1. User taps search button (now accent colored)
2. DictionaryView slides out quickly
3. Termform shrinks back to normal size
4. Tags, Romanization → restored to previous state
5. Webviews remain cached (don't destroy - for next open)

### Code Changes Summary

**Files to Modify:**

1. **lib/features/reader/widgets/term_form.dart**
   - Remove `_buildDictionariesSection` method (~lines 321-345)
   - Remove call to `_buildDictionariesSection` in build method (~line 156)
   - Add search button to translation field (`_buildTranslationField`)
   - Add `DictionaryView` widget between translation field and status buttons
   - Add state management for expanded/collapsed
   - Add animation logic

2. **lib/features/reader/widgets/dictionary_view.dart** (NEW)
   - Create new widget for dictionary webview container
   - Implement swipe navigation
   - Implement narrow header
   - Manage multiple webview instances
   - Cache webviews

3. **lib/core/network/dictionary_service.dart** (NEW)
   - Service to construct dictionary URLs
   - Substitute `{term}` in URL templates
   - Fetch dictionary list from server
   - Manage webview lifecycle

4. **lib/features/reader/providers/reader_provider.dart** (if needed)
   - Add dictionary-related state if not in widget state
   - Track dictionary view state

### Questions Before Implementation

1. **Swipe behavior**: Should swipe sensitivity be standard or more generous for easier switching?

2. **Webview initial state**: When dictionary first opens, should it:
   - Always start with first dictionary in list?
   - Remember last used dictionary per term/language?

3. **Empty dictionary list**: If server returns no dictionaries, should we:
   - Hide search button entirely?
   - Show disabled search button with tooltip?
   - Show "No dictionaries configured" message when tapped?

4. **WebView cookies/cache**: Should webviews share cookies/cache between dictionaries for better UX (e.g., if you log in to one, it applies to all)?

Ready to implement when you confirm!

## User

1- We want swipe to be slightly harder to trigger than normal so it takes an intentional swipe. 2- remember the last used per language. 3 - show no dictionaries messages. 4- yes

## Assistant

<thinking>
Perfect! The user answered my questions:

1. Swipe should be slightly harder to trigger than normal - requires intentional swipe
2. Remember last used dictionary per language
3. Show "No dictionaries configured" message if no dictionaries
4. Webviews should share cookies/cache between dictionaries

Now I have a complete plan. Since I'm in PLAN MODE, I should NOT implement anything. I need to:

1. Present the final comprehensive plan
2. Make sure all details are covered
3. Ask if user is ready to proceed with implementation

Let me structure the final plan clearly.
</thinking>

Perfect! I have all the details. Here's the final comprehensive implementation plan:

---

## Phase 5.2: Web Dictionary Integration - Final Implementation Plan

### Overview
Add in-app dictionary browser to TermForm with swipe navigation, using Lute server's dictionary URL templates.

### User Experience Flow

**Normal State:**
- TermForm shows all fields (Title, Translation, Romanization, Tags, Parents, Status buttons)
- Translation field has search button (magnifying glass icon) on the right
- Dictionaries chip section removed entirely

**Dictionary Opens:**
1. User taps search button → TermForm expands to top of screen
2. Romanization and Tags fields hidden
3. DictionaryView slides in smoothly (200-300ms) between translation field and status buttons
4. Search button highlights with accent color
5. Narrow header shows current dictionary name
6. WebView loads with term name substituted into URL

**Dictionary Navigation:**
- Swipe left/right (intentional swipe, slightly harder to trigger)
- Pre-cached webviews switch instantly
- Narrow header updates with current dictionary name
- Cookies/cache shared across all dictionaries
- Last used dictionary remembered per language

**Dictionary Closes:**
1. User taps search button (accent colored)
2. DictionaryView slides out quickly
3. TermForm shrinks back to normal size
4. Romanization and Tags fields restored to previous states

### Technical Architecture

#### 1. Data Layer

**Fetch Dictionary URLs:**
- Endpoint: `GET /language/edit/<int:langid>` or `GET /read/termform/<int:langid>/<text>`
- Extract: Dictionary names and URL templates from server response
- Store: Per-language dictionary list with structure:
  ```dart
  class DictionarySource {
    final String name;
    final String urlTemplate;  // e.g., "https://spanishdict.com/translate/{term}"
  }
  ```

**Last Used Tracking:**
- Key: `last_dictionary_{languageId}`
- Storage: SharedPreferences
- Default: First dictionary in list if none used yet

#### 2. Service Layer

**DictionaryService (NEW)**
- Construct URLs: Replace `{term}` placeholder with actual term text
- URL encode: Handle special characters in term text
- Cache webviews: One webview per dictionary, created on first access
- Share cookies/cache: Same WebViewConfiguration for all webviews
- Remember last used: Get/set per-language preference

**Methods:**
```dart
String buildUrl(String term, String urlTemplate)
Future<WebViewWidget> getOrCreateWebView(DictionarySource dict, String term)
void rememberLastUsedDictionary(int languageId, String dictionaryName)
String? getLastUsedDictionary(int languageId)
```

#### 3. Widget Layer

**TermFormWidget Changes:**

**Remove:**
- `_buildDictionariesSection` method (~lines 321-345)
- Call to `_buildDictionariesSection` in build method (~line 156)

**Modify:**
- `_buildTranslationField`: Add search button on the right side of text field
- Build method: Add `DictionaryView` between translation and status sections
- State: Add `_isDictionaryOpen`, `_lastOptionalFieldVisibility` tracking
- Animation: Wrap content in `AnimatedContainer` or `AnimatedSize` for expansion

**Keep Visible When Dictionary Open:**
- Title (term name)
- Translation field
- Parents section

**Hide When Dictionary Open:**
- Romanization field
- Tags field
- Status buttons (move below dictionary, or hide and show separately)

**DictionaryView (NEW Widget):**
```dart
class DictionaryView extends StatefulWidget {
  final String term;
  final List<DictionarySource> dictionaries;
  final int languageId;
  final VoidCallback onClose;
  final bool isVisible;
}

Features:
- Swipe gesture detector (harder sensitivity)
- PageView or similar for swipe navigation
- Narrow header: current dictionary name
- WebView widget (from flutter_inappwebview)
- Empty state: "No dictionaries configured" message
- Initial page: Last used dictionary per language, or first if none
```

#### 4. State Management

**TermFormWidget State:**
```dart
bool _isDictionaryOpen = false;
String? _currentDictionaryName;
List<WebViewWidget> _cachedWebviews = [];
Map<String, bool> _optionalFieldVisibility = {};
```

**Flow:**
1. **Opening**: Save visibility states, hide fields, expand, open dictionary view
2. **Switching**: Update `_currentDictionaryName`, switch webview in PageView
3. **Closing**: Restore visibility states, collapse, close dictionary view

### File Structure

**New Files:**
- `lib/features/reader/widgets/dictionary_view.dart`
- `lib/core/network/dictionary_service.dart`

**Modified Files:**
- `lib/features/reader/widgets/term_form.dart`
- `lib/features/reader/models/term_form.dart` (possibly, if dictionary data needed in model)

### Implementation Checklist

**Data Layer:**
- [ ] Parse dictionary data from Lute server response
- [ ] Create `DictionarySource` model
- [ ] Fetch and store dictionary list per language

**Service Layer:**
- [ ] Create `DictionaryService` class
- [ ] Implement URL construction with `{term}` substitution
- [ ] Implement webview caching (one per dictionary)
- [ ] Implement shared cookies/cache configuration
- [ ] Implement last-used dictionary tracking with SharedPreferences

**Widget - DictionaryView:**
- [ ] Create new widget with swipe navigation
- [ ] Add narrow header with dictionary name
- [ ] Implement harder swipe sensitivity
- [ ] Add "No dictionaries configured" empty state
- [ ] Load last used dictionary per language on open

**Widget - TermFormWidget:**
- [ ] Remove `_buildDictionariesSection` method
- [ ] Add search button to translation field
- [ ] Implement accent color toggle on search button
- [ ] Add dictionary view insertion point
- [ ] Implement termform expansion animation
- [ ] Implement field hiding/showing (Romanization, Tags)
- [ ] Implement state restoration on close

**Integration:**
- [ ] Connect DictionaryService to TermFormWidget
- [ ] Pass dictionary list from server to DictionaryView
- [ ] Test dictionary opening/closing animations
- [ ] Test swipe navigation between dictionaries
- [ ] Test last-used dictionary persistence
- [ ] Test cookies/cache sharing
- [ ] Test empty state (no dictionaries)

### Key Technical Details

**Swipe Sensitivity:**
- Use `GestureDetector` with `onHorizontalDragEnd`
- Require minimum velocity or distance threshold
- Higher threshold than default for "intentional" swipe

**Animation Timing:**
- Expansion: 250ms curve
- Slide-in: 200ms ease-in-out
- Smooth but quick transitions

**WebView Configuration:**
```dart
InAppWebView(
  initialSettings: InAppWebViewSettings(
    sharedCookiesEnabled: true,
    cacheEnabled: true,
    // ... other settings
  )
)
```

**URL Construction Example:**
```dart
// Template: "https://spanishdict.com/translate/{term}"
// Term: "hola"
// Result: "https://spanishdict.com/translate/hola"
// Encoded: "https://spanishdict.com/translate/hola"
```

### Questions Before Implementation

1. **Status buttons during dictionary open**: Should status buttons be:
   - Hidden along with other fields?
   - Moved to very bottom of expanded termform?
   - Visible but below dictionary view?

2. **Dictionary view height**: Should dictionary view:
   - Take all available space to bottom of screen?
   - Have a fixed/max height (e.g., 60% of screen)?

3. **Loading indicator**: Should we show:
   - Skeleton/loading state while webview loads?
   - Just show empty webview until content loads?

4. **Search button placement**: In translation field, should search button be:
   - On the far right (suffix icon)?
   - As part of input decoration?

Ready to implement when you answer these final questions!

