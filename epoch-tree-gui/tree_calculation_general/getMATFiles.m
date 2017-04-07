function matfiles = getMATFiles(topDir, beRecursive, toIgnore)
%(Recursively) get matfiles in given directory
%
%   matfiles = getmatfiles(topDir, beRecursive, toIgnore)
%
%   matfiles is a cell array of strings containing filenames for
%   matfiles in and below topDir, with paths relative to topDir.
%
%   topDir is the fodler where to start looking for matfiles, default is the
%   current MATLAB directory.
%
%   beRecursive is a boolean, whether to recurse into subdirectories.
%   Default is true, be recursive.
%
%   toIgnore is an optional cell array of regular expressions.  Directories
%   and matfiles that match any of these will be ignored.

% benjamin.heasly@gmail.com
% Seattle, WA 2008

% sanity check for given dir
if ~nargin || isempty(topDir) || ~ischar(topDir)
    topDir = pwd;
end
assert(exist(topDir, 'dir')==7, sprintf('%s could not find directory "%s"', mfilename, topDir))

if nargin<2 || isempty(beRecursive)
    beRecursive = true;
end

if nargin<3
    toIgnore = {};
end

matfiles = {};

% ignore this dir?
for ii = 1:length(toIgnore)
    if ~isempty(regexp(topDir, toIgnore{ii}));
        disp(topDir)
        return
    end
end

% accumulate matfiles and child directories
d = dir(topDir);
childDirs = {};
for ii = 1:length(d)
    
    if d(ii).isdir && isempty(regexp(d(ii).name, '\.'))
        
        % get directories, ignore ".", "..", ".svn", etc.
        childDirs = cat(2, childDirs, d(ii).name);
        
    elseif ~isempty(regexp(d(ii).name, '\.mat$'))
        
        % get matfiles
        matfiles = cat(2, matfiles, fullfile(topDir, d(ii).name));
    end
end

% recur into children?
if beRecursive
    for ii = 1:length(childDirs)
        fullChild = fullfile(topDir, childDirs{ii});
        matfiles = cat(2, matfiles, getMATFiles(fullChild, true, toIgnore));
    end
end