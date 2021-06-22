codeunit 139016 "File Mgt. Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [File Management]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        FileMgt: Codeunit "File Management";
        LibraryUtility: Codeunit "Library - Utility";
        ExpectedFileNotFoundErr: Label 'does not exist.';
        ImportBlobFromServerFailedErr: Label 'Import blob from server failed.';
        ExpectedAlreadyExistsErr: Label 'already exists.';
        FileNotEmptyErr: Label 'Exported file is not empty.';
        AppendedFileErr: Label 'File is not appended.';
        TextStringTxt: Label 'This is the text string.';
        ServerFileErr: Label 'You must specify a source file name.';
        ClientFileErr: Label 'You must specify a target file name.';
        BLOBExportTxt: Label 'This is the text string that we want to store in a BLOB field.';
        ServerDirectoryHelper: DotNet Directory;
        [RunOnClient]
        ClientDirectoryHelper: DotNet Directory;
        [RunOnClient]
        ClientFileHelper: DotNet File;
        ServerPathHelper: DotNet Path;
        [RunOnClient]
        ClientPathHelper: DotNet Path;
        Initialized: Boolean;
        IncorrectFileNameErr: Label 'BLOB exported to incorrect file';
        FileNameChangedErr: Label 'File name has been changed.';

    [Test]
    [Scope('OnPrem')]
    procedure BlobExport()
    var
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text;
        BLOBContent: Text;
    begin
        Initialize;

        // Setup
        WriteToBlob(TempBlob, BLOBExportTxt);

        // Exercise
        ClientFileName := FileMgt.BLOBExport(TempBlob, 'Default.txt', false);

        // Verify
        BLOBContent := BLOBExportTxt; // Assign to Text to make Assert.AreEqual work
        Assert.IsTrue(TempBlob.HasValue, 'The blob field does not contain anything.');
        Assert.AreEqual(ClientFileHelper.ReadAllText(ClientFileName), BLOBContent,
          'The file content doesn''t match what was written to the BLOB');

        // Cleanup
        DeleteClientFile(ClientFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlobExportFileNameWithFolderAndCommonDialog()
    var
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text;
        ClientTempFileName: Text;
    begin
        // [FEATURE] [BLOB Export]
        // [SCENARIO] BLOB exported with predefined filename with folder and Common Dialog window

        Initialize;

        // [GIVEN] Temporary file name with folder = "X"
        WriteToBlob(TempBlob, BLOBExportTxt);
        ClientTempFileName := FileMgt.ClientTempFileName('');

        // [WHEN] Export BLOB using File Name = "X" and Common Dialog window
        ClientFileName := FileMgt.BLOBExport(TempBlob, ClientTempFileName, true);

        // [THEN] BLOB exported in File name = "X"
        Assert.AreEqual(ClientTempFileName, ClientFileName, IncorrectFileNameErr);

        // Cleanup
        DeleteClientFile(ClientFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestClientTempFileNameReturnsNonExistingFileInExistingDirectory()
    var
        ClientTempFile: Text;
    begin
        Initialize;

        ClientTempFile := FileMgt.ClientTempFileName('');

        Assert.IsTrue(StrLen(ClientTempFile) > 0, 'ClientTempFileName should not return an empty string');
        Assert.IsTrue(ClientDirectoryHelper.Exists(ClientPathHelper.GetDirectoryName(ClientTempFile)),
          'The directory containing the temporary file should exist');
        Assert.IsFalse(ClientFileHelper.Exists(ClientTempFile), 'The temporary file should not exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestClientTempFileNameLeavesNoTraceOnServer()
    var
        ServerFile: File;
        ServerTempDir: Text;
        NumFilesBefore: Integer;
    begin
        Initialize;

        // Get the path to the temporary folder used on the server
        ServerFile.CreateTempFile;
        ServerTempDir := ServerPathHelper.GetDirectoryName(ServerFile.Name);
        ServerFile.Close;

        // Count the number of files in the server temp folder
        NumFilesBefore := ServerDirectoryHelper.GetFiles(ServerTempDir).Length;

        // Make the call
        FileMgt.ClientTempFileName('');

        // Make sure the number of files is still the same
        if ServerDirectoryHelper.GetFiles(ServerTempDir).Length <> NumFilesBefore then
            Assert.Fail('Creating a temporary file without extension on the client left garbage on the server.');

        // Try again with extension
        FileMgt.ClientTempFileName('.cfg');
        if ServerDirectoryHelper.GetFiles(ServerTempDir).Length <> NumFilesBefore then
            Assert.Fail('Creating a temporary file with extension on the client left garbage on the server.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestClientTempFileNameLeavesNoTraceOnClient()
    var
        ClientTempFile: Text;
        ClientTempDir: Text;
        NumFilesBefore: Integer;
    begin
        Initialize;

        // Get the path to the temporary folder used on the client
        ClientTempFile := FileMgt.ClientTempFileName('');
        ClientTempDir := ClientPathHelper.GetDirectoryName(ClientTempFile);

        // Count the number of files in the client temp folder
        NumFilesBefore := ClientDirectoryHelper.GetFiles(ClientTempDir).Length;

        // Make the call
        FileMgt.ClientTempFileName('');

        // Make sure the number of files is still the same
        if ClientDirectoryHelper.GetFiles(ClientTempDir).Length <> NumFilesBefore then
            Assert.Fail('Creating a temporary file without extension on the client left garbage on the client.');

        // Try again with extension
        FileMgt.ClientTempFileName('.cfg');
        if ClientDirectoryHelper.GetFiles(ClientTempDir).Length <> NumFilesBefore then
            Assert.Fail('Creating a temporary file with extension on the client left garbage on the client.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestClientTempFileNameHasRightExtension()
    var
        Extension: Text;
        I: Integer;
        ActualExtension: Text;
        ClientTempFile: Text;
    begin
        Initialize;

        // Test without extension
        ClientTempFile := FileMgt.ClientTempFileName('');
        ActualExtension := ClientPathHelper.GetExtension(ClientTempFile);
        Assert.AreEqual('', ActualExtension, 'Extension for temporary file was ' + ActualExtension + ', but should be extensionless.');
        Assert.IsFalse(ClientTempFile[StrLen(ClientTempFile)] = '.', 'Extensionless file name should not end in period.');

        // Test with extensions of different length
        for I := 1 to 10 do begin
            Extension := PadStr('html', I, 'x');
            ClientTempFile := FileMgt.ClientTempFileName(Extension);
            ActualExtension := ClientPathHelper.GetExtension(ClientTempFile);
            Assert.AreEqual('.' + Extension, ActualExtension,
              'Extension for temporary file was "' + ActualExtension + '", but should be "' + Extension + '".');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateClientTempSubDirectoryReturnsExistingDirectory()
    var
        TempSubDir: Text;
    begin
        Initialize;

        TempSubDir := FileMgt.CreateClientTempSubDirectory;

        Assert.IsTrue(ClientDirectoryHelper.Exists(TempSubDir), 'The directory should exist');

        ClientDirectoryHelper.Delete(TempSubDir);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateClientTempSubDirectoryReturnsEmptyDirectory()
    var
        TempSubDir: Text;
        TempDir: Text;
        ExpectedCountOfFiles: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 234665] Consequent calls of COD419.CreateClientTempSubDirectory function does not leave rubbish files
        Initialize;

        TempSubDir := FileMgt.CreateClientTempSubDirectory;
        Assert.AreEqual(0, ClientDirectoryHelper.GetFiles(TempSubDir).Length, 'The temp sub directory should be empty');
        TempDir := FileMgt.GetDirectoryName(TempSubDir);

        ExpectedCountOfFiles := ClientDirectoryHelper.GetFiles(TempDir).Length;

        TempSubDir := FileMgt.CreateClientTempSubDirectory;

        Assert.AreEqual(0, ClientDirectoryHelper.GetFiles(TempSubDir).Length, 'The temp sub directory should be empty');
        Assert.AreEqual(ExpectedCountOfFiles, ClientDirectoryHelper.GetFiles(TempDir).Length, 'The temp directory should be empty');

        ClientDirectoryHelper.Delete(TempSubDir);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateClientTempSubDirectoryReturnsTempSubDirectory()
    var
        ClientTempDir: Text;
        TempSubDir: Text;
    begin
        Initialize;

        ClientTempDir := ClientPathHelper.GetDirectoryName(FileMgt.ClientTempFileName(''));
        TempSubDir := FileMgt.CreateClientTempSubDirectory;

        Assert.AreEqual(ClientTempDir, ClientPathHelper.GetDirectoryName(TempSubDir),
          'The directory should be in the client temp directory');

        ClientDirectoryHelper.Delete(TempSubDir);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetServerTempFile()
    var
        ServerTempFile: Text;
    begin
        Initialize;
        ServerTempFile := FileMgt.ServerTempFileName('');

        Assert.IsTrue(StrLen(ServerTempFile) > 0, 'The server temp file cannot be empty.');
        Assert.IsTrue(ServerDirectoryHelper.Exists(ServerPathHelper.GetDirectoryName(ServerTempFile)),
          'The directory does not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClientFileExist()
    var
        FileName: Text;
        FileExist: Boolean;
    begin
        Initialize;

        FileName := CreateClientFile;
        FileExist := FileMgt.ClientFileExists(FileName);
        Assert.IsTrue(FileExist, 'The client file does not exist');

        // Cleanup
        DeleteClientFile(FileName);

        FileName := '';
        FileExist := FileMgt.ClientFileExists(FileName);

        Assert.IsFalse(FileExist, 'The client file does exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClientDirectoryExist()
    var
        DirectoryName: Text;
        FileName: Text;
        DirectoryExist: Boolean;
    begin
        Initialize;

        FileName := CreateClientFile;
        DirectoryName := ClientPathHelper.GetDirectoryName(FileName);

        DirectoryExist := FileMgt.ClientDirectoryExists(DirectoryName);
        Assert.IsTrue(DirectoryExist, 'The directory does not exist');

        // Cleanup
        DeleteClientFile(FileName);

        DirectoryName := '';
        DirectoryExist := FileMgt.ClientDirectoryExists(DirectoryName);
        Assert.IsFalse(DirectoryExist, 'The directory does exist');

        DirectoryName := 'c:\doesnotexistsdirectory';
        DirectoryExist := FileMgt.ClientDirectoryExists(DirectoryName);
        Assert.IsFalse(DirectoryExist, 'The directory does exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyClientFile()
    var
        FileName: Text;
        FileNameNew: Text;
    begin
        Initialize;

        FileName := CreateClientFile;
        FileNameNew := CreateClientFile;
        FileMgt.CopyClientFile(FileName, FileNameNew, true);
        Assert.IsTrue(VerifyClientFileExist(FileNameNew), 'The client file does not exist');

        // Cleanup
        DeleteClientFile(FileName);
        DeleteClientFile(FileNameNew);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClientFileDelete()
    var
        FileName: Text;
        FileExist: Boolean;
    begin
        Initialize;

        FileName := CreateClientFile;
        FileExist := FileMgt.DeleteClientFile(FileName);
        Assert.IsTrue(FileExist, 'The client file is not deleted.');

        FileName := '';
        FileExist := FileMgt.DeleteClientFile(FileName);
        Assert.IsFalse(FileExist, 'The client file does not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetToFilterTextDoc()
    var
        "Filter": Text;
    begin
        Initialize;

        Filter := FileMgt.GetToFilterText('Movie Files (*.avi)|*.avi', '');
        Assert.AreEqual('Movie Files (*.avi)|*.avi', Filter, 'Filter is not the expected one');

        Filter := FileMgt.GetToFilterText('', 'filename.doc');
        Assert.IsTrue(StrPos(Filter, '*.doc)|*.doc') > 0, 'Could not identify filter for DOC file type');

        Filter := FileMgt.GetToFilterText('', 'filename.docx');
        Assert.IsTrue(StrPos(Filter, '|*.docx;*.doc') > 0, 'Filter for DOCX file type did not include both *.doc and *.docx');

        Filter := FileMgt.GetToFilterText('', 'filename.xls');
        Assert.IsTrue(StrPos(Filter, '*.xls)|*.xls') > 0, 'Could not identify filter for XLS file type');

        Filter := FileMgt.GetToFilterText('', 'filename.xlsx');
        Assert.IsTrue(StrPos(Filter, '|*.xlsx;*.xls') > 0, 'Filter for XLSX file type did not include both *.xls and *.xlsx');

        Filter := FileMgt.GetToFilterText('', 'filename.txt');
        Assert.IsTrue(StrPos(Filter, '*.txt)|*.txt') > 0, 'Could not identify filter for TXT file type');

        Filter := FileMgt.GetToFilterText('', 'filename.htm');
        Assert.IsTrue(StrPos(Filter, '*.htm)|*.htm') > 0, 'Could not identify filter for HTM file type');

        Filter := FileMgt.GetToFilterText('', 'filename.xml');
        Assert.IsTrue(StrPos(Filter, '*.xml)|*.xml') > 0, 'Could not identify filter for XML file type');

        Filter := FileMgt.GetToFilterText('', 'filename.xsd');
        Assert.IsTrue(StrPos(Filter, '*.xsd)|*.xsd') > 0, 'Could not identify filter for XSD file type');

        Filter := FileMgt.GetToFilterText('', 'filename.xslt');
        Assert.IsTrue(StrPos(Filter, '*.xslt)|*.xslt') > 0, 'Could not identify filter for XSLT file type');

        Filter := FileMgt.GetToFilterText('', 'filename.rdl');
        Assert.IsTrue(StrPos(Filter, '*.rdl;*.rdlc)|*.rdl') > 0, 'Could not identify filter for RDL file type');

        Filter := FileMgt.GetToFilterText('', 'filename.rdlc');
        Assert.IsTrue(StrPos(Filter, '|*.rdl;*.rdlc') > 0, 'Filter for RDLC file type did not include both *.rdl and *.rdlc');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveAndRenameClientFile()
    var
        NewFileName: Text;
        OldFileName: Text;
    begin
        Initialize;

        OldFileName := CreateClientFile;
        NewFileName := FileMgt.MoveAndRenameClientFile(OldFileName, 'NewFileName.TMP', 'SubDir');
        Assert.IsFalse(VerifyClientFileExist(OldFileName), 'The old client file does exist.');
        Assert.IsTrue(VerifyClientFileExist(NewFileName), 'The new client file does not exist.');

        // Cleanup
        DeleteClientFile(NewFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveAndRenameClientFileBlankNewFileName()
    var
        OldFileName: Text;
    begin
        Initialize;

        OldFileName := CreateClientFile;
        asserterror FileMgt.MoveAndRenameClientFile(OldFileName, '', 'SubDir');

        // Cleanup
        DeleteClientFile(OldFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveAndRenameClientFileBlankOldFilePath()
    begin
        Initialize;

        asserterror FileMgt.MoveAndRenameClientFile('', 'NewFileName.TMP', 'SubDir');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveAndRenameClientFileOldFilePathDoNotExist()
    begin
        Initialize;

        asserterror FileMgt.MoveAndRenameClientFile('randomfilename.txt', 'NewFileName.TMP', 'SubDir');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveFileToFileWithSameName()
    var
        OldFileName: Text;
    begin
        Initialize;

        OldFileName := CreateClientFile;

        // exercise
        FileMgt.MoveFile(OldFileName, OldFileName);

        // verify
        // Bug 101134: When called with same source and target file name,
        // the MoveFile would delete the target file (which is also the source file) and then fail to move it
        // you would end up deleting the file
        Assert.IsTrue(FileMgt.ClientFileExists(OldFileName), 'File ' + OldFileName + ' has been deleted.');

        // Cleanup
        DeleteClientFile(OldFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveFileToFileWithSimilarName()
    var
        OldFileName: Text;
    begin
        Initialize;

        OldFileName := CreateClientFile;

        // exercise
        FileMgt.MoveFile(LowerCase(OldFileName), UpperCase(OldFileName));

        // verify
        // Bug 101134: When called with same source and target file name,
        // the MoveFile would delete the target file (which is also the source file) and then fail to move it
        // you would end up deleting the file
        Assert.IsTrue(FileMgt.ClientFileExists(OldFileName), 'File ' + OldFileName + ' has been deleted.');

        // Cleanup
        DeleteClientFile(OldFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UploadFileSilent()
    var
        ClientFileName: Text;
        ServerFileName: Text;
    begin
        Initialize;

        ClientFileName := CreateClientFile;
        ServerFileName := FileMgt.UploadFileSilent(ClientFileName);
        Assert.AreNotEqual(ClientFileName, ServerFileName, 'Server and client filename is the same.');

        // Cleanup
        DeleteClientFile(ClientFileName);
        Erase(ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UploadFileToServer()
    var
        ClientFileName: Text;
        ServerFileName: Text;
    begin
        Initialize;

        ClientFileName := CreateClientFile;
        ServerFileName := FileMgt.UploadFileToServer(ClientFileName);
        Assert.AreNotEqual(ClientFileName, ServerFileName, 'Expected taht the file is uploaded silently.');

        // Cleanup
        DeleteClientFile(ClientFileName);
        Erase(ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadFile()
    var
        ClientFileName: Text;
        ServerFileName: Text;
        TextArray: array[10] of Text[30];
    begin
        Initialize;

        CreateExpectedTexts(TextArray, 1);
        ServerFileName := CreateTextFileOnServerWithExtension(TextArray, 1, 'txt');
        ClientFileName := CreateClientFile;
        FileMgt.DownloadToFile(ServerFileName, ClientFileName);

        Assert.AreNotEqual(ClientFileName, ServerFileName, 'Server and client filename is the same.');
        Assert.IsTrue(VerifyClientFileExist(ClientFileName), 'The client file does not exist.');

        // Cleanup
        DeleteClientFile(ClientFileName);
        Erase(ServerFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDownloadFileThrowsErrorIfSourceNotSpecified()
    begin
        Initialize;

        asserterror FileMgt.DownloadToFile('', 'SomeTargetFileName');

        Assert.ExpectedError(ServerFileErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDownloadFileThrowsErrorIfTargetNotSpecified()
    begin
        Initialize;

        asserterror FileMgt.DownloadToFile('SomeSourceFileName', '');

        Assert.ExpectedError(ClientFileErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorOnAppendToFileWhenServerFileNameIsBlank()
    var
        FileManagement: Codeunit "File Management";
        ClientFileName: Text;
    begin
        Initialize;
        ClientFileName := CreateClientFile;
        asserterror FileManagement.AppendAllTextToClientFile('', ClientFileName);
        Assert.ExpectedError(ServerFileErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorOnAppendToFileWhenClientFileNameIsBlank()
    var
        FileManagement: Codeunit "File Management";
        ServerFileName: Text;
    begin
        Initialize;
        ServerFileName := FileManagement.ServerTempFileName('');
        asserterror FileManagement.AppendAllTextToClientFile(ServerFileName, '');
        Assert.ExpectedError(ClientFileErr);
    end;

    [Normal]
    local procedure CheckClientDirectoryExist(FileName: Text): Boolean
    begin
        if FileName = '' then
            exit(false);

        exit(ClientDirectoryHelper.Exists(ClientPathHelper.GetDirectoryName(FileName)));
    end;

    [Normal]
    local procedure CreateClientFile(): Text
    begin
        exit(ClientPathHelper.GetTempFileName);
    end;

    [Normal]
    local procedure DeleteClientFile(FileName: Text)
    begin
        ClientFileHelper.Delete(FileName);
    end;

    [Normal]
    local procedure VerifyClientFileExist(FileName: Text): Boolean
    begin
        exit(ClientFileHelper.Exists(FileName));
    end;

    local procedure WriteToBlob(var TempBlob: Codeunit "Temp Blob"; Content: Text)
    var
        OStream: OutStream;
        BigStr: BigText;
    begin
        Clear(BigStr);
        Clear(TempBlob);
        BigStr.AddText(Content);
        TempBlob.CreateOutStream(OStream);
        BigStr.Write(OStream);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UploadNormalFile()
    var
        FileMgt: Codeunit "File Management";
        FileAttributes: DotNet FileAttributes;
        Content: Text[1024];
        FileName: Text;
        UploadedFileName: Text;
    begin
        // Pre-Setup
        Content := LibraryUtility.GenerateGUID;

        // Setup
        FileName := CreateNonEmptyTextFile(Content);
        ClientFileHelper.SetAttributes(FileName, FileAttributes.Normal);

        // Exercise
        UploadedFileName := FileMgt.UploadFileSilent(FileName);

        // Verify
        VerifyUploadedFile(UploadedFileName, Content);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UploadReadOnlyFile()
    var
        FileMgt: Codeunit "File Management";
        FileAttributes: DotNet FileAttributes;
        Content: Text[1024];
        FileName: Text;
        UploadedFileName: Text;
    begin
        // Pre-Setup
        Content := LibraryUtility.GenerateGUID;

        // Setup
        FileName := CreateNonEmptyTextFile(Content);
        ClientFileHelper.SetAttributes(FileName, FileAttributes.ReadOnly);

        // Exercise
        UploadedFileName := FileMgt.UploadFileSilent(FileName);

        // Verify
        VerifyUploadedFile(UploadedFileName, Content);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServerDirectoryExist()
    var
        DirectoryName: Text;
        FileName: Text;
        DirectoryExist: Boolean;
    begin
        Initialize;

        FileName := FileMgt.ServerTempFileName('txt');
        DirectoryName := ServerPathHelper.GetDirectoryName(FileName);

        DirectoryExist := FileMgt.ClientDirectoryExists(DirectoryName);
        Assert.IsTrue(DirectoryExist, 'The directory does not exist');

        DirectoryName := '';
        DirectoryExist := FileMgt.ServerDirectoryExists(DirectoryName);
        Assert.IsFalse(DirectoryExist, 'The directory does exist');

        DirectoryName := 'c:\doesnotexistsdirectory';

        DirectoryExist := FileMgt.ServerDirectoryExists(DirectoryName);
        Assert.IsFalse(DirectoryExist, 'The directory does exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServerCreateDirectory()
    var
        FileName: Text;
    begin
        FileName := FileMgt.ServerTempFileName('.txt');
        Assert.IsFalse(FileMgt.ServerDirectoryExists(FileName), 'The directory should not exist.');
        FileMgt.ServerCreateDirectory(FileName);
        Assert.IsTrue(FileMgt.ServerDirectoryExists(FileName), 'The directory should exist.');
        FileMgt.ServerCreateDirectory(FileName);
        Assert.IsTrue(FileMgt.ServerDirectoryExists(FileName), 'The directory should exist.');
        FileMgt.ServerRemoveDirectory(FileName, true);
        Assert.IsFalse(FileMgt.ServerDirectoryExists(FileName), 'The directory should not exist.');
        FileMgt.ServerRemoveDirectory(FileName, true);
        Assert.IsFalse(FileMgt.ServerDirectoryExists(FileName), 'The directory should not exist.');

        FileName := FileMgt.ClientTempFileName('.txt');
        Assert.IsFalse(FileMgt.ClientDirectoryExists(FileName), 'The directory should not exist.');
        FileMgt.CreateClientDirectory(FileName);
        Assert.IsTrue(FileMgt.ClientDirectoryExists(FileName), 'The directory should exist.');
        FileMgt.CreateClientDirectory(FileName);
        Assert.IsTrue(FileMgt.ClientDirectoryExists(FileName), 'The directory should exist.');
        FileMgt.DeleteClientDirectory(FileName);
        Assert.IsFalse(FileMgt.ClientDirectoryExists(FileName), 'The directory should not exist.');
        FileMgt.DeleteClientDirectory(FileName);
        Assert.IsFalse(FileMgt.ClientDirectoryExists(FileName), 'The directory should not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSafeFileName()
    var
        PathHelper: DotNet Path;
        DotNetString: DotNet String;
        FileName: Text;
        Str: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379537] GetSafeFileName should remove invalid characters (colon, etc) in the file name
        Initialize;

        DotNetString := FileName;
        foreach Str in DotNetString.Split(PathHelper.GetInvalidFileNameChars) do
            FileName += Str;
        FileName += 'Default.docx';

        FileName := FileMgt.GetSafeFileName(FileName);

        Assert.AreEqual('Default.docx', FileName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UploadClientDirectorySilentWithLastSlashUT()
    var
        RelativeServerPath: Text;
        DirectoryPath: Text;
        FileName: Text;
        ClientFullPath: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 265298] Filemgt.UploadClientDirectorySilent must not cut 1st symbol of file name if DirectoryPath has ending slash
        Initialize;

        ClientFullPath := FileMgt.ClientTempFileName('.txt'); // c:\temp\Test\Test.txt
        DirectoryPath := FileMgt.GetDirectoryName(ClientFullPath) + '\'; // c:\temp\Test\
        FileName := FileMgt.GetFileName(ClientFullPath); // Test.txt

        FileMgt.CreateClientDirectory(DirectoryPath);
        FileMgt.CreateClientFile(FileMgt.CombinePath(DirectoryPath, FileName));
        RelativeServerPath := FileMgt.UploadClientDirectorySilent(DirectoryPath, '*.*', false);
        Assert.IsTrue(FileMgt.ServerFileExists(FileMgt.CombinePath(RelativeServerPath, FileName)), FileNameChangedErr);

        FileMgt.DeleteClientFile(ClientFullPath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UploadClientDirectorySilentWithoutLastSlashUT()
    var
        RelativeServerPath: Text;
        DirectoryPath: Text;
        FileName: Text;
        ClientFullPath: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 265298] Filemgt.UploadClientDirectorySilent must not cut 1st symbol of file name if DirectoryPath has no ending slash
        Initialize;

        ClientFullPath := FileMgt.ClientTempFileName('.txt'); // c:\temp\Test\Test.txt
        DirectoryPath := FileMgt.GetDirectoryName(ClientFullPath); // c:\temp\Test
        FileName := FileMgt.GetFileName(ClientFullPath); // Test.txt

        FileMgt.CreateClientDirectory(DirectoryPath);
        FileMgt.CreateClientFile(FileMgt.CombinePath(DirectoryPath, FileName));
        RelativeServerPath := FileMgt.UploadClientDirectorySilent(DirectoryPath, '*.*', false);
        Assert.IsTrue(FileMgt.ServerFileExists(FileMgt.CombinePath(RelativeServerPath, FileName)), FileNameChangedErr);

        FileMgt.DeleteClientFile(ClientFullPath);
    end;

    [Normal]
    local procedure Initialize()
    begin
        if not Initialized then
            Initialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileNameNonBlank()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        Initialize;
        FileName := FileManagement.GetFileName('c:\temp\Test001.txt');
        Assert.AreEqual('Test001.txt', FileName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileNameBlank()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        Initialize;
        FileName := FileManagement.GetFileName('');
        Assert.AreEqual('', FileName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileNameNoExtension()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        Initialize;
        FileName := FileManagement.GetFileName('c:\temp\Test001');
        Assert.AreEqual('Test001', FileName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileNameWithSpaces()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        Initialize;
        FileName := FileManagement.GetFileName('c:\temp\Test 001.txt');
        Assert.AreEqual('Test 001.txt', FileName, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDirectory()
    var
        ClientFileName: Text;
        PathName: Text;
    begin
        Initialize;

        ClientFileName := CreateClientFile;
        PathName := FileMgt.GetDirectoryName(ClientFileName);
        Assert.IsTrue(CheckClientDirectoryExist(PathName), 'Path did not exist.');

        // Cleanup
        DeleteClientFile(ClientFileName);

        ClientFileName := 'clientfilenamewithoutpath.txt';
        PathName := FileMgt.GetDirectoryName(ClientFileName);
        Assert.AreEqual('', PathName, 'Path should be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDirectoryFileNameBlank()
    var
        PathName: Text;
    begin
        Initialize;

        PathName := FileMgt.GetDirectoryName('');
        Assert.AreEqual('', PathName, 'Path should be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetClientDirectoryFilesListCount()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        [RunOnClient]
        ClientStream: DotNet Stream;
        ClientFileName: Text;
        ClientDirectoryName: Text;
        InitialFilesCount: Integer;
    begin
        // [SCENARIO 121134] "File Management".GetClientDirectoryFilesList() returns correct files count
        Initialize;

        // [GIVEN] Current client directory files count = InititalFilesCount
        ClientFileName := FileMgt.ClientTempFileName('');
        ClientDirectoryName := FileMgt.GetDirectoryName(ClientFileName);
        FileMgt.GetClientDirectoryFilesList(TempNameValueBuffer, ClientDirectoryName);
        InitialFilesCount := TempNameValueBuffer.Count;

        // [WHEN] Create client file
        ClientFileName := FileMgt.ClientTempFileName('');
        ClientStream := ClientFileHelper.Create(ClientFileName);
        ClientStream.Close;

        // [THEN] Client directory new files count = InitialFilesCount + 1
        FileMgt.GetClientDirectoryFilesList(TempNameValueBuffer, ClientDirectoryName);
        Assert.AreEqual(1, TempNameValueBuffer.Count - InitialFilesCount, '');

        // TearDown
        FileMgt.DeleteClientFile(ClientFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetClientDirectoryFilesListName()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        ClientFileName: Text;
        ClientDirectoryName: Text;
        FileIsFound: Boolean;
    begin
        // [SCENARIO 121134] "File Management".GetClientDirectoryFilesList() return correct file name
        Initialize;

        // [GIVEN] Create client file
        ClientFileName := FileMgt.ClientTempFileName('');
        FileMgt.CreateClientFile(ClientFileName);
        ClientDirectoryName := FileMgt.GetDirectoryName(ClientFileName);
        FileMgt.GetClientDirectoryFilesList(TempNameValueBuffer, ClientDirectoryName);

        // [WHEN] Find created file in client directory
        FileIsFound := false;
        if TempNameValueBuffer.FindSet then
            repeat
                FileIsFound := StrPos(TempNameValueBuffer.Name, ClientFileName) = 1;
            until FileIsFound or (TempNameValueBuffer.Next = 0);

        // [THEN] Created client file is found
        Assert.IsTrue(FileIsFound, '');

        // TearDown
        FileMgt.DeleteClientFile(ClientFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetClientFileProperties()
    var
        TextArray: array[10] of Text[30];
        ServerFileName: Text;
        ClientFileName: Text;
        FileDate: Date;
        FileTime: Time;
        FileSize: BigInteger;
        ExpectedFileSize: BigInteger;
    begin
        // [SCENARIO 121134] "File Management".GetClientFileProperties()
        Initialize;

        // [GIVEN] Create server file with text string, download to client
        TextArray[1] := TextStringTxt;
        ServerFileName := CreateTextFileOnServer(TextArray, 1);
        ClientFileName := FileMgt.ClientTempFileName('');
        FileMgt.DownloadToFile(ServerFileName, ClientFileName);

        // [WHEN] Read client file properties
        FileMgt.GetClientFileProperties(ClientFileName, FileDate, FileTime, FileSize);

        // [THEN] Client file has: Date=TODAY, Time=CurrentTime+-10sec, Size=string length + 2(special symbols)
        Assert.AreEqual(Today, FileDate, '');
        Assert.IsTrue(Abs(Time - FileTime) < 10000, '');
        ExpectedFileSize := StrLen(TextArray[1]) + 2;
        Assert.AreEqual(ExpectedFileSize, FileSize, '');

        // TearDown
        FileMgt.DeleteServerFile(ServerFileName);
        FileMgt.DeleteClientFile(ClientFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportTempBlobFileNotFoundTest()
    var
        TempBlob: Codeunit "Temp Blob";
        TempFileName: Text;
    begin
        Initialize;
        TempFileName := FileMgt.ServerTempFileName('');
        asserterror FileMgt.BLOBImportFromServerFile(TempBlob, TempFileName);
        Assert.ExpectedError(ExpectedFileNotFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportExportBlobHasTheSameContentTest()
    var
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        ExportFileName: Text;
        TextArray: array[10] of Text[30];
    begin
        Initialize;
        ExportFileName := FileMgt.ServerTempFileName('');
        CreateExpectedTexts(TextArray, 2);
        FileName := CreateTextFileOnServer(TextArray, 2);
        FileMgt.BLOBImportFromServerFile(TempBlob, FileName);
        FileMgt.BLOBExportToServerFile(TempBlob, ExportFileName);
        Assert.IsTrue(ValidateExportedServerFile(ExportFileName, TextArray, 2), ImportBlobFromServerFailedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportBlobToServerToExistingFileTest()
    var
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        TextArray: array[10] of Text[30];
    begin
        Initialize;
        CreateExpectedTexts(TextArray, 1);
        FileName := CreateTextFileOnServer(TextArray, 1);
        asserterror FileMgt.BLOBExportToServerFile(TempBlob, FileName);
        Assert.ExpectedError(ExpectedAlreadyExistsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportEmptyBlobToServer()
    var
        TempBlob: Codeunit "Temp Blob";
        ExportedFile: File;
        FileName: Text;
        TempText: Text[1024];
    begin
        Initialize;
        FileName := FileMgt.ServerTempFileName('');
        FileMgt.BLOBExportToServerFile(TempBlob, FileName);
        ExportedFile.WriteMode(false);
        ExportedFile.TextMode(true);
        ExportedFile.Open(FileName);
        Assert.IsTrue(ExportedFile.Read(TempText) = 0, FileNotEmptyErr);
        ExportedFile.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportInstreamToServerFile()
    var
        TempBlob: Codeunit "Temp Blob";
        File: File;
        InStream: InStream;
        OutStream: OutStream;
        Content: Text;
        FileName: Text;
    begin
        Initialize;
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('hello world');
        TempBlob.CreateInStream(InStream);
        FileName := FileMgt.InstreamExportToServerFile(InStream, 'html');
        File.Open(FileName);
        File.CreateInStream(InStream);
        InStream.ReadText(Content);
        Assert.AreEqual('hello world', Content, 'file content does not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateAndWriteToServerFile()
    var
        File: File;
        InStream: InStream;
        Content: Text;
        FileName: Text;
    begin
        Initialize;
        FileName := FileMgt.CreateAndWriteToServerFile('hello world', 'html');
        File.Open(FileName);
        File.CreateInStream(InStream);
        InStream.ReadText(Content);
        Assert.AreEqual('hello world', Content, 'file content does not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetServerDirectoryFilesListInclSubDirs()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        File: File;
        DirectoryPath: Text;
        Names: array[5] of Text;
        Index: Integer;
    begin
        // [SCERNARIO] A list of every file under a directory is returned including subdirectories
        DirectoryPath := FileMgt.ServerCreateTempSubDirectory;
        FileMgt.ServerCreateDirectory(DirectoryPath + '\Temp');

        Names[1] := DirectoryPath + '\file1.txt';
        Names[2] := DirectoryPath + '\file2.txt';
        Names[3] := DirectoryPath + '\file3.txt';
        Names[4] := DirectoryPath + '\Temp\file1.txt';
        Names[5] := DirectoryPath + '\Temp\file2.txt';

        // [GIVEN] 3 files are contained directly under the folder
        File.Create(Names[1]);
        File.Close;

        File.Create(Names[2]);
        File.Close;

        File.Create(Names[3]);
        File.Close;

        // [GIVEN] 2 files are contained in a subfolder
        File.Create(Names[4]);
        File.Close;

        File.Create(Names[5]);
        File.Close;

        // [WHEN] GetAllFilesUnderDirectory function is called
        FileMgt.GetServerDirectoryFilesListInclSubDirs(TempNameValueBuffer, DirectoryPath);

        // [THEN] 5 files are found
        Assert.RecordCount(TempNameValueBuffer, 5);

        TempNameValueBuffer.FindSet;
        for Index := 1 to 5 do begin
            Assert.AreEqual(TempNameValueBuffer.Name, Names[Index], 'name was different');
            TempNameValueBuffer.Next;
        end;

        // Clean up
        FileMgt.DeleteServerFile(DirectoryPath + '\Temp\file1.txt');
        FileMgt.DeleteServerFile(DirectoryPath + '\Temp\file2.txt');
        FileMgt.DeleteServerFile(DirectoryPath + '\file1.txt');
        FileMgt.DeleteServerFile(DirectoryPath + '\file2.txt');
        FileMgt.DeleteServerFile(DirectoryPath + '\file3.txt');
        FileMgt.DeleteClientDirectory(DirectoryPath + '\Temp');
        FileMgt.DeleteClientDirectory(DirectoryPath);
    end;

    local procedure CreateTextFileOnServerWithExtension(TextArray: array[10] of Text[30]; NoOfElements: Integer; FileExtension: Text[5]) FileName: Text
    var
        FileManagement: Codeunit "File Management";
        File: File;
        Counter: Integer;
    begin
        FileName := FileManagement.ServerTempFileName(FileExtension);
        File.WriteMode(true);
        File.TextMode(true);
        File.Create(FileName);
        for Counter := 1 to NoOfElements do
            File.Write(TextArray[Counter]);
        File.Close;
    end;

    local procedure CreateTextFileOnServer(TextArray: array[10] of Text[30]; NoOfElements: Integer) FileName: Text
    begin
        FileName := CreateTextFileOnServerWithExtension(TextArray, NoOfElements, '');
    end;

    local procedure ValidateExportedServerFile(FileName: Text; TextArray: array[10] of Text[30]; NoOfElements: Integer): Boolean
    var
        StreamReader: DotNet StreamReader;
        Result: Boolean;
    begin
        StreamReader := StreamReader.StreamReader(FileName);
        Result := ValidateExportedFile(StreamReader, TextArray, NoOfElements);
        StreamReader.Close;
        exit(Result);
    end;

    local procedure ValidateExportedClientFile(FileName: Text; TextArray: array[10] of Text[30]; NoOfElements: Integer): Boolean
    var
        [RunOnClient]
        StreamReader: DotNet StreamReader;
        Result: Boolean;
    begin
        StreamReader := StreamReader.StreamReader(FileName);
        Result := ValidateExportedFile(StreamReader, TextArray, NoOfElements);
        StreamReader.Close;
        exit(Result);
    end;

    local procedure ValidateExportedFile(var StreamReader: DotNet StreamReader; TextArray: array[10] of Text[30]; NoOfElements: Integer): Boolean
    var
        ReadData: Text[30];
        Counter: Integer;
    begin
        Counter := 1;
        while Counter <= NoOfElements do begin
            ReadData := StreamReader.ReadLine;
            if (ReadData = '') or (ReadData <> TextArray[Counter]) then
                exit(false);
            Counter := Counter + 1
        end;
        exit(Counter > NoOfElements);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsValidFileNameTest()
    var
        FileName: Text;
    begin
        FileName := 'WithoutExtension';
        Assert.IsTrue(FileMgt.IsValidFileName(FileName), 'File name without extension should be valid.');

        FileName := 'WithExtension.txt';
        Assert.IsTrue(FileMgt.IsValidFileName(FileName), 'File name with extension should be valid.');

        FileName := 'WithExtension.ext1.txt';
        Assert.IsTrue(FileMgt.IsValidFileName(FileName), 'File name with two dots should be valid.');

        FileName := '';
        Assert.IsFalse(FileMgt.IsValidFileName(FileName), 'Empty file name.');

        FileName := '*';
        Assert.IsFalse(FileMgt.IsValidFileName(FileName), 'File name of one invalid char.');

        FileName := '*InvalidAtStart';
        Assert.IsFalse(FileMgt.IsValidFileName(FileName), 'File name with invalid char at the beginning should not be valid.');

        FileName := 'InvalidAtEnd?';
        Assert.IsFalse(FileMgt.IsValidFileName(FileName), 'File name with invalid char at the end should not be valid.');

        FileName := 'Invalid?InMiddle';
        Assert.IsFalse(FileMgt.IsValidFileName(FileName), 'File name with invalid char in the middle should not be valid.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppendToFile()
    var
        ClientFileName: Text;
        ServerFileName: Text;
        TextArray: array[10] of Text[30];
    begin
        Initialize;
        CreateExpectedTexts(TextArray, 2);
        ServerFileName := CreateOneLineTextFileOnServer(TextArray[1]);
        ClientFileName := CreateClientFile;
        FileMgt.DownloadToFile(ServerFileName, ClientFileName);
        ServerFileName := CreateOneLineTextFileOnServer(TextArray[2]);
        FileMgt.AppendAllTextToClientFile(ServerFileName, ClientFileName);
        Assert.IsTrue(ValidateExportedClientFile(ClientFileName, TextArray, 2), AppendedFileErr); // check that both values are in the appended file
    end;

    local procedure CreateExpectedTexts(var TextArray: array[10] of Text[30]; NoOfElements: Integer)
    var
        Counter: Integer;
    begin
        for Counter := 1 to NoOfElements do
            TextArray[Counter] := TextStringTxt + Format(Counter);
    end;

    local procedure CreateOneLineTextFileOnServer(Text: Text[30]): Text
    var
        TmpTextArray: array[1] of Text[30];
    begin
        TmpTextArray[1] := Text;
        exit(CreateTextFileOnServer(TmpTextArray, 1));
    end;

    local procedure CreateNonEmptyTextFile(Content: Text[1024]) FileName: Text
    var
        FileMgt: Codeunit "File Management";
        InputFile: File;
        OutStream: OutStream;
    begin
        FileName := FileMgt.ServerTempFileName('txt');

        with InputFile do begin
            WriteMode := true;
            TextMode := true;
            Create(FileName);
            CreateOutStream(OutStream);
            OutStream.WriteText(Content);
            Close;
        end;
    end;

    local procedure VerifyUploadedFile(FileName: Text; Content: Text[1024])
    var
        UploadedFile: File;
        ActualContent: Text[1024];
    begin
        with UploadedFile do begin
            WriteMode := false;
            TextMode := true;
            Open(FileName);
            Assert.AreNotEqual(0, Len, 'Uploaded file is empty.');
            Read(ActualContent);
            Assert.AreEqual(Content, ActualContent, 'Uploaded file''s content is different.');
            Close;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveFileDialogWebClientUsage()
    var
        FileManagement: Codeunit "File Management";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [FEATURE] [UT] [Web Client]
        // [SCENARIO 275156] SaveFileDialog returns empty value if called from Web Client
        Initialize;

        // [GIVEN] Web client
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);

        // [WHEN] FileManagement.SaveFileDialog is called
        // [THEN] Empty value is returned
        Assert.AreEqual('', FileManagement.SaveFileDialog('', '', ''), '');
    end;
}

