window.whatbook = window.whatbook || {}
isbn = location.href.match(/product\-book\-(\d+)/i)[1]
return unless isbn?

window.whatbook.isbn = isbn