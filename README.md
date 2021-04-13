# WRF-Chem-LDA-LFR

## Authors

[Xin Zhang](mailto:xinzhang1215@gmail.com) and [Yunyao Li](mailto:yli74@gmu.edu)

## Background

The WRF-Chem-LDA-LFR Model is open-source code in the public domain, and its use is unrestricted.

We have added the lightning assimilation to the basic [WRF model](https://github.com/wrf-model/WRF).

## Modifications

Note that the lightning assimilation has two parts:

### 1. LDA

The lightning data assimilation (LDA) technique was applied to improve the WRF meteorological simulations.

We provide two methods to create the gridded flashes data for LDA.

​	1) The Python scripts saved in `/LDA/Python`

​	2) The IDL scripts in `/LDA/IDL`.

For the LDA concept, please check the following papers:

>[[1]](https://doi.org/10.1002/2017JD026461) Li, Y., Pickering, K. E., Allen, D. J., Barth, M. C., Bela, M. M., Cummings, K. A., ... & Biggerstaff, M. I. (2017). Evaluation of deep convective transport in storms from different convective regimes during the DC3 field campaign using WRF‐Chem with lightning data assimilation. *Journal of Geophysical Research: Atmospheres*, *122*(13), 7140-7163.
>
>[[2]](https://doi.org/10.1175/MWR-D-11-00299.1) Fierro, A. O., Mansell, E. R., Ziegler, C. L., & MacGorman, D. R. (2012). Application of a lightning data assimilation technique in the WRF-ARW model at cloud-resolving scales for the tornado outbreak of 24 May 2011. *Monthly Weather Review*, *140*(8), 2609-2627.
>
>[[3]](https://doi.org/10.1175/MWR-D-13-00142.1) Fierro, A. O., Gao, J., Ziegler, C. L., Mansell, E. R., MacGorman, D. R., & Dembek, S. R. (2014). Evaluation of a cloud-scale lightning data assimilation technique and a 3DVAR method for the analysis and short-term forecast of the 29 June 2012 derecho event. *Monthly Weather Review*, *142*(1), 183-202.
>
>[[4]](https://doi.org/10.1175/MWR-D-14-00183.1) Fierro, A. O., Clark, A. J., Mansell, E. R., MacGorman, D. R., Dembek, S. R., & Ziegler, C. L. (2015). Impact of storm-scale lightning data assimilation on WRF-ARW precipitation forecasts during the 2013 warm season over the contiguous United States. *Monthly Weather Review*, *143*(3), 757-777.

### 2. LFR

The lightning flash rate (LFR) is read directly from the generated LFR files to replace the lightning parameterization.

Then, both lightning flash and lightning NO<sub>x</sub> will be placed in the "true" grids.

For the LFR concept, please check the following papers:

> [[1]](https://doi.org/10.5194/gmd-12-4409-2019
> ) Kang, D., Foley, K. M., Mathur, R., Roselle, S. J., Pickering, K. E., & Allen, D. J. (2019). Simulating lightning NO production in CMAQv5. 2: performance evaluations. *Geoscientific model development*, *12*(10), 4409-4424.
>
> [[2]](https://doi.org/10.5194/gmd-12-3071-2019
> ) Kang, D., Pickering, K. E., Allen, D. J., Foley, K. M., Wong, D. C., Mathur, R., & Roselle, S. J. (2019). Simulating lightning NO production in CMAQv5. 2: evolution of scientific updates. *Geoscientific model development*, *12*(7), 3071-3083.

## Usage

Please check the `README.md` under `LDA` and `LFR` directories.

## Applications

- Improving the convection simulation
- Improving the lightning NO<sub>x</sub> estimation

## Publications

Feel free to use this model for your own research and add the paper information below:

- Xin Zhang et al. (2021). Influence of convection on the upper tropospheric O3 and NOx budget in China. In review.