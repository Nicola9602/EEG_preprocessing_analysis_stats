function Bad_chan=Mark_bad_channel(Params,layout,bad_chan)

Bad_chan=[];
fig=uifigure('Position',[Params.x0 Params.y0 Params.Size Params.Size]);


uilabel(fig,'Text',{'Indicate channels to discard';'Press Ok once you are done'},...
    'Position',[10 Params.Size-50 Params.Size-200 50],'FontSize',20)

position=0.5*Params.Size+layout.pos*Params.Size;
global button State

State=nan(length(layout.label),1);

    for lb=1:length(layout.label)
        if ismember(layout.label{lb},bad_chan)
            Color=[1 0 0];
            State(lb)=true;

        else
            Color=[0.7 1 0.7];
            State(lb)=false;
        end

        button{lb}.button=uibutton(fig,'Text',layout.label{lb},'Position', [position(lb,1)...
            position(lb,2) Params.Label_size Params.Label_size],'BackgroundColor',Color,...
            'UserData',State(lb),'ButtonPushedFcn',@pushbutton1_Callback);



    end

    Ok_button=uibutton(fig,'Text','Ok','Position',[300 550 60 50],'FontSize',20,...
        'ButtonPushedFcn',@okpush_Callback);

    %Pause the code until the figure is closed
uiwait(fig);



Bad_channel=find(State);

if any(State) 
    for lb=1:length(Bad_channel)
        Bad_chan{lb}=layout.label{Bad_channel(lb)};
    end
else
    Bad_chan={''};
end

end
