Calil = ->
    @initialize.apply this, arguments
CalilRender = ->
    @set_mode.apply this, arguments
CalilCitySelectDlg = ->
    @initialize.apply this, arguments
Calil:: =
    initialize: (options) ->
        @api_timeout_timer = 0
        @api_call_count = 0
        @data_cache = ""
        @render = options.render or false
        @systemid_list = []
        @isbn_list = []
        self = this
        @appkey = options.appkey or false
        if @appkey is false
            alert "please set app key"
            return
        if options.isbn
            if $.isArray(options.isbn)
                $(options.isbn).each (i, isbn) ->
                    self.add_isbn isbn

            else @add_isbn options.isbn    if typeof options.isbn is "string"
        else
            alert "please set isbn"
            return
        if options.systemid
            if $.isArray(options.systemid)
                $(options.systemid).each (i, systemid) ->
                    self.add_systemid systemid

            else @add_systemid options.systemid    if typeof options.systemid is "string"
        else
            alert "please set systemid"
            return
        @

    add_systemid: (sytemid) ->
        @systemid_list.push sytemid

    add_isbn: (isbn) ->
        @isbn_list.push isbn
        $("#" + isbn).attr "status", ""

    search: ->
        domain = "http://api.calil.jp"
        apiurl = domain + "/check?appkey=" + @appkey + "&systemid=" + @systemid_list.join(",") + "&isbn=" + @isbn_list.join(",")
        @call_api apiurl
        @render.start_render_books @isbn_list, @systemid_list    if @render

    call_api: (url) ->
        self = this
        $.ajax
            url: url
            dataType: "text"
            success: (data) ->
                json = data.match /^callback\((.*?)\);$/
                data = JSON.parse json[1]
                self.callback data
            error: ->
                alert "error"

        clearTimeout @api_timeout_timer
        @api_timeout_timer = setTimeout(->
            self.api_timeout self.render
        , 10000)

    callback: (data) ->
        session = data["session"]
        conti = data["continue"]
        @data_cache = data
        clearTimeout @api_timeout_timer
        if conti is 1
            @api_call_count++
            seconds = (if (@api_call_count < 3) then 1000 else 2000)
            seconds = 5000    if @api_call_count > 7
            newurl = "http://api.calil.jp/check?appkey=" + @appkey + "&session=" + session
            self = this
            setTimeout (->
                self.call_api newurl
            ), seconds
        @render.render_books data    if @render

    api_timeout: ->
        @render.timeoutSearchProgress()    if @render

CalilRender:: =
    render_mode: "list"
    filter_system_id: "all"
    filter_libkey: ""
    target: ""
    set_mode: (mode) ->
        @render_mode = mode or "list"

    set_target: (name) ->
        @target = name

    showSearchProgress: ->
        i = 0
        $(".calil_searching").each ->
            $(this).show()
            return false    if i >= 2
            i++


    timeoutSearchProgress: ->
        i = 0
        if @render_mode is "single"
            $(".calil_system_status").each ->
                $(this).html "：タイムアウト"

        else if @render_mode is "list"
            $(".calil_searching").each ->
                $(this).css "background-image", "url()"
                $(this).html "タイムアウト"
                $(this).show()
                return false    if i >= 2
                i++

        else
            $(".calil_searching").each ->
                $(this).html "T"
                $(this).show()
                return false    if i >= 2
                i++


    start_render_books: (isbn_list, systemid_list) ->
        @systemid_list = systemid_list
        for i of isbn_list
            @init_abstract isbn_list[i]

    render_books: (data) ->
        @conti = data["continue"]
        isbn = ""
        systemid = ""
        for isbn of data.books
            csc = @get_complete_systemid_count(data.books[isbn])
            for systemid of data.books[isbn]
                if @filter_system_id is "all" or @filter_system_id is systemid
                    conti = (csc < @systemid_list.length)
                    @render_abstract isbn, systemid, data.books[isbn][systemid], conti

    get_complete_systemid_count: (data) ->
        count = 0
        systemid = ""
        for systemid of data
            count++    unless data[systemid]["status"] is "Running"
        count

    get_color: (status) ->
        status_color =
            "貸出可": "#339AFC"
            "蔵書あり": "#5CC00F"
            "館内のみ": "#EC6A8C"
            "貸出中": "#F29327"
            "予約中": "#F29327"
            "準備中": "#F29327"
            "休館中": "#F29327"

        return status_color[status]    if status_color[status]
        ""

    get_rank: (status) ->
        srank =
            "貸出可": "100"
            "蔵書あり": "90"
            "館内のみ": "80"
            "貸出中": "70"
            "準備中": "60"
            "予約中": "50"
            "蔵書なし": "40"

        if srank[status]
            return parseInt(srank[status])
        else return 10    if status isnt `undefined` and status isnt ""
        0

    init_abstract: (isbn) ->
        $("#" + isbn).html "<div class=\"calil_searching\">検索中</div>"

    render_abstract: (isbn, systemid, data, conti) ->
        text = ""
        status = "蔵書なし"
        status_show = status
        status_rank = 0
        for i of data.libkey
            if @filter_libkey is "" or @filter_libkey is i
                temp = data.libkey[i]
                if @get_rank(temp) > status_rank
                    status = temp
                    status_show = status
                    status_rank = @get_rank(temp)
        if data.status is "Error"
            status = "システムエラー"
            status_show = status
        style = @render_status(status)
        link = "http://calil.jp/book/" + isbn
        text += "<div style=\"white-space:nowrap;\">"
        text += "<a href=\"" + link + "\" target=\"_blank\" class=\"calil_status " + style.css + "\">" + style.status + "</a></div>"
        return    if (data.status is "Running" or conti) and @get_rank(status) <= 40
        if $("#" + isbn)
            before_s = $("#" + isbn).attr("status")
            isup = ((@filter_system_id isnt "all") or (@get_rank(status) > @get_rank(before_s)))
            if isup
                unless data.reserveurl is ""
                    text += "<div style=\"clear:both\">"
                    text += "<a href=\"" + data.reserveurl + "\" target=\"_blank\"><img border=\"0\" src=\"http://gae.calil.jp/public/img/gyazo/2064f557b8c17c879558165b0020ff5e.png\"></a>"
                    text += "</div>"
                $("#" + isbn).html text
                $("#" + isbn).attr "status", status
                @showSearchProgress()

    render_status: (status) ->
        style =
            raw_status: status
            status: status
            total_status: "蔵書なし"
            color: "red"
            bgcolor: ""
            css: "calil_nothing"

        if style.status is "貸出可"
            style.status = "蔵書あり(貸出可)"
            style.total_status = "蔵書あり"
            style.color = "white"
            style.bgcolor = "#339AFC"
            style.css = "calil_nijumaru"
        if style.status is "蔵書あり"
            style.total_status = "蔵書あり"
            style.color = "white"
            style.bgcolor = "#5CC00F"
            style.css = "calil_maru"
        if style.status is "館内のみ"
            style.status = "蔵書あり(館内のみ)"
            style.total_status = "蔵書あり"
            style.color = "white"
            style.bgcolor = "#EC6A8C"
            style.css = "calil_marukannai"
        if style.status is "準備中"
            style.status = "蔵書あり(準備中)"
            style.color = "white"
            style.bgcolor = "#F29327"
            style.css = "calil_sankaku"
        if style.status is "貸出中"
            style.status = "蔵書あり(貸出中)"
            style.total_status = "蔵書あり"
            style.color = "white"
            style.bgcolor = "#F29327"
            style.css = "calil_sankaku"
        if style.status is "予約中"
            style.status = "蔵書あり(予約中)"
            style.color = "white"
            style.bgcolor = "#F29327"
            style.css = "calil_sankaku"
        if style.status is "休館中"
            style.status = "蔵書あり(休館中)"
            style.total_status = "蔵書あり"
            style.color = "white"
            style.bgcolor = "#F29327"
            style.css = "calil_sankaku"
        style

CalilCitySelectDlg:: =
    pref_name: ""
    pref_data: false
    initialize: (options) ->
        @appkey = options.appkey or false
        if @appkey is false
            alert "please set app key"
            return
        @getstart = options.getstart or false
        $(document.body).append @dialog_html
        @placeDialog = $(options.placeDialog or "#calil_place_dialog")
        @placeDialogWrapper = $(options.placeDialogWrapper or "#calil_place_dialog_wrapper")
        unless typeof options.select_func is "function"
            alert "Please set function"
            return
        @selectFunc = options.select_func or false
        self = this
        $(".calil_place_dialog_close").click (e)->
            e.preventDefault()
            self.closeDlg()

        $("#calil_pref_selector a").each (i, e) ->
            temp = $(e).attr("href").split("/")
            pref = temp[temp.length - 1]
            $(e).attr("href", "#").click (e) ->
                e.preventDefault()
                self.load_pref pref

        $(".calil_hide_city").click (e) ->
            e.preventDefault()
            self.hidecity()

        $(window).resize ->
            self.placeDialogWrapper.css "height", $(window).height()
            self.placeDialogWrapper.css "width", $(window).width()
            self.placeDialog.css "top", ($(window).height() - self.placeDialog.height()) / 2 + $(window).scrollTop() + "px"
            self.placeDialog.css "left", ($(window).width() - self.placeDialog.width()) / 2 + $(window).scrollLeft() + "px"

        if @getstart is true
            self = this
            setTimeout (->
                self.showDlg()
            ), 1000
        @

    showDlg: ->
        self = this
        @placeDialogWrapper.show()
        @placeDialog.show "fast", ->
            self.placeDialogWrapper.css "height", $(window).height()
            self.placeDialogWrapper.css "width", $(window).width()
            self.placeDialog.css "top", ($(window).height() - self.placeDialog.height()) / 2 + $(window).scrollTop() + "px"
            self.placeDialog.css "left", ($(window).width() - self.placeDialog.width()) / 2 + $(window).scrollLeft() + "px"


    closeDlg: ->
        @placeDialog.hide "fast"
        @placeDialogWrapper.hide()
        @hidecity()

    load_pref: (pref) ->
        @pref_name = pref
        unless @pref_data is false
            @expand_city()
            return
        url = "http://calil.jp/city_list"
        self = this
        $.ajax
            url: url
            dataType: "text"
            success: (data) ->
                json = data.match /^loadcity\((.*?)\);$/
                data = JSON.parse json[1]
                self.loadcity data
            error: ->
                alert "error"

    loadcity: (data) ->
        @pref_data = data
        @expand_city()

    expand_city: ->
        cities = @pref_data[@pref_name]
        html = "<div class=\"calil_city_list\">"
        yindex = "あ,か,さ,た,な,は,ま,や,ら,わ".split(",")
        i = 0

        while i < yindex.length
            y = yindex[i]
            if cities[y]
                html += "<div class=\"calil_yomi_block\"></div>"
                html += "<div class=\"calil_yomi\">" + y + "</div>"
                html += "<div class=\"calil_cities\">"
                city = ""
                for city of cities[y]
                    html += "<a class=\"calil_city_part\" href=\"" + @pref_name + "," + cities[y][city] + "\">" + cities[y][city] + "</a>"
                html += "</div>"
            i++
        html += "</div>"
        $("#calil_city_selector").show()
        $("#calil_pref_selector").hide()
        $("#calil_city_selector .calil_pref_list").html html
        self = this
        $("#calil_city_selector .calil_pref_list a").each (i, e) ->
            temp = $(e).attr("href").split("/")
            pref = temp[temp.length - 1]
            $(e).attr("href", "#").click (e) ->
                e.preventDefault()
                self.get_systemid pref

    hidecity: ->
        $("#calil_pref_selector").show()
        $("#calil_city_selector").hide()

    get_systemid: (raw_pref) ->
        @closeDlg()
        temp = raw_pref.split(",")
        raw_pref = raw_pref.split(",").join("")
        pref = temp[0]
        city = temp[1]
        pref = encodeURIComponent(pref)
        city = encodeURIComponent(city)
        url = "http://api.calil.jp/library?appkey=" + @appkey + "&format=json&pref=" + pref + "&city=" + city
        self = this
        $.ajax
            url: url
            dataType: "text"
            success: (data) ->
                json = data.match /^callback\((.*?)\);$/
                console.log json[1]
                data = JSON.parse json[1]
                self.set_systemid data, raw_pref
            error: ->
                alert "error"

    set_systemid: (data, pref) ->
        if data.length > 0
            systemid_list = []
            $(data).each (i, e) ->
                systemid_list.push e.systemid

            systemid_list = @uniq(systemid_list)
            @selectFunc.apply this, [systemid_list, pref]
        else
            alert "図書館が見つかりませんでした。"

    uniq: (arr) ->
        o = {}
        r = []
        i = 0

        while i < arr.length
            r.push arr[i]    if (if arr[i] of o then false else o[arr[i]] = true)
            i++
        r

    dialog_html: ["<div id=\"calil_place_dialog_wrapper\">", "<div id=\"calil_place_dialog\">", "\t<div class=\"calil_dlg_content\">", "\t\t<div style=\"float:right;font-size:140%;\"><a href=\"#\" class=\"calil_place_dialog_close\">[×]</a></div>", "\t\t<h3>図書館のエリアを選んでください。</h3>", "\t\t<div id = \"calil_city_selector\" style=\"display:none;\">", "\t\t<a href=\"#\" class=\"calil_hide_city\">« 戻る</a>", "\t\t<div class=\"calil_pref_list\">&nbsp;</div>", "\t\t</div>", "", "<table cellspacing=\"0\" cellpadding=\"6\" id=\"calil_pref_selector\">", "<tr>", "<td>", "", "<table width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" style=\"font-size:14px;line-height:140%;\">", "<tr valign=\"top\">", "<td>", "", "</td>", "<td align=\"right\">", "", "", "<table cellspacing=\"1\" cellpadding=\"0\">", "<tr height=\"40\" style=\"font-size:10px;text-align:center;\">", "<td></td>", "<td bgcolor=\"#8888ff\" width=\"50\">", "<a href=\"北海道\">北海道</a>", "</td>", "</tr>", "", "<tr>", "<td height=\"10\"></td>", "</tr>", "</table>", "", "<table cellspacing=\"1\" cellpadding=\"0\" style=\"font-size:10px;text-align:center;margin-bottom:-1;\">", "<tr height=\"25\">", "<td></td><td></td><td></td><td width=\"30\"></td>", "<td bgcolor=\"#99ddff\" width=\"30\">", "<a href=\"青森県\">青森</a>", "</td>", "<td width=\"20\"></td>", "</tr>", "", "<tr height=\"40\">", "<td></td><td></td><td width=\"30\"></td>", "<td bgcolor=\"#99ddff\" width=\"30\">", "<a href=\"秋田県\">秋田</a>", "</td>", "<td bgcolor=\"#99ddff\">", "<a href=\"岩手県\">岩手</a>", "</td>", "</tr>", "", "<tr height=\"35\">", "<td></td><td></td><td></td>", "<td bgcolor=\"#99ddff\" width=\"30\">", "<a href=\"山形県\">山形</a>", "</td>", "<td bgcolor=\"#99ddff\">", "<a href=\"宮城県\">宮城</a>", "</td>", "</tr>", "", "<tr height=\"25\">", "<td bgcolor=\"#ccf577\" width=\"30\">", "<a href=\"石川県\">石川</a>", "</td>", "<td bgcolor=\"#ccf577\" width=\"30\">", "<a href=\"富山県\">富山</a>", "</td>", "<td bgcolor=\"#ccaaff\" width=\"60\" colspan=\"2\">", "<a href=\"新潟県\">新潟</a>", "</td>", "<td bgcolor=\"#99ddff\" width=\"30\">", "<a href=\"福島県\">福島</a>", "</td>", "</tr>", "</table>", "", "</td>", "</tr>", "</table>", "", "<table cellspacing=\"1\" cellpadding=\"0\" style=\"font-size:10px;text-align:center;border-style:none;\">", "<tr height=\"25\">", "<td bgcolor=\"#f5e577\" width=\"26\">", "<a href=\"長崎県\">長崎</a>", "</td>", "<td bgcolor=\"#f5e577\" width=\"26\">", "<a href=\"佐賀県\">佐賀</a>", "</td>", "<td bgcolor=\"#f5e577\" width=\"26\">", "<a href=\"福岡県\">福岡</a>", "</td>", "<td width=\"10\"></td>", "<td bgcolor=\"#ff88bb\" width=\"26\" rowspan=\"2\">", "<a href=\"山口県\">山口</a>", "</td>", "<td bgcolor=\"#ff88bb\" width=\"26\">", "<a href=\"島根県\">島根</a>", "</td>", "<td bgcolor=\"#ff88bb\" width=\"26\">", "<a href=\"鳥取県\">鳥取</a>", "</td>", "<td bgcolor=\"#80f580\" width=\"26\" rowspan=\"2\">", "<a href=\"兵庫県\">兵庫</a>", "</td>", "<td bgcolor=\"#80f580\" width=\"30\">", "<a href=\"京都府\">京都</a>", "</td>", "<td bgcolor=\"#80f580\" width=\"26\">", "<a href=\"滋賀県\">滋賀</a>", "</td>", "<td bgcolor=\"#ccf577\" width=\"30\">", "<a href=\"福井県\">福井</a>", "</td>", "<td bgcolor=\"#ccaaff\" width=\"30\" rowspan=\"2\">", "<a href=\"長野県\">長野</a>", "</td>", "<td bgcolor=\"#ff99ff\" width=\"30\">", "<a href=\"群馬県\">群馬</a>", "</td>", "<td bgcolor=\"#ff99ff\" width=\"30\">", "<a href=\"栃木県\">栃木</a>", "</td>", "<td bgcolor=\"#ff99ff\" width=\"30\">", "<a href=\"茨城県\">茨城</a>", "</td>", "<td width=\"20\"></td>", "</tr>", "", "<tr height=\"25\">", "<td></td>", "<td bgcolor=\"#f5e577\">", "<a href=\"熊本県\">熊本</a>", "</td>", "<td bgcolor=\"#f5e577\">", "<a href=\"大分県\">大分</a>", "</td>", "<td></td>", "<td bgcolor=\"#ff88bb\">", "<a href=\"広島県\">広島</a>", "</td>", "<td bgcolor=\"#ff88bb\">", "<a href=\"岡山県\">岡山</a>", "</td>", "<td bgcolor=\"#80f580\">", "<a href=\"大阪府\">大阪</a>", "</td>", "<td bgcolor=\"#80f580\">", "<a href=\"奈良県\">奈良</a>", "</td>", "<td bgcolor=\"#ffcc88\">", "<a href=\"岐阜県\">岐阜</a>", "</td>", "<td bgcolor=\"#ff99ff\">", "<a href=\"山梨県\">山梨</a>", "</td>", "<td bgcolor=\"#ff99ff\">", "<a href=\"埼玉県\">埼玉</a>", "</td>", "<td bgcolor=\"#ff99ff\">", "<a href=\"千葉県\">千葉</a>", "</td>", "</tr>", "", "<tr height=\"24\">", "<td></td>", "<td bgcolor=\"#f5e577\">", "<a href=\"鹿児島県\">鹿児島</a>", "</td>", "<td bgcolor=\"#f5e577\">", "<a href=\"宮崎県\">宮崎</a>", "</td>", "<td></td><td></td><td></td><td></td><td></td>", "<td bgcolor=\"#80f580\">", "<a href=\"和歌山県\">和歌山</a>", "</td>", "<td bgcolor=\"#ffcc88\">", "<a href=\"三重県\">三重</a>", "</td>", "<td bgcolor=\"#ffcc88\">", "<a href=\"愛知県\">愛知</a>", "</td>", "<td bgcolor=\"#ffcc88\">", "<a href=\"静岡県\">静岡</a>", "</td>", "<td bgcolor=\"#ff99ff\">", "<a href=\"神奈川県\">神奈川</a>", "</td>", "<td bgcolor=\"#ff99ff\">", "<a href=\"東京都\">東京</a>", "</td>", "</tr>", "", "<tr height=\"20\">", "<td></td><td></td><td></td><td></td><td></td>", "<td bgcolor=\"#ddbb99\">", "<a href=\"愛媛県\">愛媛</a>", "</td>", "<td bgcolor=\"#ddbb99\">", "<a href=\"香川県\">香川</a>", "</td>", "</tr><tr height=\"20\">", "<td bgcolor=\"#ff8888\">", "<a href=\"沖縄県\">沖縄</a>", "</td>", "<td></td><td></td><td></td><td></td>", "<td bgcolor=\"#ddbb99\">", "<a href=\"高知県\">高知</a>", "</td>", "<td bgcolor=\"#ddbb99\">", "<a href=\"徳島県\">徳島</a>", "</td>", "</tr>", "</table>", "", "</td>", "</tr>", "</table>", "", "</div>", "</div>", "</div>"].join("")

window.Calil = Calil || {}
window.CalilRender = CalilRender || {}
window.CalilCitySelectDlg = CalilCitySelectDlg || {}