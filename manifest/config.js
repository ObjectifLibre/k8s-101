const fs = require('fs');

var config;

config = {
  production: {
    url: 'http://localhost:2368',
    database: {
      client: 'mysql',
      connection: {
        host: 'mysql.default.svc.cluster.local',
        user: 'ghost',
        password: 'K4sp3r',
        database: 'ghost',
        charset: 'utf8',
      }
    },
    server: {
      host: '127.0.0.1',
      port: '2368'
    },
    paths: {
      contentPath: '/var/lib/ghost'
    },
  }
}

module.exports = config;

