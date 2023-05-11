%==========================================================================
% [CPcor_new, M_new] = COMPUTE_new_cpcor_brian(floatnum)
% Compute optimum CPcor_new and M_new (cell gain factor) values by comparing an Argo profile to a reference profile (e.g. deployment CTD)
%   INPUT :  floatnum  (float)  e.g. 6901601
%   OUTPUT :  CPcor_new    optimum cpcor value (by comparison to shipboard reference data)
%             M_new        optimum cell gain   (by comparison to shipboard reference data)
%
% USE GSW matlab routines  https://github.com/TEOS-10/GSW-Matlab/tree/master/Toolbox
% USE OW matlab routine   ./lib/ext_lib/interp_climatology.m  https://github.com/ArgoDMQC/matlab_owc/blob/master/matlab_codes/interp_climatology.m
%
% ccabanes (12/2020)  from Brian King’s routine (ploat_float_ctd_v2-1.m)
%          (03/2021)  use of pres_adjusted and temp_adjusted if available (i.e. after pressure correction)
%==========================================================================
function [CPcor_new, M_new]=COMPUTE_new_cpcor_brian(floatnum)

init_path
floatname=num2str(floatnum);

%local directory (input  files)
CONFIG.DIR_DATA=['./example_data/'];
CONFIG.ARGO_FILE=[CONFIG.DIR_DATA 'ex_' floatname '_float_data.mat'];
CONFIG.REF_FILE=[CONFIG.DIR_DATA 'ex_' floatname '_ref_data.mat'];



% nominal CPcor/CTcor values from SBE.
%--------------------------------------------------------------------------
CPcor_SBE = -9.5700E-8;
CTcor_SBE =  3.2500E-6;

% Default new CPcor values for SBE41/SBE61 (for comparison purpose only)
%--------------------------------------------------------------------------
CPcor_DEF_SBE61 = -12.500E-8;  
CPcor_DEF_SBE41 = -13.500E-8;  
CPcor_DEF = CPcor_DEF_SBE41; 

% Minimum pressure considered for the optimum fit (do not considerd depth shallower than minPRESS)
%--------------------------------------------------------------------------
% This value is somewhat arbitrary and could have some influence on the final results. 
% This is to avoid the high variability, generally located in the upper layers,
%  which can degrade the comparison between the deployment ctd and the argo profile.
minPRESS = 1000;

% only use reference data that are within +/- MAX_P_DELTA dbar from float data when
% interpolating psal_ref onto float conservative temperature levels
%--------------------------------------------------------------------------
MAX_P_DELTA=250;



%1. Load Argo data (e.g. 1st ascending profile if deep enough)
% Suffix _argo means values from the float 
%                         : (1xN_LEVELS) psal_argo,  temp_argo, pres_argo, from PSAL, TEMP, PRES,with bad QCS removed (NaN values)
%                         : (1xN_LEVELS) optional : tempad_argo, presad_argo, from TEMP_ADJUSTED and PRES_ADJUSTED, if available
%                         : (1x1)        lon_argo, lat_argo  from  LONGITUDE, LATITUDE
%--------------------------------------------------------------------------

load(CONFIG.ARGO_FILE);

if exist('presad_argo')==1 & exist('tempad_argo')==1 % adjusted values exist for temp and pres
   pres_argo_corr = presad_argo;
   temp_argo_corr = tempad_argo;
   notisnan = ~isnan(psal_argo)&~isnan(pres_argo)&~isnan(temp_argo)&~isnan(presad_argo)&~isnan(tempad_argo);
else % no adjusted value for temp or pres
  disp('There are no adjusted values for TEMP or PRES')
  pres_argo_corr = pres_argo;
  temp_argo_corr = temp_argo;
  notisnan = ~isnan(psal_argo)&~isnan(pres_argo)&~isnan(temp_argo);
end

psal_argo = psal_argo(notisnan);
temp_argo = temp_argo(notisnan);
pres_argo = pres_argo(notisnan);

pres_argo_corr =  pres_argo_corr(notisnan);
temp_argo_corr =  temp_argo_corr(notisnan);

%2. Load reference data (eg deployment CTD)
%  Suffix _ref means values  from the reference data
%                                           : (1xN_LEVELS2)  psal_ref, temp_ref, pres_ref,
%                                           : (1x1)          lon_ref, lat_ref
%--------------------------------------------------------------------------

load(CONFIG.REF_FILE);

notisnan = ~isnan(psal_ref)&~isnan(pres_ref)&~isnan(temp_ref);
psal_ref = psal_ref(notisnan);
temp_ref = temp_ref(notisnan);
pres_ref = pres_ref(notisnan);

if isempty(pres_argo)==0 & isempty(pres_ref)==0
    
    % 3. Back off temp and pressure correction values to get uncorrected float conductivity (cond_ZERO)
    %--------------------------------------------------------------------------
    a1 = (1 + CTcor_SBE.*temp_argo + CPcor_SBE.*pres_argo);   %  take raw temp & pres values
    cond_argo = gsw_C_from_SP(psal_argo,temp_argo,pres_argo);
    cond_ZERO = cond_argo.*a1;
	
	%4. Re-calculate salinity data by using adjusted pressure and compute Argo data’s derived quantities
    % sa : absolute salinity
    % ct : conservative temperature
    %--------------------------------------------------------------------------
	psal_argo_corr = gsw_SP_from_C(cond_argo,temp_argo_corr,pres_argo_corr);
    sa_argo_corr = gsw_SA_from_SP(psal_argo_corr,pres_argo_corr,lon_argo,lat_argo);
    ct_argo_corr = gsw_CT_from_t(sa_argo_corr,temp_argo_corr,pres_argo_corr);
    
    %5. Compute reference data’s derived quantities
    %--------------------------------------------------------------------------
    sa_ref = gsw_SA_from_SP(psal_ref,pres_ref,lon_ref,lat_ref);
    ct_ref = gsw_CT_from_t(sa_ref,temp_ref,pres_ref);
    
    
    %6. Compute the conductivity that the float should have used to calculate
    %   and report practical salinity that is in agreement with reference data
    %   => cond_expected
    %--------------------------------------------------------------------------
    
    % Interpolation of psal_ref onto float conservative temperature levels.
    [psal_ref_i,pres_ref_i] = interp_climatology(psal_ref',ct_ref',pres_ref',psal_argo_corr,ct_argo_corr,pres_argo_corr); % routine OW (=>deal with temp inv)
    
    % and the conductivity that the float should have used to calculate and report practical salinity that is in agreement with reference data:
    cond_expected = gsw_C_from_SP(psal_ref_i',temp_argo_corr,pres_argo_corr);
    
    % difference of pressure   %change CC 05/09/2022
    okdiffP = abs(pres_ref_i'-pres_argo_corr)< MAX_P_DELTA;
    
    % 7. Levels selection
    %---------------------
    %kok = find(pres_argo_corr > minPRESS & isfinite(cond_expected);
    kok = find(pres_argo_corr > minPRESS & isfinite(cond_expected)& okdiffP);  %change CC 05/09/2022
    
    % 8. Solve least square problem to get optimized values of CPcor and M (from B.King)
    %---------------------------------------------------------------------
    % We are looking for M and CPcor so that:
    % cond_expected = (cond_ZERO * M)/(1 + t * CTcor_SBE + p * CPcor)
    % so CPcor * p - M * (cond_ZERO/cond_expected) = - (1 + t*CTcor_SBE)
    % This is a least squares problem similar to linear regression;
    % Borrow QR factorisation from polyfit;
    % In vector terms below:
    % v * [CPcor; M] = b;
    
    p = pres_argo_corr(kok);
    rat = -cond_ZERO(kok)./cond_expected(kok);
    b = -1 - CTcor_SBE*temp_argo_corr(kok);
    v = [p(:)/1e8 rat(:)];
    b = b(:);
    [Q R] = qr(v);
    coefs = R\(Q'*b);
    cpcor_n = coefs(1); % cpcor * 1e8
    M_n = coefs(2); % best cfac for this profile;
    CPcor_new = cpcor_n*1e-8;
    M_new = M_n;
    
    
    % 9. Some plots
    %--------------------------------------------------------------------------
    % compute psal differences (argo-ref)on CT levels
    
    delta_psal_SBE=[psal_argo_corr-psal_ref_i'];
    
    
    [cond_argo_DM, psal_argo_DM] = change_cpcor(CPcor_new, 1, CTcor_SBE, CPcor_SBE, psal_argo, temp_argo, pres_argo,temp_argo_corr,pres_argo_corr); % correction CPCOR,  no offset corrected
    sa_argo_DM = gsw_SA_from_SP(psal_argo_DM,pres_argo_corr,lon_argo,lat_argo);
    ct_argo_DM = gsw_CT_from_t(sa_argo_DM,temp_argo_corr,pres_argo_corr);
    [psal_i_ref_o,pres_i_ref_o] = interp_climatology(psal_ref',ct_ref',pres_ref',psal_argo_DM,ct_argo_DM,pres_argo_corr); % routine OW
    delta_psal_DM = [psal_argo_DM-psal_i_ref_o'];
    
    
    % calculate the cell gain if standard CPcor value (CPcor_DEF) is used
    % M_DEF =  mean((CPcor_DEF * p + (1 + temp_argo(kok)*CTcor_SBE))./  (cond_ZERO(kok)./cond_expected(kok)));
    
    [cond_argo_DEF, psal_argo_DEF] = change_cpcor(CPcor_DEF, 1, CTcor_SBE, CPcor_SBE, psal_argo, temp_argo, pres_argo,temp_argo_corr,pres_argo_corr); %  CPCOR_DEF,  no offset corrected
    sa_argo_DEF = gsw_SA_from_SP(psal_argo_DEF,pres_argo_corr,lon_argo,lat_argo);
    ct_argo_DEF = gsw_CT_from_t(sa_argo_DEF,temp_argo_corr,pres_argo_corr);
    [psal_i_ref_o,pres_i_ref_o] = interp_climatology(psal_ref',ct_ref',pres_ref',psal_argo_DEF,ct_argo_DEF,pres_argo_corr); % routine OW
    delta_psal_DEF = [psal_argo_DEF-psal_i_ref_o'];
    
    
    figure(1)
    hold on
    grid on
    box on
    plot(delta_psal_SBE(okdiffP),pres_argo(okdiffP),'+b')
    plot(delta_psal_DM(okdiffP),pres_argo(okdiffP),'*r')
    plot(delta_psal_DEF(okdiffP),pres_argo(okdiffP),'og')
    title({[ floatname ': Salinity deviation from the deployement CTD'];['Effect of the Cpcor correction only (M_new=1)']},'Fontsize',12,'interpreter','none')
    xlabel('Salinity deviation','Fontsize',12)
    legend({'Original  profile : CPcor_SBE  (-9.57e-8) , cell gain=1',['Modified profile: CPcor_new (' num2str(CPcor_new) '), cell gain=1'],['Modified profile: CPcor_new - default value (' num2str(CPcor_DEF) '),   cell gain=1']},'location','SouthOutside','Fontsize',8,'interpreter','none')
    ylabel('pressure','Fontsize',12)
    set(gca,'Ydir','reverse')
    
else
    CPcor_new=[];
    M_new=[];
    disp('no valid argo or ref data available to estimate CPcor_new')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute  conductiviy and psal with a new CPCOR value and eventually
% pres_adjusted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cond_argo_DM, psal_argo_DM] = change_cpcor(CPcor_new,M_new,CTcor_SBE, CPcor_SBE, psal_argo, temp_argo, pres_argo,temp_argo_corr,pres_argo_corr)

a1 = (1 + CTcor_SBE.*temp_argo + CPcor_SBE.*pres_argo);  %take raw temp & pres values
cond_argo = gsw_C_from_SP(psal_argo,temp_argo,pres_argo);
cond_ZERO = cond_argo.*a1;

%Calculate the optimized float conductivities using  CPcor_new value and a multiplicative calibration value M_new.
b1 = (1 + CTcor_SBE.*temp_argo_corr + CPcor_new.*pres_argo_corr);
cond_argo_DM = M_new.*cond_ZERO./b1;

% compute the corresponding psal
psal_argo_DM = gsw_SP_from_C(cond_argo_DM,temp_argo_corr,pres_argo_corr);

