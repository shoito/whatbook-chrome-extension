chrome.tabs.getSelected null, (tab) ->
    currentIndex = 0
    isbn = ""
    summaries = []
    systemIds = []

    loadSummary = (isbn, summary) ->
        $("#title").text(summary.title).attr("href", summary.href).attr("target", "_blank")
        $("#summaries").html(summary.content)
        $("#page").text((currentIndex + 1) + "/" + summaries.length)
        $(".calil-render").attr "id", isbn

        pref = JSON.parse(localStorage.getItem("pref") || "{}")
        $("#pref-name").text(pref?.pref || "東京都世田谷区")
        systemIds = pref?.systemIds || ["Tokyo_Setagaya"]

        changeButtonState()
    prev = ->
        currentIndex -= 1
        loadSummary isbn, summaries[currentIndex]
    next = ->
        currentIndex += 1
        loadSummary isbn, summaries[currentIndex]
    changeButtonState = ->
        if currentIndex > 0
            $("#prev").removeAttr("disabled")
        else
            $("#prev").attr("disabled", "")

        if currentIndex < summaries.length - 1
            $("#next").removeAttr("disabled")
        else
            $("#next").attr("disabled", "")
    showCalil = ->
        new Calil({
            appkey: "b76b6d0249f02659c5f62c4d0ff7a113"
            render: new CalilRender()
            isbn: [isbn]
            systemid: systemIds
        }).search()

    chrome.tabs.sendMessage tab.id, {msg: "getSummaries"}, (data) ->
        isbn = data.isbn
        summaries = data.summaries
        loadSummary isbn, summaries[0]
        $("#prev").click =>
            prev()
        $("#next").click =>
            next()

        $("#lib-select").on "click", (e) ->
            e.preventDefault()
            new CalilCitySelectDlg(
                appkey: "b76b6d0249f02659c5f62c4d0ff7a113"
                select_func: (systemId, pref) ->
                                localStorage.setItem "pref", JSON.stringify({systemIds: systemId, pref: pref})
                                systemIds = systemId
                                $("#pref").show()
                                $("#pref-name").text pref
                                showCalil()
            ).showDlg()

        showCalil()