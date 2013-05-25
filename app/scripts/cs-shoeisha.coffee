window.whatbook = window.whatbook || {}
isbn = $(".netShopPullDown li a:nth(1)")?.attr("href")?.match(/isbn=(\d+)/)[1]
return unless isbn?

window.whatbook.isbn = isbn