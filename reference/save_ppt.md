# Function for saving a ggplot object, or list of ggplot objects to a powerpoint document for presentations.

Function for saving a ggplot object, or list of ggplot objects to a
powerpoint document for presentations.

## Usage

``` r
save_ppt(
  object,
  template = "../graphs/RD.pptx",
  powerpoint = "../graphs/pptExample.pptx",
  slide_title = "Treatment Difference",
  offx = 0.75,
  offy = 0.8,
  width = 8,
  height = 6
)
```

## Arguments

- object:

  ggplot object, or list of ggplot objects

- template:

  a powerpoint presentation, used as a template for creating the output
  document

- powerpoint:

  filename for saving the powerpoint presentation output

- slide_title:

  the string used for the slide title

- offx:

  x offset from upper left slide corner

- offy:

  y offset from upper left slide corner

- width:

  graphic object width

- height:

  graphic object height

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a plot
d.plt <- ggplot(plt.dta) + geom_smooth(aes(x=x, y=yhat, color=inductCRT), se=FALSE, width=4)+
  scale_color_brewer(palette = "Set3")+
  labs(x="", y="")+
  theme(legend.position="none")
  } # }
```
