window.whatbook = window.whatbook || {}
isbn = location.href.match(/sell_book\/(\d+).html/i)[1]
return unless isbn?

window.whatbook.isbn = isbn