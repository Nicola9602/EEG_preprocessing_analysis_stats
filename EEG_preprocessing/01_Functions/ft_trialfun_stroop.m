function trl=ft_trialfun_stroop(cfg)
% Mireia Torralba Cuello MRG Group 2024
% Use this script to segment data for the stroop task

events=ft_read_event(cfg.marker);
hdr=ft_read_header(cfg.header);

samples_to_add=round(cfg.Add_time*hdr.Fs);

fixation=cfg.Fixation;
onset=cfg.Stim_onset;
response=cfg.Response;
trl=[];
for ev=1:length(events)-2
    is_fixation=strcmp(events(ev).value,fixation);
    is_onset=any(strcmp(events(ev+1).value,onset));
    is_response=any(strcmp(events(ev+2).value,response));
    if is_fixation & is_onset & is_response
       
       beg_sample=events(ev).sample-samples_to_add;
       end_sample=events(ev+2).sample+samples_to_add;
       t_fixation_onset=(events(ev+1).sample-events(ev).sample)/hdr.Fs;
        offset=-samples_to_add-(events(ev+1).sample-events(ev).sample);
       code_trial=find(strcmp(events(ev+1).value,onset));
       code_response=find((strcmp(events(ev+2).value,response)));
       switch code_response
           case 3
               RT=nan;
           otherwise
                RT=(events(ev+2).sample-events(ev+1).sample)/hdr.Fs;
     
       end
       %Trial information
       trl=cat(1,trl,[beg_sample end_sample offset 10*code_trial 10*code_response RT t_fixation_onset]);
    end
end

end