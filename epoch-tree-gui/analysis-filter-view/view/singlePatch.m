function singlePatch(epochTree, fig, doInit, params)
% based on singleEpoch
% Show info about one Epoch at at time, under given EpochTree

% benjamin.heasly@gmail.com
%   2 Feb. 2009
% modified by ZY when select the patch number
import riekesuite.guitools.*;

if ~nargin && ~isobject(epochTree)
    disp(sprintf('%s needs an EpochTree', mfilename));
    return
end
if nargin < 2
    disp(sprintf('%s needs a figure', mfilename));
    return
end
if (~strcmp(epochTree.parent().splitKey(),'protocolSettings(imagePatchIndex)'))
    disp('Please select the right node')
    return 
end
if nargin < 3
    doInit = false;
end



% init when told, or when this is not the 'current function' of the figure
figData = get(fig, 'UserData');
if doInit || ~isfield(figData, 'currentFunction') || ~strcmp(figData.currentFunction, mfilename)
    % create new panel slider, info table
    delete(get(fig, 'Children'));
    figData.currentFunction = mfilename;
    x = .02;
    w = .96;
    %{  
    noData = {...
        'number', []; ...
        'date', []; ...
        'isSelected', []; ...
        'includeInAnalysis', []; ...
        'tags', []};
    figData.infoTable = uitable('Parent', fig', ...
        'Units', 'normalized', ...
        'Position', [x .8, w, .18], ...
        'Data', noData, ...
        'RowName', {}, ...
        'ColumnName', [], ...
        'ColumnEditable', false);
    %}
    figData.imageLoc = '~/Documents/MATLAB/subunitModel_NaturalImages';
    figData.panel_pic = uipanel('Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [x .8 .18 .18]); % for displaying the image patch
    figData.button = uicontrol('Parent',fig,'Units','normalized',...
        'Position',[0.22 0.8 0.76 0.18],'Style','pushbutton','String','SelectImage',...
        'Callback',{@selectImage,figData});
    figData.panel = uipanel('Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [x .05 w .75]);
    figData.next = uicontrol('Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [x 0 w .05], ...
        'Style', 'slider', ...
        'Callback', {@plotNextCond, figData});
    set(fig, 'UserData', figData, 'ResizeFcn', {@canvasResizeFcn, figData});
    canvasResizeFcn(figData.panel, [], figData);
end

% prepare for displaying for different recording conditions:
cond = length(epochTree.children(1).children());
% get all Epochs under the given tree
%el = getTreeEpochs(epochTree);
%n = el.length;
if cond > 1
    set(figData.next, ...
        'Enable', 'on', ...
        'UserData', epochTree, ...
        'Min',  1, ...
        'Max',  cond+eps, ...
        'SliderStep', [1/cond, 1/cond], ...
        'Value', 1);
    plotNextCond(figData.next, [], figData);
else
    delete(get(figData.panel, 'Children'));
    set(figData.next, 'Enable', 'off');
end
end


function plotNextCond(slider, event, figData)
% slider control picks one Epoch
 ind = round(get(slider, 'Value'));
 el = get(slider, 'UserData');
 img_ds = el.children(1).children(ind); 
 disc_ds = el.children(2).children(ind);
 set(figData.panel, 'Title', 'getting response data...');
 drawnow;

% Epoch responses in subplots
sp = subplot(2,1,1,'Parent',figData.panel);
cla(sp);
TempRespData = riekesuite.getResponseMatrix(img_ds.epochList, 'Amp1');


TempEpochData = riekesuite.getResponseMatrix(CurrentLeaf.epochList, params.Amp);
temp = ep.responses.keySet;
temp.remove('Optometer');
resps = temp.toArray;
nResp = length(resps);
for ii = 1:nResp
    sp = subplot(nResp, 1, ii, 'Parent', figData.panel);
    cla(sp);

    respData = riekesuite.getResponseVector(ep, resps(ii));

    if ischar(respData)
        % dont' break when lazyLoads disabled
        ylabel(sp, respData);
    else
        line(1:length(respData), respData, 'Parent', sp);
        ylabel(sp, resps(ii));
    end
end

set(figData.panel, 'Title', 'responses:');
drawnow;
end

function selectImage(button, event, figData)
end

function canvasResizeFcn(panel, event, figData)
% set infoTable column widths proportionally
oldUnits = get(figData.infoTable, 'Units');
set(figData.infoTable, 'Units', 'pixels');
tablePos = get(figData.infoTable, 'Position');
set(figData.infoTable, 'Units', oldUnits);

set(figData.infoTable, 'ColumnWidth', {.2*tablePos(3), .65*tablePos(3)});
end
