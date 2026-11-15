function out = simulate_grid_event(casefile, scenario, opt)
%SIMULATE_GRID_EVENT  Quasi-steady-state simulation of a documented event on
%   the 99-bus Puerto Rico case.
%
%   OUT = SIMULATE_GRID_EVENT(CASEFILE, SCENARIO, OPT)
%
%   CASEFILE  MATPOWER case (default 'Puerto_Rico2', the corrected case).
%   SCENARIO  'sep2016'  blackout of 21 September 2016, about 2:30 p.m. AST
%             'aug2022'  loss of the AES plant on 17 August 2022, 11:10 a.m.
%   OPT       struct with any of the fields below. Defaults are in brackets,
%             written [sep2016 / aug2022] where the two scenarios differ.
%
%   Pre-event operating point
%     load_shape  how the load is distributed over the buses:
%               a field of pr100_bus_loads.m ('sep21_14', 'aug15_11',
%               'first_hour', 'peak', 'minimum', 'sep19_14'), 'case' for the
%               distribution stored in the case file, or a [bus MW] matrix.
%               Loads taken from pr100_bus_loads.m get a 0.95 power factor.
%               ['sep21_14' / 'aug15_11']
%     load_MW   total bus load before the event; [] keeps the total of
%               LOAD_SHAPE. NOT a measured value in either scenario.
%               sep2016 [2650]: PR100 puts 21 September at 14:00 at 0.90
%               of the annual peak; with the 3030-MW system peak of fiscal
%               year 2015 (PREPA 2015 IRP, Volume III) this is about
%               2720 MW of generation, or about 2640 MW without the plant
%               auxiliaries (2590 MW if transmission losses are also
%               removed).
%               aug2022 [2450]: PR100 gives a mean of 2551 MW of gross
%               generation for August weekdays at 11:00 (its July-August
%               energy is within 1% of what LUMA reported for 2022), or
%               about 2470 MW without the plant auxiliaries (2430 MW if
%               transmission losses are also removed).
%     wind_cf   wind output as a fraction of capacity [0.15]
%     solar_MW  [Oriana, Humacao] output in MW [0 0 / 29 13]. For 2016
%               both are assumed off (Oriana reached commercial operation
%               in December 2016). For 2022: 65% of 45 MW and of 20 MW
%               (late morning, August; assumed).
%     dispatch  'proportional' the base-case dispatch of the case file scaled
%                              to the load. For sep2016 Aguirre and Costa
%                              Sur then carry about 1020 MW together, close
%                              to the "almost 1000 MW" reported lost.
%               'fuelmix'      (sep2016) plant outputs follow the 2016 fuel
%                              shares reported by EIA (petroleum 47%, gas
%                              34%, coal 17%, renewables 2%); Aguirre is
%                              assumed to carry 30% of generation; San Juan
%                              and Palo Seco share the rest; one Cambalache
%                              unit at 40 MW
%               'merit'        (sep2016) AES and EcoElectrica near full
%                              output, Aguirre and Costa Sur share the rest
%               'fleet2022'    (aug2022) AES at AES_MW, EcoElectrica at 97%,
%                              and Costa Sur, Aguirre, Palo Seco and San
%                              Juan sharing the rest in proportion to
%                              AVAIL_MW; Cambalache and Mayaguez are added
%                              only if that is not enough
%               ['proportional' / 'fleet2022']. The actual dispatch is not
%               public for either date; every option is an assumption.
%     aes_MW    (aug2022) AES output before the event [447], from LUMA's
%               preliminary report on the incident
%     avail_MW  (aug2022) capacity assumed available at Costa Sur, Aguirre,
%               Palo Seco and San Juan [600 350 350 480]. Aguirre 1 was on
%               an extended outage (LUMA); the other values are assumptions
%               based on the deratings listed in LUMA's monthly report.
%
%   Response to a loss of generation
%     response  'online'  only committed units respond, up to their rating
%               'pmax'    every plant can rise to its full Pmax
%               ['online']
%     reserve_MW  spinning reserve of the on-line synchronous plants before
%               the event [535 / 250]. Units are committed until their
%               headroom reaches this value and the headroom of every plant
%               is then scaled down to match it; [] keeps all headroom of
%               the units needed for the dispatch. Both defaults are
%               ASSUMPTIONS: 535 MW exceeds the largest unit (450 MW); the
%               actual reserve on either date is not public. Ignored with
%               'pmax'.
%     response_frac  fraction of that reserve delivered before underfrequency
%               relays act, in the stages where generation is lost [1].
%               With 1 the reserve is used first and load is shed only for
%               what is left; with 0 the whole deficit is shed.
%     ufls_max  largest fraction of the pre-event load that underfrequency
%               load shedding can remove; a larger deficit is taken as a
%               collapse of that island [0.25]. PREPA's scheme is not
%               public; 25% is the NERC PRC-006 benchmark imbalance.
%     trip_pct  branch loading (percent of rateA) at which protection trips
%               the most heavily loaded branch [110]
%     watch     [from to] branch whose loading is reported at every stage
%               [[] / [22 19]]
%     enforce_q enforce generator reactive limits (0/1) [0]
%     verbose   print the stage table (0/1) [1]
%
%   Event sequences
%     sep2016  1  Aguirre plant lost (fire in the 230-kV switchyard)
%              2  230-kV lines Aguirre-Aguas Buenas (two circuits) and
%                 Aguirre-Costa Sur out of service
%              3  Costa Sur units trip
%     aug2022  0  230-kV line Cambalache-Manati (51-9) out for repairs and
%                 Aguirre unit 1 on outage before the event
%              1  230-kV line AES-Yabucoa (93-19) trips (vegetation fault)
%              2  230-kV line AES-Aguirre (22-19) trips (open jumper); the
%                 AES plant is isolated from the grid
%   After every change the model (1) de-energizes islands without
%   synchronous generation, (2) shares any generation deficit among the
%   on-line synchronous plants in proportion to committed capacity, up to
%   that capacity, (3) sheds load uniformly for the remaining deficit, and
%   (4) trips the most overloaded branch above TRIP_PCT, then repeats.
%   The method is quasi-steady-state: frequency and voltage dynamics,
%   relay timing and generator protection are not represented.
%
%   OUT.stage     one row per stage (struct array)
%   OUT.log       list of protective trips and island events
%   OUT.pre       pre-event dispatch [bus, Pg, on-line capacity, status]
%   OUT.pre_case  pre-event MATPOWER case
%
%   See also SIMULATE_BLACKOUT_2016, SIMULATE_EVENT_AUG2022, PR100_BUS_LOADS.
%
%   Requires MATPOWER 7 or later and pr100_bus_loads.m on the path.

if nargin < 1 || isempty(casefile), casefile = 'Puerto_Rico2'; end
if nargin < 2 || isempty(scenario), scenario = 'sep2016'; end
if nargin < 3, opt = struct(); end
switch scenario
    case 'sep2016'
        def = struct('load_shape', 'sep21_14', 'load_MW', 2650, 'solar_MW', [0 0], ...
            'dispatch', 'proportional', 'reserve_MW', 535, 'watch', []);
    case 'aug2022'
        def = struct('load_shape', 'aug15_11', 'load_MW', 2450, 'solar_MW', [29 13], ...
            'dispatch', 'fleet2022', 'reserve_MW', 250, 'watch', [22 19]);
    otherwise
        error('unknown scenario ''%s''', scenario);
end
def.wind_cf = 0.15; def.aes_MW = 447; def.avail_MW = [600 350 350 480];
def.response = 'online'; def.response_frac = 1; def.ufls_max = 0.25;
def.trip_pct = 110; def.enforce_q = 0; def.verbose = 1;
fn = fieldnames(def);
for i = 1:numel(fn)
    if ~isfield(opt, fn{i}), opt.(fn{i}) = def.(fn{i}); end
end

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD] = idx_bus;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX] = idx_gen;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, TAP, SHIFT, BR_STATUS] = idx_brch;

mpopt = mpoption('verbose', 0, 'out.all', 0, 'pf.alg', 'NR', 'pf.tol', 1e-8, ...
    'pf.nr.max_it', 30, 'pf.enforce_q_lims', opt.enforce_q);
mpc = loadcase(casefile);

%% ---- plant data ---------------------------------------------------------
B_AGUIRRE = 31; B_AGUIRRE230 = 22; B_COSTASUR = 24; B_COSTASUR230 = 25;
B_AGUASBUENAS = 1; B_PALOSECO = 61; B_SANJUAN = 17; B_AES = 19; B_ECO = 29;
B_CAMBALACHE = 9; B_MAYAGUEZ = 54; B_YABUCOA = 93; B_MANATI = 51;
B_WIND = [96 99]; B_SOLAR = [95 97];          % Santa Isabel, Naguabo; Oriana, Humacao
nonsync = [B_WIND B_SOLAR];
% generating-unit ratings (MW) used to decide how much capacity is on line
units = {24, [410 410 85 85]; 19, [227 227]; 29, 507; 61, [216 216 85 85]; ...
         17, [220 220 100 100 100 100]; 9, [83 83 83]; 54, [55 55 55 55]; ...
         31, [450 450]; 15, 18; 72, 5; 94, 5};
if strcmp(scenario, 'aug2022')
    units{cellfun(@(x) x == B_AGUIRRE, units(:, 1)), 2} = 450;      % unit 1 on outage
end

gi = @(b) find(mpc.gen(:, GEN_BUS) == b);
ng = size(mpc.gen, 1);
is_sync = ~ismember(mpc.gen(:, GEN_BUS), nonsync);
brsel = @(M, a, b) (M(:, F_BUS) == a & M(:, T_BUS) == b) | (M(:, F_BUS) == b & M(:, T_BUS) == a);

%% ---- pre-event operating point -----------------------------------------
shape = [];
if ischar(opt.load_shape)
    if ~strcmp(opt.load_shape, 'case')
        L = pr100_bus_loads();
        if ~isfield(L, opt.load_shape), error('unknown load_shape ''%s''', opt.load_shape); end
        shape = [L.bus, L.(opt.load_shape)];
    end
else
    shape = opt.load_shape;
end
if ~isempty(shape)
    [tf, loc] = ismember(shape(:, 1), mpc.bus(:, BUS_I));
    if ~all(tf), error('load_shape contains a bus that is not in the case'); end
    mpc.bus(:, [PD QD]) = 0;
    mpc.bus(loc, PD) = shape(:, 2);
    mpc.bus(loc, QD) = shape(:, 2) * tan(acos(0.95));
end
P_case = sum(mpc.bus(:, PD));
if isempty(opt.load_MW), opt.load_MW = P_case; end
k = opt.load_MW / P_case;
mpc.bus(:, [PD QD]) = k * mpc.bus(:, [PD QD]);

if strcmp(scenario, 'aug2022')                  % line 50100 was out for repairs
    mpc.branch(brsel(mpc.branch, B_MANATI, B_CAMBALACHE), BR_STATUS) = 0;
end

for b = B_WIND, mpc.gen(gi(b), PG) = opt.wind_cf * mpc.gen(gi(b), PMAX); end
for j = 1:2
    mpc.gen(gi(B_SOLAR(j)), PG) = opt.solar_MW(j);
    mpc.gen(gi(B_SOLAR(j)), GEN_STATUS) = opt.solar_MW(j) > 0;
end

thermal = [B_AES B_ECO B_AGUIRRE B_COSTASUR B_SANJUAN B_PALOSECO B_CAMBALACHE B_MAYAGUEZ];
other = ~ismember(mpc.gen(:, GEN_BUS), thermal) & mpc.gen(:, GEN_STATUS) > 0;
base_pg = arrayfun(@(b) mpc.gen(gi(b), PG), thermal);       % dispatch stored in the case
pmx = arrayfun(@(b) mpc.gen(gi(b), PMAX), thermal);
PS_TARGET = 150;                                            % Palo Seco (swing) must-run level
lossfrac = 0.02;                                            % first guess of the losses
for pass = 1:6
    need = opt.load_MW * (1 + lossfrac) - sum(mpc.gen(other, PG));
    switch opt.dispatch
        case 'merit'
            % base-load plants in the south, must-run units in the north.
            % One Cambalache unit stays on line for north-coast voltage
            % support (the case has no capacitor banks); Mayaguez is off.
            p = zeros(size(thermal));
            p(thermal == B_AES) = mpc.gen(gi(B_AES), PMAX);
            p(thermal == B_ECO) = 0.95 * mpc.gen(gi(B_ECO), PMAX);
            p(thermal == B_SANJUAN) = 150;
            p(thermal == B_PALOSECO) = PS_TARGET;
            p(thermal == B_CAMBALACHE) = 40;
            rest = need - sum(p);
            capA = 900; capC = 820;                         % Aguirre 1-2, Costa Sur 5-6
            both = min(rest, 0.95 * (capA + capC));
            p(thermal == B_AGUIRRE) = both * capA / (capA + capC);
            p(thermal == B_COSTASUR) = both * capC / (capA + capC);
            extra = rest - both;                            % beyond the base-load plants
            for b = [B_SANJUAN B_PALOSECO B_CAMBALACHE B_MAYAGUEZ]
                j = find(thermal == b);
                add = max(min(extra, 0.9 * pmx(j) - p(j)), 0);
                p(j) = p(j) + add; extra = extra - add;
            end
        case 'fuelmix'
            % plant outputs follow the 2016 fuel shares reported by EIA
            % (coal 17%, natural gas 34%, petroleum 47%, renewables 2%);
            % Aguirre is assumed to carry 30% of generation. Costa Sur is
            % counted as gas.
            G = need + sum(mpc.gen(other, PG));             % total generation
            p = zeros(size(thermal));
            p(thermal == B_AES) = min(mpc.gen(gi(B_AES), PMAX), 0.17 * G);
            gas = 0.34 * G;
            p(thermal == B_ECO) = min(0.95 * mpc.gen(gi(B_ECO), PMAX), gas);
            p(thermal == B_COSTASUR) = gas - p(thermal == B_ECO);
            p(thermal == B_AGUIRRE) = min(0.30 * G, 0.95 * 900);
            p(thermal == B_CAMBALACHE) = 40;                % voltage support, as in 'merit'
            rest = need - sum(p);
            p(thermal == B_SANJUAN) = rest / 2;
            p(thermal == B_PALOSECO) = rest / 2;
        case 'proportional'
            p = base_pg; free = true(size(base_pg));
            for it = 1:20
                sc = (need - sum(p(~free))) / sum(base_pg(free));
                p(free) = sc * base_pg(free);
                over = p > pmx + 1e-9;
                if ~any(over), break; end
                p(over) = pmx(over); free(over) = false;
            end
        case 'fleet2022'
            % AES at its reported output, EcoElectrica near full output; the
            % PREPA steam and combined-cycle plants share the rest in
            % proportion to the capacity assumed available in August 2022.
            av = zeros(size(thermal));
            av(thermal == B_COSTASUR) = opt.avail_MW(1);
            av(thermal == B_AGUIRRE)  = opt.avail_MW(2);
            av(thermal == B_PALOSECO) = opt.avail_MW(3);
            av(thermal == B_SANJUAN)  = opt.avail_MW(4);
            p = zeros(size(thermal));
            p(thermal == B_AES) = opt.aes_MW;
            p(thermal == B_ECO) = 0.97 * mpc.gen(gi(B_ECO), PMAX);
            rest = need - sum(p);
            if rest > 0.97 * sum(av)                        % peaking plants are needed too
                av(thermal == B_CAMBALACHE) = 160; av(thermal == B_MAYAGUEZ) = 110;
            end
            if rest > sum(av), error('the load exceeds the capacity assumed available'); end
            p = p + rest * av / sum(av);
        otherwise
            error('unknown dispatch option');
    end
    for j = 1:numel(thermal)
        mpc.gen(gi(thermal(j)), PG) = p(j);
        mpc.gen(gi(thermal(j)), GEN_STATUS) = p(j) > 0;
    end
    r0 = runpf(mpc, mpopt);
    if ~r0.success, error('pre-event power flow did not converge'); end
    newfrac = sum(r0.gen(r0.gen(:, GEN_STATUS) > 0, PG)) / opt.load_MW - 1;
    if abs(newfrac - lossfrac) < 2e-5, break; end
    lossfrac = newfrac;
end
mpc.gen(:, PG) = r0.gen(:, PG);                 % swing output from the solution
P0 = mpc.gen(:, PG);
load0 = sum(mpc.bus(:, PD));
Pd0 = mpc.bus(:, PD); Qd0 = mpc.bus(:, QD);

% committed (on-line) capacity of every plant
cap = zeros(ng, 1);
ucs = cell(ng, 1);                              % cumulative unit ratings of every plant
ncom = zeros(ng, 1);                            % number of committed units
for i = 1:ng
    if mpc.gen(i, GEN_STATUS) <= 0, continue; end
    b = mpc.gen(i, GEN_BUS);
    if strcmp(opt.response, 'pmax') || ~is_sync(i)
        cap(i) = mpc.gen(i, PMAX);
    else
        u = units{cellfun(@(x) x == b, units(:, 1)), 2};
        cs = cumsum(u); j = find(cs >= P0(i) - 1e-6, 1);
        if isempty(j), j = numel(cs); end
        cap(i) = min(cs(j), mpc.gen(i, PMAX));
        ucs{i} = cs; ncom(i) = j;
    end
    if ~is_sync(i), cap(i) = P0(i); end         % wind and solar hold their output
end
if ~isempty(opt.reserve_MW) && strcmp(opt.response, 'online')
    head = (cap - P0) .* is_sync;                       % headroom of committed units
    while sum(head) < opt.reserve_MW                    % too little: commit further units
        best = 0; bl = -1;                              % at the most heavily loaded plant
        for i = 1:ng
            if ncom(i) > 0 && ncom(i) < numel(ucs{i}) && cap(i) < mpc.gen(i, PMAX) - 1e-6 && P0(i) / cap(i) > bl
                bl = P0(i) / cap(i); best = i;
            end
        end
        if best == 0, break; end                        % nothing left to commit
        ncom(best) = ncom(best) + 1;
        cap(best) = min(ucs{best}(ncom(best)), mpc.gen(best, PMAX));
        head = (cap - P0) .* is_sync;
    end
    if sum(head) > opt.reserve_MW
        cap(is_sync) = P0(is_sync) + head(is_sync) * opt.reserve_MW / sum(head);
    end
end
reserve0 = sum((cap - P0) .* is_sync);                  % spinning reserve before the event
out.scenario = scenario;
out.reserve_MW = reserve0;
out.pre = [mpc.gen(:, GEN_BUS), P0, cap, mpc.gen(:, GEN_STATUS)];
out.pre_case = mpc;

%% ---- event ------------------------------------------------------------
S = struct('mpc', mpc, 'P0', P0, 'cap', cap, 'cap_full', cap, 'Pd0', Pd0, 'Qd0', Qd0, ...
    'shed', zeros(size(Pd0)), 'dead', false(size(Pd0)), 'collapsed', false, ...
    'genlost', 0, 'why', '', 'need_pct', NaN, 'lossfrac', lossfrac);
S.log = {};
ctx = struct('opt', opt, 'mpopt', mpopt, 'is_sync', is_sync, 'load0', load0);

stages = {};
[S, row] = settle(S, ctx, 'Pre-event', false);  stages{end+1} = row;

switch scenario
    case 'sep2016'
        % Stage 1: Aguirre plant and its connections
        S = trip_gen(S, gi(B_AGUIRRE));
        S.mpc.branch(any(S.mpc.branch(:, [F_BUS T_BUS]) == B_AGUIRRE, 2), BR_STATUS) = 0;
        [S, row] = settle(S, ctx, 'Stage 1: Aguirre plant lost', true);  stages{end+1} = row;
        % Stage 2: 230-kV lines out of the Aguirre switchyard
        if ~S.collapsed
            sel = brsel(S.mpc.branch, B_AGUIRRE230, B_AGUASBUENAS) | brsel(S.mpc.branch, B_AGUIRRE230, B_COSTASUR230);
            S.mpc.branch(sel, BR_STATUS) = 0;
            [S, row] = settle(S, ctx, 'Stage 2: 230-kV lines 22-1 (x2), 22-25 out', false);  stages{end+1} = row;
        end
        % Stage 3: Costa Sur units
        if ~S.collapsed
            S = trip_gen(S, gi(B_COSTASUR));
            [S, row] = settle(S, ctx, 'Stage 3: Costa Sur units trip', true);  stages{end+1} = row;
        end
    case 'aug2022'
        % Stage 1: AES-Yabucoa line (vegetation fault, 11:07:24, reclosed and tripped again 11:08:27)
        S.mpc.branch(brsel(S.mpc.branch, B_YABUCOA, B_AES), BR_STATUS) = 0;
        [S, row] = settle(S, ctx, 'Stage 1: line AES-Yabucoa (93-19) trips', false);  stages{end+1} = row;
        % Stage 2: AES-Aguirre line (open jumper, 11:10:47); the plant is isolated
        if ~S.collapsed
            S.mpc.branch(brsel(S.mpc.branch, B_AGUIRRE230, B_AES), BR_STATUS) = 0;
            S = trip_gen(S, gi(B_AES));
            [S, row] = settle(S, ctx, 'Stage 2: line AES-Aguirre (22-19) trips, AES lost', true);  stages{end+1} = row;
        end
end

out.stage = [stages{:}];
out.log = S.log;
out.final = S;

if opt.verbose
    if ischar(opt.load_shape), shp = opt.load_shape; else, shp = 'user matrix'; end
    fprintf('\nScenario %s. Pre-event: load %.0f MW (distribution ''%s''), dispatch ''%s'', response ''%s'',\n', scenario, load0, shp, opt.dispatch, opt.response);
    fprintf('spinning reserve %.0f MW (%.0f%% of it acts before the underfrequency relays), load-shedding limit %.0f%%, trip at %.0f%%\n', ...
        reserve0, 100 * opt.response_frac, 100 * opt.ufls_max, opt.trip_pct);
    fprintf('  %-10s %9s %14s\n', 'plant bus', 'Pg (MW)', 'on line (MW)');
    for i = 1:ng
        if out.pre(i, 4) > 0, fprintf('  %-10d %9.1f %14.1f\n', out.pre(i, 1), out.pre(i, 2), out.pre(i, 3)); end
    end
    wl = '';
    if ~isempty(opt.watch), wl = sprintf('%d-%d (%%)', opt.watch(1), opt.watch(2)); end
    fprintf('\n%-50s %8s %7s %7s %9s %6s %-14s %6s %5s %10s  %s\n', 'Stage', 'GenLost', 'Pickup', 'Shed', 'Unserved', '(%)', 'Max loading', 'Vmin', 'Trips', wl, 'Status');
    for j = 1:numel(out.stage)
        r = out.stage(j);
        if isempty(opt.watch) || isnan(r.watch), ws = ''; else, ws = sprintf('%.1f', r.watch); end
        if isnan(r.max_loading)
            fprintf('%-50s %8.0f %7s %7s %9.0f %6.1f %-14s %6s %5d %10s  %s\n', r.label, r.gen_lost, '-', '-', ...
                r.unserved, r.unserved_pct, '-', '-', r.ntrips, ws, r.status);
        else
            fprintf('%-50s %8.0f %7.0f %7.0f %9.0f %6.1f %-14s %6.3f %5d %10s  %s\n', r.label, r.gen_lost, round(r.pickup) + 0, r.shed, ...
                r.unserved, r.unserved_pct, sprintf('%.1f%% %s', r.max_loading, r.max_branch), r.vmin, r.ntrips, ws, r.status);
        end
    end
    if ~isempty(out.log), fprintf('\nEvents:\n'); fprintf('  %s\n', out.log{:}); end
end
end

%% ========================================================================
function S = trip_gen(S, i)
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS] = idx_gen;
if S.mpc.gen(i, GEN_STATUS) > 0
    S.genlost = S.genlost + S.mpc.gen(i, PG);
    S.mpc.gen(i, GEN_STATUS) = 0;
    S.mpc.gen(i, PG) = 0;
end
end

%% ========================================================================
function [S, row] = settle(S, ctx, label, fast)
% balance every island, solve, and let protection act until nothing trips.
% FAST: generation was lost in this stage, so every plant can add only the
% fraction RESPONSE_FRAC of its remaining headroom to the output it had just
% before the stage; the rest of the deficit goes to load shedding.
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS] = idx_gen;
S.cap = S.cap_full;
if fast && strcmp(ctx.opt.response, 'online') && ctx.opt.response_frac < 1
    on = S.mpc.gen(:, GEN_STATUS) > 0 & ctx.is_sync;
    now = S.mpc.gen(:, PG);
    S.cap(on) = now(on) + ctx.opt.response_frac * max(S.cap_full(on) - now(on), 0);
end
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, TAP, SHIFT, BR_STATUS] = idx_brch;
ntrips = 0;
while true
    [S, res, info] = balance(S, ctx);
    if S.collapsed, break; end
    on = res.branch(:, BR_STATUS) > 0;
    Sf = abs(res.branch(:, 14) + 1j * res.branch(:, 15));
    St = abs(res.branch(:, 16) + 1j * res.branch(:, 17));
    ld = zeros(size(on)); ld(on) = 100 * max(Sf(on), St(on)) ./ res.branch(on, RATE_A);
    [m, kk] = max(ld);
    if m <= ctx.opt.trip_pct || ntrips >= 80, break; end
    S.mpc.branch(kk, BR_STATUS) = 0;
    ntrips = ntrips + 1;
    S.log{end+1} = sprintf('%s: protection trips %d-%d at %.1f%%', label, S.mpc.branch(kk, F_BUS), S.mpc.branch(kk, T_BUS), m);
end
[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM] = idx_bus;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS] = idx_gen;
row.label = label; row.gen_lost = S.genlost; row.ntrips = ntrips; row.need_pct = S.need_pct;
if S.collapsed
    row.pickup = NaN; row.shed = NaN; row.unserved = ctx.load0; row.unserved_pct = 100;
    row.max_loading = NaN; row.max_branch = '-'; row.vmin = NaN;
    row.status = ['COLLAPSE: ' S.why];
else
    live = res.bus(:, BUS_TYPE) ~= NONE;
    served = sum(res.bus(live, PD));
    on = res.gen(:, GEN_STATUS) > 0 & ctx.is_sync;
    row.pickup = sum(res.gen(on, PG) - S.P0(on));
    row.shed = sum(S.shed .* S.Pd0 .* ~S.dead);
    row.unserved = ctx.load0 - served;
    row.unserved_pct = 100 * row.unserved / ctx.load0;
    row.max_loading = m;
    row.max_branch = sprintf('%d-%d', res.branch(kk, F_BUS), res.branch(kk, T_BUS));
    row.vmin = min(res.bus(live, VM));
    if row.unserved > 0.5, row.status = 'stable after load loss'; else, row.status = 'stable'; end
end
row.watch = NaN;                                % loading of the watched branch, if any
if ~S.collapsed && ~isempty(ctx.opt.watch)
    w = find((res.branch(:, F_BUS) == ctx.opt.watch(1) & res.branch(:, T_BUS) == ctx.opt.watch(2)) | ...
             (res.branch(:, F_BUS) == ctx.opt.watch(2) & res.branch(:, T_BUS) == ctx.opt.watch(1)), 1);
    if ~isempty(w) && res.branch(w, BR_STATUS) > 0, row.watch = ld(w); end
end
end

%% ========================================================================
function [S, res, info] = balance(S, ctx)
% island handling, governor response, load shedding, power flow
[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD] = idx_bus;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX] = idx_gen;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, TAP, SHIFT, BR_STATUS] = idx_brch;
res = []; info.deficit = 0; need_pct = NaN;
nb = size(S.mpc.bus, 1);
busnum = S.mpc.bus(:, BUS_I);
gbus = arrayfun(@(b) find(busnum == b), S.mpc.gen(:, GEN_BUS));

for pass = 1:40                               % repeat when an island collapses
    mpc = S.mpc;
    % --- islands
    tmp = mpc; tmp.bus(S.dead, BUS_TYPE) = NONE;
    tmp.branch(any(ismember(tmp.branch(:, [F_BUS T_BUS]), busnum(S.dead)), 2), BR_STATUS) = 0;
    [groups, isolated] = find_islands(tmp);
    newdead = false(nb, 1);
    newdead(isolated) = true;
    live_groups = {};
    for g = 1:numel(groups)
        idx = groups{g}(:);
        gg = find(ismember(gbus, idx) & mpc.gen(:, GEN_STATUS) > 0 & ctx.is_sync);
        if isempty(gg), newdead(idx) = true; else, live_groups{end+1} = idx; end %#ok<AGROW>
    end
    newdead = newdead & ~S.dead;
    if any(newdead)
        lost = sum(S.Pd0(newdead) .* (1 - S.shed(newdead)));
        if lost > 0.05 || any(ismember(gbus, find(newdead)) & mpc.gen(:, GEN_STATUS) > 0)
            S.log{end+1} = sprintf('island without synchronous generation de-energized: %d buses, %.1f MW of load', nnz(newdead), lost);
        end
        S.dead = S.dead | newdead;
        offg = ismember(gbus, find(newdead)) & S.mpc.gen(:, GEN_STATUS) > 0;
        S.mpc.gen(offg, GEN_STATUS) = 0; S.mpc.gen(offg, PG) = 0;
        mpc = S.mpc;
    end
    if isempty(live_groups)
        S.collapsed = true; if isempty(S.why), S.why = 'no island with synchronous generation remains'; end
        return;
    end

    % --- bus types and reference bus of every live island
    mpc.bus(S.dead, BUS_TYPE) = NONE;
    mpc.branch(any(ismember(mpc.branch(:, [F_BUS T_BUS]), busnum(S.dead)), 2), BR_STATUS) = 0;
    mpc.gen(ismember(gbus, find(S.dead)), GEN_STATUS) = 0;
    live = ~S.dead;
    mpc.bus(live, BUS_TYPE) = PQ;
    ongen = mpc.gen(:, GEN_STATUS) > 0;
    mpc.bus(gbus(ongen), BUS_TYPE) = PV;
    refgen = zeros(numel(live_groups), 1);
    for g = 1:numel(live_groups)
        idx = live_groups{g};
        gg = find(ismember(gbus, idx) & ongen & ctx.is_sync);
        j = gg(busnum(gbus(gg)) == 61);        % Palo Seco if it is in this island
        if isempty(j), [~, m] = max(S.cap(gg)); j = gg(m); end
        refgen(g) = j(1);
        mpc.bus(gbus(j(1)), BUS_TYPE) = REF;
    end

    % --- balance each island (fixed point on the losses)
    loss = zeros(numel(live_groups), 1);
    for g = 1:numel(live_groups)                % start from the previous loss level
        loss(g) = S.lossfrac * sum(S.Pd0(live_groups{g}) .* (1 - S.shed(live_groups{g})));
    end
    shed0 = S.shed;                             % load shedding before this call
    over = zeros(numel(live_groups), 1);        % shedding needed where it exceeds the limit
    for it = 1:40
        S.shed = shed0;                         % recomputed with the updated losses
        over(:) = 0;
        mpc.bus(:, PD) = S.Pd0 .* (1 - S.shed) .* live;
        mpc.bus(:, QD) = S.Qd0 .* (1 - S.shed) .* live;
        Ptarget = zeros(size(mpc.gen, 1), 1);
        for g = 1:numel(live_groups)
            idx = live_groups{g};
            gg = find(ismember(gbus, idx) & ongen);
            gs = gg(ctx.is_sync(gg)); gn = gg(~ctx.is_sync(gg));
            Pl = sum(mpc.bus(idx, PD));
            p = S.P0(gs);                                   % pre-event outputs
            d = Pl + loss(g) - sum(p) - sum(S.P0(gn));      % >0: deficit, <0: surplus
            info.deficit = max(info.deficit, d);
            act = true(size(gs));
            for q = 1:30                                    % share in proportion to capacity
                if abs(d) < 1e-6 || ~any(act), break; end
                share = d * S.cap(gs(act)) / sum(S.cap(gs(act)));
                pn = p(act) + share;
                cact = S.cap(gs(act));
                hi = pn > cact; lo = pn < 0;
                pn(hi) = cact(hi); pn(lo) = 0;
                d = d - sum(pn - p(act));
                a = find(act); p(a) = pn; act(a(hi | lo)) = false;
            end
            Ptarget(gs) = p; Ptarget(gn) = S.P0(gn);
            if d > 0.01                                     % deficit left: shed load
                Pl0 = sum(S.Pd0(idx));
                newshed = 1 - (Pl - d) / Pl0;               % cumulative fraction of pre-event load
                if newshed > ctx.opt.ufls_max + 1e-9, over(g) = newshed; end
                S.shed(idx) = max(S.shed(idx), newshed);
                mpc.bus(idx, PD) = S.Pd0(idx) .* (1 - S.shed(idx));
                mpc.bus(idx, QD) = S.Qd0(idx) .* (1 - S.shed(idx));
            end
        end
        mpc.gen(:, PG) = Ptarget;
        res = runpf(mpc, ctx.mpopt);
        if ~res.success
            if any(over > 0), break; end                    % judged below as a generation deficit
            S.collapsed = true; S.why = 'no power flow solution (voltage)'; return;
        end
        err = res.gen(refgen, PG) - Ptarget(refgen);
        loss = loss + err;
        if max(abs(err)) < 0.02, break; end
    end
    [mx, collapsed_island] = max(over);
    if mx > 0                                               % shedding above the limit: collapse
        need_pct = 100 * mx;
        S.shed = shed0;
        idx = live_groups{collapsed_island};
        lostload = sum(S.Pd0(idx) .* (1 - S.shed(idx)));
        S.log{end+1} = sprintf('island of %d buses (%.0f MW of load) collapses: balancing it would need %.0f%% load shedding (limit %.0f%%)', ...
            numel(idx), lostload, need_pct, 100 * ctx.opt.ufls_max);
        S.why = sprintf('generation deficit needs %.0f%% load shedding', need_pct);
        S.dead(idx) = true;
        offg = ismember(gbus, idx) & S.mpc.gen(:, GEN_STATUS) > 0;
        S.mpc.gen(offg, GEN_STATUS) = 0; S.mpc.gen(offg, PG) = 0;
        S.need_pct = need_pct;
        continue;                                           % re-evaluate what is left
    end
    S.mpc.gen(:, PG) = res.gen(:, PG);
    S.mpc.bus(:, BUS_TYPE) = mpc.bus(:, BUS_TYPE);
    served = sum(res.bus(res.bus(:, BUS_TYPE) ~= NONE, PD));
    if served > 0, S.lossfrac = sum(res.gen(res.gen(:, GEN_STATUS) > 0, PG)) / served - 1; end
    return;
end
end
