% Mireia Torralba MRG Group 2024
% Use this script to calculate conflict related theta
%Initialize paths and parameters that you will use
clear
code='pilot';
analysis='stroop_theta';

[Path,Params]=MI_00_Setup_analysis(code,analysis);


load(Params.layout)
%Initialize fieldtrip (you can comment these lines if you already called
%fieldtrip at least once in your matlab session)
try
    ft_defaults;
   
catch
    addpath(Path.fieldtrip);
    ft_defaults;
end


subject=select_subject(Path.raw_eeg,'multiple');

for sj=1:length(subject)
       load(fullfile(Path.segmented,[Params.experiment_name subject{sj} '_segmented_stroop.mat']),'stroop');

%Extract behavioral information

Behavior(sj).Data=stroop.trialinfo;

%Detect trials with nan
select_trial=true(length(stroop.trial),1);
for trl=1:length(stroop.trial)
       if any(isnan(stroop.trial{trl}(1,:)))
           select_trial(trl)=false;
       end
end

%Now select only trials without artifact and with correct response
cfg=[];
cfg.trials=find(select_trial&stroop.trialinfo(:,2)==Params.Stroop.Correct);
stroop_correct=ft_selectdata(cfg,stroop);

%Calculate power

cfg=[];
cfg.method='wavelet';
cfg.ouptut='power';
cfg.width=5;
cfg.foi=Params.Stroop.Freq;
cfg.toi=-1:0.02:2;
cfg.pad=10;
cfg.trials=stroop_correct.trialinfo(:,1)==Params.Stroop.Congruent;
congruent=ft_freqanalysis(cfg,stroop_correct);
cfg.trials=stroop_correct.trialinfo(:,1)==Params.Stroop.Incongruent;
incongruent=ft_freqanalysis(cfg,stroop_correct);

cfg=[];
cfg.latency=Params.Stroop.Baseline;
cfg.avgovertime='yes';
bsC=ft_selectdata(cfg,congruent);
bsI=ft_selectdata(cfg,incongruent);

congruent.powspctrm=10*log10(congruent.powspctrm./repmat(bsC.powspctrm,1,1,length(congruent.time)));
incongruent.powspctrm=10*log10(incongruent.powspctrm./repmat(bsI.powspctrm,1,1,length(incongruent.time)));


cfg=[];
cfg.latency=[-0.5 1];
Congruent{1,sj}=ft_selectdata(cfg,congruent);
Incongruent{1,sj}=ft_selectdata(cfg,incongruent);
end
%%
cfg=[];
congruent=ft_freqgrandaverage(cfg,Congruent{:});
incongruent=ft_freqgrandaverage(cfg,Incongruent{:});

cfg=[];
cfg.channel=Params.Stroop.ROI;
tmp=ft_selectdata(cfg,congruent);
tmp2=ft_selectdata(cfg,incongruent);

h=figure('Position', [114 227 1126 751])

subplot(2,2,1)
contourf(congruent.time,congruent.freq,squeeze(tmp.powspctrm),20,'LineStyle','none');
caxis([-3 3])
xlabel('Time (s)')
ylabel('Frequency (Hz)')
c = colorbar;
c.Label.String = 'Power (dB)';
ylim([2 15])
ax=gca;
set(ax,'FontName','Arial','FontSize',16)
title('Congruent')
subplot(2,2,2)
contourf(congruent.time,congruent.freq,squeeze(tmp2.powspctrm),20,'LineStyle','none');
caxis([-3 3])
xlabel('Time (s)')
ylabel('Frequency (Hz)')
c = colorbar;
c.Label.String = 'Power (dB)';
ylim([2 15])
ax=gca;
set(ax,'FontName','Arial','FontSize',16)
title('Incongruent')
subplot(2,1,2)      
contourf(congruent.time,congruent.freq,squeeze(tmp2.powspctrm-tmp.powspctrm),20,'LineStyle','none');
caxis([-1 1])
xlabel('Time (s)')
ylabel('Frequency (Hz)')
c = colorbar;
c.Label.String = '\Delta Power (dB)';
ylim([2 15])
ax=gca;
set(ax,'FontName','Arial','FontSize',16)
title('Incongruent - Congruent')

saveas(h,'FCz_activity_stroop.jpg','jpg');
close

%% Now run behavior

Bev=[];
for sj=1:2

    TB=Behavior(sj).Data;
    
    Hit_C=TB(TB(:,1)==10 & TB(:,2)==10,3);
    Hit_I=TB(TB(:,1)==20 & TB(:,2)==10,3);
    Miss_C=TB(TB(:,1)==10 & TB(:,2)==20,3);
    Miss_I=TB(TB(:,1)==20 & TB(:,2)==20,3);
    Tout_C=TB(TB(:,1)==10 & TB(:,2)==30,3);
    Tout_I=TB(TB(:,1)==20 & TB(:,2)==30,3);
    
    Bev(sj).Congruent_hits=size(Hit_I,1);
    Bev(sj).Incongruent_hits=size(Hit_C,1);
    Bev(sj).Congruent_misses=size(Miss_C,1);
    Bev(sj).Incongruent_misses=size(Miss_I,1);
    Bev(sj).Congruent_timeouts=size(Tout_C,1);
    Bev(sj).Incongruent_timeouts=size(Tout_I,1);
    Bev(sj).Congruent_RT_corr=mean(Hit_C);
    Bev(sj).Congruent_RT_corr_sd=std(Hit_C);
    Bev(sj).Incongruent_RT_corr=mean(Hit_I);
    Bev(sj).Incongruent_RT_corr_sd=std(Hit_I);
    
    Pooled_S=sqrt(((size(Hit_C,1)-1)*std(Hit_C)^2+(size(Hit_I,1)-1)*std(Hit_I)^2)/(size(Hit_C,1)+size(Hit_I,1)-2));
    Bev(sj).Cohen_d=(mean(Hit_I)-mean(Hit_C))/Pooled_S;
end

Bev=struct2table(Bev)

writetable(Bev,'pilot_behavior.xlsx')