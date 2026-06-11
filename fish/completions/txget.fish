complete -c txget -s f -l file -d 'Input root directory or a .zip file' -r
complete -c txget -s o -l output -d 'Output Markdown file path' -r
complete -c txget -l include-analysis -d 'Include analysis field when available' -r -f -a "true\t''
false\t''"
complete -c txget -l include-source -d 'Include source file path for each question' -r -f -a "true\t''
false\t''"
complete -c txget -l font-dir -d 'Directory containing CJK fonts for PDF generation' -r
complete -c txget -l pdf -d 'Also generate PDF from the output markdown'
complete -c txget -s h -l help -d 'Print help'
complete -c txget -s V -l version -d 'Print version'
