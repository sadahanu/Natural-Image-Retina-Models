classdef epochTreeGUI < handle
    
    properties
        epochTree;
        showEpochs = true;
        figure;
        isBusy = false;
    end
    
    properties(Hidden = true)
        title = 'Epoch Tree GUI';
        busyTitle = 'Epoch Tree GUI (busy...)';
        
        fontSize = 12;
        xDivLeft = .25;
        xDivRight = .1;
        yDiv = .3;
        
        treeBrowser = struct();
        databaseInteraction = struct();
        plottingCanvas = struct();
        analysisTools = struct();
        miscControls = struct();
    end
    
    methods
        function self = epochTreeGUI(epochTree, varargin)
            if nargin < 1
                return
            end
            
            self.epochTree = epochTree;
            

            % init flags
            if nargin > 1
                if any(strcmp(varargin, 'noEpochs'))
                    self.showEpochs = false;
                end
            end
            
            self.buildUIComponents;
            self.isBusy = true;
            self.initAnalysisTools;
            self.initTreeBrowser;
            self.isBusy = false;
        end
        
        function delete(self)
            % attempt to close figure
            if ~isempty(self.figure) ...
                    && ishandle(self.figure) ...
                    && strcmp(get(self.figure, 'BeingDeleted'), 'off')
                close(self.figure);
            end
        end
        
        %%% top-level
        
        function buildUIComponents(self)
            % clean out the figure
            if ~isempty(self.figure) && ishandle(self.figure)
                delete(self.treeBrowser.panel);
                delete(self.databaseInteraction.panel);
                delete(self.plottingCanvas.panel);
                delete(self.analysisTools.panel);
                delete(self.miscControls.panel);
                clf(self.figure);
            else
                self.figure = figure;
            end
            
            set(self.figure, ...
                'Name',         self.title, ...
                'NumberTitle',  'off', ...
                'ToolBar',      'none', ...
                'Units',      'normalized', ...
                'OuterPosition', [.1 1 .6 .6], ...
                'DeleteFcn',    {@epochTreeGUI.figureDeleteCallback, self}, ...
                'ResizeFcn',    {@epochTreeGUI.figureResizeCallback, self}, ...
                'HandleVisibility', 'on');
            
            % new panels and widgets
            self.buildTreeBrowserUI();
            self.buildDatabaseInteractionUI();
            self.buildPlottingCanvasUI();
            self.buildAnalysisToolsUI();
            self.buildMiscControlsUI();
        end
        
        function rebuildUIComponents(self)
            % save existing graphical tree object
            graphTree = self.treeBrowser.graphTree;
            
            self.buildUIComponents;
            self.isBusy = true;
            
            % rewire existing graphicalTree to new axes
            self.treeBrowser.graphTree = graphTree;
            self.treeBrowser.graphTree.axes = self.treeBrowser.treeAxes;
            self.refreshBrowserNodes;
            
            self.initAnalysisTools;
            self.isBusy = false;
        end
        
        function set.isBusy(self, isBusy)
            self.isBusy = isBusy;
            if isBusy
                set(self.figure, 'Name', self.busyTitle);
            else
                set(self.figure, 'Name', self.title);
            end
            drawnow;
        end
        
        function set.xDivLeft(self, xDivLeft)
            self.xDivLeft = xDivLeft;
            self.rebuildUIComponents;
        end
        
        function set.xDivRight(self, xDivRight)
            self.xDivRight = xDivRight;
            self.rebuildUIComponents;
        end
        
        function set.yDiv(self, yDiv)
            self.yDiv = yDiv;
            self.rebuildUIComponents;
        end
        
        function set.fontSize(self, fontSize)
            self.fontSize = fontSize;
            self.rebuildUIComponents;
        end
        
        
        %%% tree browser
        
        function buildTreeBrowserUI(self)
            % main tree browser panel and axes
            treeBrowser.panel = uipanel( ...
                ...'Title',    'tree browser', ...
                'Parent',   self.figure, ...
                'HandleVisibility', 'off', ...
                'Units',    'normalized', ...
                'Position', [0 self.yDiv self.xDivLeft 1-self.yDiv]);
            treeBrowser.treeAxes = axes( ...
                'Parent',	treeBrowser.panel, ...
                'HandleVisibility', 'on', ...
                'Units',    'normalized', ...
                'Position', [0 .05 1 .9]);
            
            [keySummary, shortKeys] = getEpochTreeSplitString(self.epochTree);
            treeBrowser.splitKeys = uicontrol( ...
                'Parent',   treeBrowser.panel, ...
                'Style',    'popupmenu', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   shortKeys, ...
                'HorizontalAlignment', 'left', ...
                'Position', [0 .95 1 .05], ...
                'TooltipString', 'EpochTree split keys');
            treeBrowser.invertFlags = uicontrol( ...
                'Parent',   treeBrowser.panel, ...
                'Callback', @(obj, event)self.invertFlags, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'invert flags', ...
                'HorizontalAlignment', 'left', ...
                'Position', [0 0 .4 .05], ...
                'TooltipString', 'invert all flags from selected node');
            treeBrowser.pan = uicontrol( ...
                'Parent',   treeBrowser.panel, ...
                'Callback', @(obj, event)self.panTreeBrowserCallback(obj), ...
                'Style',    'togglebutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'pan', ...
                'HorizontalAlignment', 'left', ...
                'Position', [.5 0 .2 .05], ...
                'TooltipString', 'activate axes grab-and-drag mode');
            treeBrowser.refresh = uicontrol( ...
                'Parent',   treeBrowser.panel, ...
                'Callback', @(obj, event)self.refreshTreeBrowserCallback, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'refresh', ...
                'HorizontalAlignment', 'left', ...
                'Position', [.8 0 .2 .05], ...
                'TooltipString', 're-read EpochTree data');
            self.treeBrowser = treeBrowser;
        end
        
        function initTreeBrowser(self)
            if isfield(self.treeBrowser, 'graphTree') && isobject(self.treeBrowser.graphTree)
                delete(self.treeBrowser.graphTree);
            end
            
            % new graphicalTree object
            graphTree = graphicalTree(self.treeBrowser.treeAxes, 'EpochTree');
            graphTree.nodesSelectedFcn = {@epochTreeGUI.refreshUIForNodeSelection, self};
            graphTree.nodeBecameCheckedFcn = {@epochTreeGUI.nodeDataTakesFlag};
            graphTree.draw;
            self.treeBrowser.graphTree = graphTree;
            
            % populate grahical tree with EpochTree and Epoch objects
            if ~isempty(self.epochTree) %GWS, only check I need here?
                self.marryEpochNodesToWidgets(self.epochTree, graphTree.trunk);
            end
            
            self.epochTree.custom.put('display', java.util.HashMap());
            self.epochTree.custom.get('display').put('name', 'EpochTree');
            self.epochTree.custom.get('display').put('color', [0 0 0]);
            self.epochTree.custom.get('display').put('backgroundColor', 'none');
            self.refreshBrowserNodes;
        end
        
        function marryEpochNodesToWidgets(self, epochNode, browserNode)
            browserNode.userData = epochNode;
            
            % node appearance
            if isempty(epochNode.custom.get('isSelected'))
                epochNode.custom.put('isSelected',false);
            end
            
            if isobject(epochNode.splitValue)
                display.name = epochNode.splitValue.toString();
            else
                display.name = num2str(epochNode.splitValue);
            end
            display.color = [0 0 0];
            display.backgroundColor = 'none';
            
            % and optional alternate appearance
            if epochNode.custom.containsKey('display') && epochNode.custom.containsKey('alt')
                display.alt = epochNode.custom.display.alt;
            else
                display.alt.name = [];
                display.alt.color = [];
                display.alt.backgroundColor = [];
            end
            epochNode.custom.put('display', riekesuite.util.toJavaMap(display));
            
            % other nodes may be Epoch capsules
            epochNode.custom.put('isCapsule', false);
            
            if epochNode.isLeaf && self.showEpochs
                % base case: special nodes with Epoch data
                %import auimodel.*;
                epochs = epochNode.epochList.elements;
                for ii = 1:length(epochs)
                    ep = epochs(ii);
                    if isempty(ep.isSelected)
                        ep.isSelected = true;
                    end
                    
                    epochWidget = browserNode.tree.newNode(browserNode);
                    epochWidget.userData = ep;
                    
                    epochWidget.isChecked = ep.isSelected;
                    epochWidget.name = sprintf('%3d: %d-%02d-%02d %d:%d:%d', ii, ep.startDate);
                    epochWidget.textColor = [0 0 0];
                    epochWidget.textBackgroundColor = [1 .85 .85];
                end
                
            else
                % recur: new browserNode for each child node
                if ~isempty(epochNode.children) && epochNode.children.length > 0
                    children = epochNode.children.elements;
                    for ii = 1:length(children)
                        childWidget = browserNode.tree.newNode(browserNode);
                        self.marryEpochNodesToWidgets(children(ii), childWidget);
                    end
                end
            end
        end
        
        function refreshBrowserNodes(self, startNode)
            if nargin < 2
                startNode = self.treeBrowser.graphTree.trunk;
            end
            
            self.isBusy = true;
            self.readEpochTreeNodeDisplayState(startNode);
            self.treeBrowser.graphTree.trunk.countCheckedDescendants;
            self.treeBrowser.graphTree.draw;
            self.isBusy = false;
        end
        
        function readEpochTreeNodeDisplayState(self, browserNode)
            nodeData = browserNode.userData;
            if ~isempty(nodeData)
                
                if isa(nodeData, 'edu.washington.rieke.jauimodel.AuiEpoch')
                    % only read selection for Epoch
                    browserNode.isChecked = nodeData.isSelected;
                    
                elseif isa(nodeData, 'edu.washington.rieke.jauimodel.AuiEpochTree')
                    % read selection and apperance for EpochTree
                    
                    if nodeData.custom.get('isCapsule');
                        % reconcile capsule node with encapsulated Epoch
                        epoch = nodeData.epochList.firstValue;
                        nodeData.custom.isSelected = epoch.isSelected;
                        browserNode.isChecked = epoch.isSelected;
                    else
                        browserNode.isChecked =  nodeData.custom.get('isSelected');
                    end
                    
                    % name
                    if isempty(nodeData.custom.get('display').get('alt')) || nodeData.custom.get('display').get('alt').get('name').isEmpty
                        browserNode.name = nodeData.custom.get('display').get('name');
                        %browserNode
                        %pause;
                    else
                        browserNode.name = nodeData.custom.get('display').get('alt').get('name');
                    end
                    
                    % text color
                    if isempty(nodeData.custom.get('display').get('alt')) || nodeData.custom.get('display').get('alt').get('color').isEmpty
                        browserNode.textColor = nodeData.custom.get('display').get('color');
                    else
                        browserNode.textColor = nodeData.custom.get('display').get('alt').get('color');
                    end
                    
                    % background color
                    if isempty(nodeData.custom.get('display').get('alt')) || nodeData.custom.get('display').get('alt').get('backgroundColor').isEmpty
                        browserNode.textBackgroundColor = nodeData.custom.get('display').get('backgroundColor');
                    else
                        browserNode.textBackgroundColor = nodeData.custom.get('display').get('alt').get('backgroundColor');
                    end
                    %keyboard;
                end
            end
            
            % recur: set child selections
            for ii = 1:browserNode.numChildren
                self.readEpochTreeNodeDisplayState(browserNode.getChild(ii));
            end
        end
        
        function invertFlags(self)
            % invoke filter functions directly, from selected nodes.
            if (self.treeBrowser.graphTree.selectionSize == 1)
                nodes = self.getSelectedEpochTreeNodes;
                self.isBusy = true;
                if exist('invertTreeSelections', 'file')
                    invertTreeSelections(nodes{1});
                end
                
                if exist('invertEpochSelections', 'file')
                    invertEpochSelections(nodes{1});
                end
                self.refreshBrowserNodes;
                self.isBusy = false;
            end
        end
        
        function panTreeBrowserCallback(self, widget)
            p = pan(self.figure);
            if get(widget, 'Value')
                % STUPID, axes will not pan when HandleVisibility=off
                %   even for the pan button in builtin figure toolbar
                set(self.treeBrowser.treeAxes, 'HandleVisibility', 'on');
                set(p, 'Enable', 'on');
                setAllowAxesPan(p, self.treeBrowser.treeAxes, true);
            else
                set(self.treeBrowser.treeAxes, 'HandleVisibility', 'off');
                set(p, 'Enable', 'off');
                setAllowAxesPan(p, self.treeBrowser.treeAxes, false);
            end
        end
        
        function refreshTreeBrowserCallback(self)
            allEpochs = getTreeEpochs(self.epochTree);
            allEpochs.refresh;
            if isfield(self.treeBrowser, 'graphTree')
                self.refreshBrowserNodes;
            end
        end
        
        function showSplitKeyStringForSelectedNode(self);
            if (self.treeBrowser.graphTree.selectionSize == 1)
                [nodes, nodeKeys] = self.treeBrowser.graphTree.getSelectedNodes;
                % split strings stored in a popup menu
                %   jump to key for selected tree depth
                numKeys = length(get(self.treeBrowser.splitKeys, 'String'));
                keyIndex = max(min(numKeys, nodes{1}.depth), 1);
                set(self.treeBrowser.splitKeys, 'Value', keyIndex);
            end
        end
        
        function epochTreeNodes = getSelectedEpochTreeNodes(self) %capsule stuff
            [nodes, nodeKeys] = self.treeBrowser.graphTree.getSelectedNodes;
            epochTreeNodes = cell(size(nodes));
            
            for ii = 1:length(epochTreeNodes)
                nodeData = nodes{ii}.userData;
                
                if isa(nodeData, 'edu.washington.rieke.jauimodel.AuiEpochTree')
                    % easy, return the EpochTree
                    epochTreeNodes{ii} = nodeData;
                    
                elseif isa(nodeData, 'edu.washington.rieke.jauimodel.AuiEpoch')
                    % encapsulate the Epoch, cache the capsule
                    disp('selecting a capsule')
                    capsuleNode = self.encapsulateEpochForBrowserNode(nodes{ii});
                    nodes{ii}.userData = capsuleNode;
                    epochTreeNodes{ii} = capsuleNode;
                end
            end
        end
        
        function capsuleNode = encapsulateEpochForBrowserNode(self, browserNode)
            % browserNode.userData is an auimodel.Epoch
            %   encapsulate the Epoch in an EpochTree, replace userData
            %need to fix this
            epoch = browserNode.userData;
            listFactory = edu.washington.rieke.Analysis.getEpochListFactory();
            treeFactory = edu.washington.rieke.Analysis.getEpochTreeFactory();
            
            epochList = listFactory.create();
            epochList.append(epoch);
            %epochList.populateStreamNames;
            
            capsuleNode = treeFactory.create(epochList, {'protocolSettings.acquirinoEpochNumber'}); %temp hack
            capsuleNode.custom.put('isCapsule', true);
            capsuleNode.custom.put('isSelected', epoch.isSelected);
            
            % node appearance should be customizable
            display.name = browserNode.name;
            display.color = browserNode.textColor;
            display.backgroundColor = browserNode.textBackgroundColor;
            display.alt.name = [];
            display.alt.color = [];
            display.alt.backgroundColor = [];
            capsuleNode.custom.put('display', riekesuite.util.toJavaMap(display));
            
            % wire capsule node to tree, but not reciprocally
            browserParent = self.treeBrowser.graphTree.nodeList.getValue(browserNode.parentKey);
            %capsuleNode.parent = browserParent.userData; %can't do this now!
        end
        
        %%% database interaction
        
        function buildDatabaseInteractionUI(self)
            % main database interaction panel:
            databaseInteraction.panel = uipanel( ...
                ...'Title',    'db interaction', ...
                'Parent',   self.figure, ...
                'HandleVisibility', 'off', ...
                'Units',    'normalized', ...
                'Position', [0 0 self.xDivLeft self.yDiv]);
            
            % input and view tags
            databaseInteraction.refreshTag = uicontrol( ...
                'Parent',   databaseInteraction.panel, ...
                'Callback', @(obj, event)self.refreshEpochTags, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'Tags:', ...
                'Position', [0 .7 .25 .2], ...
                'HorizontalAlignment', 'left', ...
                'TooltipString', 'refresh Epoch tags');
            databaseInteraction.existingTags = uicontrol( ...
                'Parent',   databaseInteraction.panel, ...
                'Callback', @(obj, event)self.inputExistingTag, ...
                'Style',    'popupmenu', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   {' '}, ...
                'Position', [.25 .8 .75 .2], ...
                'HorizontalAlignment', 'left', ...
                'TooltipString', 'tags common to selected Epochs');
            databaseInteraction.inputTag = uicontrol( ...
                'Parent',   databaseInteraction.panel, ...
                'BackgroundColor', [1 1 1], ...
                'Units', 'normalized', ...
                'Position', [.25 .6 .75 .2], ...
                'HorizontalAlignment', 'left', ...
                'String', '', ...
                'Style', 'edit', ...
                'TooltipString', 'input a keyword tag');
            
            % for flagged Epochs
            databaseInteraction.addTagToFlagged = uicontrol( ...
                'Parent',   databaseInteraction.panel, ...
                'Callback', @(obj, event)self.addTagToFlagged, ...
                'Units', 'normalized', ...
                'Position', [0 .2 .33 .2], ...
                'HorizontalAlignment', 'left', ...
                'String', '+ flagged', ...
                'Style', 'pushbutton', ...
                'TooltipString', 'add tag to flagged Epochs');
            databaseInteraction.removeTagFromFlagged = uicontrol( ...
                'Parent',   databaseInteraction.panel, ...
                'Callback', @(obj, event)self.removeTagFromFlagged, ...
                'Units', 'normalized', ...
                'Position', [.33 .2 .33 .2], ...
                'HorizontalAlignment', 'left', ...
                'String', '- flagged', ...
                'Style', 'pushbutton', ...
                'TooltipString', 'remove tag from flagged Epochs');
            databaseInteraction.setFlagsForTag = uicontrol( ...
                'Parent',   databaseInteraction.panel, ...
                'Callback', @(obj, event)self.setFlagsForTag, ...
                'Units', 'normalized', ...
                'Position', [.67 .2 .33 .2], ...
                'HorizontalAlignment', 'left', ...
                'String', 'set flags', ...
                'Style', 'pushbutton', ...
                'TooltipString', 'flag only Epochs with tag');
            
            % for selected Epochs
            databaseInteraction.addTagToSelected = uicontrol( ...
                'Parent',   databaseInteraction.panel, ...
                'Callback', @(obj, event)self.addTagToSelected, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   '+ selected', ...
                'Position', [0 .4 .33 .2], ...
                'HorizontalAlignment', 'left', ...
                'TooltipString', 'add tag to selected Epochs');
            databaseInteraction.removeTagFromSelected = uicontrol( ...
                'Parent',   databaseInteraction.panel, ...
                'Callback', @(obj, event)self.removeTagFromSelected, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   '- selected', ...
                'Position', [.33 .4 .33 .2], ...
                'HorizontalAlignment', 'left', ...
                'TooltipString', 'remove tag from selected Epochs');
            databaseInteraction.separator = uipanel( ...
                'Parent',   databaseInteraction.panel, ...
                'HandleVisibility', 'off', ...
                'Units', 'normalized', ...
                'Position', [0 0 1 .2], ...
                'BorderType', 'none', ...
                'BackgroundColor', [1 1 1]*.33, ...
                'BorderWidth', 1);
            databaseInteraction.includeSelected = uicontrol( ...
                'Parent',   databaseInteraction.panel, ...
                'Callback', @(obj, event)self.includeExcludeSelected(true), ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'include selected', ...
                'Position', [0 0 .5 .2], ...
                'HorizontalAlignment', 'left', ...
                'TooltipString', 'include selected Epochs in analysis');
            databaseInteraction.excludeSelected = uicontrol( ...
                'Parent',   databaseInteraction.panel, ...
                'Callback', @(obj, event)self.includeExcludeSelected(false), ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'exclude selected', ...
                'Position', [.5 0 .5 .2], ...
                'HorizontalAlignment', 'left', ...
                'TooltipString', 'exclude selected Epochs from analysis');
            self.databaseInteraction = databaseInteraction;
        end
        
        function setFlagsForTag(self)
            gui.isBusy = true;
            tag = get(self.databaseInteraction.inputTag, 'String');
            if ~isempty(tag)
                disp(sprintf('flagging Epochs with tag "%s"...', tag))
                el = getTreeEpochs(self.epochTree);
                %el.refresh;
                ec = el.toCell;
                flagCount = 0;
                for ii = 1:length(ec)
                    ep = ec{ii};
                    hasTag = any(strcmp(ep.keywords.elements, tag));
                    ep.isSelected = hasTag;
                    flagCount = flagCount + hasTag;
                end
                disp(sprintf('...%d Epochs are flagged', flagCount))
            end
            self.refreshBrowserNodes;
            self.reinvokeView;
            gui.isBusy = false;
        end
        
        function addTagToFlagged(self)
            gui.isBusy = true;
            tag = get(self.databaseInteraction.inputTag, 'String');
            if ~isempty(tag)
                el = getTreeEpochs(self.epochTree, true);
                %el.refresh;
                disp(sprintf('adding tag "%s" to %d Epochs', tag, el.length))
                el.addKeywordTag(tag);
                self.populateTagMenuWithTags;
                self.reinvokeView;
            end
            self.isBusy = false;
        end
        
        function removeTagFromFlagged(self)
            self.isBusy = true;
            tag = get(self.databaseInteraction.inputTag, 'String');
            if ~isempty(tag)
                el = getTreeEpochs(self.epochTree, true);
                %el.refresh;
                disp(sprintf('removing tag "%s" from %d Epochs', tag, el.length))
                el.removeKeywordTag(tag);
                self.populateTagMenuWithTags;
                self.reinvokeView;
            end
            self.isBusy = false;
        end
        
        function addTagToSelected(self)
            self.isBusy = true;
            tag = get(self.databaseInteraction.inputTag, 'String');
            if ~isempty(tag)
                nodes = self.getSelectedEpochTreeNodes;
                el = getUniqueEpochsFromNodes(nodes);
                %el.refresh;
                disp(sprintf('adding tag "%s" to %d Epochs', tag, el.length))
                el.addKeywordTag(tag);
                self.populateTagMenuWithTags;
                self.reinvokeView;
            end
            self.isBusy = false;
        end
        
        function removeTagFromSelected(self)
            self.isBusy = true;
            tag = get(self.databaseInteraction.inputTag, 'String');
            if ~isempty(tag)
                nodes = self.getSelectedEpochTreeNodes;
                el = getUniqueEpochsFromNodes(nodes);
                %el.refresh;
                disp(sprintf('removing tag "%s" from %d Epochs', tag, el.length))
                el.removeKeywordTag(tag);
                self.populateTagMenuWithTags;
                self.reinvokeView;
            end
            self.isBusy = false;
        end
        
        function includeExcludeSelected(self, isIncluded)
            self.isBusy = true;
            nodes = self.getSelectedEpochTreeNodes;
            el = getUniqueEpochsFromNodes(nodes);
            %el.refresh;
            %elements = el.toCell;
            disp(sprintf('includeInAnalysis = %d for %d Epochs', isIncluded, el.length))
            for ii = 1:el.length
                ep = el.valueByIndex(ii);
                ep.includeInAnalysis = isIncluded;
            end
            self.reinvokeView;
            self.isBusy = false;
        end
        
        function inputExistingTag(self)
            tags = get(self.databaseInteraction.existingTags, 'String');
            if ~isempty(tags)
                selection = get(self.databaseInteraction.existingTags, 'Value');
                set(self.databaseInteraction.inputTag, 'String', tags{selection});
            end
        end
        
        function refreshEpochTags(self)
            self.isBusy = true;
            el = getTreeEpochs(self.epochTree);
            %el.refresh;
            self.populateTagMenuWithTags;
            self.isBusy = false;
        end
        
        function cellArray = javaArray2CellArray(self, javaArray)
            cellArray = cell(length(javaArray), 1);
            for i = 1 : length(javaArray)
                cellArray{i} = javaArray(i);
            end
        end
        
        function populateTagMenuWithTags(self)
            self.isBusy = true;
            tags = self.getSelectedEpochsTagIntersection;
            tags = self.javaArray2CellArray(tags);
            if isempty(tags)
                set(self.databaseInteraction.existingTags, ...
                    'String',   {' '}, ...
                    'Enable',   'inactive', ...
                    'Value',    1);
            else
                set(self.databaseInteraction.existingTags, ...
                    'String',   tags, ...
                    'Enable',	'on', ...
                    'Value',    1);
            end
            self.isBusy = false;
        end
        
        function tags = getSelectedEpochsTagIntersection(self)
            nodes = self.getSelectedEpochTreeNodes;
            el = getUniqueEpochsFromNodes(nodes);
            
            tags = java.util.HashSet(el.firstValue.keywords);
            epochs = el.elements;
            
            if ~isempty(epochs)
                ep = epochs(1);
                tags.retainAll(ep.keywords);
            end
            
            tags = tags.toArray();
        end
        
        %%% plotting canvas
        
        function buildPlottingCanvasUI(self)
            % big panel for plotting or custom tools
            self.plottingCanvas.panel = uipanel( ...
                ...'Title',    'plotting canvas', ...
                'Parent',   self.figure, ...
                'HandleVisibility', 'on', ...
                'Units',    'normalized', ...
                'Position', [self.xDivLeft self.yDiv 1-self.xDivLeft 1-self.yDiv]);
        end
        
        %%% analysis tools
        
        function buildAnalysisToolsUI(self)
            % main analysis tools panel
            analysisTools.panel = uipanel( ...
                ...'Title',    'analysis tools', ...
                'HandleVisibility', 'off', ...
                'Parent',   self.figure, ...
                'Units',    'normalized', ...
                'Position', [self.xDivLeft 0 1-self.xDivLeft-self.xDivRight self.yDiv]);
            
            % mutually exclusive buttons
            analysisTools.afvGroup = uibuttongroup( ...
                'Parent',   analysisTools.panel, ...
                'SelectionChangeFcn', @(obj, event)self.afvGroupCallback(event), ...
                'Units',    'normalized', ...
                'HandleVisibility', 'off', ...
                'Position', [.1 .8 .8 .15]);
            analysisTools.analysis = uicontrol( ...
                'Parent',   analysisTools.afvGroup, ...
                'Style',    'togglebutton', ...
                'Units',    'normalized', ...
                'UserData', struct('funcIndex',1,'paramIndex',1), ...
                'FontSize', self.fontSize, ...
                'String',   'analysis', ...
                'Position', [0 0 .25 1], ...
                'TooltipString', '"analysis" functions for running calculations');
            analysisTools.filter = uicontrol( ...
                'Parent',   analysisTools.afvGroup, ...
                'Style',    'togglebutton', ...
                'Units',    'normalized', ...
                'UserData', struct('funcIndex',1,'paramIndex',1), ...
                'FontSize', self.fontSize, ...
                'String',   'filter', ...
                'Position', [.25 0 .25 1], ...
                'TooltipString', '"filter" functions for flagging EpochTree nodes and Epochs');
            analysisTools.view = uicontrol( ...
                'Parent',   analysisTools.afvGroup, ...
                'Style',    'togglebutton', ...
                'Units',    'normalized', ...
                'UserData', struct('funcIndex',1,'paramIndex',1), ...
                'FontSize', self.fontSize, ...
                'String',   'view', ...
                'Position', [.5 0 .25 1], ...
                'TooltipString', '"view" functions for visualizing data and results');
            analysisTools.noUpdate = uicontrol( ...
                'Parent',   analysisTools.afvGroup, ...
                'Style',    'togglebutton', ...
                'Units',    'normalized', ...
                'UserData', struct('funcIndex',1,'paramIndex',1), ...
                'FontSize', self.fontSize, ...
                'String',   'none', ...
                'Position', [.75 0 .25 1], ...
                'TooltipString', 'disable functions');
            
            analysisTools.functionMenu = uicontrol( ...
                'Parent',   analysisTools.panel, ...
                'Callback', @(obj, event)self.choseAnalysisFunction, ...
                'Style',    'popupmenu', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   {'pick a tool'}, ...
                'Position', [.05 .55 .4 .2], ...
                'TooltipString', 'choose a function to invoke');
            analysisTools.paramsMenu = uicontrol( ...
                'Parent',   analysisTools.panel, ...
                'Callback', @(obj, event)self.choseParamSet, ...
                'Style',    'popupmenu', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   {'---pick a params set---'}, ...
                'Position', [.05 .4 .4 .2], ...
                'TooltipString', 'choose a parameter set');
            % mutually exclusive buttons
            analysisTools.runTypeGroup = uibuttongroup( ...
                'Parent',   analysisTools.panel, ...
                'Units',    'normalized', ...
                'HandleVisibility', 'off', ...
                'Position', [.05 .25 .4 .2]);
            analysisTools.treeLevelButton = uicontrol( ...
                'Parent',   analysisTools.runTypeGroup, ...
                'Style',    'radiobutton', ...
                'Units',    'normalized', ...
                'UserData', struct('funcIndex',1,'paramIndex',1), ...
                'FontSize', self.fontSize, ...
                'String',   'selected level', ...
                'Value',    1, ...
                'Position', [0 0 .5 1], ...
                'TooltipString', 'run calculation on selected tree level');
            analysisTools.selectionButton = uicontrol( ...
                'Parent',   analysisTools.runTypeGroup, ...
                'Style',    'radiobutton', ...
                'Units',    'normalized', ...
                'UserData', struct('funcIndex',1,'paramIndex',1), ...
                'FontSize', self.fontSize, ...
                'String',   'selected nodes', ...
                'Value',    0, ...
                'Position', [.5 0 .5 1], ...
                'TooltipString', 'run calculation on selected nodes');
            analysisTools.saveParamsTool = uicontrol( ...
                'Parent',   analysisTools.panel, ...
                'Callback', @(obj, event)self.saveParams, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'save', ...
                'Position', [.05 .05 .2 .2], ...
                'TooltipString', 'save the chosen function and params');
            analysisTools.applyTool = uicontrol( ...
                'Parent',   analysisTools.panel, ...
                'Callback', @(obj, event)self.invokeAnalysisTool, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'apply', ...
                'Position', [.25 .05 .2 .2], ...
                'TooltipString', 'invoke the chosen function');
            analysisTools.paramsTable = uitable( ...
                'Parent',   analysisTools.panel, ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize - 1, ...
                'Position', [.45 .05 .5 .7], ...
                'ColumnName', {'Param', 'Value'}, ...
                'ColumnEditable', logical([0 1]), ...
                'RowName', [], ...
                'Data', cell(4,2), ...
                'CellSelectionCallback', @(obj, event)self.paramsTable_cellSelection_callback(event), ...
                'CellEditCallback', @(obj, event)self.paramsTable_cellEdit_callback(event), ...
                'TooltipString', 'table of parameters');
            %filter panel stuff
            analysisTools.filt = TreeSearchQuery;
            analysisTools.filtTable = uitable( ...
                'Parent',   analysisTools.panel, ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize - 1, ...
                'Position', [.05 .28 .9 .5], ...
                'ColumnName', {'Param', 'Operator', 'Value'}, ...
                'ColumnEditable', logical([1 1 1]), ...
                'Data', cell(4,3), ...
                'CellEditCallback', @(obj, event)self.filtTable_cellEdit_callback(event), ...
                'TooltipString', 'table for filter contruction');
            analysisTools.loadFilterTool = uicontrol( ...
                'Parent',   analysisTools.panel, ...
                'Callback', @(obj, event)self.loadFilter, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'load', ...
                'Position', [.45 .05 .2 .2], ...
                'TooltipString', 'load a filter');
            analysisTools.filtPatternEdit = uicontrol( ...
                'Parent',   analysisTools.panel, ...
                'Callback', @(obj, event)self.filtPatternEdit_callBack, ...
                'Style',    'edit', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize - 1, ...
                'Position', [.65 .05 .3 .2], ...
                'TooltipString', 'filter pattern expression');
            
            
            
            %do something so that it shows up before resize
            
            self.analysisTools = analysisTools;
        end
        
        function initAnalysisTools(self)
            global ANALYSIS_FILTER_VIEW_FOLDER
            if isempty(ANALYSIS_FILTER_VIEW_FOLDER)
                disp(sprintf('You should define the global variable ''ANALYSIS_FILTER_VIEW_FOLDER'''))
            end
            
            self.analysisTools.selectedFunction = {};
            self.analysisTools.lastUsedFunction = {};
            set(self.analysisTools.noUpdate, 'Value', 1);
            %self.populateFunctionMenuWithFunctions(get(self.analysisTools.view, 'String'));
            set(self.analysisTools.functionMenu, 'Enable', 'off');
            set(self.analysisTools.applyTool, 'Enable', 'off');
            set(self.analysisTools.saveParamsTool, 'Enable', 'off');
            set(self.analysisTools.paramsMenu, 'Enable', 'off');
            set(self.analysisTools.runTypeGroup, 'Visible', 'off');
            set(self.analysisTools.paramsTable, 'Visible', 'off');
            set(self.analysisTools.filtTable, 'Visible', 'off');
            set(self.analysisTools.filtPatternEdit, 'Visible', 'off');
            set(self.analysisTools.loadFilterTool, 'Visible', 'off');
            
            self.initializeFiltTable;
        end
        
        function initializeFiltTable(self)
            M = makeDepthFirstSearchMap(self.epochTree);
            treeProps = [' ', M.keys];
            operators = {' ','==','>','<','>=','<=','~='};
            columnFormat = {treeProps, operators, 'char'};
            set(self.analysisTools.filtTable,'ColumnFormat',columnFormat);
            %set(self.analysisTools.filtPatternEdit,'String','');
            
            
            figure = self.figure;
            panelPos = get(figure,'Position');
            panelWidth = panelPos(3);
            
            %filtTable
            tablePos = get(self.analysisTools.filtTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(panelWidth*tableWidth*.23);
            col2W = round(panelWidth*tableWidth*.1);
            col3W = round(panelWidth*tableWidth*.23);
            set(self.analysisTools.filtTable,'ColumnWidth',{col1W, col2W, col3W});
        end
        
        function initializeParamsTable(self)
            figure = self.figure;
            panelPos = get(figure,'Position');
            panelWidth = panelPos(3);
            
            
            %paramsTable
            tablePos = get(self.analysisTools.paramsTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(panelWidth*tableWidth*.3); %param_table width is normalized
            col2W = round(panelWidth*tableWidth*.33);
            set(self.analysisTools.paramsTable,'ColumnWidth',{col1W, col2W});
        end
        
        
        function afvGroupCallback(self, event)
            % remember last function used
            Udata.funcIndex = get(self.analysisTools.functionMenu, 'Value');
            Udata.paramIndex = get(self.analysisTools.paramsMenu, 'Value');
            set(event.OldValue, 'UserData', Udata);
            
            subdir = get(event.NewValue, 'String');
            if strcmp(subdir, get(self.analysisTools.noUpdate, 'String'))
                % don't do much
                set(self.analysisTools.functionMenu, 'Visible', 'on');
                set(self.analysisTools.functionMenu, 'Enable', 'off');
                set(self.analysisTools.applyTool, 'Enable', 'off');
                set(self.analysisTools.saveParamsTool, 'Enable', 'off');
                set(self.analysisTools.paramsMenu, 'Visible', 'on');
                set(self.analysisTools.paramsMenu, 'Enable', 'off');
                set(self.analysisTools.runTypeGroup, 'Visible', 'off');
                set(self.analysisTools.paramsTable, 'Visible', 'off');
                set(self.analysisTools.filtTable, 'Visible', 'off');
                set(self.analysisTools.loadFilterTool, 'Visible', 'off');
                set(self.analysisTools.filtPatternEdit, 'Visible', 'off');
            elseif get(self.analysisTools.filter, 'Value')
                set(self.analysisTools.functionMenu, 'Visible', 'off');
                set(self.analysisTools.paramsMenu, 'Visible', 'off');
                set(self.analysisTools.paramsTable, 'Visible', 'off');
                set(self.analysisTools.filtTable, 'Visible', 'on');
                set(self.analysisTools.filtPatternEdit, 'Visible', 'on');
                set(self.analysisTools.applyTool, 'Enable', 'on');
                set(self.analysisTools.saveParamsTool, 'Enable', 'on');
                set(self.analysisTools.runTypeGroup, 'Visible', 'off');
                set(self.analysisTools.loadFilterTool, 'Visible', 'on');
                
                self.initializeFiltTable;
                
            else
                % populate function menu with selected function type,
                %   recall last function of this type used
                set(self.analysisTools.paramsTable, 'Visible', 'on');
                set(self.analysisTools.filtTable, 'Visible', 'off');
                set(self.analysisTools.filtPatternEdit, 'Visible', 'off');
                set(self.analysisTools.loadFilterTool, 'Visible', 'off');
                self.populateFunctionMenuWithFunctions(subdir);
                Udata = get(event.NewValue, 'UserData');
                set(self.analysisTools.functionMenu, ...
                    'Visible', 'on', ...
                    'Enable', 'on', ...
                    'Value', Udata.funcIndex);
                self.choseAnalysisFunction;
                set(self.analysisTools.paramsMenu, ...
                    'Visible', 'on', ...
                    'Enable', 'on', ...
                    'Value', Udata.paramIndex);
                %self.setParamsFromTable;
                self.choseParamSet;
                self.updateParamsTable;
                set(self.analysisTools.applyTool, 'Enable', 'on');
                set(self.analysisTools.saveParamsTool, 'Enable', 'on');
                if get(self.analysisTools.analysis, 'Value') %treeLevel menu only for analysis
                    set(self.analysisTools.runTypeGroup, 'Visible', 'on');
                else
                    set(self.analysisTools.runTypeGroup, 'Visible', 'off');
                end
                self.initializeParamsTable;
            end
        end
        
        function choseAnalysisFunction(self)
            functionNames = get(self.analysisTools.functionMenu, 'String');
            functionIndex = get(self.analysisTools.functionMenu, 'Value');
            if ~isempty(functionNames) && functionIndex > 1
                self.analysisTools.selectedFunction = str2func(functionNames{functionIndex});
                funcStr = functionNames{functionIndex};
                set(self.analysisTools.paramsMenu, 'Value',1);
                if get(self.analysisTools.view, 'Value')
                    self.populateParamsMenu('view',funcStr);
                elseif get(self.analysisTools.analysis, 'Value')
                    self.populateParamsMenu('analysis',funcStr);
                end
            end
            
            %if ~isfield(self.analysisTools,'selectedParams') || isempty(fieldnames(self.analysisTools.selectedParams))
            if functionIndex>1
                funcName = functionNames{functionIndex};
                paramNames = getFunctionParamNames(funcName);
                L = length(paramNames);
                self.analysisTools.selectedParams = struct;
                for i=1:L
                    self.analysisTools.selectedParams.(paramNames{i}) = [];
                end
            end
            %            keyboard;
            self.updateParamsTable;
        end
        
        function choseParamSet(self)
            global ANALYSIS_FILTER_VIEW_FOLDER
            paramsNames = get(self.analysisTools.paramsMenu, 'String');
            paramsIndex = get(self.analysisTools.paramsMenu, 'Value');
            functionNames = get(self.analysisTools.functionMenu, 'String');
            functionIndex = get(self.analysisTools.functionMenu, 'Value');
            if ~isempty(paramsNames) && paramsIndex > 1
                funcName = functionNames{functionIndex};
                paramName = paramsNames{paramsIndex};
                
                %set the params here by loading the mat files and copying
                %params to self.analysisTools.curParams
                if get(self.analysisTools.view, 'Value')
                    fullFile = [ANALYSIS_FILTER_VIEW_FOLDER '/view/saved_params/' funcName '_p_' paramName];
                elseif get(self.analysisTools.analysis, 'Value')
                    fullFile = [ANALYSIS_FILTER_VIEW_FOLDER '/analysis/saved_params/' funcName '_p_' paramName];
                end
                load(fullFile,'calc')
                self.analysisTools.selectedParams = calc.params;
            else
                self.analysisTools.selectedParams = struct;
            end
            self.updateParamsTable;
        end
        
        function displayCreationCommands(self,calc)
            funcName = func2str(calc.func);
            fnames = fieldnames(calc.params);
            
            disp(['disp([' '''running ''' '''' funcName ''''  ''' ...''' ']);']);
            for i=1:length(fnames)
                if isempty(calc.params.(fnames{i}))
                    disp(['params.' fnames{i} ' = [];']);
                elseif ischar(calc.params.(fnames{i}))
                    disp(['params.' fnames{i} ' = ' '''' num2str(calc.params.(fnames{i})) '''' ';']);
                elseif isnumeric(calc.params.(fnames{i})) && length(calc.params.(fnames{i})) > 1
                    disp(['params.' fnames{i} ' = [' num2str(calc.params.(fnames{i})) '];']);
                else
                    disp(['params.' fnames{i} ' = ' num2str(calc.params.(fnames{i})) ';']);
                end
            end
            disp(['calc.func = @' funcName ';']);
            disp('calc.params = params;');
            disp('% select nodes on which to run calculation ...');
            disp('% nodes = getTreeLevel(tree,level,[TreeSearchQuery object])');
            disp('% runTreeCalculation(nodes,calc)');
        end
        
        function displayFilterCreationCommands(self,filt)
            N = length(filt.fieldnames);
            s = '';
            for i=1:N
                if i>1
                    s = [s ','];
                end
                if ischar(filt.values{i})
                    s = [s '''' filt.fieldnames{i} '''' ',' '''' filt.operators{i} '''' ',' '''' filt.values{i} ''''];
                elseif isnumeric(filt.values{i})
                    s = [s '''' filt.fieldnames{i} '''' ',' '''' filt.operators{i} '''' ',' num2str(filt.values{i})];
                end
            end
            disp(['filt = TreeSearchQuery(' s ');']);
            disp(['filt.pattern = ' '''' filt.pattern '''' ';']);
            disp('%to run filter ...')
            disp('%runFilter(tree,filt.makeQueryString,[0,1] for deselect/select)');
        end
        
        function saveParams(self)
            global ANALYSIS_FILTER_VIEW_FOLDER
            if get(self.analysisTools.filter, 'Value')
                filt = self.analysisTools.filt;
                filtName = input('Filter Name: ', 's');
                fullName = [filtName '.mat'];
                save([ANALYSIS_FILTER_VIEW_FOLDER '/filter/saved_params/' fullName], 'filt');
                self.displayFilterCreationCommands(filt);
            else
                calc.func = self.analysisTools.selectedFunction;
                calc.params = self.analysisTools.selectedParams;
                funcName = func2str(self.analysisTools.selectedFunction);
                paramsName = input('Parameter Set Name: ', 's');
                fullName = [funcName '_p_' paramsName '.mat'];
                if get(self.analysisTools.view, 'Value')
                    save([ANALYSIS_FILTER_VIEW_FOLDER '/view/saved_params/' fullName], 'calc');
                elseif get(self.analysisTools.analysis, 'Value')
                    save([ANALYSIS_FILTER_VIEW_FOLDER '/analysis/saved_params/' fullName], 'calc');
                    self.displayCreationCommands(calc);
                end
            end
        end
        
        function loadFilter(self)
            global ANALYSIS_FILTER_VIEW_FOLDER
            [FileName,PathName] = uigetfile('*.mat','Load a Filter',[ANALYSIS_FILTER_VIEW_FOLDER '/filter/saved_params/']);
            load([PathName FileName]);
            if exist('filt','var') && strcmp(class(filt),'TreeSearchQuery')
                %disp('found filter');
                self.analysisTools.filt = filt;
                
                N = length(filt.fieldnames);
                D = get(self.analysisTools.filtTable,'Data');
                for i=1:N
                    D{i,1} = filt.fieldnames{i};
                    D{i,2} = filt.operators{i};
                    D{i,3} = num2str(filt.values{i});
                end
                set(self.analysisTools.filtTable,'Data',D);
                set(self.analysisTools.filtPatternEdit,'String',filt.pattern);
                
            end
        end
        
        
        function paramsTable_cellSelection_callback(self,eventData)
            if isempty(eventData.Indices), return; end
            rowSelected = eventData.Indices(1);
            colSelected = eventData.Indices(2);
            if colSelected == 1 %only if we select param name
                paramNames = fieldnames(self.analysisTools.selectedParams);
                paramValue = self.analysisTools.selectedParams.(paramNames{rowSelected});
                %set(self.handles('params_menu'),'value',rowSelected);
                disp(paramValue);
            end
        end
        
        function paramsTable_cellEdit_callback(self,eventData)
            if isempty(eventData.Indices), return; end
            rowEdited = eventData.Indices(1);
            paramNames  = fieldnames(self.analysisTools.selectedParams);
            
            entry = eventData.EditData;
            if isnumeric(str2num(entry)) && ~isempty(str2num(entry)); %#ok<ST2NM>
                Data = eval(entry);
            else
                Data = entry;
            end
            self.analysisTools.selectedParams.(paramNames{rowEdited}) = Data;
            
            self.updateParamsTable;
        end
        
        function filtTable_cellEdit_callback(self,eventData)
            newData = eventData.EditData;
            rowInd = eventData.Indices(1);
            colInd = eventData.Indices(2);
            D = get(self.analysisTools.filtTable,'Data');
            
            if strcmp(newData,' ') %blank the row
                D{rowInd,1} = '';
                D{rowInd,2} = '';
                D{rowInd,3} = '';
            else
                D{rowInd,colInd} = newData;
            end
            set(self.analysisTools.filtTable,'Data',D);
            
            self.updateFilterObject();
        end
        
        function filtPatternEdit_callBack(self,hObject,eventData)
            self.updateFilterObject();
        end
        
        function updateFilterObject(self)
            D = get(self.analysisTools.filtTable,'Data');
            N = size(D,1);
            if isempty(self.analysisTools.filt) || isempty(self.analysisTools.filt.fieldnames)
                previousL = 0;
            else
                previousL = length(self.analysisTools.filt.fieldnames);
            end
            for i=1:N
                if ~isempty(D{i,1}) %change stuff and add stuff
                    self.analysisTools.filt.fieldnames{i} = D{i,1};
                    self.analysisTools.filt.operators{i} = D{i,2};
                    value_str = D{i,3};
                    if ~isempty(value_str),
                        value = str2num(value_str); %#ok<ST2NM>
                    else
                        value = [];
                    end
                    if ~isempty(value)
                        self.analysisTools.filt.values{i} = value;
                    else
                        self.analysisTools.filt.values{i} = value_str;
                    end
                    if i>previousL
                        pattern_str = get(self.analysisTools.filtPatternEdit,'String');
                        if previousL == 0 %first condition
                            pattern_str = '@1';
                        else
                            pattern_str = [pattern_str ' && @' num2str(i)];
                        end
                        set(self.analysisTools.filtPatternEdit,'String',pattern_str);
                    end
                elseif i == previousL %remove last condition
                    self.analysisTools.filt.fieldnames = self.analysisTools.filt.fieldnames(1:i-1);
                    self.analysisTools.filt.operators = self.analysisTools.filt.operators(1:i-1);
                    self.analysisTools.filt.values = self.analysisTools.filt.values(1:i-1);
                    
                    pattern_str = get(self.analysisTools.filtPatternEdit,'String');
                    pattern_str = regexprep(pattern_str, ['@' num2str(i)], '?');
                    set(self.analysisTools.filtPatternEdit,'String',pattern_str);
                end
            end
            
            self.analysisTools.filt.pattern = get(self.analysisTools.filtPatternEdit,'String');
        end
        
        
        function setParamsFromTable(self)
            self.analysisTools.selectedParams = struct;
            D = get(self.analysisTools.paramsTable,'Data');
            L = size(D,1);
            for i=1:L
                if ~isempty(D{i,1})
                    entry = D{i,2};
                    if ~isempty(entry) && isnumeric(str2num(entry)) && ~isempty(str2num(entry)); %#ok<ST2NM>
                        self.analysisTools.selectedParams.(D{i,1}) = eval(entry);
                    else
                        self.analysisTools.selectedParams.(D{i,1}) = entry;
                    end
                end
            end
        end
        
        function updateParamsTable(self)
            D = cell(1,2);
            if ~isfield(self.analysisTools, 'selectedParams')
                self.analysisTools.selectedParams = struct;
            end
            paramNames = fieldnames(self.analysisTools.selectedParams);
            L = length(paramNames);
            for i=1:L
                D{i,1} = paramNames{i};
                D{i,2} = makeValueString(self.analysisTools.selectedParams.(paramNames{i}));
            end
            set(self.analysisTools.paramsTable,'Data',D);
            %self.setParamsFromTable;
        end
        
        function populateFunctionMenuWithFunctions(self, subDir)
            global ANALYSIS_FILTER_VIEW_FOLDER
            funcFolder = fullfile(ANALYSIS_FILTER_VIEW_FOLDER, subDir);
            funcFiles = getMFiles(funcFolder, false);
            funcNames = cell(1, length(funcFiles)+1);
            funcNames{1} = '---pick a function---';
            for ii = 1:length(funcFiles)
                [pat, funcNames{ii+1}] = fileparts(funcFiles{ii});
            end
            set(self.analysisTools.functionMenu, 'String', funcNames);
        end
        
        function populateParamsMenu(self, subDir, prefix)
            global ANALYSIS_FILTER_VIEW_FOLDER
            matFolder = fullfile(ANALYSIS_FILTER_VIEW_FOLDER, [subDir '/saved_params/']);
            matFiles = getMATFiles(matFolder, false);
            L = length(prefix);
            matNames{1} = '---pick a params set---';
            z=2;
            for i = 1:length(matFiles)
                [pat, cur] = fileparts(matFiles{i});
                if length(cur) > L+4 && strcmp(cur(1:L), prefix)
                    matNames{z} = cur(L+4:end);
                    z=z+1;
                end
            end
            set(self.analysisTools.paramsMenu, 'String', matNames);
        end
        
        
        function invokeAnalysisTool(self)
            if isempty(self.analysisTools.selectedFunction) && ~get(self.analysisTools.filter, 'Value')
                return
            end
            
            self.isBusy = true;
            
            nodes = self.getSelectedEpochTreeNodes;
            
            % initialize the chosen analysis tool?
            doInit = ~isequal(self.analysisTools.lastUsedFunction, ...
                self.analysisTools.selectedFunction);
            if doInit
                delete(get(self.plottingCanvas.panel, 'Children'));
            end
            
            %set params to empty by default
            if ~isfield(self.analysisTools, 'selectedParams') || isempty(fieldnames(self.analysisTools.selectedParams))
                self.analysisTools.selectedParams = struct;
            end
            
            % invoke analysis/filter/view function
            if get(self.analysisTools.analysis, 'Value')
                %for analysis, run on either selection or tree level
                calc.func = self.analysisTools.selectedFunction;
                calc.params = self.analysisTools.selectedParams;
                
                if get(self.analysisTools.selectionButton,'Value') %if selection
                    runTreeCalculation(cell2mat(nodes),calc);
                elseif get(self.analysisTools.treeLevelButton,'Value') %else if treeLevel
                    nodes = self.getSelectedTreeLevel;
                    runTreeCalculation(nodes,calc);
                end
            elseif get(self.analysisTools.view, 'Value')
                %for view, run on first selected node only
                feval(self.analysisTools.selectedFunction, ...
                    nodes{1}, ...
                    self.plottingCanvas.panel, ...
                    doInit, ...
                    self.analysisTools.selectedParams);
            elseif get(self.analysisTools.filter, 'Value')
                %for filter, run on first selected node only (goes depth
                %first from there)
                runFilter(nodes{1},self.analysisTools.filt.makeQueryString,1)
            end
            
            self.analysisTools.lastUsedFunction = ...
                self.analysisTools.selectedFunction;
            
            % refresh selections on return from filter function
            if get(self.analysisTools.filter, 'Value')
                browserNodes = self.treeBrowser.graphTree.getSelectedNodes;
                self.refreshBrowserNodes(browserNodes{1});
            end
            
            self.isBusy = false;
        end
        
        function nodes = getSelectedTreeLevel(self)
            curNode = self.getSelectedEpochTreeNodes{1};
            levelsDown = 0;
            while ~isempty(curNode.parent)
                curNode = curNode.parent;
                levelsDown = levelsDown+1;
            end
            nodes = getTreeLevel(self.epochTree,levelsDown);
        end
        
        function reinvokeView(self)
            % if a view function is chosen, reinvoke it
            if get(self.analysisTools.view, 'Value')
                self.invokeAnalysisTool;
            end
        end
        
        %%% misc controls
        
        function buildMiscControlsUI(self)
            % miscellaneous controls
            miscControls.panel = uipanel( ...
                ...'Title',    'misc', ...
                'HandleVisibility', 'off', ...
                'Parent',   self.figure, ...
                'Units',    'normalized', ...
                'Position', [1-self.xDivRight 0 self.xDivRight self.yDiv]);
            
            miscControls.saveTree = uicontrol( ...
                'Parent',   miscControls.panel, ...
                'Callback', @(obj, event)self.saveEpochTree, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'save tree', ...
                'Position', [.1 .7 .8 .2], ...
                'TooltipString', 'save the current EpochTree to a .mat file');
            miscControls.loadTree = uicontrol( ...
                'Parent',   miscControls.panel, ...
                'Callback', @(obj, event)self.loadEpochTree, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'load tree', ...
                'Position', [.1 .5 .8 .2], ...
                'TooltipString', 'load a different EpochTree from a .mat file');
            miscControls.rebuild = uicontrol( ...
                'Parent',   miscControls.panel, ...
                'Callback', @(obj, event)self.rebuildUIComponents, ...
                'Style',    'pushbutton', ...
                'Units',    'normalized', ...
                'FontSize', self.fontSize, ...
                'String',   'fix GUI', ...
                'Position', [.1 .1 .8 .2], ...
                'TooltipString', 'rebuild the epochTreeGUI figure');
            self.miscControls = miscControls;
        end
        
        function saveEpochTree(self)
            if strcmp(class(self.epochTree), 'edu.washington.rieke.jauimodel.AuiEpochTree');
                [n, p] = uiputfile({'*.mat';'*.*'}, 'Save EpochTree as');
                if ischar(n)
                    self.isBusy = true;
                    self.epochTree.saveTree(fullfile(p,n));
                    self.isBusy = false;
                end
            end
        end
        
        function loadEpochTree(self)
            [n, p] = uigetfile({'*.mat';'*.*'}, 'Load EpochTree from file');
            if ischar(n)
                
                self.isBusy = true;
                
                % forget old tree
                if isobject(self.epochTree) && isfield(self.treeBrowser, 'graphTree')
                    % destroy handle references to reduce closing time
                    self.treeBrowser.graphTree.forgetExternalReferences;
                    self.treeBrowser.graphTree.forgetInternalReferences;
                    delete(self.treeBrowser.graphTree);
                end
                
                % get new tree
                %import auimodel.EpochTree;
                self.epochTree = EpochTree.loadTree(fullfile(p,n));
                
                % init (slowly)
                self.buildUIComponents;
                self.isBusy = true;
                self.initAnalysisTools;
                self.initTreeBrowser;
                self.isBusy = false;
            end
        end
    end
    
    methods(Static) %capsule stuff
        % This method gets hammered during recursive flagging
        % static method is *way* faster than instance method
        function nodeDataTakesFlag(browserNode)
            % disp('in nodeDataTakesFlag');
            nodeData = browserNode.userData;
            %keyboard;
            %            if isobject(nodeData) %why test this?
            %            if isa(nodeData, 'edu.washington.rieke.symphony.generic.GenericEpochTree') %need this?
            
            %elseif isa(nodeData, 'edu.washington.rieke.jauimodel.AuiEpoch')
            if isa(nodeData, 'edu.washington.rieke.jauimodel.AuiEpoch') %epoch capsule node
                %disp('selecting epoch');
                % reconcile encapsulated Epoch with browser
                %epoch = nodeData.epochList.firstValue;
                epoch = nodeData;
                %browserNode.isChecked
                epoch.setIsSelected(browserNode.isChecked);
            else %node
                nodeData.custom.put('isSelected',browserNode.isChecked);
            end
            %           end
        end
        
        function refreshUIForNodeSelection(nodeKeys, self)
            self.showSplitKeyStringForSelectedNode;
            self.reinvokeView;
            %self.populateTagMenuWithTags;
        end
        
        function figureResizeCallback(figure,event,gui)
            panelPos = get(figure,'Position');
            panelWidth = panelPos(3);
            
            %paramsTable
            tablePos = get(gui.analysisTools.paramsTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(panelWidth*tableWidth*.3); %param_table width is normalized
            col2W = round(panelWidth*tableWidth*.33);
            set(gui.analysisTools.paramsTable,'ColumnWidth',{col1W, col2W});
            
            %filtTable
            tablePos = get(gui.analysisTools.filtTable,'Position');
            tableWidth = tablePos(3);
            col1W = round(panelWidth*tableWidth*.23);
            col2W = round(panelWidth*tableWidth*.1);
            col3W = round(panelWidth*tableWidth*.23);
            set(gui.analysisTools.filtTable,'ColumnWidth',{col1W, col2W, col3W});
        end
        
        % when the GUI figure closes, try to delete the gui object
        function figureDeleteCallback(figure, event, gui)
            gui.isBusy = true;
            if isobject(gui)
                if isfield(gui.treeBrowser, 'graphTree')
                    % destroy handle references to reduce closing time
                    gui.treeBrowser.graphTree.forgetExternalReferences;
                    gui.treeBrowser.graphTree.forgetInternalReferences;
                end
                if isvalid(gui)
                    delete(gui);
                end
            end
        end
    end
end
