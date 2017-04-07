classdef DownTreeParam
    properties
        paramName = '';
        treeLevel = [];
        filt = [];
    end
    
    methods
        function self = DownTreeParam(varargin)
            if nargin<1
                error('must init with a param name');
            elseif nargin>3
                error('only 3 inputs allowed')
            end
            if nargin>1
                self.treeLevel = varargin{2};
            end
            if nargin>2
                self.filt = varargin{3};
            end
            
            self.paramName = varargin{1};
            
        end %end constructor
    end %methods
    
end