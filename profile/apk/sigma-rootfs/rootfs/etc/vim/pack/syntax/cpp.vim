" Delete the keyword-based cType matching, it just gets in the way
syn clear cppType

" Redefine cppStatement so that "new" is not a keyword, so the below can match
" it
syn clear cppStatement

syn keyword cppStatement	delete this friend using
if !exists("cpp_no_cpp20")
  syn keyword cppStatement	co_await co_return co_yield requires
endif

" Likewise remove "throw" from cppExceptions
syn clear cppExceptions
syn keyword cppExceptions	try catch

syn clear cppCast

syn match cppCast		"\<\(const\|static\|dynamic\|reinterpret\)_cast\s*<"me=e-1 nextgroup=cJCTemplateType
syn match cppCast		"\<\(const\|static\|dynamic\|reinterpret\)_cast\s*$" nextgroup=cJCTemplateType
if !exists("cpp_no_cpp11")
  syn keyword cppExceptions	noexcept
  syn match cppCast		"\<\(const\|static\|dynamic\)_pointer_cast\s*<"me=e-1 nextgroup=cJCTemplateType
  syn match cppCast		"\<\(const\|static\|dynamic\)_pointer_cast\s*$" nextgroup=cJCTemplateType
endif
if !exists("cpp_no_cpp17")
  syn match cppCast		"\<reinterpret_pointer_cast\s*<"me=e-1 nextgroup=cJCTemplateType
  syn match cppCast		"\<reinterpret_pointer_cast\s*$" nextgroup=cJCTemplateType
endif

" Match various well known templates from the STL that are known to contain types
" in their arguments
syn match cJCStlTemplate "\(time_point_cast\|make_unique\|make_shared\|make_optional\)\s*<"me=e-1 nextgroup=cJCTemplateType

" Highlight the type in a template with a type argument or a C++ cast
syn match cJCTemplateType "<\zs\I[[:ident:]:&*]*>"ms=s+1,me=e-1

" Redefine several things from the C syntax to handle templates and references
" in addition to the other things
syn clear cJCTypeInDecl
syn clear cJCDecl
syn clear cJCFunc
syn clear cJCParamType

syn match	cJCTypeInDecl	"^\s*\(\(inline\|const\|restrict\|extern\|GLOBAL\|static\|register\|auto\|volatile\|virtual\|signed\|unsigned\|struct\)[ \t*]\+\)*\I[[:ident:]:<>]*&\?\([ \t*]\+\(const\|restrict\|volatile\)\)*[ \t*]*" contained
syn match	cJCDecl		"^\s*\(inline\s\+\)\=\(\I[[:ident:]:<>]*&\?[ \t*]\+\)\+\s*\I" contains=cJCTypeInDecl

syn region	cJCFunc		start="^\t*\(\(inline\|const\|extern\|GLOBAL\|static\|register\|auto\|volatile\|virtual\|signed\|unsigned\|struct\)[ \t*]\+\)*\I[[:ident:]:<>]*\s\+\**\s*\I[[:ident:]:]*\s*(" end=")" contains=CJCParamVoid,cJCParamType,cJCTypeInDecl,cComment

" This matches constructors, but only if they are in the first column for now
" (no identation). Otherwise it also matches all function calls, and that
" breaks a lot of things.
syn region	cJCFunc		start="^\I[[:ident:]:<>]*\s*(" end=")" contains=CJCParamVoid,cJCParamType

syn match	cJCParamType	"\<\(\(const\|restrict\|volatile\|signed\|unsigned\|struct\|enum\)[ \t*]\+\)*\I[[:ident:]:<>]*&\?[ \t*]\+\I"he=e-1 contained containedin=cJCFor


syn keyword	cJCNewStatement	new throw contained

" Detect type in "new" and "throw" expressions
syn match cJCNew "\(^\t*throw\|new\) \I[[:ident:]:]*"  contains=cJCNewStatement


hi def link cJCNewStatement cppStatement
hi def link cppCast		cppStatement
hi def link cppExceptions		Exception

" And finally the thing we wanted to do: highlight all the types using cType
" highlight, not just the ones matching C++ keywords.
hi link cJCNew		cType
hi link cJCTemplateType cType

hi link cJCCppCast cType
hi link cJCTypeInDecl cType
hi link cJCParamType cType

" Uncomment these for debug mode: very visible highlight of what we match
"hi cJCNewKeyword		guibg=#00FF80
"hi cJCNew		guibg=#00FF00
