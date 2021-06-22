codeunit 419 "File Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'Default';
        Text002: Label 'You must enter a file path.';
        Text003: Label 'You must enter a file name.';
        FileDoesNotExistErr: Label 'The file %1 does not exist.', Comment = '%1 File Path';
        Text006: Label 'Export';
        Text007: Label 'Import';
        PathHelper: DotNet Path;
        [RunOnClient]
        DirectoryHelper: DotNet Directory;
        [RunOnClient]
        ClientFileHelper: DotNet File;
        ServerFileHelper: DotNet File;
        ServerDirectoryHelper: DotNet Directory;
        Text010: Label 'The file %1 has not been uploaded.';
        Text011: Label 'You must specify a source file name.';
        Text012: Label 'You must specify a target file name.';
        Text013: Label 'The file name %1 already exists.';
        DirectoryDoesNotExistErr: Label 'Directory %1 does not exist.', Comment = '%1=Directory user is trying to upload does not exist';
        CreatePathQst: Label 'The path %1 does not exist. Do you want to add it now?';
        AllFilesFilterTxt: Label '*.*', Locked = true;
        AllFilesDescriptionTxt: Label 'All Files (*.*)|*.*', Comment = '{Split=r''\|''}{Locked=s''1''}';
        XMLFileType: Label 'XML Files (*.xml)|*.xml', Comment = '{Split=r''\|''}{Locked=s''1''}';
        WordFileType: Label 'Word Files (*.doc)|*.doc', Comment = '{Split=r''\|''}{Locked=s''1''}';
        Word2007FileType: Label 'Word Files (*.docx;*.doc)|*.docx;*.doc', Comment = '{Split=r''\|''}{Locked=s''1''}';
        ExcelFileType: Label 'Excel Files (*.xls)|*.xls', Comment = '{Split=r''\|''}{Locked=s''1''}';
        Excel2007FileType: Label 'Excel Files (*.xlsx;*.xls)|*.xlsx;*.xls', Comment = '{Split=r''\|''}{Locked=s''1''}';
        XSDFileType: Label 'XSD Files (*.xsd)|*.xsd', Comment = '{Split=r''\|''}{Locked=s''1''}';
        HTMFileType: Label 'HTM Files (*.htm)|*.htm', Comment = '{Split=r''\|''}{Locked=s''1''}';
        XSLTFileType: Label 'XSLT Files (*.xslt)|*.xslt', Comment = '{Split=r''\|''}{Locked=s''1''}';
        TXTFileType: Label 'Text Files (*.txt)|*.txt', Comment = '{Split=r''\|''}{Locked=s''1''}';
        RDLFileTypeTok: Label 'SQL Report Builder (*.rdl;*.rdlc)|*.rdl;*.rdlc', Comment = '{Split=r''\|''}{Locked=s''1''}';
        UnsupportedFileExtErr: Label 'Unsupported file extension (.%1). The supported file extensions are (%2).';
        SingleFilterErr: Label 'Specify a file filter and an extension filter when using this function.';
        InvalidWindowsChrStringTxt: Label '"#%&*:<>?\/{|}~', Locked = true;
        DownloadImageTxt: Label 'Download image';
        LocalFileSystemNotAccessibleErr: Label 'Sorry, this action is not available for the online version of the app.';
        ChooseFileTitleMsg: Label 'Choose the file to upload.';
        NotAllowedPathErr: Label 'Files outside of the current user''s folder cannot be accessed. Access is denied to file %1.', Comment = '%1=the full path to a file. ex: C:\Windows\TextFile.txt ';

    procedure BLOBImport(var TempBlob: Codeunit "Temp Blob"; Name: Text): Text
    begin
        exit(BLOBImportWithFilter(TempBlob, Text007, Name, AllFilesDescriptionTxt, AllFilesFilterTxt));
    end;

    procedure BLOBImportWithFilter(var TempBlob: Codeunit "Temp Blob"; DialogCaption: Text; Name: Text; FileFilter: Text; ExtFilter: Text): Text
    var
        NVInStream: InStream;
        NVOutStream: OutStream;
        UploadResult: Boolean;
        ErrorMessage: Text;
    begin
        // ExtFilter examples: 'csv,txt' if you only accept *.csv and *.txt or '*.*' if you accept any extensions
        ClearLastError;

        if (FileFilter = '') xor (ExtFilter = '') then
            Error(SingleFilterErr);

        // There is no way to check if NVInStream is null before using it after calling the
        // UPLOADINTOSTREAM therefore if result is false this is the only way we can throw the error.
        UploadResult := UploadIntoStream(DialogCaption, '', FileFilter, Name, NVInStream);
        if UploadResult then
            ValidateFileExtension(Name, ExtFilter);
        if UploadResult then begin
            TempBlob.CreateOutStream(NVOutStream);
            CopyStream(NVOutStream, NVInStream);
            exit(Name);
        end;
        ErrorMessage := GetLastErrorText;
        if ErrorMessage <> '' then
            Error(ErrorMessage);

        exit('');
    end;

    local procedure BLOBExportLocal(var InStream: InStream; Name: Text; IsCommonDialog: Boolean): Text
    var
        ToFile: Text;
        Path: Text;
        IsDownloaded: Boolean;
    begin
        if IsCommonDialog then begin
            if StrPos(Name, '*') = 0 then
                ToFile := Name
            else
                ToFile := DelChr(InsStr(Name, Text001, 1), '=', '*');
            Path := PathHelper.GetDirectoryName(ToFile);
            ToFile := GetFileName(ToFile);
        end else begin
            ToFile := ClientTempFileName(GetExtension(Name));
            Path := Magicpath;
        end;
        IsDownloaded := DownloadFromStream(InStream, Text006, Path, GetToFilterText('', Name), ToFile);
        if IsDownloaded then
            exit(ToFile);
        exit('');
    end;

    procedure BLOBExportWithEncoding(var TempBlob: Codeunit "Temp Blob"; Name: Text; CommonDialog: Boolean; Encoding: TextEncoding): Text
    var
        NVInStream: InStream;
    begin
        TempBlob.CreateInStream(NVInStream, Encoding);
        exit(BLOBExportLocal(NVInStream, Name, CommonDialog));
    end;

    procedure BLOBExport(var TempBlob: Codeunit "Temp Blob"; Name: Text; CommonDialog: Boolean): Text
    var
        NVInStream: InStream;
    begin
        TempBlob.CreateInStream(NVInStream);
        exit(BLOBExportLocal(NVInStream, Name, CommonDialog));
    end;

    [Scope('OnPrem')]
    procedure ServerTempFileName(FileExtension: Text) FileName: Text
    var
        TempFile: File;
    begin
        TempFile.CreateTempFile;
        FileName := CreateFileNameWithExtension(TempFile.Name, FileExtension);
        TempFile.Close;
    end;

    [Scope('OnPrem')]
    procedure ClientTempFileName(FileExtension: Text) ClientFileName: Text
    var
        TempFile: File;
        ClientTempPath: Text;
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        // Returns the pseudo uniquely generated name of a non existing file in the client temp directory
        TempFile.CreateTempFile;
        ClientFileName := CreateFileNameWithExtension(TempFile.Name, FileExtension);
        TempFile.Close;
        TempFile.Create(ClientFileName);
        TempFile.Close;
        ClientTempPath := GetDirectoryName(DownloadTempFile(ClientFileName));
        if Erase(ClientFileName) then;
        ClientFileHelper.Delete(ClientTempPath + '\' + PathHelper.GetFileName(ClientFileName));
        ClientFileName := CreateFileNameWithExtension(ClientTempPath + '\' + Format(CreateGuid), FileExtension);
    end;

    [Scope('OnPrem')]
    procedure CreateClientTempSubDirectory() ClientDirectory: Text
    var
        ServerFile: File;
        ServerFileName: Text;
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        // Creates a new subdirectory in the client's TEMP folder
        ServerFile.Create(CreateGuid);
        ServerFileName := ServerFile.Name;
        ServerFile.Close;
        ClientDirectory := GetDirectoryName(DownloadTempFile(ServerFileName));
        if Erase(ServerFileName) then;
        DeleteClientFile(CombinePath(ClientDirectory, GetFileName(ServerFileName)));
        ClientDirectory := CombinePath(ClientDirectory, CreateGuid);
        CreateClientDirectory(ClientDirectory);
    end;

    procedure DownloadTempFile(ServerFileName: Text): Text
    var
        FileName: Text;
        Path: Text;
    begin
        FileName := ServerFileName;
        Path := Magicpath;
        Download(ServerFileName, '', Path, AllFilesDescriptionTxt, FileName);
        exit(FileName);
    end;

    [Scope('OnPrem')]
    procedure UploadFileSilent(ClientFilePath: Text): Text
    begin
        exit(
          UploadFileSilentToServerPath(ClientFilePath, ''));
    end;

    [Scope('OnPrem')]
    procedure UploadFileSilentToServerPath(ClientFilePath: Text; ServerFilePath: Text): Text
    var
        ClientFileAttributes: DotNet FileAttributes;
        ServerFileName: Text;
        TempClientFile: Text;
        FileName: Text;
        FileExtension: Text;
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        if not ClientFileHelper.Exists(ClientFilePath) then
            Error(FileDoesNotExistErr, ClientFilePath);
        FileName := GetFileName(ClientFilePath);
        FileExtension := GetExtension(FileName);

        TempClientFile := ClientTempFileName(FileExtension);
        ClientFileHelper.Copy(ClientFilePath, TempClientFile, true);

        if ServerFilePath <> '' then
            ServerFileName := ServerFilePath
        else
            ServerFileName := ServerTempFileName(FileExtension);

        if not Upload('', Magicpath, AllFilesDescriptionTxt, GetFileName(TempClientFile), ServerFileName) then
            Error(Text010, ClientFilePath);

        ClientFileHelper.SetAttributes(TempClientFile, ClientFileAttributes.Normal);
        ClientFileHelper.Delete(TempClientFile);
        exit(ServerFileName);
    end;

    [Scope('OnPrem')]
    procedure UploadFileToServer(ClientFilePath: Text): Text
    begin
        if IsLocalFileSystemAccessible then
            exit(UploadFileSilentToServerPath(ClientFilePath, ''));

        exit(UploadFile(ChooseFileTitleMsg, ''));
    end;

    [Scope('OnPrem')]
    procedure UploadFile(WindowTitle: Text[50]; ClientFileName: Text) ServerFileName: Text
    var
        "Filter": Text;
    begin
        Filter := GetToFilterText('', ClientFileName);

        if PathHelper.GetFileNameWithoutExtension(ClientFileName) = '' then
            ClientFileName := '';

        ServerFileName := UploadFileWithFilter(WindowTitle, ClientFileName, Filter, AllFilesFilterTxt);
    end;

    [Scope('OnPrem')]
    procedure UploadFileWithFilter(WindowTitle: Text[50]; ClientFileName: Text; FileFilter: Text; ExtFilter: Text) ServerFileName: Text
    var
        Uploaded: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUploadFileWithFilter(ServerFileName, WindowTitle, ClientFileName, FileFilter, ExtFilter, IsHandled);
        if IsHandled then
            exit;

        ClearLastError;

        if (FileFilter = '') xor (ExtFilter = '') then
            Error(SingleFilterErr);

        Uploaded := Upload(WindowTitle, '', FileFilter, ClientFileName, ServerFileName);
        if Uploaded then
            ValidateFileExtension(ClientFileName, ExtFilter);
        if Uploaded then
            exit(ServerFileName);

        if GetLastErrorText <> '' then
            Error('%1', GetLastErrorText);

        exit('');
    end;

    procedure Magicpath(): Text
    begin
        exit('<TEMP>');   // MAGIC PATH makes sure we don't get a prompt
    end;

    [Scope('OnPrem')]
    procedure DownloadHandler(FromFile: Text; DialogTitle: Text; ToFolder: Text; ToFilter: Text; ToFile: Text): Boolean
    var
        Downloaded: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDownloadHandler(ToFolder, ToFile, FromFile, IsHandled);
        if IsHandled then
            exit;

        ClearLastError;
        Downloaded := Download(FromFile, DialogTitle, ToFolder, ToFilter, ToFile);
        if not Downloaded then
            if GetLastErrorText <> '' then
                Error('%1', GetLastErrorText);
        exit(Downloaded);
    end;

    [Scope('OnPrem')]
    procedure DownloadFromStreamHandler(FromInStream: InStream; DialogTitle: Text; ToFolder: Text; ToFilter: Text; ToFile: Text): Boolean
    var
        Downloaded: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDownloadFromStreamHandler(ToFolder, ToFile, FromInStream, IsHandled);
        if IsHandled then
            exit(true);

        ClearLastError;
        Downloaded := DownloadFromStream(FromInStream, DialogTitle, ToFolder, ToFilter, ToFile);
        if not Downloaded then
            if GetLastErrorText <> '' then
                Error('%1', GetLastErrorText);
        exit(Downloaded);
    end;

    [Scope('OnPrem')]
    procedure DownloadToFile(ServerFileName: Text; ClientFileName: Text)
    var
        TempClientFileName: Text;
    begin
        if IsLocalFileSystemAccessible then begin
            ValidateFileNames(ServerFileName, ClientFileName);
            TempClientFileName := DownloadTempFile(ServerFileName);
            MoveFile(TempClientFileName, ClientFileName);
        end else
            DownloadHandler(ServerFileName, '', '', '', ClientFileName);
    end;

    [Scope('OnPrem')]
    procedure AppendAllTextToClientFile(ServerFileName: Text; ClientFileName: Text)
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        ValidateFileNames(ServerFileName, ClientFileName);
        IsAllowedPath(ServerFileName, false);
        ClientFileHelper.AppendAllText(ClientFileName, ServerFileHelper.ReadAllText(ServerFileName));
    end;

    [Scope('OnPrem')]
    procedure MoveAndRenameClientFile(OldFilePath: Text; NewFileName: Text; NewSubDirectoryName: Text) NewFilePath: Text
    var
        directory: Text;
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        if OldFilePath = '' then
            Error(Text002);

        if NewFileName = '' then
            Error(Text003);

        if not ClientFileHelper.Exists(OldFilePath) then
            Error(FileDoesNotExistErr, OldFilePath);

        // Get the directory from the OldFilePath, if directory is empty it will just use the current location.
        directory := GetDirectoryName(OldFilePath);

        // create the sub directory name is name is given
        if NewSubDirectoryName <> '' then begin
            directory := PathHelper.Combine(directory, NewSubDirectoryName);
            DirectoryHelper.CreateDirectory(directory);
        end;

        NewFilePath := PathHelper.Combine(directory, NewFileName);
        MoveFile(OldFilePath, NewFilePath);

        exit(NewFilePath);
    end;

    [Scope('OnPrem')]
    procedure CreateClientFile(FilePathName: Text)
    var
        [RunOnClient]
        StreamWriter: DotNet StreamWriter;
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        if not ClientFileHelper.Exists(FilePathName) then begin
            StreamWriter := ClientFileHelper.CreateText(FilePathName);
            StreamWriter.Close;
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteClientFile(FilePath: Text): Boolean
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        if not ClientFileHelper.Exists(FilePath) then
            exit(false);

        ClientFileHelper.Delete(FilePath);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CopyClientFile(SourceFileName: Text; DestFileName: Text; OverWrite: Boolean)
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        ClientFileHelper.Copy(SourceFileName, DestFileName, OverWrite);
    end;

    [Scope('OnPrem')]
    procedure ClientFileExists(FilePath: Text): Boolean
    begin
        if not IsLocalFileSystemAccessible then
            exit(false);
        exit(ClientFileHelper.Exists(FilePath));
    end;

    [Scope('OnPrem')]
    procedure ClientDirectoryExists(DirectoryPath: Text): Boolean
    begin
        if not IsLocalFileSystemAccessible then
            exit(false);
        exit(DirectoryHelper.Exists(DirectoryPath));
    end;

    [Scope('OnPrem')]
    procedure CreateClientDirectory(DirectoryPath: Text)
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        if not ClientDirectoryExists(DirectoryPath) then
            DirectoryHelper.CreateDirectory(DirectoryPath);
    end;

    [Scope('OnPrem')]
    procedure DeleteClientDirectory(DirectoryPath: Text)
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        if ClientDirectoryExists(DirectoryPath) then
            DirectoryHelper.Delete(DirectoryPath, true);
    end;

    [Scope('OnPrem')]
    procedure UploadClientDirectorySilent(DirectoryPath: Text; FileExtensionFilter: Text; IncludeSubDirectories: Boolean) ServerDirectoryPath: Text
    var
        [RunOnClient]
        SearchOption: DotNet SearchOption;
        [RunOnClient]
        ArrayHelper: DotNet Array;
        [RunOnClient]
        ClientFilePath: DotNet String;
        ServerFilePath: Text;
        RelativeServerPath: Text;
        i: Integer;
        ArrayLength: Integer;
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        if not ClientDirectoryExists(DirectoryPath) then
            Error(DirectoryDoesNotExistErr, DirectoryPath);

        if IncludeSubDirectories then
            ArrayHelper := DirectoryHelper.GetFiles(DirectoryPath, FileExtensionFilter, SearchOption.AllDirectories)
        else
            ArrayHelper := DirectoryHelper.GetFiles(DirectoryPath, FileExtensionFilter, SearchOption.TopDirectoryOnly);

        ArrayLength := ArrayHelper.GetLength(0);

        if ArrayLength = 0 then
            exit;

        ServerDirectoryPath := ServerCreateTempSubDirectory;

        for i := 1 to ArrayLength do begin
            ClientFilePath := ArrayHelper.GetValue(i - 1);
            RelativeServerPath := ClientFilePath.Replace(DirectoryPath, '');
            if PathHelper.IsPathRooted(RelativeServerPath) then
                RelativeServerPath := DelChr(RelativeServerPath, '<', '\');
            ServerFilePath := CombinePath(ServerDirectoryPath, RelativeServerPath);
            ServerCreateDirectory(GetDirectoryName(ServerFilePath));
            UploadFileSilentToServerPath(ClientFilePath, ServerFilePath);
        end;
    end;

    [Scope('OnPrem')]
    procedure MoveFile(SourceFileName: Text; TargetFileName: Text)
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        // System.IO.File.Move is not used due to a known issue in KB310316
        if not ClientFileHelper.Exists(SourceFileName) then
            Error(FileDoesNotExistErr, SourceFileName);

        if UpperCase(SourceFileName) = UpperCase(TargetFileName) then
            exit;

        ValidateClientPath(GetDirectoryName(TargetFileName));

        DeleteClientFile(TargetFileName);
        ClientFileHelper.Copy(SourceFileName, TargetFileName);
        ClientFileHelper.Delete(SourceFileName);
    end;

    [Scope('OnPrem')]
    procedure CopyServerFile(SourceFileName: Text; TargetFileName: Text; Overwrite: Boolean)
    begin
        IsAllowedPath(SourceFileName, false);
        IsAllowedPath(TargetFileName, false);
        ServerFileHelper.Copy(SourceFileName, TargetFileName, Overwrite);
    end;

    procedure ServerFileExists(FilePath: Text): Boolean
    begin
        exit(Exists(FilePath));
    end;

    [Scope('OnPrem')]
    procedure DeleteServerFile(FilePath: Text): Boolean
    begin
        IsAllowedPath(FilePath, false);
        if not Exists(FilePath) then
            exit(false);

        ServerFileHelper.Delete(FilePath);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ServerDirectoryExists(DirectoryPath: Text): Boolean
    begin
        exit(ServerDirectoryHelper.Exists(DirectoryPath));
    end;

    [Scope('OnPrem')]
    procedure ServerCreateDirectory(DirectoryPath: Text)
    begin
        if not ServerDirectoryExists(DirectoryPath) then
            ServerDirectoryHelper.CreateDirectory(DirectoryPath);
    end;

    [Scope('OnPrem')]
    procedure ServerCreateTempSubDirectory() DirectoryPath: Text
    var
        ServerTempFile: Text;
    begin
        ServerTempFile := ServerTempFileName('tmp');
        DirectoryPath := CombinePath(GetDirectoryName(ServerTempFile), Format(CreateGuid));
        ServerCreateDirectory(DirectoryPath);
        DeleteServerFile(ServerTempFile);
    end;

    [Scope('OnPrem')]
    procedure ServerRemoveDirectory(DirectoryPath: Text; Recursive: Boolean)
    begin
        if ServerDirectoryExists(DirectoryPath) then
            ServerDirectoryHelper.Delete(DirectoryPath, Recursive);
    end;

    procedure GetFileName(FilePath: Text): Text
    begin
        exit(PathHelper.GetFileName(FilePath));
    end;

    procedure GetSafeFileName(FileName: Text): Text
    var
        DotNetString: DotNet String;
        Result: Text;
        Str: Text;
    begin
        DotNetString := FileName;
        foreach Str in DotNetString.Split(PathHelper.GetInvalidFileNameChars) do
            Result += Str;
        exit(Result);
    end;

    procedure GetFileNameWithoutExtension(FilePath: Text): Text
    begin
        exit(PathHelper.GetFileNameWithoutExtension(FilePath));
    end;

    procedure HasExtension(FilePath: Text): Boolean
    begin
        exit(PathHelper.HasExtension(FilePath));
    end;

    procedure GetFileNameMimeType(FileName: Text): Text
    var
        MimeMapping: DotNet MimeMapping;
    begin
        exit(MimeMapping.GetMimeMapping(FileName));
    end;

    procedure GetDirectoryName(FileName: Text): Text
    begin
        if FileName = '' then
            exit(FileName);

        FileName := DelChr(FileName, '<');
        exit(PathHelper.GetDirectoryName(FileName));
    end;

    [Scope('OnPrem')]
    procedure GetClientDirectoryFilesList(var NameValueBuffer: Record "Name/Value Buffer"; DirectoryPath: Text)
    var
        [RunOnClient]
        ArrayHelper: DotNet Array;
        i: Integer;
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        NameValueBuffer.Reset();
        NameValueBuffer.DeleteAll();

        ArrayHelper := DirectoryHelper.GetFiles(DirectoryPath);
        for i := 1 to ArrayHelper.GetLength(0) do begin
            NameValueBuffer.ID := i;
            Evaluate(NameValueBuffer.Name, ArrayHelper.GetValue(i - 1));
            NameValueBuffer.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetServerDirectoryFilesList(var NameValueBuffer: Record "Name/Value Buffer"; DirectoryPath: Text)
    var
        ArrayHelper: DotNet Array;
        i: Integer;
    begin
        NameValueBuffer.Reset();
        NameValueBuffer.DeleteAll();

        ArrayHelper := ServerDirectoryHelper.GetFiles(DirectoryPath);
        for i := 1 to ArrayHelper.GetLength(0) do begin
            NameValueBuffer.ID := i;
            Evaluate(NameValueBuffer.Name, ArrayHelper.GetValue(i - 1));
            NameValueBuffer.Value := CopyStr(GetFileNameWithoutExtension(NameValueBuffer.Name), 1, 250);
            NameValueBuffer.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetServerDirectoryFilesListInclSubDirs(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; DirectoryPath: Text)
    begin
        TempNameValueBuffer.Reset();
        TempNameValueBuffer.DeleteAll();

        GetServerDirectoryFilesListInclSubDirsInner(TempNameValueBuffer, DirectoryPath);
    end;

    local procedure GetServerDirectoryFilesListInclSubDirsInner(var NameValueBuffer: Record "Name/Value Buffer"; DirectoryPath: Text)
    var
        ArrayHelper: DotNet Array;
        FileSystemEntry: Text;
        Index: Integer;
        LastId: Integer;
    begin
        ArrayHelper := ServerDirectoryHelper.GetFileSystemEntries(DirectoryPath);
        for Index := 1 to ArrayHelper.GetLength(0) do begin
            if NameValueBuffer.FindLast then
                LastId := NameValueBuffer.ID;
            Evaluate(FileSystemEntry, ArrayHelper.GetValue(Index - 1));
            if ServerDirectoryExists(FileSystemEntry) then
                GetServerDirectoryFilesListInclSubDirsInner(NameValueBuffer, FileSystemEntry)
            else begin
                NameValueBuffer.ID := LastId + 1;
                NameValueBuffer.Name := CopyStr(FileSystemEntry, 1, 250);
                NameValueBuffer.Value := CopyStr(GetFileNameWithoutExtension(NameValueBuffer.Name), 1, 250);
                NameValueBuffer.Insert();
            end;
        end;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure GetClientFileProperties(FullFileName: Text; var ModifyDate: Date; var ModifyTime: Time; var Size: BigInteger)
    var
        [RunOnClient]
        FileInfo: DotNet FileInfo;
        ModifyDateTime: DateTime;
    begin
        if not IsLocalFileSystemAccessible then
            Error(LocalFileSystemNotAccessibleErr);

        ModifyDateTime := ClientFileHelper.GetLastWriteTime(FullFileName);
        ModifyDate := DT2Date(ModifyDateTime);
        ModifyTime := DT2Time(ModifyDateTime);
        Size := FileInfo.FileInfo(FullFileName).Length;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure GetServerFileProperties(FullFileName: Text; var ModifyDate: Date; var ModifyTime: Time; var Size: BigInteger)
    var
        FileInfo: DotNet FileInfo;
        ModifyDateTime: DateTime;
    begin
        ModifyDateTime := ServerDirectoryHelper.GetLastWriteTime(FullFileName);
        ModifyDate := DT2Date(ModifyDateTime);
        ModifyTime := DT2Time(ModifyDateTime);
        Size := FileInfo.FileInfo(FullFileName).Length;
    end;

    [Scope('OnPrem')]
    procedure CombinePath(BasePath: Text; Suffix: Text): Text
    begin
        exit(PathHelper.Combine(BasePath, Suffix));
    end;

    [Scope('OnPrem')]
    procedure BLOBImportFromServerFile(var TempBlob: Codeunit "Temp Blob"; FilePath: Text)
    var
        OutStream: OutStream;
        InStream: InStream;
        InputFile: File;
    begin
        IsAllowedPath(FilePath, false);

        if not FILE.Exists(FilePath) then
            Error(FileDoesNotExistErr, FilePath);

        InputFile.Open(FilePath);
        InputFile.CreateInStream(InStream);
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        InputFile.Close;
    end;

    [Scope('OnPrem')]
    procedure BLOBExportToServerFile(var TempBlob: Codeunit "Temp Blob"; FilePath: Text)
    var
        OutStream: OutStream;
        InStream: InStream;
        OutputFile: File;
    begin
        if FILE.Exists(FilePath) then
            Error(Text013, FilePath);

        OutputFile.WriteMode(true);
        OutputFile.Create(FilePath);
        OutputFile.CreateOutStream(OutStream);
        TempBlob.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        OutputFile.Close;
    end;

    [Scope('OnPrem')]
    procedure InstreamExportToServerFile(Instream: InStream; FileExt: Text) FileName: Text
    var
        OutStream: OutStream;
        OutputFile: File;
    begin
        FileName := CopyStr(ServerTempFileName(FileExt), 1, 250);
        OutputFile.WriteMode(true);
        OutputFile.Create(FileName);
        OutputFile.CreateOutStream(OutStream);
        CopyStream(OutStream, Instream);
        OutputFile.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateAndWriteToServerFile(FileContent: Text; FileExt: Text) FileName: Text
    var
        File: File;
        OutStream: OutStream;
    begin
        FileName := CopyStr(ServerTempFileName(FileExt), 1, 250);
        File.Create(FileName);
        File.CreateOutStream(OutStream);
        OutStream.WriteText(FileContent);
        File.Close;
    end;

    procedure GetToFilterText(FilterString: Text; FileName: Text): Text
    var
        OutExt: Text;
    begin
        if FilterString <> '' then
            exit(FilterString);

        case UpperCase(GetExtension(FileName)) of
            'DOC':
                OutExt := WordFileType;
            'DOCX':
                OutExt := Word2007FileType;
            'XLS':
                OutExt := ExcelFileType;
            'XLSX':
                OutExt := Excel2007FileType;
            'XSLT':
                OutExt := XSLTFileType;
            'XML':
                OutExt := XMLFileType;
            'XSD':
                OutExt := XSDFileType;
            'HTM':
                OutExt := HTMFileType;
            'TXT':
                OutExt := TXTFileType;
            'RDL':
                OutExt := RDLFileTypeTok;
            'RDLC':
                OutExt := RDLFileTypeTok;
        end;

        OnAfterGetToFilterTextSetOutExt(FileName, OutExt);

        if OutExt = '' then
            exit(AllFilesDescriptionTxt);
        exit(OutExt + '|' + AllFilesDescriptionTxt);  // Also give the option of the general selection
    end;

    procedure GetExtension(Name: Text): Text
    var
        FileExtension: Text;
    begin
        FileExtension := PathHelper.GetExtension(Name);

        if FileExtension <> '' then
            FileExtension := DelChr(FileExtension, '<', '.');

        exit(FileExtension);
    end;

    procedure OpenFileDialog(WindowTitle: Text[50]; DefaultFileName: Text; FilterString: Text): Text
    var
        [RunOnClient]
        OpenFileDialog: DotNet OpenFileDialog;
        [RunOnClient]
        DialogResult: DotNet DialogResult;
    begin
        if not IsLocalFileSystemAccessible then
            exit(UploadFile(WindowTitle, DefaultFileName));

        OpenFileDialog := OpenFileDialog.OpenFileDialog;
        OpenFileDialog.ShowReadOnly := false;
        OpenFileDialog.FileName := GetFileName(DefaultFileName);
        OpenFileDialog.Title := WindowTitle;
        OpenFileDialog.Filter := GetToFilterText(FilterString, DefaultFileName);
        OpenFileDialog.InitialDirectory := GetDirectoryName(DefaultFileName);

        DialogResult := OpenFileDialog.ShowDialog;
        if DialogResult.CompareTo(DialogResult.OK) = 0 then
            exit(OpenFileDialog.FileName);
        exit('');
    end;

    [Scope('OnPrem')]
    procedure SaveFileDialog(WindowTitle: Text[50]; DefaultFileName: Text; FilterString: Text): Text
    var
        [RunOnClient]
        SaveFileDialog: DotNet SaveFileDialog;
        [RunOnClient]
        DialogResult: DotNet DialogResult;
    begin
        if not IsLocalFileSystemAccessible then
            exit('');
        SaveFileDialog := SaveFileDialog.SaveFileDialog;
        SaveFileDialog.CheckPathExists := true;
        SaveFileDialog.OverwritePrompt := true;
        SaveFileDialog.FileName := GetFileName(DefaultFileName);
        SaveFileDialog.Title := WindowTitle;
        SaveFileDialog.Filter := GetToFilterText(FilterString, DefaultFileName);
        SaveFileDialog.InitialDirectory := GetDirectoryName(DefaultFileName);

        DialogResult := SaveFileDialog.ShowDialog;
        if DialogResult.CompareTo(DialogResult.OK) = 0 then
            exit(SaveFileDialog.FileName);
        exit('');
    end;

    procedure SelectFolderDialog(WindowTitle: Text; var SelectedFolder: Text): Boolean
    var
        [RunOnClient]
        FolderBrowser: DotNet FolderBrowserDialog;
        [RunOnClient]
        DialogResult: DotNet DialogResult;
    begin
        if not IsLocalFileSystemAccessible then
            exit(false);

        FolderBrowser := FolderBrowser.FolderBrowserDialog;
        FolderBrowser.ShowNewFolderButton := true;
        FolderBrowser.Description := WindowTitle;

        DialogResult := FolderBrowser.ShowDialog;
        if DialogResult = 1 then begin
            SelectedFolder := FolderBrowser.SelectedPath;
            exit(true);
        end;
    end;

    procedure IsLocalFileSystemAccessible(): Boolean
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        exit(ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Windows);
    end;

    procedure IsValidFileName(FileName: Text): Boolean
    var
        String: DotNet String;
    begin
        if FileName = '' then
            exit(false);

        String := GetFileName(FileName);
        if String.IndexOfAny(PathHelper.GetInvalidFileNameChars) <> -1 then
            exit(false);

        String := GetDirectoryName(FileName);
        if String.IndexOfAny(PathHelper.GetInvalidPathChars) <> -1 then
            exit(false);

        exit(true);
    end;

    local procedure ValidateFileNames(ServerFileName: Text; ClientFileName: Text)
    begin
        if not IsValidFileName(ServerFileName) then
            Error(Text011);

        if not IsValidFileName(ClientFileName) then
            Error(Text012);
    end;

    procedure ValidateFileExtension(FilePath: Text; ValidExtensions: Text)
    var
        FileExt: Text;
        LowerValidExts: Text;
    begin
        if StrPos(ValidExtensions, AllFilesFilterTxt) <> 0 then
            exit;

        FileExt := LowerCase(GetExtension(GetFileName(FilePath)));
        LowerValidExts := LowerCase(ValidExtensions);

        if StrPos(LowerValidExts, FileExt) = 0 then
            Error(UnsupportedFileExtErr, FileExt, LowerValidExts);
    end;

    local procedure ValidateClientPath(FilePath: Text)
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if FilePath = '' then
            exit;
        if DirectoryHelper.Exists(FilePath) then
            exit;

        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(CreatePathQst, FilePath), true) then
            DirectoryHelper.CreateDirectory(FilePath)
        else
            Error('');
    end;

    procedure CreateFileNameWithExtension(FileNameWithoutExtension: Text; Extension: Text) FileName: Text
    begin
        FileName := FileNameWithoutExtension;
        if Extension <> '' then begin
            if Extension[1] <> '.' then
                FileName := FileName + '.';
            FileName := FileName + Extension;
        end
    end;

    procedure Ansi2SystemEncoding(Destination: OutStream; Source: InStream)
    var
        StreamReader: DotNet StreamReader;
        Encoding: DotNet Encoding;
        EncodedTxt: Text;
    begin
        StreamReader := StreamReader.StreamReader(Source, Encoding.Default, true);
        EncodedTxt := StreamReader.ReadToEnd;
        Destination.WriteText(EncodedTxt);
    end;

    procedure Ansi2SystemEncodingTxt(Destination: OutStream; Source: Text)
    var
        StreamWriter: DotNet StreamWriter;
        Encoding: DotNet Encoding;
    begin
        StreamWriter := StreamWriter.StreamWriter(Destination, Encoding.Default);
        StreamWriter.Write(Source);
        StreamWriter.Close;
    end;

    procedure BrowseForFolderDialog(WindowTitle: Text[50]; DefaultFolderName: Text; ShowNewFolderButton: Boolean): Text
    var
        [RunOnClient]
        FolderBrowserDialog: DotNet FolderBrowserDialog;
        [RunOnClient]
        DialagResult: DotNet DialogResult;
    begin
        FolderBrowserDialog := FolderBrowserDialog.FolderBrowserDialog;
        FolderBrowserDialog.Description := WindowTitle;
        FolderBrowserDialog.SelectedPath := DefaultFolderName;
        FolderBrowserDialog.ShowNewFolderButton := ShowNewFolderButton;

        DialagResult := FolderBrowserDialog.ShowDialog;
        if DialagResult.CompareTo(DialagResult.OK) = 0 then
            exit(FolderBrowserDialog.SelectedPath);
        exit(DefaultFolderName);
    end;

    procedure StripNotsupportChrInFileName(InText: Text): Text
    begin
        exit(DelChr(InText, '=', InvalidWindowsChrStringTxt));
    end;

    [Scope('OnPrem')]
    procedure ExportImage(ImagetPath: Text; ToFile: Text)
    var
        NameValueBuffer: Record "Name/Value Buffer";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileManagement: Codeunit "File Management";
    begin
        NameValueBuffer.DeleteAll();
        FileManagement.GetServerDirectoryFilesList(TempNameValueBuffer, TemporaryPath);
        TempNameValueBuffer.SetFilter(Name, StrSubstNo('%1*', ImagetPath));
        TempNameValueBuffer.FindFirst;
        ToFile := StripNotsupportChrInFileName(ToFile);
        Download(TempNameValueBuffer.Name, DownloadImageTxt, '', '', ToFile);
        if FileManagement.DeleteServerFile(TempNameValueBuffer.Name) then;
    end;

    [Scope('OnPrem')]
    procedure IsClientDirectoryEmpty(Path: Text): Boolean
    begin
        if DirectoryHelper.Exists(Path) then
            exit(DirectoryHelper.GetFiles(Path).Length = 0);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsServerDirectoryEmpty(Path: Text): Boolean
    begin
        if ServerDirectoryHelper.Exists(Path) then
            exit(ServerDirectoryHelper.GetFiles(Path).Length = 0);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetFileContent(FilePath: Text) Result: Text
    var
        FileHandle: File;
        InStr: InStream;
    begin
        if not FILE.Exists(FilePath) then
            exit;

        FileHandle.Open(FilePath, TEXTENCODING::UTF8);
        FileHandle.CreateInStream(InStr);

        InStr.ReadText(Result);
    end;

    procedure IsAllowedPath(Path: Text; SkipError: Boolean): Boolean
    var
        MembershipEntitlement: Record "Membership Entitlement";
        WebRequestHelper: Codeunit "Web Request Helper";
    begin
        if not MembershipEntitlement.IsEmpty then
            if not WebRequestHelper.IsHttpUrl(Path) then begin
                ClearLastError();
                if not FILE.IsPathTemporary(Path) then begin
                    if SkipError then
                        exit(false);
                    Error(NotAllowedPathErr, Path);
                end;
            end;
        exit(true)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetToFilterTextSetOutExt(FileName: Text; var OutExt: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUploadFileWithFilter(var ServerFileName: Text; WindowTitle: Text[50]; ClientFileName: Text; FileFilter: Text; ExtFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadFromStreamHandler(var ToFolder: Text; ToFileName: Text; FromInStream: InStream; var IsHandled: Boolean)
    begin
    end;

    procedure SaveStreamToFileServerFolder(var TempBlob: Codeunit "Temp Blob"; Name: Text; FileExtension: Text; InnerFolder: Text): Text
    //@param Name: File-s name
    //@param FileExtension: FileExtension
    //@param InnerFolder: In the case you want to create an inner folder inside the server folder. It must be in the form "folderName\" or "''". It will 
    // be created if does not exist.
    //@return Path to the file.
    var
        NVInStream: InStream;
        ServerFolderFilePath: Text;
        ServerDirectory: Text;
        NewPath: Text;
    begin
        TempBlob.CreateInStream(NVInStream);
        ServerFolderFilePath := InstreamExportToServerFile(NVInStream, FileExtension);
        ServerDirectory := GetDirectoryName(ServerFolderFilePath);
        if InnerFolder <> '' then
            ServerCreateDirectory(ServerDirectory + '\' + InnerFolder);
        NewPath := ServerDirectory + '\' + InnerFolder + Name;
        MoveAndRenameServerFile(ServerFolderFilePath, InnerFolder, Name);
        exit(NewPath);
    end;

    procedure MoveAndRenameServerFile(AbsolutePathToFile: Text; RelativePathFolder: Text; NewNameFile: Text)
    //@param AbsolutePathToFile: Absolute path to the file to rename.
    //@param RelativePathFolder: relative path starting from the server folder to the folder that will contain the file
    //  Start with the name of the folder without '\' and finish with '\': ex. 'folder\'. If you want to just rename the file without moving it
    // you can have to pass ''. In the eventual intern forlder/s, THEY MUST BE ALREADY CREATED.
    //@param NewNameFile: new file's name.
    var
        ServerDirectory: Text;
        newPath: Text;
    begin
        ServerDirectory := GetDirectoryName(AbsolutePathToFile);
        newPath := ServerDirectory + '\' + RelativePathFolder + NewNameFile;
        CopyServerFile(AbsolutePathToFile, newPath, true);
        DeleteServerFile(AbsolutePathToFile);
    end;
}

