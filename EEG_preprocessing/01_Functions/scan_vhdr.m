function Electrode=scan_vhdr(filename,Num_chans_per_set)


fid=fopen(filename,'r');

for l=1:22
    fgetl(fid);
end

%Read the electrodes in the first channel set
for el=1:Num_chans_per_set

l=fgetl(fid);

p1=strfind(l,'=');
p2=strfind(l,',');

chan_name=l(p1+1:p2(1)-1);
chan_num=sscanf(l(3:p1-1),'%i');

Electrode(el).Name=chan_name;
Electrode(el).Set=1;
Electrode(el).Chan_num=chan_num;
end


%Read the electrodes in the second channel set
for el=1:Num_chans_per_set

l=fgetl(fid);

p1=strfind(l,'=');
p2=strfind(l,',');

chan_name=l(p1+1:p2(1)-1);
chan_num=sscanf(l(3:p1-1),'%i');

Electrode(el+Num_chans_per_set).Name=chan_name;
Electrode(el+Num_chans_per_set).Set=2;
Electrode(el+Num_chans_per_set).Chan_num=chan_num-Num_chans_per_set;
end
fclose(fid)

Electrode=struct2table(Electrode);