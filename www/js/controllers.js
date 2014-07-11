'use strict';

/* Controllers */

var footballControllers = angular.module('footballControllers', []);

footballControllers.controller('FootballCtrl',['$scope', '$http', 'MatchesService','$route','LoginService','LogoutService','LeaderService',
  function($scope, $http, MatchesService,$route, LoginService,LogoutService,LeaderService ) {
    $scope.loginuser= LoginService.query();
    $scope.matches=MatchesService.query();
    $scope.login= function(){
      LoginService.save($scope.user, function() {
        $route.reload();
      })
    };
    $scope.logout=function(){
      LogoutService.save(function(){
        $route.reload();
      })
    };
    $scope.leaderboard=LeaderService.query();
    $scope.orderProp = 'points'
	  /*$http.get('matches/matches.json').success(function(data) {
	    $scope.matches = data;
	  });*/
  }]);

footballControllers.controller('MatchLeaderboard',['$scope', '$http', 'LeaderService','$route','LoginService','LogoutService',
  function($scope, $http, LeaderService,$route, LoginService,LogoutService ) {
    $scope.loginuser= LoginService.query();
    $scope.login= function(){
      LoginService.save($scope.user, function() {
        $route.reload();
      })
    };
    $scope.logout=function(){
      LogoutService.save(function(){
        $route.reload();
      })
    };
    $scope.leaderboard=LeaderService.query();
    $scope.orderProp = 'points'
    /*$http.get('matches/matches.json').success(function(data) {
      $scope.matches = data;
    });*/
  }]);

footballControllers.controller('MatchDetailCtrl', ['$scope', '$routeParams', '$http', 'BetService','$route','HaveResults','LoginService','LogoutService',
  function($scope, $routeParams, $http, BetService, $route, HaveResults, LoginService,LogoutService) {
    $scope.loginuser= LoginService.query();
    $scope.login= function(){
      LoginService.save($scope.user, function() {
        $route.reload();
      })
    };
    $scope.logout=function(){
      LogoutService.save(function(){
        $route.reload();
      })
    };
    $http.get('matches/' + $routeParams.matchId + '.json').success(function(data) {
      $scope.match = data;
    });
    $scope.answer = HaveResults.query({id: $routeParams.matchId});
    $scope.bets = BetService.query({id: $routeParams.matchId});
    
    //BetService.single({ matchId: $routeParams.matchId }, function(response){ 
     //  $scope.bets = response ; 
    //});

    //$scope.bets=BetService.query();
    //$route.reload();
    $scope.save = function() {
      BetService.save({id: $routeParams.matchId},$scope.user, function() {
        $route.reload();
      })
    };
  }]);

footballControllers.controller('MatchResultCtrl', ['$scope', '$routeParams', '$http', 'ResultService','$route','HaveResults','WinningResults','LoginService','LogoutService',
  function($scope, $routeParams, $http, ResultService, $route, HaveResults, WinningResults, LoginService,LogoutService) {
    $scope.loginuser= LoginService.query();
    $scope.login= function(){
      LoginService.save($scope.user, function() {
        $route.reload();
      })
    };
    $scope.logout=function(){
      LogoutService.save(function(){
        $route.reload();
      })
    };
    $http.get('matches/' + $routeParams.matchId + '.json').success(function(data) {
      $scope.match = data;
    });

    $scope.results=ResultService.query({id: $routeParams.matchId});
    $scope.answer = HaveResults.query({id: $routeParams.matchId});
    $scope.stats = WinningResults.query({id: $routeParams.matchId});
    //$route.reload();
    $scope.save = function() {
      ResultService.save({id: $routeParams.matchId},$scope.user, function() {
        $route.reload();
      })
    };
    $scope.orderProp='points';
  }]);