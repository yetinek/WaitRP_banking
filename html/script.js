let canReturn = false
let minValuee = 0
let maxValuee = 0
let dateRange = 0
let searchTerm = ""
let CurrentSelectedAccount = 'self'
let CurrentAction = null
let haveTimeout = false
let isATM = false

window.onload = () => {
    // zakres operacji
    let rangeMin = 100;
    const range = $(".rangeSliders > .range > .rangeVal");
    const rangeInput = $(".rangeSliders > input");
    const minValue = $(".rangeSliders > .valueDis#minValue")
    const maxValue = $(".rangeSliders > .valueDis#maxValue")

    rangeInput.on("input", function() {
        minValuee = parseInt($(".min").val());
        maxValuee = parseInt($(".max").val());

        if (maxValuee - minValuee < rangeMin) {
            if ($(this).hasClass("min")) {
                $(".min").val(maxValuee - rangeMin);
            } else {
                $(".max").val(minValuee + rangeMin);
            }
        } else {
            minValue.text(`${minValuee}$`)
            maxValue.text(`${maxValuee}$`)
            minValue.css("left", (minValuee / $(".min").attr("max")) * 100 + "%")
            maxValue.css("right", 100 - (maxValuee / $(".max").attr("max")) * 100 + "%")
            range.css("left", (minValuee / $(".min").attr("max")) * 100 + "%");
            range.css("right", 100 - (maxValuee / $(".max").attr("max")) * 100 + "%");
            sortHistory()
        }
    });

    $('input[type="number"]').on('keydown', function(event) {
        if (event.key === 'e' || event.key === 'E' || event.key === '+' || event.key === '-') {
            event.preventDefault();
        }
    });

    // kopiowanie numeru konta
    $(".btnCopy").on("click", function() {
        const textCopy = removeSpaces($(".welcomeItem > .accountNumber").text());
        const btn = $(this)
        btn.text("Skopiowano")

        const tempInput = $("<input>");
        $("body").append(tempInput);
        tempInput.val(textCopy).select();
        document.execCommand("copy");
        tempInput.remove();

        setTimeout(function() {
            btn.text("Skopiuj")
        }, 2000);
    });

    // cofanie esc
    document.addEventListener("keydown", function(event) {
        if (event.keyCode === 27) {
            if (canReturn) {
                canReturn = false
                $(".mainMenu").css("display", "flex")
                $(".historyContainer").css("display", "flex")
                $(".historyContainer > .topContainer > .btn").css("display", "flex")
                $(".historySearch").css("display", "none")
                $(".transferMoney").css("display", "none")
            } else {
                $('body').fadeOut(250)
                $.post('https://yesk_bank/Close', JSON.stringify({}));
            }
        }
    });

    //przyciski
    $(".historyContainer > .topContainer > .btn").on("click", function() {
        $(this).css("display", "none")
        $(".mainMenu").css("display", "none")
        $(".historySearch").css("display", "flex")
        canReturn = true
    })

    $(".actionsContainer > .btn.transfer").on("click", function() {
        $(".historyContainer").css("display", "none")
        $(".transferMoney").css("display", "none")
        $(".transferMoney.transfer").css("display", "flex")
        CurrentAction = 'transfer'
        canReturn = true
    })

    $(".actionsContainer > .btn.withdrawDep").on("click", function() {
        $(".historyContainer").css("display", "none")
        $(".transferMoney").css("display", "none")
        $(".transferMoney.withdrawDep > .title").text(`${$(this).find(".title").text()} funduszy`)
        $(".transferMoney.withdrawDep").css("display", "flex")
        CurrentAction = $(this).find(".title").text() == 'Wpłata' && 'deposit' || 'withdraw'
        canReturn = true
    })

    $(".transferMoney > .btnConfirm").on("click", function() {
        if (haveTimeout) {
            return
        }
        haveTimeout = true
        setTimeout(function() {
            haveTimeout = false
        }, 2000);
        let a = 0 // kwota
        let b = '' // konto
        let c = '' // tytuł
        if (CurrentAction == 'transfer') {
            a = $('.transferMoney.transfer > .option > .input.kwota').val()
            b = $('.transferMoney.transfer > .option > .input.konto').val()
            c = $('.transferMoney.transfer > .option > .input.tytul').val()
            if (b == '' || b == ' ') {
                let btn = $(this).addClass("horizontalShake")
                $(this).text("Podaj numer konta")
                setTimeout(function() {
                    btn.removeClass("horizontalShake")
                    $(".transferMoney > .btnConfirm").text("Potwierdź")
                }, 2000);
                return
            }
            if (c == '' || c == ' ') {
                // mio: error: podaj powod przelewu
                let btn = $(this).addClass("horizontalShake")
                $(this).text("Podaj tytuł transferu")
                setTimeout(function() {
                    btn.removeClass("horizontalShake")
                    $(".transferMoney > .btnConfirm").text("Potwierdź")
                }, 2000);
                return
            }
        } else if (CurrentAction == 'withdraw') {
            a = $('.transferMoney.withdrawDep > .option > .input').val()
        } else if (CurrentAction == 'deposit') {
            a = $('.transferMoney.withdrawDep > .option > .input').val()
        }
        if (a == 0) {
            // mio: error: podaj kwote
            let btn = $(this).addClass("horizontalShake")
            $(this).text("Podaj kwotę")
            setTimeout(function() {
                btn.removeClass("horizontalShake")
                $(".transferMoney > .btnConfirm").text("Potwierdź")
            }, 2000);
            return
        }
        $('.transferMoney.transfer > .option > .input.kwota').val('')
        $('.transferMoney.transfer > .option > .input.konto').val('')
        $('.transferMoney.transfer > .option > .input.tytul').val('')
        $('.transferMoney.withdrawDep > .option > .input').val('')
        $.post('https://yesk_bank/Action', JSON.stringify({
            action: CurrentAction,
            account: CurrentSelectedAccount,
            otherData: [a, b, c],
            isATM: isATM
        }), function(CallbackData) {
            if (CallbackData.type == 'error') {
                // mio: error: CallbackData.text
                let btn = $(".transferMoney > .btnConfirm").addClass("horizontalShake")
                $(".transferMoney > .btnConfirm").text(CallbackData.text)
                setTimeout(function() {
                    btn.removeClass("horizontalShake")
                    $(".transferMoney > .btnConfirm").text("Potwierdź")
                }, 2000);
                return
            }
            if (CallbackData.type == 'withdraw') {
                let notificationSound = new Audio('sounds/withdraw.wav');
                notificationSound.play();
            }
            if (CallbackData.type == 'transfer') {
                if (CurrentSelectedAccount == CallbackData.account) {
                    SetInfo({ money: CallbackData.amount })
                }
            } else {
                SetInfo({ money: CallbackData.amount })
            }
        });
    })

    //wybieranie konta mainmenu
    $(".mainMenu > .accountSelect").on("click", function() {
        $(this).toggleClass("slided")
        $(this).find(".accountsSelector").slideToggle(100)
        if ($(this).hasClass("slided")) {
            $(this).css("border-radius", "var(--Number) var(--Number) 0 0")
            $(this).find(".icon > img").attr('src', 'icons/chevron-up.svg');
        } else {
            $(this).css("border-radius", "var(--Number)")
            $(this).find(".icon > img").attr('src', 'icons/chevron-down.svg');
        }
    })

    //chowanie w accountSelectora w mainMenu
    $(".mainMenu > .accountSelect").on("mouseleave", function() {
        if ($(this).find(".accountsSelector").is(":visible")) {
            $(this).find(".accountsSelector").slideUp();
            $(this).removeClass("slided")
            $(this).closest(".accountSelect").css("border-radius", "var(--Number)")
            $(this).closest(".accountSelect").find(".icon > img").attr('src', 'icons/chevron-down.svg');
        }
    });

    //Wybieranie zakresu dat
    $(".historySearch > .rangeSelect").on("click", function() {
        $(this).toggleClass("slided")
        $(this).find(".rangeSelector").slideToggle(100)
        if ($(this).hasClass("slided")) {
            $(this).css("border-radius", "var(--Number) var(--Number) 0 0")
            $(this).find(".icon > img").attr('src', 'icons/chevron-up.svg');
        } else {
            $(this).css("border-radius", "var(--Number)")
            $(this).find(".icon > img").attr('src', 'icons/chevron-down.svg');
        }
    })

    //chowanie w accountSelectora w mainMenu
    $(".historySearch > .rangeSelect").on("mouseleave", function() {
        if ($(this).find(".rangeSelector").is(":visible")) {
            $(this).find(".rangeSelector").slideUp();
            $(this).removeClass("slided")
            $(this).closest(".rangeSelect").css("border-radius", "var(--Number)")
            $(this).closest(".rangeSelect").find(".icon > img").attr('src', 'icons/chevron-down.svg');
        }
    });

    $(".historySearch > .rangeSelect > .rangeSelector > .range").on("click", function() {
        $(this).closest(".rangeSelect").find(".title").text($(this).text())
        dateRange = Number($(this).data("days"))
        sortHistory()
    })

    //wyszukiwanie transakcji inputem
    $('.historySearch > .inputSearch > .historyInput').on('input', function() {
        searchTerm = $(this).val().toLowerCase().replace(/ /g, "");
        sortHistory()
    });

    const sortHistory = () => {
        $('.history > .element').each(function() {
            const text = $(this).find(".name").text().toLowerCase().replace(/ /g, "");
            const amount = ($(this).find(".amount").text().replace(/[$ ]/g, "")).substring(1);;
            const date = $(this).find(".date").text()
            if (dateRange == 0) {
                if (text.includes(searchTerm) && (Number(amount) >= Number(minValuee) && Number(amount) <= Number(maxValuee))) {
                    $(this).show();
                } else {
                    $(this).hide();
                }
            } else if (dateRange != 0) {
                const currentDate = new Date()
                currentDate.setHours(0, 0, 0, 0);
                const historyDate = new Date(date)
                historyDate.setHours(0, 0, 0, 0);

                const dateDifference = currentDate.getDate() - historyDate.getDate()
                if (text.includes(searchTerm) && (Number(amount) >= Number(minValuee) && Number(amount) <= Number(maxValuee)) && dateDifference <= dateRange) {
                    $(this).show();
                } else {
                    $(this).hide();
                }
            }
        });
    }
}

window.addEventListener('message', function(event) {
    if (event.data.action == "open") {
        isATM = event.data.IsATM
        if (event.data.IsATM) {
            $(".actionsContainer > .btn.transfer").closest(".actionsContainer").hide()
            $(".historyContainer > .topContainer > .btn").css("display", "none")
        } else {
            $(".actionsContainer > .btn.transfer").closest(".actionsContainer").show()
            $(".historyContainer > .topContainer > .btn").css("display", "flex")
        }
        $('.accountsSelector').html('<div class="account" data-account="self">Konto osobiste</div>')

        //Ustawianie min i max slidera

        if (event.data.data.Jobs['job'][0]) {
            $('.accountsSelector').append(`
                <div class="account" data-account="${event.data.data.Jobs['job'][1]}">Konto firmowe [${event.data.data.Jobs['job'][2]}]</div>
            `)
        }
        $('.accountSelect > .title').html('Konto osobiste')
        let account = 'self'
        $.post('https://yesk_bank/GetAccountData', JSON.stringify({
            account: account
        }), function(CallbackData) {
            SetInfo(CallbackData, account)
        });

        //zmiana konta w mainmenu
        $(".mainMenu > .accountSelect > .accountsSelector > .account").on("click", function() {
            $(this).closest(".accountSelect").find(".title").text($(this).text())
            let account = $(this).data('account')
            $.post('https://yesk_bank/GetAccountData', JSON.stringify({
                account: account
            }), function(CallbackData) {
                SetInfo(CallbackData, account)
            });
        })

        $('body').fadeIn(250)
    }
});

SetInfo = (data, account) => {
        if (account != undefined) {
            CurrentSelectedAccount = account
        }
        if (data.name != undefined) {
            $('#name').html(data.name)
        }
        if (data.money != undefined) {
            $('#money').html(`$${data.money}`)
        }
        if (data.changeIn7days != undefined) {
            $('#changeIn7days').html(`<span class="${data.changeIn7days > 0 && 'green' || 'red'}">$${data.changeIn7days}</span>`)
        }
        if (data.accountNumber != undefined) {
            CurrentSelectedAccountNumber = data.accountNumber
            $('.accountNumber').text(formatNumber(data.accountNumber))
        }
        if (data.transactions != undefined) {
            $('.historyContainer > .history').html(`
            <div class="labels">
                <div class="item">Imię nazwisko</div>
                <div class="item accountNumber">Numer konta</div>
                <div class="item">Kwota</div>
                <div class="item">Data</div>
            </div>
        `)
            data.transactions.forEach((element, index) => {
                        $(".historyContainer > .history").append(`
                <div class="element">
                    <div class="name">${element.senderName}</div>
                    <div class="accountNumber">${formatNumber(element.sender)}</div>
                    <div class="amount ${(element.action == 'withdraw' || (element.action == 'transfer' && element.sender == CurrentSelectedAccountNumber)) && `red` || `green`}">${(element.action == 'withdraw' || (element.action == 'transfer' && element.sender == CurrentSelectedAccountNumber)) && `-` || `+`}${element.money}$</div>
                    <div class="date">${element.date}</div>
                </div>
            `)
        });

        let minMoney = 0;
        let maxMoney = 0;

        
        for (const transaction of data.transactions) {
          if (transaction.money < minMoney) {
            minMoney = transaction.money;
          }
          if (transaction.money > maxMoney) {
            maxMoney = transaction.money;
          }
        }

        $('input.min').attr('min', minMoney)
        $('input.min').attr('max', maxMoney)
        $('input.max').attr('min', minMoney)
        $('input.max').attr('max', maxMoney) 
        $('input.min').val(minMoney)
        $('input.max').val(maxMoney)
        $(".valueDis#minValue").text(`${minMoney}$`)
        $(".valueDis#maxValue").text(`${maxMoney}$`)
        maxValuee = maxMoney
        minValuee = minMoney
    }
}

const formatNumber = (number) => {
    if(number != undefined){
        const cleanedNumber = number.replace(/\D/g, '');
        const groups = cleanedNumber.match(/(\d{2})(\d{4})(\d{4})/);
        const formattedNumber = groups.slice(1).filter(Boolean).join(' ');
        return formattedNumber;
    }
    return number
}

const removeSpaces = (number) => {
    return number.replace(/\s/g, '');
}