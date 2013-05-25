window.whatbook = window.whatbook || {}
window.whatbook.convertToIsbn10 = (isbn13) ->
    return isbn13 if isbn13.length is 10

    isbn10 = isbn13.substring 3, 12
    checkDigit = 0
    for i in [0..8]
        checkDigit += parseInt(isbn10[i]) * (10 - i)
    checkDigit = 11 - (checkDigit % 11)

    if checkDigit is 10
        checkDigitStr = "X"
    else if checkDigit is 11
        checkDigitStr = "0"
    else
        checkDigitStr = String(checkDigit)

    isbn10 += checkDigitStr