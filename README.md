# Puerto Rico 99-Bus Synthetic Transmission Model

A synthetic AC power flow model of the Puerto Rico 230-kV and 115-kV transmission system, built entirely from public data and distributed in MATPOWER format.

This repository accompanies the paper:

> S. Rivera-Ayala, S. A. Al Nahid, and J. Qi, "Developing a Power Flow Model for Puerto Rico Power Grid Resilience Analysis," submitted to the *IEEE PES General Meeting 2027*.

>This work was developed as part of the [POWER-UP REU for Undergraduate Research](https://www.sdstate.edu/mechanical-engineering/power-reu-undergraduate-research) at South Dakota State University, under the mentorship of Dr. Junjian Qi.

## Model summary

| Component | Value |
|---|---|
| Buses | 99 (86 at 115 kV, 13 at 230 kV) |
| Branches | 143 (139 lines, 4 transformers) |
| Generators | 15 |
| Load buses | 72 |
| Total generation capacity | 4,891.0 MW |
| Total load | 2,330.3 MW, 812.0 MVAr |
| Swing bus | Bus 61 (Palo Seco), 1.0 p.u. |
| System base | 100 MVA |

The base-case power flow converges with 2,356.0 MW of generation and 25.69 MW of active losses.

## Repository contents

| File | Description |
|---|---|
| `Puerto_Rico2.m` | MATPOWER case file (bus, branch, and generator data) |
| `gispowergrid230_115kv.geojson` | GIS layer of 230-kV and 115-kV lines and substations |
| `lines_data_115_230.xlsx` | Line lengths and impedance calculations |
| `Systhetic_Power_Data_for_Load_Buses.xlsx` | Load allocation from municipal demand to substation buses |

## Quick start

Requires MATLAB and [MATPOWER](https://matpower.org/).

```matlab
mpc = loadcase('Puerto_Rico2');
results = runpf(mpc);
```

## How the model was built

**Buses.** Each bus corresponds to a 230-kV or 115-kV substation in the GIS data of the Puerto Rico geodata portal. Bus coordinates are taken from the GIS data and checked against the 2014 transmission center layer.

**Lines.** Branches follow the GIS transmission-line layer, supplemented by OpenStreetMap where the GIS data have gaps. Line lengths are measured from the line geometries.

| Line type | Conductor | Thermal limit |
|---|---|---|
| 230-kV overhead | 1192.5-kcmil ACSR Bunting | 450.2 MVA |
| 115-kV overhead | 1192.5-kcmil ACSR Bunting | 225.1 MVA |
| 115-kV underground (2 lines) | XLPE copper cable | 287.8 MVA |

**Transformers.** Four 230/115-kV transformers are modeled explicitly with assumed typical parameters (r = 0.0005 p.u., x = 0.01 p.u., 547 MVA). Substations with both 230-kV and 115-kV yards are represented by a single bus, so the transformation inside them is treated as ideal.

**Generators.** The 15 generators are connected at the 115-kV or 230-kV buses of their power stations. All PV buses have a voltage setpoint of 1.0 p.u.

**Loads.** Municipal demand comes from the 2021 PR100 data. Each municipality is assigned to the substations that serve it by tracing the 38-kV subtransmission lines in the GIS data. When N substations serve a municipality, its demand is split equally among them (weight 1/N). Reactive power assumes a power factor of about 0.95.

## Assumptions and limitations

- This is a **synthetic** model. It reproduces the structure of the real grid but is not the utility's network model.
- Conductor, transformer, and dispatch data are not publicly available, so they are assumed as described above.
- Line charging is small (3.7 MVAr in total).
- Results should not be used for operational decisions.

## Data sources

- Puerto Rico Innovation and Technology Office (PRITO), *Infraestructuras de electricidad de Puerto Rico*, Portal de Geodatos del Gobierno de Puerto Rico. https://gis.pr.gov/descargaGeodatos/Infraestructuras/Pages/Electricidad.aspx
- U.S. Department of Energy, *PR100: Puerto Rico Grid Resilience and Transitions to 100% Renewable Energy Study*, NREL, 2024.
- Puerto Rico Energy Bureau, *PREPARE Dashboard*. https://dashboard.energia.pr.gov/Custom
- LUMA Energy, material specifications 4752.205 (ACSR Bunting) and 4752.249 (115-kV underground cable).


## References
 
[1] R. D. Zimmerman, C. E. Murillo-Sánchez, and R. J. Thomas, "MATPOWER: Steady-state operations, planning, and analysis tools for power systems research and education," *IEEE Trans. Power Syst.*, vol. 26, no. 1, pp. 12–19, Feb. 2011, doi: 10.1109/TPWRS.2010.2051168.
 
[2] Puerto Rico Innovation and Technology Office (PRITO), "Infraestructuras de electricidad de Puerto Rico: Líneas de transmisión de 230 kV y 115 kV y subestaciones," Portal de Geodatos del Gobierno de Puerto Rico [Dataset], 2024. [Online]. Available: https://gis.pr.gov/descargaGeodatos/Infraestructuras/Pages/Electricidad.aspx
 
[3] Puerto Rico Innovation and Technology Office (PRITO), "Centros de transmisión 2014," Portal de Geodatos del Gobierno de Puerto Rico [Dataset], 2014. [Online]. Available: https://gis.pr.gov/descargaGeodatos/Infraestructuras/Pages/Electricidad.aspx
 
[4] OpenStreetMap contributors, "OpenStreetMap." [Online]. Available: https://www.openstreetmap.org
 
[5] LUMA Energy, "Material specification 4752.205: 1192.5 MCM ACSR Bunting overhead conductor," San Juan, PR, USA, 2025. [Online]. Available: https://lumapr.com/wp-content/uploads/2025/01/4752.205-1192.5-MCM-ACSR-Bunting-Overhead-Conductor.pdf
 
[6] Prysmian Group, "TransPowr ACSR/AW bare overhead conductor," Datasheet. [Online]. Available: https://na.prysmian.com/sites/na.prysmian.com/files/media/documents/TransPowr%C2%AE%20ACSR-AW%20Bare%20Overhead%20Conductor%20%28US%29.pdf
 
[7] LUMA Energy, "Material specification 4752.249: 115 kV concentric neutral wire shield underground cable and accessories," San Juan, PR, USA, 2025. [Online]. Available: https://lumapr.com/wp-content/uploads/2025/01/4752.249-115kV-Concentric-Neutral-Wire-Shield-Underground-Cable-and-Accessories.pdf
 
[8] alfanar, "Power cables," Product catalog. [Online]. Available: https://media.alfanar.com/catalogs/cables_wires/LV_power_cables.pdf
 
[9] *IEEE Standard Power Cable Ampacity Tables*, IEEE Std 835-1994, 1994.
 
[10] U.S. Department of Energy (DOE), "PR100: Puerto Rico grid resilience and transitions to 100% renewable energy study," National Renewable Energy Laboratory (NREL), Golden, CO, USA, 2024. [Online]. Available: https://catalog.data.gov/dataset/pr100-puerto-rico-grid-resilience-and-transition-to-100-renewable-energy
 
[11] A. B. Birchfield, T. Xu, K. M. Gegner, K. S. Shetye, and T. J. Overbye, "Grid structural characteristics as validation criteria for synthetic networks," *IEEE Trans. Power Syst.*, vol. 32, no. 4, pp. 3258–3265, Jul. 2017, doi: 10.1109/TPWRS.2016.2616385.
 
[12] A. B. Birchfield, T. Xu, and T. J. Overbye, "Power flow convergence and reactive power planning in the creation of large synthetic grids," *IEEE Trans. Power Syst.*, vol. 33, no. 6, pp. 6667–6674, Nov. 2018, doi: 10.1109/TPWRS.2018.2813525.
 
[13] L. L. Anton and M. D. Ilić, "Unified diagnostics for quantifying AC operating-point robustness under injection and topological uncertainties with regime changes," arXiv preprint arXiv:2602.19002, 2026. [Online]. Available: https://arxiv.org/abs/2602.19002
 
[14] L. L. Anton and M. D. Ilić, "Probabilistic deliverability assessment of distributed energy resources via scenario-based AC optimal power flow," *Energies*, vol. 18, no. 18, Art. no. 4832, Sep. 2025, doi: 10.3390/en18184832.
 
[15] M. Ilić, R. Salcedo Ulerio, E. Corbett, E. Austin, M. Shatz, and E. Limpaecher, "A framework for evaluating electric power grid improvements in Puerto Rico," MIT Lincoln Laboratory, Lexington, MA, USA, Project Rep., Jul. 2019.

## Citation

If you use this model, please cite the paper above. A BibTeX entry will be added once the paper is published.

## Acknowledgments
 
This work was carried out through the [POWER-UP REU for Undergraduate Research](https://www.sdstate.edu/mechanical-engineering/power-reu-undergraduate-research) at South Dakota State University.
 
- **Lead PI:** Dr. Jeffrey Doom, Mechanical Engineering
- **Co-PI:** Dr. Jung-Han Kimn, Mathematics
- **Research mentor:** Dr. Junjian Qi, Department of Electrical Engineering and Computer Science

## Contact

- Sebastián Rivera-Ayala, Electrical and Computer Engineering, University of Puerto Rico at Mayagüez, sebastian.rivera50@upr.edu
- Syed Abdullah Al Nahid, Electrical Engineering and Computer Science, South Dakota State University, syedabdullahal.nahid@jacks.sdstate.edu
- Dr. Junjian Qi, Electrical Engineering and Computer Science, South Dakota State University, junjian.qi@sdstate.edu
