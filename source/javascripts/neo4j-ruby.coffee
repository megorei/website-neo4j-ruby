$ ->
  $('#nav').affix
    offset:
      top: $('header').height()

  $('#nav').on 'affix.bs.affix', ->
    navHeight = $('#nav').outerHeight(true)
    $('#nav + .container').css('margin-top', navHeight)

  $('#nav').on 'affix-top.bs.affix', ->
    $('#nav + .container').css('margin-top', 0)
