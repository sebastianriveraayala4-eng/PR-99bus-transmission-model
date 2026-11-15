function out = simulate_blackout_2016(casefile, opt)
%SIMULATE_BLACKOUT_2016  Quasi-steady-state reconstruction of the Puerto Rico
%   blackout of 21 September 2016 (about 2:30 p.m. AST) on the 99-bus case.
%
%   OUT = SIMULATE_BLACKOUT_2016(CASEFILE, OPT) runs
%   SIMULATE_GRID_EVENT(CASEFILE, 'sep2016', OPT). All options, the event
%   sequence and the outputs are described in SIMULATE_GRID_EVENT.
%
%   Defaults: load 2650 MW distributed as PR100's 21 September 14:00 hour,
%   dispatch 'proportional' (the base-case dispatch scaled to the load),
%   spinning reserve 535 MW, all of it acting before the relays
%   (response_frac = 1), load-shedding limit 25%.
%
%   Example
%     out = simulate_blackout_2016('Puerto_Rico2');
%     out = simulate_blackout_2016('Puerto_Rico2', struct('response_frac', 0));

if nargin < 1, casefile = []; end
if nargin < 2, opt = struct(); end
out = simulate_grid_event(casefile, 'sep2016', opt);
end
