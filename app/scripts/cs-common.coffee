return unless window.whatbook.isbn?
window.whatbook.isbn = window.whatbook.convertToIsbn10 window.whatbook.isbn if window.whatbook.isbn.length is 13

bukupeBookUrl = "http://bukupe.com/book/" + window.whatbook.isbn
pipeUrl = "http://pipes.yahoo.com/pipes/pipe.run?_id=7d854928584dce4dff625e0ae77b6011&_render=json&bukupeUrl=" + bukupeBookUrl
summaries = []

$.ajax
    type: "GET"
    url: pipeUrl
    crossDomain: true
.done (data) =>
    summaries = data.value?.items
    chrome.runtime.sendMessage {msg: "showAction"} if summaries?.length > 0
.fail (req, status, error) =>
    console.error error
  
chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
    sendResponse summaries if request.msg is "getSummaries"
