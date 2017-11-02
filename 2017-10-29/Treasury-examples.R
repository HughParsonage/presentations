library(readxl)
library(data.table)
library(taxstats)
library(Census2016.DataPack)
library(ggplot2)
library(scales)
library(ASGS)
library(broom)
library(grattan)

SA4_simple <-
  tidy(x = SA4_2016,
       region = "SA4_CODE16") %>%
  setDT %>%
  .[, Region := as.integer(id)]

sample_file_1314 %>%
  .[, 
    .(avg_Taxable_Income = mean(Taxable_Income)),
    keyby = Region] %>%
  .[SA4_simple, on = "Region"] %>%
  ggplot(aes(x = long, y = lat, group = group,
             fill = avg_Taxable_Income)) +
  geom_polygon(na.rm = TRUE) + 
  scale_fill_viridis_c()


Drop_CGT <- 
  sample_file_1314 %>%
  copy %>%
  .[, tax_baseline := income_tax(Taxable_Income,
                                 fy.year = "2013-14",
                                 .dots.ATO = .)] %>%
  .[, tax_0pc_CGT := income_tax(Taxable_Income + Net_CG_amt,
                                fy.year = "2013-14",
                                .dots.ATO = .)] %>%
  .[, extra_tax := tax_0pc_CGT - tax_baseline]

# Revenue
Drop_CGT %$%
  sum(extra_tax) * 50 / 10^9

# Chart some distribution:
Drop_CGT %>%
  .[, income_decile := dplyr::ntile(Taxable_Income, 10)] %>%
  .[, 
    .(total_extra_tax = sum(extra_tax)),
    keyby = income_decile] %>%
  .[, total_extra_tax := total_extra_tax * 50] %>%
  ggplot(aes(x = income_decile,
             y = total_extra_tax)) + 
  geom_bar(stat = "identity") + 
  scale_x_continuous(breaks = 1:10) +
  scale_y_continuous(labels = function(x) paste0("$", x / 10^9, "bn"))


# In 2019-20?
Drop_CGT_1920 <- 
  sample_file_1314 %>%
  project(h = 6L) %>%
  .[, tax_baseline := income_tax(Taxable_Income,
                                 fy.year = "2013-14",
                                 .dots.ATO = .)] %>%
  .[, tax_0pc_CGT := income_tax(Taxable_Income + Net_CG_amt,
                                fy.year = "2013-14",
                                .dots.ATO = .)] %>%
  .[, extra_tax := tax_0pc_CGT - tax_baseline] %>%
  .[]

Drop_CGT_1920 %$%
  sum(extra_tax * WEIGHT) / 1e9

##
## Not run: 
library(readxl)
library(data.table)
library(magrittr)
library(grattanCharts)

Unemployment_by_SA2_2011 <- 
  read_excel(system.file("extdata", "unemp.xlsx", package = "ASGS")) %>%
  setDT %>%
  .[, `% unemployment rate` := percent(`2016 unemployment rate` / 100)] %>%
  .[, .(SA2_NAME11 = `Statistical Area Level 2 (SA2)`,
        fillColor = gpal(7, rev = TRUE)[Breaks], 
        labelText = `% unemployment rate`,
        labelTitle = "Unemployment")]

grattan_leaflet(Unemployment_by_SA2_2011, Year = "2011", simple = TRUE)

## End(Not run)












