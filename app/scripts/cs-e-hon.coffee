window.whatbook = window.whatbook || {}
isbn = $(".detailInfo .codeSelect:first").text()
return unless isbn?

window.whatbook.isbn = isbn.replace /-/g, ""