function edges=meshedge(elem)
%
% edges=meshedge(elem)
%
% return all edges in a surface or volumetric mesh
%
% author: Qianqian Fang (fangq<at> nmr.mgh.harvard.edu)
% date: 2011/02/26
%
% input:
%    elem:  element table of a mesh (support N-d space element)
%
% output
%    edge:  edge list; each row is an edge, specified by the starting and
%           ending node indices, the total edge number is
%           size(elem,1) x nchoosek(size(elem,2),2). All edges are ordered
%           by looping through each element first. 
%
% -- this function is part of iso2mesh toolbox (http://iso2mesh.sf.net)
%

dim=size(elem);
edgeid=nchoosek(1:dim(2),2);
len=size(edgeid,1);
edges=zeros(dim(1)*len,2);
for i=0:len-1
    edges((i*dim(1)+1):((i+1)*dim(1)),:)=[elem(:,edgeid(i+1,1)) elem(:,edgeid(i+1,2))];
end