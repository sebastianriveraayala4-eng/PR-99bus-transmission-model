function out = simulate_event_aug2022(casefile, opt)
%SIMULATE_EVENT_AUG2022  Quasi-steady-state simulation of the loss of the AES
%   plant on 17 August 2022 (11:10 a.m. AST) on the 99-bus case.
%
%   OUT = SIMULATE_EVENT_AUG2022(CASEFILE, OPT) runs
%   SIMULATE_GRID_EVENT(CASEFILE, 'aug2022', OPT). All options and outputs
%   are described in SIMULATE_GRID_EVENT.
%
%   What is documented (LUMA, preliminary report of 22 August 2022, Energy
%   Bureau docket NEPR-IN-2022-0004; LUMA monthly report for August 2022):
%     - AES units 1 and 2 were supplying 447 MW.
%     - The 230-kV line Cambalache-Manati (50100) was out for repairs and
%       Aguirre unit 1 was on an extended outage.
%     - 11:07:24  line 50700 AES-Yabucoa tripped on a vegetation fault; it
%                 was reclosed at 11:08:27 and tripped again.
%     - 11:10:47  line 50700 AES-Aguirre tripped on an open jumper; AES was
%                 isolated from the grid.
%     - 11:10:51  frequency 58.6 Hz, automatic load shedding began;
%                 minimum 58.286 Hz at 11:10:56, then recovery.
%     - 31 underfrequency relay operations (10 at 58.6 Hz, 17 at 58.5 Hz,
%       4 at 58.4 Hz) at Caguas, Juncos, Las Piedras, Rio Blanco, Humacao,
%       Jobos, Ponce, Santa Isabel, Toro Negro, Comerio, Barranquitas,
%       Monacillos and Caparra; about 300,000 customers shed.
%   What is assumed: the system load, the output of every plant except AES,
%   the spinning reserve, and how much of it acts before the relays.
%
%   Defaults: load 2450 MW distributed as PR100's August weekday 11:00
%   hour, dispatch 'fleet2022', spinning reserve 250 MW.
%
%   Example
%     out = simulate_event_aug2022('Puerto_Rico2');
%     out = simulate_event_aug2022('Puerto_Rico2', struct('response_frac', 0));

if nargin < 1, casefile = []; end
if nargin < 2, opt = struct(); end
out = simulate_grid_event(casefile, 'aug2022', opt);
end
