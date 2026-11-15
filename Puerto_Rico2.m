function mpc = Puerto_Rico2
%PUERTO_RICO2  99-bus power flow case of the Puerto Rico 230-kV and 115-kV
%   transmission system (MATPOWER case format, version 2).
%
%   Corrected version of the earlier case file (commit 24cdef4) of
%   https://github.com/sebastianriveraayala4-eng/PR-99bus-transmission-model
%   Topology, bus numbering, line lengths, overhead-line resistances and
%   transformer data are unchanged. Loads were rebuilt (change 11).
%
%   CHANGES WITH RESPECT TO THE EARLIER REPOSITORY FILE (commit 24cdef4)
%   1. Overhead-line series reactance. The previous value (0.0725 ohm/kft =
%      2.3786e-4 ohm/m) is the datasheet reactance at 1-ft spacing only. The
%      spacing term is now included: X' = w*2e-7*ln(GMD/GMR), GMR = 0.0130 m
%      (implied by the datasheet value), GMD = 8 m (230 kV) and 5 m (115 kV):
%         230 kV: X' = 4.8423e-04 ohm/m      115 kV: X' = 4.4879e-04 ohm/m
%      For the 29 lines with a 230/115-kV transformer in series, only the
%      line part of x is changed (the transformer x = 0.07997 p.u. is kept).
%   2. Line charging. The previous b was inversely proportional to length.
%      Now b = B' * length * Zbase, B' = w*2*pi*eps0/ln(GMD/r), r = 16.5 mm:
%         230 kV: B' = 3.393e-09 S/m        115 kV: B' = 3.672e-09 S/m
%      Total line charging at 1.0 p.u.: 171.9 MVAr (overhead) + 9.2 MVAr
%      (cables); it was 3.7 MVAr.
%   3. Underground cables (43-90, 43-76), from LUMA Specification 4752.249:
%      2750 kcmil segmental copper, 700-mil XLPE insulation, 90 C. The
%      repository values came from a low-voltage cable catalogue. Now
%         R' = 1.754e-05 ohm/m (ac, 90 C)   X' = 2.058e-04 ohm/m
%         C' = 0.254 uF/km  ->  B' = 9.589e-08 S/m
%      ASSUMED, because the specification does not give them: conductor
%      diameter 1.91 in, 1.5-mm conductor shield, permittivity 2.4, and a
%      flat formation at 0.23 m spacing (this sets X'). Lengths unchanged.
%   4. Plant-outlet ratings, set to plant capacity at 0.85 power factor
%      (Pmax/0.85, rounded up to 10 MVA):
%         25-29 (EcoElectrica, 507 MW):      450 -> 600 MVA
%         31-22 (Aguirre, 900 MW, 230 kV):   450 -> 1060 MVA
%         31-21 (Aguirre, 900 MW, 115 kV):   225.08 -> 1060 MVA
%   5. Generator voltage setpoints 1.00 -> 1.03 p.u. (all units). With the
%      corrected reactances, 1.00 p.u. leaves base-case voltages below 0.95.
%   6. Dispatch (Table II of the paper). The assumed dispatch pattern of the
%      thermal plants is kept and scaled to the corrected load (see 11),
%      rounded to 5 MW: Costa Sur 420 -> 395, EcoElectrica 450 -> 395,
%      Aguirre 450 -> 425, AES 400 -> 380, Cambalache 200 -> 190, San Juan
%      125 -> 120, Mayaguez 80 -> 75 MW; Palo Seco (swing) Pg = solved
%      value. (Santa Isabel Pmax = 101 MW, as now in the repository.)
%      Oriana solar farm (bus 95) Pmax 75 -> 45 MW, the AC rating of the
%      plant (58 MW is its DC rating).
%   7. Solar plants (buses 95, 97) Pg -> 0 MW, because the load snapshot is
%      0:00 on July 1, 2021. Both units stay in service.
%   8. (Superseded by 11(e): the loads at buses 63, 64, 65, 68, 69 are replaced.)
%   9. Branch 97-42: r had been entered equal to x; r recomputed from length.
%  10. Housekeeping: function name matches the file name; transformer rateC
%      1 -> 0; bus Vmax/Vmin 1.1/0.9 -> 1.05/0.95 (the limits used in the
%      paper); wrong comments fixed (bus 24 is not the swing bus; branches
%      31-21 and 31-22 are the Aguirre plant ties); the unsuppressed
%      Pdis/Qdis/pgen/qgen statements were removed.
%
%  11. Loads rebuilt from the NREL PR100 hourly load data (Mid-Case, fiscal
%      year 2022, first hour = 0:00 on July 1, 2021; a projection with a
%      typical-year hourly shape, not a measurement), with the municipal-to-
%      substation weights of the repository workbook and these corrections:
%      (a) the values of Guanica, Guayama, Guayanilla and Guaynabo had been
%          entered one position off (31.67, 9.13, 112.51, 8.35 MW); PR100
%          gives 8.35, 31.67, 9.13, 112.51 MW;
%      (b) PR100 'Auxiliary Load' (power-plant station service, 81.8 MW
%          island-wide, spread over the municipalities) is no longer part
%          of the bus loads: bus load = 'Total - Final' minus 'Auxiliary
%          Load - Final'. It still includes PR100's technical and non-
%          technical losses (14.7% of sales) and PREPA own use;
%      (c) Juana Diaz (31.1 MW) and Las Marias (2.3 MW), which had no
%          substation, and the missing third of Hatillo (6.3 MW) are
%          assigned as in the workbook's 'Substations' sheet;
%      (d) the half of Guayama that the workbook sends to the Juana Diaz
%          substation (45 km away) goes to Jobos (5 km) instead. This one
%          is a judgment, not taken from the workbook.
%      (e) the loads at the private 115-kV substations (buses 28, 63, 64,
%          65, 68, 69; 123.0 MW in the repository) are replaced. They were
%          rough estimates, and PR100 already contains the industrial
%          demand of every municipality, so they were counted twice. Each
%          private substation now receives the industrial share of its
%          municipality (PR100 industrial sales / total sales in the first
%          hour: Manati 0.408 at bus 28; Barceloneta 0.450, split equally
%          among buses 63, 64, 65; Guayanilla 0.184, split equally between
%          buses 68, 69), and the other substations of the municipality
%          are reduced by the same share. The total load does not change.
%          The split is an assumption.
%      Total load 2165.3 MW, 711.7 MVAr (0.95 power factor) at 72 buses;
%      the repository case had 2330.3 MW at 72 buses. Loads at other hours:
%      pr100_bus_loads.m.
%
%   Swing bus: 61 (Palo Seco). System base: 100 MVA.

mpc.version = '2';
mpc.baseMVA = 100;

%% MATPOWER Bus (Puerto Rico 115-230 kV)

mpc.bus = [
  % bus  type  Pd(MW)      Qd(MVAR)    Gs  Bs  area Vm      Va     baseKV  zone Vmax  Vmin
	1    1    22.7583     7.4803      0   0   1    1.0000  0.0000  230     1    1.05  0.95; % AGUAS BUENAS GIS TC
	2    1    14.3052     4.7019      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % ALTURAS DE MAYAGUEZ 6012
	3    1    32.8652     10.8023     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % ANASCO TC
	4    1    31.3435     10.3021     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % BARCELONETA TC
	5    1    93.7495     30.8140     0   0   1    1.0000  0.0000  230     1    1.05  0.95; % BAYAMON TC
	6    1    56.9278     18.7113     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % BERWIND TC
	7    1    13.5613     4.4574      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % BUEN PASTOR 1908
	8    1    95.4264     31.3651     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % CAGUAS TC
	9    2    0.0000      0.0000      0   0   1    1.0300  0.0000  230     1    1.05  0.95; % CAMBALACHE GP TC
	10   1    34.8570     11.4569     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % CAMBALACHE TC
	11   1    18.2666     6.0039      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % CANA-SUBSTATION
	12   1    44.2077     14.5304     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % CANAS TC
	13   1    13.5245     4.4453      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % CANDELARIA ARENAS 1718
	14   1    48.6921     16.0043     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % CANOVANAS TC
	15   2    0.0000      0.0000      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % CAONILLAS (Hidroeléctrica - PV)
	16   1    74.0306     24.3327     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % CAYEY TC
	17   2    0.0000      0.0000      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % CENTRAL SAN JUAN PLANT (Termoeléctrica - PV)
	18   1    5.6470      1.8561      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % CIALES 8701
	19   2    0.0000      0.0000      0   0   1    1.0300  0.0000  230     1    1.05  0.95; % COGENERADORA AES (Carbón/Privado - PV)
	20   1    52.4210     17.2299     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % COMERIO TC
	21   1    0.0000      0.0000      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % COMPLEJO DE AGUIRRE 115
	22   1    0.0000      0.0000      0   0   1    1.0000  0.0000  230     1    1.05  0.95; % COMPLEJO DE AGUIRRE 230
	23   1    6.0351      1.9836      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % CONQUISTADOR 1204
	24   2    0.0000      0.0000      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % COSTA SUR PLANT (Termoelectrica - PV)
	25   1    24.7234     8.1262      0   0   1    1.0000  0.0000  230     1    1.05  0.95; % COSTA SUR SP TC
	26   1    69.4349     22.8221     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % DORADO TC
	27   1    18.4781     6.0735      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % DUGUAO 2101
	28   1    16.4616     5.4107      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % DUPONT1-PRIVATE (Carga Industrial Reincorporada)-------INDUSTRIAL
	29   2    0.0000      0.0000      0   0   1    1.0300  0.0000  230     1    1.05  0.95; % ECOELECTRICA (Gas Natural/IPP - PV Reincorporado)
	30   1    8.9410      2.9388      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % ENCANTADA
	31   2    0.0000      0.0000      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % CENTRAL AGUIRRE
	32   1    13.4004     4.4045      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % FAJARDO TC 2001 2004
	33   1    3.7029      1.2171      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % FUTURA SUB. JUAN MARTIN
	34   1    13.5613     4.4574      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % GRANA 1907-1909
	35   1    38.8349     12.7644     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % GUANICA TC
	36   1    13.5613     4.4574      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % GUAYNABO PUEBLO 1901 1904
	37   1    47.0624     15.4687     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % HATILLO TC
	38   1    75.1944     24.7152     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % HATO REY TC
	39   1    42.3310     13.9135     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % HATO TEJAS TC
	40   1    3.3970      1.1165      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % HIDROELECTRICA DOS BOCAS 8005
	41   1    0.0000      0.0000      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % HOSPITAL DISTRITO 7003
	42   1    33.5529     11.0283     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % HUMACAO TC
	43   1    40.7948     13.4086     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % ISLA GRANDE
	44   1    6.7368      2.2143      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % JAYUYA SUB
	45   1    44.5432     14.6406     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % JOBOS TC
	46   1    44.9192     14.7642     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % JUANA DIAZ_TC
	47   1    102.7686    33.7784     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % JUNCOS TC
	48   1    29.5300     9.7060      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % LAS ACACIAS 6801 6802
	49   1    3.6627      1.2039      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % LAS CRUCES 3602
	50   1    13.5613     4.4574      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % LAS LOMAS 1525
	51   1    28.4236     9.3424      0   0   1    1.0000  0.0000  230     1    1.05  0.95; % MANATI 8404
	52   1    56.9278     18.7113     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % MARTIN PENA 1113
	53   1    13.9152     4.5737      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % MAUNABO TC
	54   1    14.3052     4.7019      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % MAYAGUEZ
	55   1    14.3052     4.7019      0   0   1    1.0000  0.0000  230     1    1.05  0.95; % MAYAGUEZ TC
	56   1    115.1045    37.8330     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % MONACILLOS TC
	57   1    11.4792     3.7730      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % MONTERREY-SUB
	58   1    30.7613     10.1108     0   0   1    1.0000  0.0000  230     1    1.05  0.95; % MORA TC
	59   1    4.5291      1.4886      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % MOROVIS 8801
	60   1    34.3108     11.2774     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % PALMER TC
	61   3    0.0000      0.0000      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % PALO SECO (Planta Generadora - Swing bus)
	62   1    16.1330     5.3027      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % PARQUE ESCORIAL
	63   1    3.4358      1.1293      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % PFIZER 1-PRIVATE-------INDUSTRIAL
	64   1    3.4358      1.1293      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % PFIZER 1-PRIVATE SUBST-------INDUSTRIAL
	65   1    3.4358      1.1293      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % PFIZER 2-PRIVATE SUBSTATION-------INDUSTRIAL
	66   1    10.5400     3.4643      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % PINAS 9403-9405
	67   1    34.9152     11.4761     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % PONCE TC
	68   1    0.8100      0.2662      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % PRIVATE OIL COMPANY SUBSTATION-------INDUSTRIAL
	69   1    0.8100      0.2662      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % PRIVATE-ROBERTO SANCHEZ VILELLA-------INDUSTRIAL
	70   1    6.0351      1.9836      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % QUEBRADA NEGRITO
	71   1    13.5613     4.4574      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % RIO BAYAMON DEV 1709
	72   2    0.0000      0.0000      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % RIO BLANCO 2702 (Hidroeléctrica - PV Reincorporado)
	73   1    73.0195     24.0003     0   0   1    1.0000  0.0000  230     1    1.05  0.95; % SABANA LLANA TC
	74   1    12.6958     4.1729      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % SAN GERMAN TC/ 6406
	75   1    45.1530     14.8411     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % SAN SEBASTIAN TC
	76   1    0.0000      0.0000      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % SAN JUAN GP TC
	77   1    35.0412     11.5175     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % SANTA ISABEL TC
	78   1    15.0472     4.9458      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % SANTA ROSA 8006
	79   1    3.2943      1.0828      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % SUB SAN JOSE 3016
	80   1    0.0000      0.0000      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % TAP141471 (Tap de Línea Intermedio)
	81   1    0.0000      0.0000      0   0   1    1.0000  0.0000  230     1    1.05  0.95; % TAP141491 (Tap de Línea Intermedio)
	82   1    0.0000      0.0000      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % TAP141502 (Tap de Línea Intermedio)
	83   1    0.0000      0.0000      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % TAP141594 (Tap de Línea Intermedio)
	84   1    0.0000      0.0000      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % TAP141784 (Tap de Línea Intermedio)
	85   1    0.0000      0.0000      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % TAP141786 (Tap de Línea Intermedio)
	86   1    0.0000      0.0000      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % TAP161417 (Tap de Línea Intermedio)
	87   1    26.8995     8.8414      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % TORO NEGRO
	88   1    4.5291      1.4886      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % UNIBON 9501
	89   1    51.3264     16.8702     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % VEGA BAJA TC 9004
	90   1    56.9278     18.7113     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % VIADUCTO TC
	91   1    35.4780     11.6611     0   0   1    1.0000  0.0000  115     1    1.05  0.95; % VICTORIA TC 7001-7007-7008
	92   1    0.0000      0.0000      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % YABUCOA
	93   1    20.9393     6.8824      0   0   1    1.0000  0.0000  230     1    1.05  0.95; % YABUCOA TC
	94   2    0.0000      0.0000      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % Toro Negro (Hidroeléctrica - PV)
	95   2    0.0000      0.0000      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % Oriana Solar Farm (Renovable - PV)
	96   2    0.0000      0.0000      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % Santa Isabel Windfarm (Eólica - PV)
	97   2    0.0000      0.0000      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % La Cometa Solar Farm
	98   1    0.0000      0.0000      0   0   1    1.0000  0.0000  115     1    1.05  0.95; % %SANTA ISABEL WIND FARM SUB
	99   2    0.0000      0.0000      0   0   1    1.0300  0.0000  115     1    1.05  0.95; % Naguabo Wind Farm
];


%% MATPOWER Generator Data (Puerto Rico Power System - Multi-Generator Dispatch)
%  bus   Pg      Qg      Qmax     Qmin     Vg    mBase status  Pmax    Pmin  Pc1 Pc2 Qc1min Qc1max Qc2min Qc2max ramp_agc ramp_10 ramp_30 ramp_q apf

mpc.gen = [
    24   395.00   169.08   300.0   -300.0   1.0300  100   1     990.0   0.0   0 0 0 0 0 0 0 0 0 0 0;  % COSTA SUR
    19   380.00   132      180.0   -180.0   1.0300  100   1     454.0   0.0   0 0 0 0 0 0 0 0 0 0 0;  % AES (Carbón / IPP)
    29   395.00   73.9168  200.0   -200.0   1.0300  100   1     507.0   0.0   0 0 0 0 0 0 0 0 0 0 0;  % ECOELECTRICA (Gas / IPP)
    61   173.17   84       200.0   -200.0   1.0300  100   1     600.0   0.0   0 0 0 0 0 0 0 0 0 0 0;  % PALO SECO (swing; Pg from the solved base case)
    17   120.00   90       250.0   -250.0   1.0300  100   1     800.0   0.0   0 0 0 0 0 0 0 0 0 0 0;  % CENTRAL SAN JUAN
    9    190.00   70       90.0    -90.0    1.0300  100   1     249.0   0.0   0 0 0 0 0 0 0 0 0 0 0;  % CAMBALACHE GP
    54   75.00    30       80.0    -80.0    1.0300  100   1     220.0   0.0   0 0 0 0 0 0 0 0 0 0 0;  % MAYAGUEZ GT
    15   10.00    3        10.0    -10.0    1.0300  100   1     18.0    0.0   0 0 0 0 0 0 0 0 0 0 0;  % CAONILLAS (Hidro)
    72   3.00     0.9      3.0     -3.0     1.0300  100   1     5.0     0.0   0 0 0 0 0 0 0 0 0 0 0;  % RIO BLANCO (Hidro)
    94   3.00     0.9      3.0     -3.0     1.0300  100   1     5.0     0.0   0 0 0 0 0 0 0 0 0 0 0;  % TORO NEGRO (Hidro)
    31   425.00   140      250.0   -250.0   1.0300  100   1     900.0   0.0   0 0 0 0 0 0 0 0 0 0 0;  % CENTRAL AGUIRRE
    95   0.00     8        15.0    -15.0    1.0300  100   1     45.0    0.0   0 0 0 0 0 0 0 0 0 0 0;  % Oriana Solar Farm (PV)
    96   12.00    4.01     12.0    -12.0    1.0300  100   1     101.0   0.0   0 0 0 0 0 0 0 0 0 0 0;  % Santa Isabel Windfarm (Eólica)
    97   0.00     0.6      10.0    -10.0    1.0300  100   1     20.0    0.0   0 0 0 0 0 0 0 0 0 0 0;  % La Cometa Solar Farm (PV)
    99   15.00    5.6      15.0    -15.0    1.0300  100   1     25.0    0.0   0 0 0 0 0 0 0 0 0 0 0;  % Naguabo Wind Farm (Eólica)
];


%% MATPOWER Branch Data (Puerto Rico TRSMISION LINES  - Impedance P.U.)
mpc.branch = [
%  fbus  tbus  r         x          b_total_pu   rateA   rateB rateC tap   shift status angmin angmax
%%%% Transformers Systems
22    21    0.002280    0.079970    0.000000    547.00   0     0     1     0     1      -360   360; % TRAFO 230/115 kV: COMPLEJO DE AGUIRRE [typical parameters]
25    24    0.002280    0.079970    0.000000    547.00   0     0     1     0     1      -360   360; % TRAFO 230/115 kV: COSTA SUR [typical parameters]
5     56    0.002280    0.079970    0.000000    547.00   0     0     1     0     1      -360   360; % TRAFO 230/115 kV: BAYAMON TC -> MONACILLOS TC [typical parameters]
1     56    0.002280    0.079970    0.000000    547.00   0     0     1     0     1      -360   360; % TRAFO 230/115 kV: AGUAS BUENAS -> MONACILLOS TC [typical parameters]

%%%% Transmission Lines
23    84    0.000018    0.000136    0.000019    225.08   0     0     0     0     1      -360   360; % CONQUISTADOR 1204 -- TAP141784
31    21    0.000018    0.000136    0.000019    1060.00  0     0     0     0     1      -360   360; % CENTRAL AGUIRRE -- AGUIRRE 115 [plant tie: rated at Pmax/0.85]
31    22    0.000018    0.000147    0.000287    1060.00  0     0     0     0     1      -360   360; % CENTRAL AGUIRRE -- AGUIRRE 230 [plant tie: rated at Pmax/0.85]
94    87    0.000018    0.000136    0.000019    225.08   0     0     0     0     1      -360   360; % TORO NEGRO -- Generator
97    42    0.000010    0.000075    0.000011    225.08   0     0     0     0     1      -360   360; % LA COMETA SOLAR FARM -- HUMACAO TC
65    80    0.000030    0.000223    0.000032    225.08   0     0     0     0     1      -360   360; % PFIZER 2 -- TAP141471
33    86    0.000036    0.000264    0.000038    225.08   0     0     0     0     1      -360   360; % FUTURA SUB. JUAN MARTIN -- TAP161417
78    82    0.000074    0.000551    0.000079    225.08   0     0     0     0     1      -360   360; % SANTA ROSA 8008 -- TAP141502
64    80    0.000078    0.000577    0.000083    225.08   0     0     0     0     1      -360   360; % PFIZER 1 -- TAP141471
4     63    0.000104    0.000770    0.000110    225.08   0     0     0     0     1      -360   360; % BARCELONETA TC -- PFIZER 1
4     80    0.000153    0.001128    0.000161    225.08   0     0     0     0     1      -360   360; % BARCELONETA TC -- TAP141471
92    86    0.000294    0.002175    0.000311    225.08   0     0     0     0     1      -360   360; % YABUCOA -- TAP161417
55    2     0.002614    0.082436    0.000353    225.08   0     0     0     0     1      -360   360; % MAYAGUEZ TC -- ALTURAS DE MAYAGUEZ [+ typical 230/115-kV transformer impedance in series]
68    24    0.000720    0.005324    0.000762    225.08   0     0     0     0     1      -360   360; % PRIVATE OIL COMPANY -- COSTA SUR
58    81    0.000190    0.001519    0.002978    450.00   0     0     0     0     1      -360   360; % MORA TC -- TAP141491 (230 kV)
62    73    0.003081    0.085896    0.000848    225.08   0     0     0     0     1      -360   360; % PARQUE ESCORIAL -- SABANA LLANA TC [+ typical 230/115-kV transformer impedance in series]
54    2     0.001015    0.007507    0.001074    225.08   0     0     0     0     1      -360   360; % MAYAGUEZ -- ALTURAS DE MAYAGUEZ
38    52    0.001089    0.008055    0.001153    225.08   0     0     0     0     1      -360   360; % HATO REY TC -- MARTIN PENA
30    84    0.001135    0.008392    0.001201    225.08   0     0     0     0     1      -360   360; % ENCANTADA -- TAP141784
54    55    0.003466    0.088742    0.001255    225.08   0     0     0     0     1      -360   360; % MAYAGUEZ -- MAYAGUEZ TC [+ typical 230/115-kV transformer impedance in series]
6     62    0.001334    0.009862    0.001411    225.08   0     0     0     0     1      -360   360; % BERWIND TC -- PARQUE ESCORIAL
24    69    0.001381    0.010209    0.001461    225.08   0     0     0     0     1      -360   360; % COSTA SUR PLANT -- SANCHEZ VILELLA
24    69    0.001388    0.010260    0.001468    225.08   0     0     0     0     1      -360   360; % COSTA SUR PLANT -- SANCHEZ VILELLA
9     10    0.003695    0.090430    0.001497    225.08   0     0     0     0     1      -360   360; % CAMBALACHE GP TC -- CAMBALACHE TC [+ typical 230/115-kV transformer impedance in series]
90    38    0.001442    0.010662    0.001526    225.08   0     0     0     0     1      -360   360; % VIADUCTO TC -- HATO REY TC
50    56    0.001472    0.010887    0.001558    225.08   0     0     0     0     1      -360   360; % LAS LOMAS -- MONACILLOS TC
12    83    0.001568    0.011592    0.001659    225.08   0     0     0     0     1      -360   360; % CANAS TC -- TAP141594
5     71    0.003852    0.091596    0.001664    225.08   0     0     0     0     1      -360   360; % BAYAMON -- RIO BAYAMON DEV [+ typical 230/115-kV transformer impedance in series]
51    28    0.003879    0.091794    0.001692    225.08   0     0     0     0     1      -360   360; % MANATI 8404 -- DUPONT1 [+ typical 230/115-kV transformer impedance in series]
1     79    0.004016    0.092808    0.001837    225.08   0     0     0     0     1      -360   360; % AGUAS BUENAS -- SUB SAN JOSE [+ typical 230/115-kV transformer impedance in series]
25    29    0.000477    0.003803    0.007456    600.00   0     0     0     0     1      -360   360; % COSTA SUR SP -- ECOELECTRICA (230 kV) [plant outlet: rated at Pmax/0.85]
93    42    0.004289    0.094825    0.002126    225.08   0     0     0     0     1      -360   360; % YABUCOA TC -- HUMACAO TC [+ typical 230/115-kV transformer impedance in series]
93    42    0.004296    0.094877    0.002133    225.08   0     0     0     0     1      -360   360; % YABUCOA TC -- HUMACAO TC [+ typical 230/115-kV transformer impedance in series]
67    83    0.002033    0.015030    0.002151    225.08   0     0     0     0     1      -360   360; % PONCE TC -- TAP141594
26    13    0.002074    0.015338    0.002195    225.08   0     0     0     0     1      -360   360; % DORADO TC -- CANDELARIA ARENAS
8     79    0.002133    0.015768    0.002256    225.08   0     0     0     0     1      -360   360; % CAGUAS TC -- SUB SAN JOSE
36    56    0.002135    0.015785    0.002259    225.08   0     0     0     0     1      -360   360; % GUAYNABO PUEBLO -- MONACILLOS TC
66    11    0.002327    0.017207    0.002462    225.08   0     0     0     0     1      -360   360; % PINAS -- CANA SUBSTATION
34    56    0.002372    0.017539    0.002510    225.08   0     0     0     0     1      -360   360; % GRANA -- MONACILLOS TC
91    41    0.002398    0.017734    0.002538    225.08   0     0     0     0     1      -360   360; % VICTORIA TC -- HOSPITAL DISTRITO
91    41    0.002410    0.017822    0.002550    225.08   0     0     0     0     1      -360   360; % VICTORIA TC -- HOSPITAL DISTRITO
12    67    0.002479    0.018330    0.002623    225.08   0     0     0     0     1      -360   360; % CANAS TC -- PONCE TC
59    88    0.002587    0.019132    0.002738    225.08   0     0     0     0     1      -360   360; % MOROVIS 8801 -- UNIBON
15    40    0.002621    0.019383    0.002774    225.08   0     0     0     0     1      -360   360; % CAONILLAS -- DOS BOCAS
56    85    0.002632    0.019462    0.002785    225.08   0     0     0     0     1      -360   360; % MONACILLOS TC -- TAP141786
5     34    0.004952    0.099730    0.002828    225.08   0     0     0     0     1      -360   360; % BAYAMON -- GRANA [+ typical 230/115-kV transformer impedance in series]
17    38    0.002694    0.019921    0.002851    225.08   0     0     0     0     1      -360   360; % CENTRAL SAN JUAN -- HATO REY TC
17    38    0.002698    0.019949    0.002855    225.08   0     0     0     0     1      -360   360; % CENTRAL SAN JUAN -- HATO REY TC
40    82    0.002762    0.020426    0.002923    225.08   0     0     0     0     1      -360   360; % DOS BOCAS -- TAP141502
17    90    0.002770    0.020479    0.002931    225.08   0     0     0     0     1      -360   360; % CENTRAL SAN JUAN -- VIADUCTO TC
17    90    0.002785    0.020596    0.002947    225.08   0     0     0     0     1      -360   360; % CENTRAL SAN JUAN -- VIADUCTO TC
57    88    0.002837    0.020979    0.003002    225.08   0     0     0     0     1      -360   360; % MONTERREY -- UNIBON
53    86    0.003262    0.024117    0.003451    225.08   0     0     0     0     1      -360   360; % MAUNABO TC -- TAP161417
71    56    0.003402    0.025156    0.003600    225.08   0     0     0     0     1      -360   360; % RIO BAYAMON DEV -- MONACILLOS TC
18    59    0.003436    0.025405    0.003636    225.08   0     0     0     0     1      -360   360; % CIALES -- MOROVIS
6     52    0.003451    0.025515    0.003651    225.08   0     0     0     0     1      -360   360; % BERWIND TC -- MARTIN PENA
30    73    0.005863    0.106460    0.003791    225.08   0     0     0     0     1      -360   360; % ENCANTADA -- SABANA LLANA TC [+ typical 230/115-kV transformer impedance in series]
51    89    0.005904    0.106770    0.003835    225.08   0     0     0     0     1      -360   360; % MANATI 8404 -- VEGA BAJA TC [+ typical 230/115-kV transformer impedance in series]
61    5     0.005921    0.106894    0.003853    225.08   0     0     0     0     1      -360   360; % PALO SECO -- BAYAMON [+ typical 230/115-kV transformer impedance in series]
93    92    0.005935    0.106992    0.003867    225.08   0     0     0     0     1      -360   360; % YABUCOA TC -- YABUCOA [+ typical 230/115-kV transformer impedance in series]
56    84    0.003677    0.027190    0.003891    225.08   0     0     0     0     1      -360   360; % MONACILLOS TC -- TAP141784
61    5     0.006015    0.107585    0.003952    225.08   0     0     0     0     1      -360   360; % PALO SECO -- BAYAMON [+ typical 230/115-kV transformer impedance in series]
61    5     0.006034    0.107730    0.003973    225.08   0     0     0     0     1      -360   360; % PALO SECO -- BAYAMON [+ typical 230/115-kV transformer impedance in series]
70    85    0.003821    0.028256    0.004044    225.08   0     0     0     0     1      -360   360; % QUEBRADA NEGRITO -- TAP141786
55    3     0.006107    0.108268    0.004049    225.08   0     0     0     0     1      -360   360; % MAYAGUEZ TC -- ANASCO TC [+ typical 230/115-kV transformer impedance in series]
17    56    0.003831    0.028324    0.004053    225.08   0     0     0     0     1      -360   360; % CENTRAL SAN JUAN -- MONACILLOS TC
56    7     0.003912    0.028922    0.004139    225.08   0     0     0     0     1      -360   360; % MONACILLOS TC -- BUEN PASTOR
57    66    0.003954    0.029239    0.004184    225.08   0     0     0     0     1      -360   360; % MONTERREY -- PINAS
49    16    0.004345    0.032130    0.004598    225.08   0     0     0     0     1      -360   360; % LAS CRUCES -- CAYEY TC
5     17    0.006899    0.114126    0.004888    225.08   0     0     0     0     1      -360   360; % BAYAMON -- CENTRAL SAN JUAN [+ typical 230/115-kV transformer impedance in series]
5     13    0.006985    0.114756    0.004978    225.08   0     0     0     0     1      -360   360; % BAYAMON -- CANDELARIA ARENAS [+ typical 230/115-kV transformer impedance in series]
39    13    0.001603    0.011855    0.001696    225.08   0     0     0     0     1      -360   360; % HATO TEJA TC -- CANDELARIA ARENAS
39    5     0.003175    0.086591    0.000947    225.08   0     0     0     0     1      -360   360; % HATO TEJA TC -- BAYAMON [+ typical 230/115-kV transformer impedance in series]
8     7     0.005157    0.038136    0.005457    225.08   0     0     0     0     1      -360   360; % CAGUAS TC -- BUEN PASTOR
10    37    0.005183    0.038322    0.005484    225.08   0     0     0     0     1      -360   360; % CAMBALACHE TC -- HATILLO TC
49    8     0.005429    0.040143    0.005745    225.08   0     0     0     0     1      -360   360; % LAS CRUCES -- CAGUAS TC
61    17    0.005475    0.040485    0.005793    225.08   0     0     0     0     1      -360   360; % PALO SECO -- CENTRAL SAN JUAN
26    66    0.005713    0.042245    0.006045    225.08   0     0     0     0     1      -360   360; % DORADO TC -- PINAS
3     91    0.006005    0.044405    0.006354    225.08   0     0     0     0     1      -360   360; % ANASCO TC -- VICTORIA TC
46    67    0.006025    0.044549    0.006375    225.08   0     0     0     0     1      -360   360; % JUANA DIAZ TC -- PONCE TC
20    1     0.008691    0.127375    0.006784    225.08   0     0     0     0     1      -360   360; % COMERIO TC -- AGUAS BUENAS TC [+ typical 230/115-kV transformer impedance in series]
87    46    0.006446    0.047666    0.006821    225.08   0     0     0     0     1      -360   360; % TORO NEGRO -- JUANA DIAZ TC
12    24    0.006510    0.048134    0.006888    225.08   0     0     0     0     1      -360   360; % CANAS TC -- COSTA SUR
27    72    0.006527    0.048262    0.006906    225.08   0     0     0     0     1      -360   360; % DUGUAO -- RIO BLANCO
83    25    0.008868    0.128685    0.006971    225.08   0     0     0     0     1      -360   360; % TAP141594 -- COSTA SUR SP TC [+ typical 230/115-kV transformer impedance in series]
51    4     0.009102    0.130411    0.007218    225.08   0     0     0     0     1      -360   360; % MANATI 8404 -- BARCELONETA TC [+ typical 230/115-kV transformer impedance in series]
26    89    0.007037    0.052032    0.007446    225.08   0     0     0     0     1      -360   360; % DORADO TC -- VEGA BAJA TC
40    10    0.007139    0.052784    0.007554    225.08   0     0     0     0     1      -360   360; % DOS BOCAS -- CAMBALACHE TC
1     56    0.009644    0.134422    0.007792    225.08   0     0     0     0     1      -360   360; % AGUAS BUENAS TC -- MONACILLOS TC [+ typical 230/115-kV transformer impedance in series]
42    72    0.007469    0.055224    0.007903    225.08   0     0     0     0     1      -360   360; % HUMACAO TC -- RIO BLANCO
73    14    0.009769    0.135347    0.007924    225.08   0     0     0     0     1      -360   360; % SABANA LLANA TC -- CANOVANAS TC [+ typical 230/115-kV transformer impedance in series]
58    91    0.009780    0.135422    0.007935    225.08   0     0     0     0     1      -360   360; % MORA TC -- VICTORIA TC [+ typical 230/115-kV transformer impedance in series]
73    14    0.009793    0.135519    0.007949    225.08   0     0     0     0     1      -360   360; % SABANA LLANA TC -- CANOVANAS TC [+ typical 230/115-kV transformer impedance in series]
32    60    0.007518    0.055590    0.007955    225.08   0     0     0     0     1      -360   360; % FAJARDO TC -- PALMER TC
42    47    0.007633    0.056437    0.008076    225.08   0     0     0     0     1      -360   360; % HUMACAO TC -- JUNCOS TC
10    4     0.007651    0.056569    0.008095    225.08   0     0     0     0     1      -360   360; % CAMBALACHE TC -- BARCELONETA TC
27    32    0.007963    0.058879    0.008426    225.08   0     0     0     0     1      -360   360; % DUGUAO -- FAJARDO TC
24    35    0.008363    0.061835    0.008849    225.08   0     0     0     0     1      -360   360; % COSTA SUR -- GUANICA TC
47    72    0.008459    0.062547    0.008950    225.08   0     0     0     0     1      -360   360; % JUNCOS TC -- RIO BLANCO
21    45    0.008517    0.062973    0.009012    225.08   0     0     0     0     1      -360   360; % AGUIRRE 115 -- JOBOS TC
21    45    0.008582    0.063454    0.009080    225.08   0     0     0     0     1      -360   360; % AGUIRRE 115 -- JOBOS TC
67    24    0.008644    0.063916    0.009147    225.08   0     0     0     0     1      -360   360; % PONCE TC -- COSTA SUR
44    40    0.008649    0.063954    0.009152    225.08   0     0     0     0     1      -360   360; % JAYUYA SUB -- DOS BOCAS
60    14    0.008687    0.064230    0.009191    225.08   0     0     0     0     1      -360   360; % PALMER TC -- CANOVANAS TC
5     1     0.002397    0.019120    0.037489    450.00   0     0     0     0     1      -360   360; % BAYAMON -- AGUAS BUENAS (230 kV)
22    19    0.002463    0.019645    0.038518    450.00   0     0     0     0     1      -360   360; % AGUIRRE 230 -- AES (230 kV)
21    77    0.010170    0.075197    0.010761    225.08   0     0     0     0     1      -360   360; % AGUIRRE 115 -- SANTA ISABEL TC
55    75    0.012483    0.155413    0.010796    225.08   0     0     0     0     1      -360   360; % MAYAGUEZ TC -- SAN SEBASTIAN TC [+ typical 230/115-kV transformer impedance in series]
74    35    0.010391    0.076833    0.010995    225.08   0     0     0     0     1      -360   360; % SAN GERMAN TC -- GUANICA TC
54    48    0.010841    0.080160    0.011471    225.08   0     0     0     0     1      -360   360; % MAYAGUEZ -- LAS ACACIAS
70    47    0.010865    0.080335    0.011496    225.08   0     0     0     0     1      -360   360; % QUEBRADA NEGRITO -- JUNCOS TC
74    48    0.010910    0.080669    0.011544    225.08   0     0     0     0     1      -360   360; % SAN GERMAN TC -- LAS ACACIAS
45    16    0.011282    0.083424    0.011938    225.08   0     0     0     0     1      -360   360; % JOBOS TC -- CAYEY TC
18    40    0.011363    0.084022    0.012024    225.08   0     0     0     0     1      -360   360; % CIALES -- DOS BOCAS
1     73    0.003076    0.024541    0.048118    450.00   0     0     0     0     1      -360   360; % AGUAS BUENAS -- SABANA LLANA (230 kV)
77    67    0.013720    0.101446    0.014517    225.08   0     0     0     0     1      -360   360; % SANTA ISABEL TC -- PONCE TC
75    82    0.013970    0.103295    0.014782    225.08   0     0     0     0     1      -360   360; % SAN SEBASTIAN TC -- TAP141502
45    53    0.014842    0.109742    0.015704    225.08   0     0     0     0     1      -360   360; % JOBOS TC -- MAUNABO TC
20    87    0.015282    0.112999    0.016170    225.08   0     0     0     0     1      -360   360; % COMERIO TC -- TORO NEGRO
51    9     0.003889    0.031027    0.060835    450.00   0     0     0     0     1      -360   360; % MANATI 8404 -- CAMBALACHE GP (230 kV)
55    81    0.004114    0.032823    0.064356    450.00   0     0     0     0     1      -360   360; % MAYAGUEZ TC -- TAP141491 (230 kV)
9     81    0.004854    0.038726    0.075931    450.00   0     0     0     0     1      -360   360; % CAMBALACHE GP -- TAP141491 (230 kV)
44    67    0.019857    0.146823    0.021011    225.08   0     0     0     0     1      -360   360; % JAYUYA SUB -- PONCE TC
22    1     0.005178    0.041308    0.080992    450.00   0     0     0     0     1      -360   360; % AGUIRRE 230 -- AGUAS BUENAS (230 kV)
22    1     0.005178    0.041314    0.081004    450.00   0     0     0     0     1      -360   360; % AGUIRRE 230 -- AGUAS BUENAS (230 kV)
40    24    0.020902    0.154555    0.022117    225.08   0     0     0     0     1      -360   360; % DOS BOCAS -- COSTA SUR
93    19    0.005263    0.041990    0.082330    450.00   0     0     0     0     1      -360   360; % YABUCOA TC -- AES (230 kV)
51    5     0.005951    0.047474    0.093083    450.00   0     0     0     0     1      -360   360; % MANATI 8404 -- BAYAMON (230 kV)
93    73    0.006405    0.051102    0.100196    450.00   0     0     0     0     1      -360   360; % YABUCOA TC -- SABANA LLANA (230 kV)
55    25    0.006594    0.052608    0.103149    450.00   0     0     0     0     1      -360   360; % MAYAGUEZ TC -- COSTA SUR SP (230 kV)
51    25    0.007192    0.057382    0.112510    450.00   0     0     0     0     1      -360   360; % MANATI 8404 -- COSTA SUR SP (230 kV)
22    25    0.008049    0.064212    0.125901    450.00   0     0     0     0     1      -360   360; % AGUIRRE 230 -- COSTA SUR SP (230 kV)
43    90    0.000274    0.003214    0.026201    287.82   0     0     0     0     1      -360   360; % ISLA GRANDE -- VIADUCTO TC
43    76    0.000693    0.008123    0.066212    287.82   0     0     0     0     1      -360   360; % ISLA GRANDE -- SAN JUAN GP
98    67    0.011006    0.081379    0.011645    225.08   0     0     0     0     1      -360   360; % SANTA ISABEL WIND SUB -- PONCE TC
98    77    0.002025    0.014972    0.002142    225.08   0     0     0     0     1      -360   360; % SANTA ISABEL WIND SUB -- SANTA ISABEL TC
96    98    0.001022    0.007553    0.001081    225.08   0     0     0     0     1      -360   360; % SANTA ISABEL WIND SUB -- WIND FARM
95    58    0.003064    0.085770    0.000830    225.08   0     0     0     0     1      -360   360; % ORIANA -- MORA TC [+ typical 230/115-kV transformer impedance in series]
99    27    0.002430    0.017973    0.002572    225.08   0     0     0     0     1      -360   360; % NAGUABO WIND -- DUGUAU TC
];
