#WTFIPN

When the Fuck is Pizza Night?

##Developing

This is a [Sinatra](http://www.sinatrarb.com/) app that uses [Compass](http://compass-style.org/) to manage its stylesheets. If you're going to edit styles, run `compass watch` to compile changes from public/scss into public/stylesheets. You can install compass with `gem install compass`.

To run a dev server, my preferred solution is `shotgun`. You can install shotgun with `gem install shotgun`.

###Dependencies

This project uses rubygems and Bundler to manage dependencies. run `bundle install` to make sure you have everything you need before starting your local server.

- wikipedia-client: used in finding the "because on this day" bit
- json: for parsing content pulled down from Wikipedia
