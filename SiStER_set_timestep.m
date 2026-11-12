function [dt_m]=SiStER_set_timestep(dx,dy,vx,vy,PARAMS)
% [dt_m]=SiStER_set_timestep(dx,dy,vx,vy,PARAMS)
% sets the advection time step
% J.-A. Olive, November 2014

dt_cfl = PARAMS.fracCFL*0.5*min(min(dx),min(dy))./max(max(max(abs(vx))),max(max(abs(vy))));
%dt_m=PARAMS.fracCFL*0.5*min(min(dx),min(dy))./max(max(max(abs(vx))),max(max(abs(vy))));

if isfield(PARAMS, 'dt_fixed') && ~isempty(PARAMS.dt_fixed)
    dt_m = min(PARAMS.dt_fixed, dt_cfl);
else
    dt_m = dt_cfl;
end