#WTFIPN

When the Fuck is Pizza Night?

##Developing

This is a [Sinatra](http://www.sinatrarb.com/) app that uses [Compass](http://compass-style.org/) to manage its stylesheets. If you're going to edit styles, run `compass watch` to compile changes from public/scss into public/stylesheets. You can install compass with `gem install compass`.

To run a dev server, my preferred solution is `shotgun`. You can install shotgun with `gem install shotgun`.

###Dependencies

This project uses rubygems and Bundler to manage dependencies. run `bundle install` to make sure you have everything you need before starting your local server.

- wikipedia-client: used in finding the "because on this day" bit
- json: for parsing content pulled down from Wikipedia

##TODO

- loading icon before ajax
- postgresql db
- data model
- dashboard
- better wiki parsing:
    - process more curly-brace tokens
        - [] citations
        - {{convert
        - one-offs: {{1/4}}¢/L, {{F1|1970}}, {{sortfrac|2|1|2}}, {{mpl|2010 XC|15}}, {{US$|2,520,700}}
    - <sub> and <sup>
    - decapitalize the first word if it is an article (or if it wasn't originally in a token?!)
    - change tenses of verbs...
    - search for all special characters: `%^&*()-=_+[]\}|;':",./<>?
    - remove instances of negative emotion?
    - for sentence fragments, rearrange the reason. current: "because on this day in 1986, First meeting of the Internet Engineering Task Force". fixed: "because today in 1986 was the First meeting of the Internet Engineering Task Force"
- caching of the pages, reporting on new events that don't parse well
- finish adding colons.txt to the matches in processColons
