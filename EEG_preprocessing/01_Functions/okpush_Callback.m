function okpush_Callback(hObject, eventdata, handles)
  global button State
% 
  for lb=1:length(button)
     State(lb)=button{lb}.button.UserData;
  end

all_fig = findall(0, 'type', 'figure');
close(all_fig)

 end