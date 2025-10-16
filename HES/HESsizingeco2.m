%**********************************************************************
%*                                                                    *
%*  sizing a hybrid solar PV-diesel-battery                           *
%* assumption:                                                        *
%*             average daily load,                                    *
%*             cloudy days are taken into account                     *
%*             random variation of irradiance around a mean value     *
%**********************************************************************
clc; clear;


%-----------------------data---------------------------------
%% Parameters
prompt = 'enter daily load in kWh   ';
load_daily = input(prompt);

prompt = 'enter daily irradiance in kWh/m2day   ';
irradiance = input(prompt);

prompt = 'enter PV derating factor   ';
eff_pv = input(prompt);

prompt = 'enter battery round trip efficiency   ';
eff_batt = input(prompt);

prompt = 'enter battery depth of discharge   ';
dod = input(prompt);


prompt = 'enter autonomy days   ';
autonomy_days = input(prompt);
display( ' ')
display(' output')


days = 365;                     % Simulation period (days)

%% Sizing
pv_capacity_kw = load_daily / (eff_pv * irradiance);
battery_capacity_kwh = (load_daily * autonomy_days) / (dod * eff_batt);
fprintf('\n=== technical performance ===\n');
fprintf('PV size: %.2f kW\n', pv_capacity_kw);
fprintf('Battery size: %.2f kWh\n', battery_capacity_kwh);

%% Initialize simulation variables
irradiance_variation = 0.2;
battery_soc = battery_capacity_kwh / 2; % Start at 50% SOC
battery_soc_log = zeros(days,1);
diesel_usage_log = zeros(days,1);
pv_gen_log = zeros(days,1);
load_log = load_daily * ones(days,1);

%% Simulate cloudy weeks (e.g., 7 cloudy days every 30 days)
cloudy_days = zeros(days,1);
for i = 1:30:days
    cloudy_days(i:min(i+6,days)) = 1; % Cloudy 7-day blocks
end

%% Daily simulation loop
for day = 1:days
    % Daily irradiance: reduced on cloudy days
    if cloudy_days(day)
        daily_irradiance = irradiance * 0.3;  % Cloudy day
    else
        daily_irradiance = irradiance * (1 + irradiance_variation*(2*rand - 1));
    end
    
    % PV generation for the day
    pv_generation = pv_capacity_kw * daily_irradiance;
    pv_gen_log(day) = pv_generation;

    % Net energy = PV generation - load
    net_energy = pv_generation - load_daily;

    if net_energy >= 0
        % Surplus: charge battery
        charge = net_energy * eff_batt;
        battery_soc = battery_soc + charge;
        if battery_soc > battery_capacity_kwh
            battery_soc = battery_capacity_kwh;
        end
    else
        % Deficit: discharge battery if possible
        deficit = abs(net_energy);
        discharge_available = battery_soc * eff_batt;

        if discharge_available >= deficit
            battery_soc = battery_soc - deficit / eff_batt;
        else
            % Battery can't meet deficit ? diesel used
            diesel_needed = deficit - discharge_available;
            diesel_usage_log(day) = diesel_needed;
            battery_soc = 0;
        end
    end

    battery_soc_log(day) = battery_soc;
end

%% Results
total_diesel = sum(diesel_usage_log);
renewable_fraction = (sum(pv_gen_log) - total_diesel) / sum(load_log);

fprintf('Total diesel used: %.2f kWh/year\n', total_diesel);
fprintf('Renewable energy fraction: %.2f%%\n', renewable_fraction * 100);

%% Plot results
figure;

subplot(3,1,1);
plot(battery_soc_log, 'LineWidth', 1.2);
ylabel('Battery SOC (kWh)');
title('Battery State of Charge');

subplot(3,1,2);
bar(diesel_usage_log);
ylabel('Diesel Usage (kWh)');
xlabel('Day');
title('Diesel Generator Usage');

subplot(3,1,3);
plot(pv_gen_log, 'g');
hold on;
plot(load_log, 'r--');
legend('PV Generation', 'Load');
ylabel('Energy (kWh)');
xlabel('Day');
title('PV Generation vs Load');
%---------------------------------------cost analysis----------------------


%% === Economic and Emissions Analysis ===
%-------------------------economic data-----------------------------
fprintf('\n===  economic data      ===\n');
prompt = 'enter PV capital cost in $/kW  ';
cpv = input(prompt);
%capital costs
pv_cost = cpv * pv_capacity_kw;
prompt = 'enter battery capital cost in $/kWh   ';
cbat = input(prompt);
prompt = 'enter diesel capital cost in kWh   ';
cdiesel = input(prompt);
battery_cost = cbat * battery_capacity_kwh;
diesel_gen_cost = cdiesel * (load_daily / 4); % 1/4 of peak demand assumption
total_capex = pv_cost + battery_cost + diesel_gen_cost;

% --- O&M costs (annual)
prompt = 'enter PV OPEX as fraction of PV CAPEX    ';
fpv = input(prompt);

pv_om = fpv * pv_cost;
prompt = 'enter battery OPEX as fraction battery CAPEX    ';
fbat = input(prompt);

battery_om = fbat * battery_cost;
prompt = 'enter diesel OPEX as fraction diesel CAPEX   ';
fdie = input(prompt);

diesel_om = fdie * sum(diesel_usage_log); % $/kWh
total_om_yearly = pv_om + battery_om + diesel_om;

prompt = 'enter cost of diesel fuel in $/kWh   ';
cfuel = input(prompt);

% --- Diesel fuel cost and emissions
diesel_energy_kwh = sum(diesel_usage_log);
diesel_liters = diesel_energy_kwh / 3.6;
%diesel_fuel_cost = diesel_liters * 1.2; % $1.2/liter
diesel_fuel_cost = diesel_energy_kwh*cfuel; % $1.2/liter
diesel_emissions = diesel_liters * 2.68; % kg CO2

% --- Total annual cost
total_annual_cost = total_om_yearly + diesel_fuel_cost;


%---------------------
% --- Levelized Cost of Energy (LCOE) approximation
prompt = 'enter discount rate   ';
discount_rate = input(prompt);
prompt = 'enter system lifetime (years)   ';
lifetime = input(prompt);
%replacement cost
prompt = 'enter battery lifetime (years)   ';
lifeb = input(prompt);
prompt = 'enter battery learning rate   ';
LR = input(prompt);
k = fix(lifetime/lifeb);
remp = 0.0;
for i=1:k
    n1 = lifeb*i;
    R = cbat*(1-LR)^i /(1+discount_rate)^n1;
    remp = remp + R;
end
%----------------------------------------------------
crf = (discount_rate * (1 + discount_rate)^lifetime) / ...
      ((1 + discount_rate)^lifetime - 1); % capital recovery factor

annualized_capex = total_capex * crf;
annualized_replacement = remp*crf;
%total_annualized_cost = annualized_capex + total_annual_cost;
total_annualized_cost = annualized_capex + annualized_replacement + total_annual_cost;
lcoe = total_annualized_cost / sum(load_log); % $/kWh

%% === Display Summary ===
fprintf('\n=== Cost and Emissions Summary ===\n');
fprintf('Total CAPEX: $%.2f\n', total_capex);
fprintf('Annual O&M cost: $%.2f\n', total_om_yearly);
fprintf('Annual diesel fuel cost: $%.2f\n', diesel_fuel_cost);
fprintf('total replacement cost: $%.2f\n', remp);
fprintf('Total CO2 emissions: %.2f kg/year\n', diesel_emissions);
fprintf('Levelized Cost of Energy (LCOE): $%.3f per kWh\n', lcoe);
