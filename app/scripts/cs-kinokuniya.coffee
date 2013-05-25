window.whatbook = window.whatbook || {}
isbn = $("input[name=GOODS_STK_NO]").val()
return unless isbn?

window.whatbook.isbn = isbn