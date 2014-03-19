/**
  An object that is responsible for logic related to mobile devices.

  @namespace Discourse
  @module Mobile
**/
Discourse.Mobile = {
  isMobileDevice: false,
  mobileView: false,

  init: function() {
    var $html = $('html');
    this.isMobileDevice = $html.hasClass('mobile-device');
    this.mobileView = $html.hasClass('mobile-view');

    if (localStorage && localStorage.mobileView) {
      var savedValue = (localStorage.mobileView === 'true');
      if (savedValue !== this.mobileView) {
        this.reloadPage(savedValue);
      }
    }
  },

  toggleMobileView: function() {
    if (localStorage) {
      localStorage.mobileView = !this.mobileView;
    }
    this.reloadPage(!this.mobileView);
  },

  reloadPage: function(mobile) {
    window.location.assign(window.location.pathname + '?mobile_view=' + (mobile ? '1' : '0'));
  }
};
