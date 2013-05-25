window.whatbook = window.whatbook || {}
isbn = $("#ASIN").val()
return unless isbn?

isbn = window.whatbook.convertToIsbn10 isbn if isbn.length is 13
window.whatbook.isbn = isbn