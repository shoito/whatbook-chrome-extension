window.whatbook = window.whatbook || {}
# isbn = location.href.match(/bk-(\d+)\.html/i)[1]
# isbn = YAHOO?.JP?.commerce?.cto?.params?.g
isbn = $(".jan").text().match(/JANコード：(\d+)/)[1]
return unless isbn?

window.whatbook.isbn = isbn