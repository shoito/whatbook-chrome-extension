chrome.runtime.onInstalled.addListener (details) ->
    console.log details, details.previousVersion

# chrome.tabs.onUpdated.addListener (tabId) ->
#     chrome.pageAction.show tabId

chrome.runtime.onMessage.addListener (request, sender) ->
    chrome.pageAction.show sender.tab.id if request.msg is "showAction"