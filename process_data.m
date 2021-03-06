function data = process_data(data,matname,moviename,annname)

nflies = length(data);

if ~exist('matname','var')
  matname = '';
end
if ~exist('moviename','var')
  moviename = '';
end
if ~exist('annname','var')
  annname = '';
end

% set moviename
for fly = 1:nflies,
  data(fly).moviename = moviename;
  data(fly).matname = matname;
  data(fly).annname = annname;
end

if isfield(data,'xpred'),
  data = rmfield(data,'xpred');
end
if isfield(data,'ypred'),
  data = rmfield(data,'ypred');
end
if isfield(data,'thetapred'),
  data = rmfield(data,'thetapred');
end

% read arena dimensions
if ~isfield(data,'arena') || isnan(data(1).arena.x),
  if ~isempty(annname) && exist(annname,'file'),
    [arena.x,arena.y,arena.r] = arena_params(annname,moviename);
  else
    arena.x = nan; arena.y = nan; arena.r = nan;
  end
  for fly = 1:nflies,
    data(fly).arena = arena;
  end
end

thetafil = [1     4     6     4     1]/16;

if ~isfield(data,'x_mm'),
  if ~isfield(data,'pxpermm'),
    error('Conversion from pixels to mm not set.');
  end
  for fly = 1:nflies,
    data(fly).x_mm = data(fly).x / data(fly).pxpermm;
    data(fly).y_mm = data(fly).y / data(fly).pxpermm;
    data(fly).a_mm = data(fly).a / data(fly).pxpermm;
    data(fly).b_mm = data(fly).b / data(fly).pxpermm;
  end
end

% compute velocities in the canonical coordinates of the fly
istimestamps = isfield(data,'timestamps');
for fly = 1:nflies,
   
   if isdummytrk( data(fly) ), continue, end

  % already set units
  data(fly).units.x = parseunits('px');
  data(fly).units.y = parseunits('px');
  data(fly).units.a = parseunits('px');
  data(fly).units.b = parseunits('px');
  data(fly).units.theta = parseunits('rad');
  data(fly).units.x_mm = parseunits('mm');
  data(fly).units.y_mm = parseunits('mm');
  data(fly).units.a_mm = parseunits('mm');
  data(fly).units.b_mm = parseunits('mm');
  
  % compute time between frames
  if istimestamps,
    data(fly).dt = diff(data(fly).timestamps);
  else
    data(fly).dt = repmat(1/data(fly).fps,[1,data(fly).nframes-1]);
  end
  data(fly).units.dt = parseunits('s');
  
  % change in body orientation
  data(fly).dtheta = modrange(diff(data(fly).theta),-pi,pi)./data(fly).dt;
  data(fly).units.dtheta = parseunits('rad/s');
  
  % change in center position
  dx = diff(data(fly).x_mm);
  dy = diff(data(fly).y_mm);
  
  % forward motion of body center
  if data(fly).nframes < 2,
    data(fly).du_ctr = [];
  else
    data(fly).du_ctr = (dx.*cos(data(fly).theta(1:end-1)) + dy.*sin(data(fly).theta(1:end-1)))./data(fly).dt;
  end
  data(fly).units.du_ctr = parseunits('mm/s');
  % sideways motion of body center
  if data(fly).nframes < 2,
    data(fly).dv_ctr = [];
  else
    data(fly).dv_ctr = (dx.*cos(data(fly).theta(1:end-1)+pi/2) + dy.*sin(data(fly).theta(1:end-1)+pi/2))./data(fly).dt;
  end
  data(fly).units.dv_ctr = parseunits('mm/s');
  
  % find the center of rotation
  if data(fly).nframes < 2,
    corfrac = zeros(2,0);
    data(fly).corisonfly = [];
  else
    [corfrac,data(fly).corisonfly] = center_of_rotation2_ctb(data(fly),false);
  end
  data(fly).corfrac_maj = corfrac(1,:);
  data(fly).corfrac_min = corfrac(2,:);
  data(fly).abscorfrac_min = abs(corfrac(2,:));
  data(fly).units.corfrac_maj = parseunits('unit');
  data(fly).units.corfrac_min = parseunits('unit');
  data(fly).units.abscorfrac_min = parseunits('unit');
  data(fly).units.corisonfly = parseunits('unit');
  
  if data(fly).nframes < 2,
    data(fly).du_cor = [];
    data(fly).dv_cor = [];
  else
    
    [x_cor_curr,y_cor_curr,x_cor_next,y_cor_next] = rfrac2center_ctb(data(fly),[data(fly).corfrac_maj;data(fly).corfrac_min]);

    % change in center of rotation
    dx_cor = x_cor_next - x_cor_curr;
    dy_cor = y_cor_next - y_cor_curr;
    
    % forward motion of center of rotation
    data(fly).du_cor = (dx_cor.*cos(data(fly).theta(1:end-1)) + dy_cor.*sin(data(fly).theta(1:end-1)))./data(fly).dt;
    % sideways motion of body center
    data(fly).dv_cor = (dx_cor.*cos(data(fly).theta(1:end-1)+pi/2) + dy_cor.*sin(data(fly).theta(1:end-1)+pi/2))./data(fly).dt;
  end
  data(fly).units.du_cor = parseunits('mm/s');
  data(fly).units.dv_cor = parseunits('mm/s');
  
  % magnitude of velocity
  if data(fly).nframes < 2,
    data(fly).velmag_ctr = [];
  else
    data(fly).velmag_ctr = sqrt(dx.^2 + dy.^2)./data(fly).dt;
  end
  data(fly).units.velmag_ctr = parseunits('mm/s');
  if data(fly).nframes < 2,
    data(fly).velmag = [];
  else
    data(fly).velmag = sqrt(dx_cor.^2 + dy_cor.^2)./data(fly).dt;
    badidx = isnan(dx_cor);
    data(fly).velmag(badidx) = data(fly).velmag_ctr(badidx);
  end
  data(fly).units.velmag = parseunits('mm/s');
  
  % acceleration magnitude
  if data(fly).nframes < 2,
    data(fly).accmag = [];
  else
    % speed from frame 1 to 2 minus speed from 2 to 3 / time from 2 to 3
    tmp = sqrt( diff( dx./data(fly).dt, 1, 2 ).^2 + diff( dy./data(fly).dt, 1, 2 ).^2 )./data(fly).dt(2:end);
    data(fly).accmag = [0,tmp];
  end
  data(fly).units.accmag = parseunits('mm/s/s');
  
  % flipped sign dv, dtheta
  data(fly).signdtheta = sign(data(fly).dtheta);
  data(fly).units.signdtheta = parseunits('unit');
  data(fly).absdv_cor = abs(data(fly).dv_cor);
  data(fly).units.absdv_cor = parseunits('mm/s');
  data(fly).flipdv_cor = data(fly).dv_cor.*data(fly).signdtheta;
  data(fly).units.flipdv_cor = parseunits('mm/s');
  %data(fly).realabsdv_cor = abs(data(fly).dv_cor);
  data(fly).absdtheta = abs(data(fly).dtheta);
  data(fly).units.absdtheta = parseunits('rad/s');
  if data(fly).nframes < 2,
    data(fly).d2theta = [];
  else
    data(fly).d2theta = [0,modrange(diff(data(fly).dtheta),-pi,pi)]./data(fly).dt;
  end
  data(fly).units.d2theta = parseunits('rad/s/s');
  data(fly).absd2theta = abs(data(fly).d2theta);
  data(fly).units.absd2theta = parseunits('rad/s/s');
  
  % smoothed orientation
  data(fly).smooththeta = myconv(unwrap(data(fly).theta),thetafil,'replicate','same');
  data(fly).units.smooththeta = parseunits('rad');
  if data(fly).nframes < 2,
    data(fly).smoothdtheta = [];
  else
    data(fly).smoothdtheta = diff(data(fly).smooththeta)./data(fly).dt;
  end
  data(fly).units.smoothdtheta = parseunits('rad/s');
  data(fly).smooththeta = modrange(data(fly).smooththeta,-pi,pi);
  data(fly).abssmoothdtheta = abs(data(fly).smoothdtheta);
  data(fly).units.abssmoothdtheta = parseunits('rad/s');
  if data(fly).nframes < 2,
    data(fly).smoothd2theta = [];
  else
    data(fly).smoothd2theta = [0,modrange(diff(data(fly).smoothdtheta),-pi,pi)]./data(fly).dt;
  end
  data(fly).units.smoothd2theta = parseunits('rad/s/s');
  data(fly).abssmoothd2theta = abs(data(fly).smoothd2theta);
  data(fly).units.abssmoothd2theta = parseunits('rad/s/s');

  data(fly).off = -data(fly).firstframe + 1;
  %data(fly).f2i = @(f) f - data(fly).firstframe + 1;
  
  % velocity direction
  if data(fly).nframes < 2,
    % if only one frame, set to orientation
    data(fly).phi = data(fly).theta;
  else
    dy1 = [data(fly).y(2)-data(fly).y(1),(data(fly).y(3:end)-data(fly).y(1:end-2))/2,data(fly).y(end)-data(fly).y(end-1)];
    dx1 = [data(fly).x(2)-data(fly).x(1),(data(fly).x(3:end)-data(fly).x(1:end-2))/2,data(fly).x(end)-data(fly).x(end-1)];
    data(fly).phi = atan2(dy1,dx1);
  end
  data(fly).units.phi = parseunits('rad');
  
  % difference between velocity direction and orientation
  data(fly).yaw = modrange(data(fly).phi - data(fly).theta,-pi,pi);
  data(fly).units.yaw = parseunits('rad');
  data(fly).absyaw = abs(data(fly).yaw);
  data(fly).units.absyaw = parseunits('rad');
end
