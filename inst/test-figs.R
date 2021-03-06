mse <- readRDS("/Volumes/Extreme-SSD/src/yelloweye-inside/data-generated/mse/MSE_upweight_dogfish.rds")

`LRP 1GT` <- ggmse::pm_factory("SBMSY", 0.4, c(38, 38))
`LRP 1.5GT` <- ggmse::pm_factory("SBMSY", 0.4, c(56, 56))
`USR 1.5GT` <- ggmse::pm_factory("SBMSY", 0.8, c(56, 56))

FMSY <- MSEtool::PNOF
AAVC <- MSEtool::AAVY
STC <- ggmse::pm_factory("LTY", 0.5, c(1, 10))
LTC <- ggmse::pm_factory("LTY", 0.5, c(38, 38))
PM <- c("LRP 1.5GT", "USR 1.5GT", "LRP 1GT", "FMSY", "STC", "LTC", "AAVC")

library(ggmse)
library(MSEtool)
pm <- ggmse::get_probs(mse, PM)
load_all(".")
pm <- pm[1:5,]
plot_lollipop(pm)
