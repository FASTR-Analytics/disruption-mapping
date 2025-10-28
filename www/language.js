// Language toggle JavaScript
Shiny.addCustomMessageHandler('updateLanguage', function(translations) {
  // Update all data-translate elements
  $('[data-translate]').each(function() {
    var key = $(this).data('translate');
    if (translations[key]) {
      if ($(this).is('input, select, textarea')) {
        // For input elements, update placeholder or label
        if ($(this).attr('placeholder')) {
          $(this).attr('placeholder', translations[key]);
        }
      } else if ($(this).hasClass('box-title')) {
        // For box titles
        $(this).text(translations[key]);
      } else {
        // For regular text elements
        $(this).text(translations[key]);
      }
    }
  });

  // Update document title
  if (translations.app_title) {
    document.title = translations.app_title;
  }
});
