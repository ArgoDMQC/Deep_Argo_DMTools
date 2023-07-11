function [bsn_num]=find_sarah_basin_num(lon,lat)
lon(lon<0)=lon(lon<0)+360;
% it is assumed that lon is in the range 0 to 360
% lat and lon can be arrays
load('bsn.mat')



lon2=lon+360;
lon3=lon-360;
bsn_num=nans(1,length(lon));
for ibsn=1:length(bsn)
    in=inpolygon(lon,lat,bsn(ibsn).boundry(1,:),bsn(ibsn).boundry(2,:));
    in2=inpolygon(lon2,lat,bsn(ibsn).boundry(1,:),bsn(ibsn).boundry(2,:));
    in3=inpolygon(lon3,lat,bsn(ibsn).boundry(1,:),bsn(ibsn).boundry(2,:));%     plot(bsn(ibsn).boundry(1,:),bsn(ibsn).boundry(2,:),'*')
    
    bsn_num(in|in2|in3)=ibsn ;

end
    