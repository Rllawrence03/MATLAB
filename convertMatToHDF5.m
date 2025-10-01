convertMatToH5('C:\Users\rlawrence2\Documents\GitHub\AcademicUtils\biomechanics_test_data.mat', ...
    'InfoStructureTest.h5')

function convertMatToH5(matFilePath, hdf5FilePath)
    if ~exist(matFilePath, 'file')
        error('MAT file does not exist: %s', matFilePath);
    end
    
    if exist(hdf5FilePath, 'file')
        delete(hdf5FilePath);
    end
    
    matData = load(matFilePath);
    h5create(hdf5FilePath, '/temp', 1);
    h5write(hdf5FilePath, '/temp', 1);
    
    fieldNames = fieldnames(matData);
    for i = 1:length(fieldNames)
        writeData(hdf5FilePath, ['/' fieldNames{i}], matData.(fieldNames{i}));
    end
    
    fid = H5F.open(hdf5FilePath, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
    H5L.delete(fid, '/temp', 'H5P_DEFAULT');
    H5F.close(fid);
end

function writeData(filename, path, data)
    try
        if isstruct(data)
            writeStruct(filename, path, data);
        elseif iscell(data)
            writeCell(filename, path, data);
        elseif isnumeric(data) || islogical(data)
            writeNumeric(filename, path, data);
        elseif ischar(data) || isstring(data)
            writeString(filename, path, data);
        else
            writeString(filename, path, mat2str(data));
        end
    catch
    end
end

function writeStruct(filename, path, data)
    if length(data) > 1
        for i = 1:length(data)
            fields = fieldnames(data(i));
            for j = 1:length(fields)
                fieldPath = sprintf('%s__%d__%s', path, i, fields{j});
                writeData(filename, fieldPath, data(i).(fields{j}));
            end
        end
    else
        fields = fieldnames(data);
        for i = 1:length(fields)
            fieldPath = [path '__' fields{i}];
            writeData(filename, fieldPath, data.(fields{i}));
        end
    end
end

function writeCell(filename, path, data)
    [rows, cols] = size(data);
    for i = 1:rows
        for j = 1:cols
            cellPath = sprintf('%s__cell_%d_%d', path, i, j);
            writeData(filename, cellPath, data{i,j});
        end
    end
end

function writeNumeric(filename, path, data)
    if islogical(data)
        data = uint8(data);
    end
    
    if isempty(data)
        h5create(filename, path, 1);
        h5write(filename, path, 0);
        return;
    end
    
    if any(isnan(data(:))) || any(isinf(data(:)))
        dataClean = data;
        dataClean(isnan(data)) = 0;
        dataClean(isinf(data) & data > 0) = 999999;
        dataClean(isinf(data) & data < 0) = -999999;
        data = dataClean;
    end
    
    try
        h5create(filename, path, size(data), 'DataType', class(data));
        h5write(filename, path, data);
    catch
        try
            h5create(filename, path, numel(data));
            h5write(filename, path, data(:));
        catch
        end
    end
end

function writeString(filename, path, data)
    if ischar(data) && size(data, 1) > 1
        cellData = cellstr(data);
        writeCell(filename, path, cellData);
        return;
    end
    
    try
        if ischar(data)
            data = string(data);
        end
        h5create(filename, path, size(data), 'DataType', 'string');
        h5write(filename, path, data);
    catch
    end
end