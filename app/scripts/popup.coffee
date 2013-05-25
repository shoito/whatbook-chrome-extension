chrome.tabs.getSelected null, (tab) ->
    currentIndex = 0
    summaries = []

    loadSummary = (summary) ->
        $("#title").text(summary.title).attr("href", summary.href).attr("target", "_blank")
        $("#summaries").html(summary.content)
        $("#page").text((currentIndex + 1) + "/" + summaries.length)
        changeButtonState()
    prev = ->
        currentIndex -= 1
        loadSummary summaries[currentIndex]
    next = ->
        currentIndex += 1
        loadSummary summaries[currentIndex]
    changeButtonState = ->
        if currentIndex > 0
            $("#prev").removeAttr("disabled")
        else
            $("#prev").attr("disabled", "")

        if currentIndex < summaries.length - 1
            $("#next").removeAttr("disabled")
        else
            $("#next").attr("disabled", "")

    chrome.tabs.sendMessage tab.id, {msg: "getSummaries"}, (data) ->
        summaries = data
        loadSummary summaries[0]
        $("#prev").click =>
            prev()
        $("#next").click =>
            next()