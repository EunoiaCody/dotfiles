function auto-play-in-mpv
    set url (pbpaste)
    mpv --ytdl-raw-options=cookies-from-browser=chrome \
        --ytdl-format="bestvideo[height<=2160]+bestaudio/best" \
        $url
end
