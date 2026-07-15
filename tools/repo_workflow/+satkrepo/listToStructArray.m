function arr = listToStructArray(items, fieldName)
%LISTTOSTRUCTARRAY Build scalar struct array from cellstr.
if nargin < 2, fieldName = 'path'; end
arr = repmat(struct(fieldName,''), 0, 1);
for i = 1:numel(items)
    arr(end+1,1).(fieldName) = items{i}; %#ok<AGROW>
end
end
