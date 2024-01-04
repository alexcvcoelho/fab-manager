/* eslint-disable
    no-return-assign,
    no-undef,
    no-useless-escape,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Directives.directive('url', [function () {
  const URL_REGEXP = /^(https?:\/\/)([\da-z\.-]+)\.([-a-z0-9\.]{2,30})([\/\w \.-]*)*\/?$/;
  return {
    require: 'ngModel',
    link (scope, element, attributes, ctrl) {
      return ctrl.$validators.url = function (modelValue, viewValue) {
        if (ctrl.$isEmpty(modelValue)) {
          return true;
        }
        if (URL_REGEXP.test(viewValue)) {
          return true;
        }

        // otherwise, this is invalid
        return false;
      };
    }
  };
}
]);

Application.Directives.directive('endpoint', [function () {
  const ENDPOINT_REGEXP = /^\/?([-._~:?#\[\]@!$&'()*+,;=%\w]+\/?)*$/;
  return {
    require: 'ngModel',
    link (scope, element, attributes, ctrl) {
      return ctrl.$validators.endpoint = function (modelValue, viewValue) {
        if (ctrl.$isEmpty(modelValue)) {
          return true;
        }
        if (ENDPOINT_REGEXP.test(viewValue)) {
          return true;
        }

        // otherwise, this is invalid
        return false;
      };
    }
  };
}
]);

Application.Directives.directive('cpf', [function () {
  return {
    require: 'ngModel',
    link: function (scope, element, attributes, ctrl) {
      ctrl.$validators.cpf = function (modelValue, viewValue) {
        if (ctrl.$isEmpty(modelValue)) {
          return true;
        }

        const cpf = modelValue.replace(/[^\d]/g, '');
        if (cpf.length !== 11) {
          return false;
        }

        if (/^(\d)\1{10}$/.test(cpf)) {
          return false;
        }

        let sum = 0;
        for (let i = 0; i < 9; i++) {
          sum += parseInt(cpf.charAt(i)) * (10 - i);
        }
        let remainder = 11 - (sum % 11);
        if (remainder === 10 || remainder === 11) {
          remainder = 0;
        }
        if (remainder !== parseInt(cpf.charAt(9))) {
          return false;
        }

        sum = 0;
        for (let j = 0; j < 10; j++) {
          sum += parseInt(cpf.charAt(j)) * (11 - j);
        }
        remainder = 11 - (sum % 11);
        if (remainder === 10 || remainder === 11) {
          remainder = 0;
        }
        return remainder === parseInt(cpf.charAt(10));
      };
    }
  };
}]);
