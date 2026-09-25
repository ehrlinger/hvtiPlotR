# page structure is stable for each section

    Code
      for (page in pages) page_structure(page)
    Output
      [ef] ef
        geoms: GeomPoint, GeomSmooth, GeomRug 
        rows : 60, 80, 5 
        y    : ef 
      [peak_grad] peak_grad
        geoms: GeomPoint, GeomSmooth, GeomRug 
        rows : 60, 80, 3 
        y    : peak_grad 

---

    Code
      for (page in pages) page_structure(page)
    Output
      [male] male
        geoms: GeomBar 
        rows : 25 
        x    : 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 
        fill : 0 1 
        y    : Proportion 
      [nyha] nyha
        geoms: GeomBar 
        rows : 31 
        x    : 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 
        fill : 1 2 3 4 
        y    : Proportion 

---

    Code
      for (page in pages) page_structure(page)
    Output
      [male] male
        geoms: GeomBar 
        rows : 25 
        x    : 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 
        fill : 0 1 
        y    : Count 
      [nyha] nyha
        geoms: GeomBar 
        rows : 31 
        x    : 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 
        fill : 1 2 3 4 
        y    : Count 

