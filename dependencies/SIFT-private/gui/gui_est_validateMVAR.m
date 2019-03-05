function varargout = gui_est_validateMVAR(varargin)
%
% GUI_EST_VALIDATEMVAR M-file for gui_est_validateMVAR.fig
%      GUI_EST_VALIDATEMVAR, by itself, creates a new GUI_EST_VALIDATEMVAR or raises the existing
%      singleton*.
%
%      H = GUI_EST_VALIDATEMVAR returns the handle to a new GUI_EST_VALIDATEMVAR or the handle to
%      the existing singleton*.
%
%      GUI_EST_VALIDATEMVAR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_EST_VALIDATEMVAR.M with the given input arguments.
%
%      GUI_EST_VALIDATEMVAR('Property','Value',...) creates a new GUI_EST_VALIDATEMVAR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_est_validateMVAR_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_est_validateMVAR_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui_est_validateMVAR

% Last Modified by GUIDE v2.5 06-Jun-2012 19:41:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @gui_est_validateMVAR_OpeningFcn, ...
    'gui_OutputFcn',  @gui_est_validateMVAR_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before gui_est_validateMVAR is made visible.
function gui_est_validateMVAR_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui_est_validateMVAR (see VARARGIN)

set(hObject,'name','Validated Fitted VAR Model');

handles.output = hObject;

% set default termination behavior
handles.ExitButtonClicked = 'Cancel';

% extract some data from command-line input
if isempty(varargin)
    error('You must pass ALLEEG to gui_est_validateMVAR');
end

% Extract input parameters/data and store
handles.ud.ALLEEG  = varargin{1};
varargin(1) = [];

% set default EEGLAB background and text colors
%-----------------------------------------------
try, icadefs;
catch,
    GUIBACKCOLOR        =   [.8 .8 .8];
    GUIPOPBUTTONCOLOR   =   [.8 .8 .8];
    GUITEXTCOLOR        =   [0 0 0];
end;

allhandlers = hObject;

hh = findobj(allhandlers,'style', 'text');
%set(hh, 'BackgroundColor', get(hObject, 'color'), 'horizontalalignment', 'left');
set(hh, 'Backgroundcolor', GUIBACKCOLOR);
set(hh, 'foregroundcolor', GUITEXTCOLOR);
set(hObject, 'color',GUIBACKCOLOR );
% set(hh, 'horizontalalignment', g.horizontalalignment);

hh = findobj(allhandlers, 'style', 'edit');
set(hh, 'BackgroundColor', [1 1 1]); %, 'horizontalalignment', 'right');

hh =findobj(allhandlers, 'parent', hObject, 'style', 'pushbutton');
if ~strcmpi(computer, 'MAC') && ~strcmpi(computer, 'MACI') % this puts the wrong background on macs
    set(hh, 'backgroundcolor', GUIPOPBUTTONCOLOR);
    set(hh, 'foregroundcolor', GUITEXTCOLOR);
end;
hh =findobj(allhandlers, 'parent', hObject, 'style', 'popupmenu');
set(hh, 'backgroundcolor', GUIPOPBUTTONCOLOR);
set(hh, 'foregroundcolor', GUITEXTCOLOR);
hh =findobj(allhandlers, 'parent', hObject, 'style', 'checkbox');
set(hh, 'backgroundcolor', GUIBACKCOLOR);
set(hh, 'foregroundcolor', GUITEXTCOLOR);
hh =findobj(allhandlers, 'parent', hObject, 'style', 'listbox');
set(hh, 'backgroundcolor', GUIPOPBUTTONCOLOR);
set(hh, 'foregroundcolor', GUITEXTCOLOR);
hh =findobj(allhandlers, 'parent', hObject, 'style', 'radio');
set(hh, 'foregroundcolor', GUITEXTCOLOR);
set(hh, 'backgroundcolor', GUIPOPBUTTONCOLOR);
set(hObject, 'visible', 'on');

set(handles.pnlPropertyGrid,'backgroundcolor', GUIBACKCOLOR);
set(handles.pnlPropertyGrid,'foregroundcolor', GUITEXTCOLOR);
%-----------------------------------------------

drawnow

% render the PropertyGrid in the correct panel
handles.PropertyGridHandle = arg_guipanel( ...
    handles.pnlPropertyGrid, ...
    'Function',@est_validateMVAR, ...
    'params',[{'ALLEEG',handles.ud.ALLEEG}, varargin]);

% Update handles structure
guidata(hObject, handles);

% Wait for user to click OK, Cancel or close figure
uiwait(handles.gui_est_validateMVAR);


% --- Outputs from this function are returned to the command line.
function varargout = gui_est_validateMVAR_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles)
    % user closed the figure
    varargout = {[] hObject};
elseif strcmpi(handles.ExitButtonClicked,'OK')
    % user clicked OK
    % get PropertySpecification
    varargout = {handles.PropertyGridHandle handles.output};
else
    % user clicked cancel
    varargout = {[] handles.output};
end

try, close(hObject);
catch; end


function cmdCancel_Callback(hObject, eventdata, handles)

handles.ExitButtonClicked = 'Cancel';
guidata(hObject,handles);
uiresume(handles.gui_est_validateMVAR);


function cmdOK_Callback(hObject, eventdata, handles)

handles.ExitButtonClicked ='OK';
guidata(hObject,handles);

% check parameter validity and return
uiresume(handles.gui_est_validateMVAR);

function cmdHelp_Callback(hObject, eventdata, handles)
% generate help text
doc('est_validateMVAR');

% --- Executes when gui_est_validateMVAR is resized.
function gui_est_validateMVAR_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to gui_est_validateMVAR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
