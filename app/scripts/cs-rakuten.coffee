window.whatbook = window.whatbook || {}
isbn = $("meta[property='books:isbn']").attr("content")
return unless isbn?

window.whatbook.isbn = isbn