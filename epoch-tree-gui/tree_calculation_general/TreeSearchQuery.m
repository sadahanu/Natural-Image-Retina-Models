classdef TreeSearchQuery < hgsetget %search query object to use with searchLeafNodes.m
    properties
        pattern = '';
        fieldnames = {};
        operators = {};
        values = {}; 
    end
    
    methods        
        function self = TreeSearchQuery(varargin)
            if nargin==0
                %self.addCondition();
            elseif rem(nargin,3) == 0
                N = nargin/3;
                for i=1:N
                    if i==1, self.pattern = '@1';
                    else self.pattern = [self.pattern ' && @' num2str(i)]; end
                    self.fieldnames{i} = varargin{(i-1)*3+1};
                    self.operators{i} = varargin{(i-1)*3+2};
                    self.values{i} = varargin{(i-1)*3+3};
                end
            else
                disp('Error: class constructor requires arguments in groups of 3');
            end
        end
        
        function addCondition(self)
            
            if isempty(self.fieldnames)
                i=1;
                self.pattern = '@1';
            else
                i=length(self.fieldnames) + 1;
                self.pattern = [self.pattern ' && @' num2str(i)];
            end
            
            self.fieldnames{i} = input('Field Name (no quotes): ','s');
            self.operators{i} = input('Operator (no quotes): ','s');
            self.values{i} = input('Value (quotes if a string): ');
            
            displayCondition(C);  
        end
        
        function queryString = makeQueryString(self)
            %inputs: tree, Conditions structure: an instantiation of the
            %LeafSearchQuery object
            %
            %returns the leaves that match the search query
            
            N = length(self.fieldnames); %number of sub-conditions in search query
            
            %construct query string for each sub-condition
            %and place each one in the correct place in self.pattern
            
            queryString = self.pattern;
            for i=1:N
                if ischar(self.values{i}) %if value is a string
                    if strcmp(self.operators{i},'==') %and the condition is equality, do a strcmp
                        s = ['strcmp(M(' '''' self.fieldnames{i} '''' '),' '''' self.values{i} '''' ')'];
                    else
                        disp('Error: only equality can be tested for strings');
                    end
                elseif isnumeric(self.values{i})
                    s = ['M(' '''' self.fieldnames{i} '''' ')' self.operators{i} num2str(self.values{i})];
                end
                queryString = regexprep(queryString, ['@' num2str(i)], s);
            end
        end
        
        function displayCondition(self)
            
            N = length(self.fieldnames); %number of sub-conditions in search query
            disp('-----------------------');
            for i=1:N
                s = ['@' num2str(i) ': ' self.fieldnames{i} ' ' self.operators{i} ' ' num2str(self.values{i})];
                disp(s);
            end
            
            disp(['Pattern: ' self.pattern]);
            disp('-----------------------');
            
        end
    end
end
    