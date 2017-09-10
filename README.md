# AffinityPropagation

This gem allows you to use the affinity propagation algorithm (see BJ Frey and D Dueck,
[Science 315, Feb 16, 2007](http://www.psi.toronto.edu/affinitypropagation/FreyDueckScience07.pdf)) to cluster arbitrary
data by providing the data and a block to calculate the similarity between any two data points in that list.

For more information on affinity propagation, visit the [FAQ over at University of Toronto](http://www.psi.toronto.edu/affinitypropagation/faq.html).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'affinity_propagation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install affinity_propagation

## Usage

A simple example of usage is:

```ruby
data = [1, 2, 3, 4, 500, 525, 602, 630, 1000, 1100, 1065, 1150]
apc = AffinityPropagation::Calculator.new(data) do |datum, exemplar|
  # A recommended similarity function from the original paper:
  # negative square of the distance between two points
  # However you can choose anything here and even make it asymmetrical if your data needs it
  -((datum - exemplar) ** 2)
end
apc.run(stable_iterations: 50)
apc.clusters
```
This will result in the following (beautified) output:
```ruby
[
  {
    :exemplar=>2,
    :members=>[1, 2, 4]
  },
  {
    :exemplar=>3,
    :members=>[3]
  },
  {
    :exemplar=>602,
    :members=>[500, 525, 602, 630]
  },
  {
    :exemplar=>1065,
    :members=>[1000, 1100, 1065, 1150]
  }
]
```
A more real-world example would be something like the following:
```ruby
require 'active_support/all'
data = [
  { value: 'A', timestamp: 1.year.ago },
  { value: 'B', timestamp: 1.year.ago },
  { value: 'C', timestamp: 1.year.ago },
  { value: 'D', timestamp: 1.year.ago + 1.hour },
  { value: 'E', timestamp: 1.year.ago + 1.day },

  { value: 'a', timestamp: 1.month.ago },
  { value: 'b', timestamp: 1.month.ago + 1.hour },
  { value: 'c', timestamp: 1.month.ago + 1.day },

  { value: 'd', timestamp: 2.weeks.ago },
  { value: 'e', timestamp: 2.weeks.ago - 3.hours },
  { value: 'f', timestamp: 2.weeks.ago - 10.hours },
  { value: 'g', timestamp: 2.weeks.ago + 5.hours },

  { value: 'h', timestamp: 24.hours.ago },
  { value: 'i', timestamp: 40.hours.ago },
  { value: 'j', timestamp: 12.hours.ago },
  { value: 'k', timestamp: 12.minutes.ago }
]
apc = AffinityPropagation::Calculator.new(data, lambda: 0.9) do |datum, exemplar|
  difference = datum[:timestamp] - exemplar[:timestamp]

  -(difference ** 2)
end
apc.run(stable_iterations: 25)
apc.clusters.map { |center| center[:members].map { |item| item[:value] } }
```
## Tweaking the Result
There are at least two ways to tweak the algorithm to generate clusters closer to any expectations you might have for
your data:

1. Changing the dampening factor, `lambda`, which can be provided to the constructor for `AffinityPropagation::Calculator`.
This helps prevent numerical oscillations while updating the responsibilities and similarities matrices.  This defaults
0.75 but can be changed by specifying the lambda name argument as in the second example above.
1. Assigning custom values to the self-similarity nodes in the similarity matrix generated when you instantiate the
`AffinityPropagation::Calculator` object.  These self-similarity values are currently assigned a common value to
not suggest any one exemplar over another.  This common value is the median of all similarities found in the entire
similarity matrix.  This is not currently tweakable from your code but there's a plan to allow this to be tweaked.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

This is my initial take on this problem and I have still to add a few usability, configuration and performance tweaks
but wanted to get this out there so people can use it.  If you find it useful and are able to contribute to remove some
of the clearly vast set of issues that this codebase has, please send me a pull request and let's talk!
 
Bug reports and pull requests are welcome on GitHub at https://github.com/sjaveed/affinity_propagation.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
