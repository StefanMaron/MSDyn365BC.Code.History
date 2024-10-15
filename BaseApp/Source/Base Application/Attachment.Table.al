table 5062 Attachment
{
    Caption = 'Attachment';

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; "Attachment File"; BLOB)
        {
            Caption = 'Attachment File';
        }
        field(3; "Storage Type"; Enum "Attachment Storage Type")
        {
            Caption = 'Storage Type';
        }
        field(4; "Storage Pointer"; Text[250])
        {
            Caption = 'Storage Pointer';
        }
        field(5; "File Extension"; Text[250])
        {
            Caption = 'File Extension';
        }
        field(6; "Read Only"; Boolean)
        {
            Caption = 'Read Only';
        }
        field(7; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
        }
        field(8; "Last Time Modified"; Time)
        {
            Caption = 'Last Time Modified';
        }
        field(13; "Merge Source"; BLOB)
        {
            Caption = 'Merge Source';
        }
        field(14; "Email Message ID"; BLOB)
        {
            Caption = 'Email Message ID';
        }
        field(15; "Email Entry ID"; BLOB)
        {
            Caption = 'Email Entry ID';
        }
        field(16; "Email Message Checksum"; Integer)
        {
            Caption = 'Email Message Checksum';
        }
        field(17; "Email Message Url"; BLOB)
        {
            Caption = 'Email Message Url';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Email Message Checksum")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        Attachment2: Record Attachment;
        NextAttachmentNo: Integer;
    begin
        "Last Date Modified" := Today;
        "Last Time Modified" := Time;

        Attachment2.LockTable();
        if Attachment2.FindLast then
            NextAttachmentNo := Attachment2."No." + 1
        else
            NextAttachmentNo := 1;

        "No." := NextAttachmentNo;

        RMSetup.Get();
        "Storage Type" := RMSetup."Attachment Storage Type";
        if "Storage Type" = "Storage Type"::"Disk File" then begin
            RMSetup.TestField("Attachment Storage Location");
            "Storage Pointer" := RMSetup."Attachment Storage Location";
        end;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        "Last Time Modified" := Time;
    end;

    var
        Text002: Label 'The attachment is empty.';
        Text003: Label 'Attachment is already in use on this machine.';
        Text004: Label 'The attachment file must be saved to disk before you can import it.\\Do you want to save the file?';
        Text005: Label 'Export Attachment';
        Text006: Label 'Import Attachment';
        Text007: Label 'All Files (*.*)|*.*';
        Text008: Label 'Error during copying file: %1.';
        Text009: Label 'Do you want to remove %1?';
        Text010: Label 'External file could not be removed.';
        Text014: Label 'You can only fax Microsoft Word documents.';
        Text015: Label 'The email cannot be displayed or has been deleted.';
        Text016: Label 'When you have finished working with a document, you should delete the associated temporary file. Please note that this will not delete the document.\\Do you want to delete the temporary file?';
        Text020: Label 'An Outlook dialog box is open. Close it and try again.';
        CouldNotActivateOutlookErr: Label 'Cannot connect to Microsoft Outlook. If Microsoft Outlook is already running, make sure that you are not running either %1 or Microsoft Outlook as administrator. Close all instances of Microsoft Outlook and try again.', Comment = '%1 - product name';
        UnspecifiedOutlookErr: Label ' Microsoft Outlook cannot display the message. Make sure that Microsoft Outlook is configured with access to the message that you are trying to open.';
        RMSetup: Record "Marketing Setup";
        FileMgt: Codeunit "File Management";
        AttachmentMgt: Codeunit AttachmentManagement;
        ClientTypeManagement: Codeunit "Client Type Management";
        AttachmentImportQst: Label 'Do you want to import attachment?';
        AttachmentExportQst: Label 'Do you want to export attachment to view or edit it externaly?';

    [Scope('OnPrem')]
    procedure OpenAttachment(Caption: Text[260]; IsTemporary: Boolean; LanguageCode: Code[10])
    var
        SegmentLine: Record "Segment Line";
#if not CLEAN17
        WordManagement: Codeunit WordManagement;
        FileName: Text;
#endif
    begin
        if IsHTML then begin
            SegmentLine.Init();
            SegmentLine."Language Code" := LanguageCode;
            SegmentLine.Date := WorkDate;
            PreviewHTMLContent(SegmentLine);
            exit;
        end;

        if "Storage Type" = "Storage Type"::Embedded then begin
            CalcFields("Attachment File");
            if not "Attachment File".HasValue then
                Error(Text002);
        end;

        if ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Web, CLIENTTYPE::Tablet, CLIENTTYPE::Phone, CLIENTTYPE::Desktop] then
            ProcessWebAttachment(Caption + '.' + "File Extension")
#if not CLEAN17
        // Code being removed as the procedure ConstFilename will always throw an error and is being removed.
        // This will cause DeleteFile to always throw an error that the file is in use.
        // OpenWordAttachment is also being removed as it uses DotNet that cannot run on non-Windows client type.
        else begin
            FileName := ConstFilename;
            if not DeleteFile(FileName) then
                Error(Text003);
            ExportAttachmentToClientFile(FileName);
            if WordManagement.IsWordDocumentExtension("File Extension") then
                WordManagement.OpenWordAttachment(Rec, FileName, Caption, IsTemporary, LanguageCode)
            else begin
                HyperLink(FileName);
                if not "Read Only" then begin
                    if Confirm(Text004, true) then
                        ImportAttachmentFromClientFile(FileName, IsTemporary, false);
                    DeleteFile(FileName);
                end else
                    if Confirm(Text016, true) then
                        DeleteFile(FileName);
            end;
        end;
#endif
    end;

    [Scope('OnPrem')]
    procedure OpenAttachment(var SegLine: Record "Segment Line"; WordCaption: Text)
    begin
        if IsHTML() then begin
            PreviewHTMLContent(SegLine);
            exit;
        end;

        if "Storage Type" = "Storage Type"::Embedded then
            CalcFields("Attachment File");

        if SegLine."Word Template Code" = '' then
            ProcessWebAttachment(WordCaption + '.' + "File Extension");
    end;

    procedure ShowAttachment(var SegLine: Record "Segment Line"; WordCaption: Text)
    var
        WordTemplateInteractions: Codeunit "Word Template Interactions";
        IsHandled: Boolean;
    begin
        OnBeforeShowAttachment(SegLine, WordCaption, IsHandled);
        if IsHandled then
            exit;

        if IsHTML() then begin
            PreviewHTMLContent(SegLine);
            exit;
        end;

        if "Storage Type" = "Storage Type"::Embedded then
            CalcFields("Attachment File");

        if WordTemplateInteractions.IsWordDocumentExtension("File Extension") then
            WordTemplateInteractions.RunMergedDocument(SegLine, Rec)
        else
            ProcessWebAttachment(WordCaption + '.' + "File Extension");
    end;

#if not CLEAN19
    [Scope('OnPrem')]
    [Obsolete('Replaced with an overload with two parameters.', '19.0')]
    procedure ShowAttachment(var SegLine: Record "Segment Line"; WordCaption: Text[260]; IsTemporary: Boolean; Handler: Boolean)
    begin
        RunAttachment(SegLine, WordCaption, IsTemporary, true, Handler);
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced with procedure ShowAttachment with two parameters.', '19.0')]
    procedure RunAttachment(var SegLine: Record "Segment Line"; WordCaption: Text[260]; IsTemporary: Boolean; IsVisible: Boolean; Handler: Boolean)
    var
        WordManagement: Codeunit WordManagement;
        WordApplicationHandler: Codeunit WordApplicationHandler;
        FileName: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunAttachment(SegLine, WordCaption, IsTemporary, IsVisible, Handler, IsHandled);
        if IsHandled then
            exit;

        if IsHTML then begin
            PreviewHTMLContent(SegLine);
            exit;
        end;

        if "Storage Type" = "Storage Type"::Embedded then
            CalcFields("Attachment File");

        WordManagement.Activate(WordApplicationHandler, 5062);
        if ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Web, CLIENTTYPE::Tablet, CLIENTTYPE::Phone] then
            ProcessWebAttachment(WordCaption + '.' + "File Extension")
        else
            if not WordManagement.CanRunWordApp then
                ProcessWebAttachment(WordCaption + '.' + "File Extension")
            else
#if CLEAN17
                if not WordManagement.IsWordDocumentExtension("File Extension") then begin
                    ExportAttachmentToClientFile(FileName);
                    HyperLink(FileName);
                    if not "Read Only" then begin
                        if Confirm(Text004, true) then
                            ImportAttachmentFromClientFile(FileName, IsTemporary, false);
                        DeleteFile(FileName);
                    end else
                        if Confirm(Text016, true) then
                            DeleteFile(FileName);
                end;
#else
                if WordManagement.IsWordDocumentExtension("File Extension") then begin
                    OnRunAttachmentOnBeforeWordManagementRunMergedDocument(Rec, Handler);
                    WordManagement.RunMergedDocument(SegLine, Rec, WordCaption, IsTemporary, IsVisible, Handler);
                end else begin
                    FileName := ConstFilename;
                    ExportAttachmentToClientFile(FileName);
                    HyperLink(FileName);
                    if not "Read Only" then begin
                        if Confirm(Text004, true) then
                            ImportAttachmentFromClientFile(FileName, IsTemporary, false);
                        DeleteFile(FileName);
                    end else
                        if Confirm(Text016, true) then
                            DeleteFile(FileName);
                end;
#endif

        WordManagement.Deactivate(5062);
    end;
#endif

    local procedure PreviewHTMLContent(SegmentLine: Record "Segment Line")
    var
        ContentPreview: Page "Content Preview";
    begin
        ContentPreview.SetContent(AttachmentMgt.LoadHTMLContent(Rec, SegmentLine));
        ContentPreview.RunModal;
    end;

    [Scope('OnPrem')]
    procedure ExportAttachmentToClientFile(var ExportToFile: Text): Boolean
    var
        FileFilter: Text;
        ServerFileName: Text;
        Path: Text;
        Success: Boolean;
    begin
        RMSetup.Get();
        if RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::"Disk File" then
            RMSetup.TestField("Attachment Storage Location");

        ServerFileName := FileMgt.ServerTempFileName("File Extension");
        ExportAttachmentToServerFile(ServerFileName);

        Path := FileMgt.Magicpath;
#if not CLEAN17
        if ExportToFile = '' then begin
            ExportToFile := FileMgt.GetFileName(FileMgt.ClientTempFileName("File Extension"));
            Path := '';
        end;
#else
        if ExportToFile = '' then
            Path := '';
#endif

        FileFilter := UpperCase("File Extension") + ' (*.' + "File Extension" + ')|*.' + "File Extension";
        Success := Download(ServerFileName, Text005, Path, FileFilter, ExportToFile);
        FileMgt.DeleteServerFile(ServerFileName);
        exit(Success);
    end;

    [Scope('OnPrem')]
    procedure ImportAttachmentFromClientFile(ImportFromFile: Text; IsTemporary: Boolean; IsInherited: Boolean): Boolean
    var
        FileName: Text;
        ServerFileName: Text;
        NewAttachmentNo: Integer;
    begin
        ClearLastError;
        if IsTemporary then
            exit(ImportTemporaryAttachmentFromClientFile(ImportFromFile));

        TestField("Read Only", false);
        RMSetup.Get();
        if RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::"Disk File" then
            RMSetup.TestField("Attachment Storage Location");

        if IsInherited then begin
            NewAttachmentNo := AttachmentMgt.InsertAttachment("No.");
            Get(NewAttachmentNo);
        end else
            if "No." = 0 then
                NewAttachmentNo := AttachmentMgt.InsertAttachment(0)
            else
                NewAttachmentNo := "No.";
        Get(NewAttachmentNo);

        // passing to UPLOAD function when only server path is specified, not ALSO the file name,
        // then function updates the server file path with the actual client name
        ServerFileName := TemporaryPath;
        FileName := ImportFromFile;
        if not Upload(Text006, '', Text007, FileName, ServerFileName) then begin
            if GetLastErrorText <> '' then
                Error(Text008, GetLastErrorText);
            exit(false);
        end;

        exit(ImportAttachmentFromServerFile(ServerFileName, false, true));
    end;

    local procedure ImportTemporaryAttachmentFromClientFile(ImportFromFile: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
    begin
        FileName := FileMgt.BLOBImport(TempBlob, ImportFromFile);

        if FileName <> '' then begin
            SetAttachmentFileFromBlob(TempBlob);
            "Storage Type" := "Storage Type"::Embedded;
            "Storage Pointer" := '';
            "File Extension" := CopyStr(UpperCase(FileMgt.GetExtension(FileName)), 1, 250);
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ExportAttachmentToServerFile(var ExportToFile: Text) Result: Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportAttachmentToServerFile(Rec, ExportToFile, Result, IsHandled);
        if IsHandled then
            exit(Result);

        // This function assumes that CALCFIELDS on the attachment field has been called before
        RMSetup.Get();
        if RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::"Disk File" then
            RMSetup.TestField("Attachment Storage Location");

        case "Storage Type" of
            "Storage Type"::Embedded:
                begin
                    if "Attachment File".HasValue then begin
                        TempBlob.FromRecord(Rec, FieldNo("Attachment File"));
                        if ExportToFile = '' then
                            ExportToFile := FileMgt.ServerTempFileName("File Extension");
                        FileMgt.BLOBExportToServerFile(TempBlob, ExportToFile); // export BLOB to file on server (UNC location also)
                        exit(true);
                    end;
                    exit(false);
                end;
            "Storage Type"::"Disk File":
                begin
                    if ExportToFile = '' then
                        ExportToFile := TemporaryPath + FileMgt.GetFileName(ConstDiskFileName);
                    FileMgt.CopyServerFile(GetServerFileName(ConstDiskFileName), ExportToFile, false); // Copy from server location to another location (UNC location also)
                    exit(true);
                end;
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ImportAttachmentFromServerFile(ImportFromFile: Text; IsTemporary: Boolean; Overwrite: Boolean) Result: Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        FileExt: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeImportAttachmentFromServerFile(Rec, ImportFromFile, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if IsTemporary then begin
            ImportTemporaryAttachmentFromServerFile(ImportFromFile);
            exit(true);
        end;

        if not Overwrite then
            TestField("Read Only", false);

        RMSetup.Get();
        if RMSetup."Attachment Storage Type" = RMSetup."Attachment Storage Type"::"Disk File" then
            RMSetup.TestField("Attachment Storage Location");

        case RMSetup."Attachment Storage Type" of
            RMSetup."Attachment Storage Type"::Embedded:
                begin
                    FileMgt.BLOBImportFromServerFile(TempBlob, ImportFromFile); // Copy from file on server (UNC location also)
                    SetAttachmentFileFromBlob(TempBlob);
                    "Storage Type" := "Storage Type"::Embedded;
                    "Storage Pointer" := '';
                    FileExt := CopyStr(FileMgt.GetExtension(ImportFromFile), 1, 250);
                    if FileExt <> '' then
                        "File Extension" := FileExt;
                    Modify(true);
                    exit(true);
                end;
            "Storage Type"::"Disk File":
                begin
                    "Storage Type" := "Storage Type"::"Disk File";
                    "Storage Pointer" := RMSetup."Attachment Storage Location";
                    FileExt := CopyStr(FileMgt.GetExtension(ImportFromFile), 1, 250);
                    if FileExt <> '' then
                        "File Extension" := FileExt;
                    FileMgt.CopyServerFile(ImportFromFile, ConstDiskFileName, Overwrite); // Copy from UNC location to another UNC location
                    Modify(true);
                    exit(true);
                end;
        end;

        exit(false);
    end;

    local procedure ImportTemporaryAttachmentFromServerFile(ImportFromFile: Text)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        FileMgt.BLOBImportFromServerFile(TempBlob, ImportFromFile);
        SetAttachmentFileFromBlob(TempBlob);
        "Storage Type" := "Storage Type"::Embedded;
        "Storage Pointer" := '';
        "File Extension" := CopyStr(UpperCase(FileMgt.GetExtension(ImportFromFile)), 1, 250);
    end;

    [Scope('OnPrem')]
    procedure RemoveAttachment(Prompt: Boolean) DeleteOK: Boolean
    var
        DeleteYesNo: Boolean;
    begin
        DeleteOK := false;
        DeleteYesNo := true;
        if Prompt then
            if not Confirm(
                 Text009, false, TableCaption)
            then
                DeleteYesNo := false;

        if DeleteYesNo then begin
            if "Storage Type" = "Storage Type"::"Disk File" then
                if not FileMgt.DeleteServerFile(ConstDiskFileName) then
                    Message(Text010);
            Delete(true);
            DeleteOK := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure WizEmbeddAttachment(FromAttachment: Record Attachment)
    begin
        Rec := FromAttachment;
        "No." := 0;
        "Storage Type" := "Storage Type"::Embedded;
        FromAttachment.TestField("No.");
        case FromAttachment."Storage Type" of
            FromAttachment."Storage Type"::"Disk File":
                ImportAttachmentFromServerFile(FromAttachment.ConstDiskFileName, true, false);
            FromAttachment."Storage Type"::Embedded:
                begin
                    FromAttachment.CalcFields("Attachment File");
                    if FromAttachment."Attachment File".HasValue then
                        "Attachment File" := FromAttachment."Attachment File";
                end;
        end;
    end;

    procedure WizSaveAttachment()
    var
        Attachment2: Record Attachment;
    begin
        with RMSetup do begin
            Get;
            if "Attachment Storage Type" = "Attachment Storage Type"::Embedded then begin
                "Storage Pointer" := '';
                exit;
            end;
        end;

        "Storage Pointer" := RMSetup."Attachment Storage Location";

        CopyAttachmentAsFile(Rec, Attachment2);

        Clear(Rec);
        Rec := Attachment2;
    end;

#if not CLEAN19
    local procedure DeleteFile(FileName: Text): Boolean
    var
        I: Integer;
    begin
        if FileName = '' then
            exit(false);

#if not CLEAN17
        if not FileMgt.ClientFileExists(FileName) then
            exit(true);

        repeat
            Sleep(250);
            I := I + 1;
        until FileMgt.DeleteClientFile(FileName) or (I = 25);
        exit(not FileMgt.ClientFileExists(FileName));
#else
        exit(true);
#endif
    end;
#endif

#if not CLEAN17
    [Scope('OnPrem')]
    [Obsolete('The local file system is not accessible, the procedure FileMgt.ClientTempFileName will always throw an error. This procedure will be removed.', '17.3')]
    procedure ConstFilename() FileName: Text
    begin
        FileName := FileMgt.ClientTempFileName("File Extension");
    end;
#endif

    procedure ConstDiskFileName() DiskFileName: Text
    begin
        DiskFileName := "Storage Pointer" + '\' + Format("No.") + '.' + "File Extension";
    end;

    procedure CheckCorrespondenceType(CorrespondenceType: Enum "Correspondence Type"): Text[80]
    begin
        if CorrespondenceType = CorrespondenceType::Fax then
            if (UpperCase("File Extension") <> 'DOC') and (UpperCase("File Extension") <> 'DOCX') then
                exit(Text014);
    end;

    local procedure CopyAttachmentAsFile(var FromAttachment: Record Attachment; var ToAttachment: Record Attachment)
    begin
        ToAttachment."No." := FromAttachment."No.";
        ToAttachment."Storage Type" := ToAttachment."Storage Type"::"Disk File";
        ToAttachment."Storage Pointer" := RMSetup."Attachment Storage Location";
        ToAttachment."File Extension" := FromAttachment."File Extension";
        ToAttachment."Read Only" := FromAttachment."Read Only";
        ToAttachment."Last Date Modified" := FromAttachment."Last Date Modified";
        ToAttachment."Last Time Modified" := FromAttachment."Last Time Modified";

        OnAfterCopyAttachmentAsFile(FromAttachment, ToAttachment);
    end;

    procedure LinkToMessage(MessageID: Text; EntryID: Text; RunTrigger: Boolean)
    begin
        "Storage Type" := "Storage Type"::"Exchange Storage";
        "Read Only" := true;

        SetMessageID(MessageID);
        SetEntryID(EntryID);

        Modify(RunTrigger);
    end;

    [Scope('OnPrem')]
    procedure DisplayInOutlook()
    var
        [RunOnClient]
        OutlookHelper: DotNet OutlookHelper;
        [RunOnClient]
        Status: DotNet OutlookStatusCode;
    begin
        Status := OutlookHelper.DisplayMailFromPublicFolder(GetEntryID);

        if Status.Equals(Status.CouldNotActivateOutlook) then
            Error(CouldNotActivateOutlookErr, PRODUCTNAME.Full);

        if Status.Equals(Status.ModalDialogOpened) then
            Error(Text020);

        if Status.Equals(Status.ItemNotFound) then
            Error(Text015);

        // If the Exchange Entry Id requires patching to be used in Outlook
        // then we update the entry id.
        if Status.Equals(Status.OkAfterExchange2013Patch) then begin
            SetMessageID(OutlookHelper.PatchExchange2013WebServicesPublicFolderItemEntryId(GetEntryID));
            Modify(true);
        end else
            if not Status.Equals(Status.Ok) then
                Error(UnspecifiedOutlookErr);
    end;

    procedure Checksum(MessageID: Text) ChecksumValue: Integer
    var
        CharNo: Integer;
        DecValue: Decimal;
        MaxInteger: Integer;
    begin
        Randomize(1);
        MaxInteger := 2147483647;

        for CharNo := 1 to StrLen(MessageID) do
            DecValue := (DecValue + (((MessageID[CharNo] mod 43) + 1) * Random((MaxInteger div 44)))) mod MaxInteger;
        ChecksumValue := DecValue;
    end;

    procedure GetMessageID() Return: Text
    var
        Stream: InStream;
    begin
        CalcFields("Email Message ID");
        "Email Message ID".CreateInStream(Stream);
        Stream.ReadText(Return);
    end;

    procedure SetMessageID(MessageID: Text)
    var
        Stream: OutStream;
    begin
        Clear("Email Message ID");
        "Email Message ID".CreateOutStream(Stream);
        Stream.WriteText(MessageID);
        "Email Message Checksum" := Checksum(MessageID);
    end;

    local procedure GetEntryID() Return: Text
    var
        Stream: InStream;
    begin
        CalcFields("Email Entry ID");
        "Email Entry ID".CreateInStream(Stream);
        Stream.ReadText(Return);
    end;

    procedure SetEntryID(EntryID: Text)
    var
        Stream: OutStream;
    begin
        Clear("Email Entry ID");
        "Email Entry ID".CreateOutStream(Stream);
        Stream.WriteText(EntryID);
    end;

    procedure GetEmailMessageUrl() Return: Text
    var
        InStream: InStream;
    begin
        CalcFields("Email Message Url");
        "Email Message Url".CreateInStream(InStream);
        InStream.ReadText(Return);
    end;

    procedure SetEmailMessageUrl(Url: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Email Message Url");
        "Email Message Url".CreateOutStream(OutStream);
        OutStream.WriteText(url);
    end;

    procedure Read() Result: Text
    var
        DataStream: InStream;
    begin
        Result := '';
        CalcFields("Attachment File");
        if not "Attachment File".HasValue then
            exit;

        "Attachment File".CreateInStream(DataStream, TEXTENCODING::UTF8);
        DataStream.Read(Result);
    end;

    procedure Write(SourceText: Text)
    var
        DataStream: OutStream;
    begin
        "Attachment File".CreateOutStream(DataStream, TEXTENCODING::UTF8);
        DataStream.Write(SourceText);
    end;

    procedure ReadHTMLCustomLayoutAttachment(var ContentBodyText: Text; var CustomLayoutCode: Code[20]): Boolean
    var
        DataText: Text;
    begin
        DataText := Read;
        exit(ParseHTMLCustomLayoutAttachment(DataText, ContentBodyText, CustomLayoutCode));
    end;

    procedure WriteHTMLCustomLayoutAttachment(ContentBodyText: Text; CustomLayoutCode: Code[20])
    var
        DataText: Text;
    begin
        DataText := PadStr('', GetCustomLayoutCodeLength - StrLen(CustomLayoutCode), '0') + CustomLayoutCode;
        DataText += ContentBodyText;
        Write(DataText);
        Modify;
    end;

    local procedure ParseHTMLCustomLayoutAttachment(DataText: Text; var ContentBodyText: Text; var CustomLayoutCode: Code[20]): Boolean
    var
        TotalLength: Integer;
        LayoutIDLength: Integer;
    begin
        LayoutIDLength := GetCustomLayoutCodeLength;
        TotalLength := StrLen(DataText);
        if TotalLength < LayoutIDLength then
            exit(false);

        if DataText = '' then
            exit;

        CustomLayoutCode := DelChr(CopyStr(DataText, 1, LayoutIDLength), '<', '0');
        if CustomLayoutCode = '' then
            exit;

        if TotalLength = LayoutIDLength then
            ContentBodyText := ''
        else
            ContentBodyText := CopyStr(DataText, LayoutIDLength + 1, TotalLength - LayoutIDLength);

        exit(true);
    end;

    procedure IsHTML(): Boolean
    begin
        exit(LowerCase("File Extension") = 'html');
    end;

    procedure IsHTMLReady(): Boolean
    var
        DataText: Text;
        DataLength: Integer;
        HTMLMask: Text;
        HTMLMaskLength: Integer;
    begin
        if not IsHTML then
            exit(false);

        HTMLMask := '<html>';
        HTMLMaskLength := StrLen(HTMLMask);
        DataText := Read;
        DataLength := StrLen(DataText);

        if DataLength < HTMLMaskLength then
            exit(false);

        exit(LowerCase(CopyStr(DataText, 1, HTMLMaskLength)) = HTMLMask);
    end;

    procedure IsHTMLCustomLayout(): Boolean
    var
        DataText: Text;
        DataLength: Integer;
        CustomLayoutIDLength: Integer;
        CustomLayoutCode: Code[20];
    begin
        CustomLayoutIDLength := GetCustomLayoutCodeLength;
        if not IsHTML then
            exit(false);

        DataText := Read;
        DataLength := StrLen(DataText);

        if DataLength < CustomLayoutIDLength then
            exit(false);

        CustomLayoutCode := DelChr(DataText, '<', '0');
        exit(CustomLayoutCode <> '');
    end;

    local procedure GetCustomLayoutCodeLength(): Integer
    var
        DummyCustomReportLayout: Record "Custom Report Layout";
    begin
        exit(MaxStrLen(DummyCustomReportLayout.Code));
    end;

    local procedure ProcessWebAttachment(FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        if Confirm(AttachmentExportQst, true) then begin
            TempBlob.FromRecord(Rec, FieldNo("Attachment File"));
            FileMgt.BLOBExport(TempBlob, FileName, true);
            if not "Read Only" then
                if Confirm(AttachmentImportQst, true) then
                    ImportAttachmentFromClientFile('', IsTemporary, false);
        end
    end;

    procedure GetServerFileName(DiskFileName: Text): Text
    begin
        if not Exists(DiskFileName) then
            DiskFileName := DelChr(DiskFileName, '>', '.' + "File Extension");
        exit(DiskFileName);
    end;

    procedure SetAttachmentFileFromBlob(TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo("Attachment File"));
        RecordRef.SetTable(Rec);
    end;

    internal procedure SetAttachmentFileFromStream(InStream: InStream)
    var
        OutStream: OutStream;
    begin
        Rec."Attachment File".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
    end;

#if not CLEAN19
    [Obsolete('Replaced by event OnBeforeShowAttachment', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunAttachment(var SegLine: Record "Segment Line"; WordCaption: Text[260]; IsTemporary: Boolean; IsVisible: Boolean; Handler: Boolean; var iSHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyAttachmentAsFile(var FromAttachment: Record Attachment; var ToAttachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAttachment(var SegLine: Record "Segment Line"; WordCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportAttachmentToServerFile(var Attachment: Record Attachment; ExportToFile: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImportAttachmentFromServerFile(var Attachment: Record Attachment; ImportFromFile: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN17
    [IntegrationEvent(false, false)]
    local procedure OnRunAttachmentOnBeforeWordManagementRunMergedDocument(var Attachment: Record Attachment; var Handler: Boolean)
    begin
    end;
#endif
}

