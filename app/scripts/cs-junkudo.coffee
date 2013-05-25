window.whatbook = window.whatbook || {}
isbn = $(".label:contains('ISBN')")?.parent()?.text().match(/ISBN\s(\d+)/)[1]
return unless isbn?

window.whatbook.isbn = isbn.replace /-/g, ""