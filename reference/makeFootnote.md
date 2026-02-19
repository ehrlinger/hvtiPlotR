# Create a footnote for figures.

Use grid graphics to add a footnote to a plot.

## Usage

``` r
makeFootnote(
  footnoteText = getwd(),
  size = 0.7,
  color = grey(0.5),
  timestamp = TRUE
)
```

## Arguments

- footnoteText:

  text to place in footnote. Defaults to the local working directory.

- size:

  font size

- color:

  Font color (lightgrey)

- timestamp:

  should we add the current timestamp.

## References

http://ryouready.wordpress.com/2009/02/17/r-good-practice-adding-footnotes-to-graphics/

## Examples

``` r
plot(1:10)
makeFootnote()

```
