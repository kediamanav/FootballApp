'use strict';

/* App Module */

var footballApp = angular.module('footballApp', [
  'ngRoute',
  'footballControllers',
  'ngResource'
]);

footballApp.config(['$routeProvider','$locationProvider',
  function($routeProvider,$locationProvider) {
    $routeProvider.
      when('/', {
        templateUrl: 'partials/match-list.html',
        controller: 'FootballCtrl'//,
        //redirectTo: '/matches'
      }).
      when('/matches/:matchId', {
        templateUrl: 'partials/match-detail.html',
        controller: 'MatchDetailCtrl'
      }).     
      when('/matches/results/:matchId', {
        templateUrl: 'partials/match-result.html',
        controller: 'MatchResultCtrl'
      }).
      when('/leaderboards',{
        templateUrl: 'partials/leaderboard.html',
        controller: 'MatchLeaderboard' 
      }).
      otherwise({
        redirectTo: '/'
      });
      $locationProvider.html5Mode(true);
  }]);

//footballApp.factory('BetService', function($resource,$routeParams) {
 // return $resource('/bets/:id', {id: $routeParams.matchId}, {update: {method: 'PUT'}});
  //});

footballApp.factory('ResultService', function($resource,$routeParams) {
  return $resource('/results/:id',{}, {query: {method:'GET', isArray:true}, 'save':   {method:'POST'}});
  });


/*footballApp.factory('BetService', ['$resource', '$routeParams',
    function($resource){
        return $resource('/bets', {}, {single: {url: '/bets/:matchId',method:'GET',}
    });
}]);*/

footballApp.factory('BetService', function($resource) {
  return $resource('/bets/:id',{}, {query: {method:'GET', isArray:true}, 'save':   {method:'POST'}});
 });

footballApp.factory('MatchesService', function($resource) {
  return $resource('/matches',{}, {query: {method:'GET', isArray:true}, 'save':   {method:'POST'}});
 });

footballApp.factory('LoginService', function($resource) {
  return $resource('/login',{}, {query: {method:'GET', isArray:true}, 'save':   {method:'POST'}});
 });

footballApp.factory('LeaderService', function($resource) {
  return $resource('/leaderboards',{}, {query: {method:'GET', isArray:true}, 'save':   {method:'POST'}});
 });

footballApp.factory('HaveResults', function($resource) {
  return $resource('/haveResults/:id',{}, {query: {method:'GET', isArray:true}});
  });

footballApp.factory('WinningResults', function($resource) {
  return $resource('/userResults/:id',{}, {query: {method:'GET', isArray:true}});
  });

footballApp.factory('LogoutService', function($resource) {
  return $resource('/logout',{}, {query: {method:'GET', isArray:true}, 'save':   {method:'POST'}});
 });
