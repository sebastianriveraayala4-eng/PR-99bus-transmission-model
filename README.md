# Puerto Rico 99-Bus Transmission Power Flow Model

An AC power flow model of the Puerto Rico 230-kV and 115-kV transmission system, built
entirely from public data and distributed in MATPOWER format.

This repository accompanies the paper:

> S. Rivera-Ayala, S. A. Al Nahid, and J. Qi, "Developing a Power Flow Model for Puerto Rico Power Grid Resilience Analysis," submitted to the *IEEE Texas Power and Energy Conference (TPEC) 2027*.

This work was developed as part of the [POWER-UP REU for Undergraduate Research](https://www.sdstate.edu/mechanical-engineering/power-reu-undergraduate-research) at South Dakota State University, under the mentorship of Dr. Junjian Qi.

## Model summary

| Component | Value |
|---|---|
| Buses | 99 (86 at 115 kV, 13 at 230 kV) |
| Branches | 143 (139 lines, 4 explicit 230/115-kV transformers) |
| Generators | 15 plants, 4939 MW of capacity |
| Load buses | 72 |
| Base-case load | 2165.3 MW, 711.7 MVAr (0.95 power factor) |
| Swing bus | Bus 61 (Palo Seco) |
| Voltage setpoints | 1.03 p.u. at all generator buses |
| System base | 100 MVA |

The base case is the first hour of the NREL PR100 load data for fiscal year 2022 (0:00 on
July 1, 2021). Its power flow converges with 2196.2 MW of generation, 30.9 MW of active
losses (1.4%), and bus voltages between 0.978 and 1.03 p.u.

## Repository contents

| File | Description |
|---|---|
| `Puerto_Rico2.m` | MATPOWER case file (bus, generator, and branch data) |
| `line_data.csv` | The 139 lines: buses, voltage class, length, r, x, b, rating |
| `bus_loads.csv` | Bus loads at six PR100 hours (the first one is the base case) |
| `load_allocation_weights.csv` | Share of each of the 78 municipalities assigned to each of the 72 load buses |
| `pr100_bus_loads.m` | The same bus loads as a function, used by the event simulation |
| `simulate_grid_event.m` | Quasi-steady-state simulation of a loss of generation (Section V-A of the paper) |
| `simulate_event_aug2022.m` | Loss of the AES plant on August 17, 2022 (Section V-B) |
| `simulate_blackout_2016.m` | Blackout of September 21, 2016 (Section V-C) |
| `gispowergrid230_115kv.geojson` | GIS layer of the 230-kV and 115-kV lines and substations |

## Quick start

Requires MATLAB or GNU Octave and [MATPOWER](https://matpower.org/) 7.1 or later [1]
(the paper uses 8.1). Run from the folder that holds the files:

```matlab
results = runpf(loadcase('Puerto_Rico2'));                           % base case

out = simulate_event_aug2022();                                      % 2022 event, rho = 1
out = simulate_event_aug2022('Puerto_Rico2', struct('response_frac', 0));   % rho = 0
out = simulate_blackout_2016();                                      % 2016 blackout, rho = 1
out = simulate_blackout_2016('Puerto_Rico2', struct('response_frac', 0));   % rho = 0
```

Each simulation prints the pre-event dispatch and one row per stage.
`help simulate_grid_event` lists all options. The code was run with GNU Octave 8.4.0 and
MATPOWER 8.1.1-dev.

## How the model was built

**Buses.** Each bus is a 230-kV or 115-kV substation in the 2014 PREPA GIS layers of the
Puerto Rico geodata portal [2].

**Lines.** Branches follow the GIS transmission-line layer [2], supplemented by
OpenStreetMap [3] for 10 lines. Line lengths are measured from the line geometries. All
overhead lines are assumed to use the 1192.5-kcmil ACSR Bunting conductor specified by
LUMA [4], with the resistance, the reactance at 1-ft spacing and the diameter from the
datasheet of the equivalent ACSR/AW conductor [5]. Series reactance and line charging are
calculated for an assumed geometric mean phase spacing of 8 m at 230 kV and 5 m at 115 kV.
The two underground 115-kV lines use the cable of LUMA Specification 4752.249 [6], with
assumed spacing and conductor diameter.

| Line type | R' [ohm/m] | X' [ohm/m] | B' [S/m] | Thermal limit |
|---|---|---|---|---|
| 230-kV overhead | 6.070e-5 | 4.842e-4 | 3.393e-9 | 450 MVA |
| 115-kV overhead | 6.070e-5 | 4.488e-4 | 3.672e-9 | 225.1 MVA |
| 115-kV cable | 1.754e-5 | 2.058e-4 | 95.89e-9 | 287.8 MVA (ampacity from [7]) |

The outlets of EcoEléctrica (25-29) and Aguirre (31-21, 31-22) are rated for the plant
capacity at a power factor of 0.85. The total line charging is 181 MVAr at 1.0 p.u.

**Transformers.** All 230/115-kV transformers use typical parameters from the public
385-bus model [8]: r = 0.00228 p.u. and x = 0.07997 p.u. on 100 MVA. Four are explicit
branches. At 29 other substations with both 230-kV and 115-kV yards, the substation is a
single bus and the transformer impedance is placed in series with the 115-kV line that
ends there.

**Generators.** The 15 plants are equivalent injections at the 115-kV or 230-kV bus of
their station. The capacities come from Genera PR [9], except the Oriana solar farm (its
45-MW AC rating). The base-case dispatch is assumed, because the actual dispatch is not
public.

**Loads.** Municipal demand comes from the NREL PR100 hourly load data [10] (Mid-Case,
fiscal year 2022): 'Total - Final' minus 'Auxiliary Load - Final'. Following part of the
approach of Birchfield *et al.* [11], the demand of each of the 78 municipalities is
assigned to the substations that serve it, found by tracing the 38-kV subtransmission
lines in the GIS data [2], and divided evenly among them. Six private 115-kV substations
(buses 28, 63, 64, 65, 68, 69) are assumed to carry the industrial share of their
municipality's PR100 sales, which is deducted from its other substations. Reactive power
assumes a power factor of 0.95.

The header of `Puerto_Rico2.m` lists every change from the earlier version of the case
file, with its reason.

## Assumptions and limitations

- The model is built from public data and is not the utility's network model. Results
  should not be used for operational decisions.
- The phase spacings, the cable geometry, the transformer parameters, the dispatch, the
  spinning reserve and the load-shedding limit are assumed.
- The 38-kV subtransmission network and shunt compensation are not modeled. Six small
  plants exceed their reactive limits in the base case.
- The PR100 loads are a projection with a typical-year hourly shape, not measurements, and
  they include the transmission losses that the power flow also computes (about 1.4%).
- The event simulation is quasi-steady-state: it does not represent frequency dynamics,
  relay timing or generator protection.
- For a larger public model that also includes the 38-kV network, see the 385-bus model of
  Anton and Ilić [8], based on the MIT Lincoln Laboratory study [12].

## References

[1] R. D. Zimmerman, C. E. Murillo-Sánchez, and R. J. Thomas, "MATPOWER: Steady-state operations, planning, and analysis tools for power systems research and education," *IEEE Trans. Power Syst.*, vol. 26, no. 1, pp. 12–19, Feb. 2011.

[2] Puerto Rico Electric Power Authority (PREPA), "AEE infrastructure: Transmission and distribution," Portal de Geodatos del Gobierno de Puerto Rico [Dataset], 2014. [Online]. Available: https://gis.pr.gov/descargaGeodatos/Infraestructuras/Pages/Electricidad.aspx

[3] OpenStreetMap contributors, "OpenStreetMap." [Online]. Available: https://www.openstreetmap.org

[4] LUMA Energy, "1192.5 MCM ACSR Bunting (45/7) overhead conductor," Material Spec. 4752.205, Nov. 2024. [Online]. Available: https://lumapr.com/wp-content/uploads/2025/01/4752.205-1192.5-MCM-ACSR-Bunting-Overhead-Conductor.pdf

[5] Prysmian Group, "TransPowr ACSR/AW bare overhead conductor," Product datasheet. [Online]. Available: https://na.prysmian.com/sites/na.prysmian.com/files/media/documents/TransPowr%C2%AE%20ACSR-AW%20Bare%20Overhead%20Conductor%20%28US%29.pdf

[6] LUMA Energy, "115 kV concentric neutral wire shield underground cable and accessories," Equip. Spec. 4752.249, Aug. 2022. [Online]. Available: https://lumapr.com/wp-content/uploads/2025/01/4752.249-115kV-Concentric-Neutral-Wire-Shield-Underground-Cable-and-Accessories.pdf

[7] *IEEE Standard Power Cable Ampacity Tables*, IEEE Std 835-1994, 1994.

[8] L. L. Anton and M. Ilić, "Unified diagnostics for quantifying AC operating-point robustness under injection and topological uncertainties with regime changes," arXiv preprint arXiv:2602.19002, 2026. [Online]. Available: https://arxiv.org/abs/2602.19002

[9] Genera PR, "Data de generación." [Online]. Available: http://genera-pr.com/data-generacion

[10] National Renewable Energy Laboratory, "PR100: Puerto Rico grid resilience and transition to 100% renewable energy," Data.gov catalog. [Online]. Available: https://catalog.data.gov/dataset/pr100-puerto-rico-grid-resilience-and-transition-to-100-renewable-energy

[11] A. B. Birchfield, T. Xu, K. M. Gegner, K. S. Shetye, and T. J. Overbye, "Grid structural characteristics as validation criteria for synthetic networks," *IEEE Trans. Power Syst.*, vol. 32, no. 4, pp. 3258–3265, Jul. 2017.

[12] M. Ilić, R. Salcedo Ulerio, E. Corbett, E. Austin, M. Shatz, and E. Limpaecher, "A framework for evaluating electric power grid improvements in Puerto Rico," MIT Lincoln Laboratory, Lexington, MA, USA, Project Rep., Jul. 2019.

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
