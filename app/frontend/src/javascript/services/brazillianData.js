'use strict';

Application.Services.factory('BrazillianData', ['$resource', function ($resource) {
  return $resource('/api/brazillian_data',
    {}, {
      all_states: {
        method: 'GET',
        url: '/api/brazillian_data/all_states',
        isArray: true
      },
      cities: {
        method: 'GET',
        url: '/api/brazillian_data/cities/:uf',
        params: { uf: '@uf' },
        isArray: true
      }
    }
  );
}]);
