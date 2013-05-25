window.whatbook = window.whatbook || {}
isbn = $(".detail_item_summary_title:contains('ISBN') + .detail_item_summary_txt").text()
return unless isbn?

window.whatbook.isbn = isbn.replace /-/g, ""