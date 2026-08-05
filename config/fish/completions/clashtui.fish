# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_clashtui_global_optspecs
	string join \n generate-shell-completion= config-dir= v/verbose load-theme-realtime h/help V/version
end

function __fish_clashtui_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_clashtui_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_clashtui_using_subcommand
	set -l cmd (__fish_clashtui_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c clashtui -n "__fish_clashtui_needs_command" -l generate-shell-completion -d 'generate shell completion' -r -f -a "bash\t''
elvish\t''
fish\t''
powershell\t''
zsh\t''"
complete -c clashtui -n "__fish_clashtui_needs_command" -l config-dir -d 'specify the ClashTUI config directory' -r -F
complete -c clashtui -n "__fish_clashtui_needs_command" -s v -l verbose -d 'increase log level, default is Warning'
complete -c clashtui -n "__fish_clashtui_needs_command" -l load-theme-realtime -d 'allow theme change without restart'
complete -c clashtui -n "__fish_clashtui_needs_command" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c clashtui -n "__fish_clashtui_needs_command" -s V -l version -d 'Print version'
complete -c clashtui -n "__fish_clashtui_needs_command" -f -a "profile" -d 'profile related'
complete -c clashtui -n "__fish_clashtui_needs_command" -f -a "service" -d 'service related'
complete -c clashtui -n "__fish_clashtui_needs_command" -f -a "mode" -d 'set proxy mode, leave empty to get current mode'
complete -c clashtui -n "__fish_clashtui_needs_command" -f -a "update" -d 'check for update'
complete -c clashtui -n "__fish_clashtui_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and not __fish_seen_subcommand_from update select list help" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and not __fish_seen_subcommand_from update select list help" -f -a "update" -d 'update the selected profile or all'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and not __fish_seen_subcommand_from update select list help" -f -a "select" -d 'select profile'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and not __fish_seen_subcommand_from update select list help" -f -a "list" -d 'list all profile'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and not __fish_seen_subcommand_from update select list help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from update" -s n -l name -d 'the profile name' -r
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from update" -l type -d 'filter by profile type' -r -f -a "file\t'file-based profiles'
url\t'URL-based profiles'
template\t'template-based profiles'
singbox\t'sing-box profiles'"
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from update" -s a -l all -d 'update all profiles, this will also update config clash is using, while --name does not'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from update" -l with-proxy -d 'update profile with proxy'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from update" -l without-proxyprovider -d 'update profile with proxyprovider removed'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from select" -s n -l name -d 'the profile name' -r
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from select" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from list" -l type -d 'filter by profile type' -r -f -a "file\t'file-based profiles'
url\t'URL-based profiles'
template\t'template-based profiles'
singbox\t'sing-box profiles'"
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from list" -l name-only -d 'without domain hint'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from help" -f -a "update" -d 'update the selected profile or all'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from help" -f -a "select" -d 'select profile'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from help" -f -a "list" -d 'list all profile'
complete -c clashtui -n "__fish_clashtui_using_subcommand profile; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c clashtui -n "__fish_clashtui_using_subcommand service; and not __fish_seen_subcommand_from restart stop help" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand service; and not __fish_seen_subcommand_from restart stop help" -f -a "restart" -d 'start/restart service, can be soft'
complete -c clashtui -n "__fish_clashtui_using_subcommand service; and not __fish_seen_subcommand_from restart stop help" -f -a "stop" -d 'stop service'
complete -c clashtui -n "__fish_clashtui_using_subcommand service; and not __fish_seen_subcommand_from restart stop help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c clashtui -n "__fish_clashtui_using_subcommand service; and __fish_seen_subcommand_from restart" -s s -l soft -d 'restart by send POST request to mihomo'
complete -c clashtui -n "__fish_clashtui_using_subcommand service; and __fish_seen_subcommand_from restart" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand service; and __fish_seen_subcommand_from stop" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand service; and __fish_seen_subcommand_from help" -f -a "restart" -d 'start/restart service, can be soft'
complete -c clashtui -n "__fish_clashtui_using_subcommand service; and __fish_seen_subcommand_from help" -f -a "stop" -d 'stop service'
complete -c clashtui -n "__fish_clashtui_using_subcommand service; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and not __fish_seen_subcommand_from rule direct global help" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and not __fish_seen_subcommand_from rule direct global help" -f -a "rule" -d 'rule'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and not __fish_seen_subcommand_from rule direct global help" -f -a "direct" -d 'direct'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and not __fish_seen_subcommand_from rule direct global help" -f -a "global" -d 'global'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and not __fish_seen_subcommand_from rule direct global help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and __fish_seen_subcommand_from rule" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and __fish_seen_subcommand_from direct" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and __fish_seen_subcommand_from global" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and __fish_seen_subcommand_from help" -f -a "rule" -d 'rule'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and __fish_seen_subcommand_from help" -f -a "direct" -d 'direct'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and __fish_seen_subcommand_from help" -f -a "global" -d 'global'
complete -c clashtui -n "__fish_clashtui_using_subcommand mode; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c clashtui -n "__fish_clashtui_using_subcommand update; and not __fish_seen_subcommand_from clashtui mihomo help" -s c -l ci -d 'check ci/alpha release instead'
complete -c clashtui -n "__fish_clashtui_using_subcommand update; and not __fish_seen_subcommand_from clashtui mihomo help" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand update; and not __fish_seen_subcommand_from clashtui mihomo help" -f -a "clashtui" -d 'check for ClashTUI'
complete -c clashtui -n "__fish_clashtui_using_subcommand update; and not __fish_seen_subcommand_from clashtui mihomo help" -f -a "mihomo" -d 'check for Mihomo'
complete -c clashtui -n "__fish_clashtui_using_subcommand update; and not __fish_seen_subcommand_from clashtui mihomo help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c clashtui -n "__fish_clashtui_using_subcommand update; and __fish_seen_subcommand_from clashtui" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand update; and __fish_seen_subcommand_from mihomo" -s h -l help -d 'Print help'
complete -c clashtui -n "__fish_clashtui_using_subcommand update; and __fish_seen_subcommand_from help" -f -a "clashtui" -d 'check for ClashTUI'
complete -c clashtui -n "__fish_clashtui_using_subcommand update; and __fish_seen_subcommand_from help" -f -a "mihomo" -d 'check for Mihomo'
complete -c clashtui -n "__fish_clashtui_using_subcommand update; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and not __fish_seen_subcommand_from profile service mode update help" -f -a "profile" -d 'profile related'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and not __fish_seen_subcommand_from profile service mode update help" -f -a "service" -d 'service related'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and not __fish_seen_subcommand_from profile service mode update help" -f -a "mode" -d 'set proxy mode, leave empty to get current mode'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and not __fish_seen_subcommand_from profile service mode update help" -f -a "update" -d 'check for update'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and not __fish_seen_subcommand_from profile service mode update help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and __fish_seen_subcommand_from profile" -f -a "update" -d 'update the selected profile or all'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and __fish_seen_subcommand_from profile" -f -a "select" -d 'select profile'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and __fish_seen_subcommand_from profile" -f -a "list" -d 'list all profile'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and __fish_seen_subcommand_from service" -f -a "restart" -d 'start/restart service, can be soft'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and __fish_seen_subcommand_from service" -f -a "stop" -d 'stop service'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and __fish_seen_subcommand_from mode" -f -a "rule" -d 'rule'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and __fish_seen_subcommand_from mode" -f -a "direct" -d 'direct'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and __fish_seen_subcommand_from mode" -f -a "global" -d 'global'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and __fish_seen_subcommand_from update" -f -a "clashtui" -d 'check for ClashTUI'
complete -c clashtui -n "__fish_clashtui_using_subcommand help; and __fish_seen_subcommand_from update" -f -a "mihomo" -d 'check for Mihomo'
