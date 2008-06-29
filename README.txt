shooting_star
    by Genki Takiuchi <genki@s21g.com>
    http://blog.s21g.com/genki
    http://blog.s21g.com/takiuchi

== DESCRIPTION:

Our goal is development of practical comet server which will be achieving
over 100,000 simultaneous connections per host. On this purpose, we abandon
portability and use system calls depending on particular OS such as epoll
and kqueue.

== FEATURES/PROBLEMS:

* Comet server
* Comet client implementation (Rails plugin)

== SYNOPSYS:

    shooting_star {init|restart|start|stat|stop} [options]

      -f <config file>
      -g                               debug mode.
      -s                               silent mode.
      -v, --version                    Show version.
      -h, --help                       Show this message.

    Options for subcommand `init':
      -d <base dir>                    ShootingStarize directory.

    Options for subcommand `start':
      -d                               daemon mode.

    Options for subcommand `stat':
      -u                               with uid.
      -s                               with signature.

== REQUIREMENTS:

* Linux or xBSD OS having epoll or kqueue.
* Increase ulimit of nofile up to over 100,000.
  (edit /etc/security/limits.conf file.)
* prototype.js 1.5.0+
* Ruby 1.8.5+
* Ruby on Rails 1.2.0+

== INSTALL:

    $ sudo gem install shooting_star
    $ cd /path/to/rails/root
    $ shooting_star init
    $ ./script/generate meteor

And then, you need to configure config/shooting_star.yml and database.yml.
See also vendor/plugins/meteor_strike/README.

== LICENSE:

(The MIT License)

Copyright (c) 2007 Genki Takiuchi

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
