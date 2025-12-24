function auto-play-in-mpv
    set url (pbpaste)
    # 自动使用 Chrome 的 Cookie 登录，并开启 4K 模式
    mpv --ytdl-raw-options=cookies-from-browser=chrome \
        --ytdl-format="bestvideo[height<=2160]+bestaudio/best" \
        $url
end
