function pushbutton1_Callback(hObject, eventdata, handles)
 switch hObject.UserData
     case true
         hObject.BackgroundColor=[0.7 1 0.7];
         hObject.UserData=false;
     case false
         hObject.BackgroundColor=[1 0 0];
         hObject.UserData=true;
 end