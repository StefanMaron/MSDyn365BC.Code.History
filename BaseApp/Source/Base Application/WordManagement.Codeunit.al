codeunit 5054 WordManagement
{

    trigger OnRun()
    begin
    end;

    var
        Text003: Label 'Merging Microsoft Word Documents...\\';
        Text004: Label 'Preparing';
        Text005: Label 'Program status';
        Text006: Label 'Preparing Merge...';
        Text007: Label 'Waiting for print job...';
        Text008: Label 'Transferring %1 data to Microsoft Word...';
        Text009: Label 'Sending individual email messages...';
        Text010: Label '%1 %2 must have %3 DOC or DOCX.', Comment = 'Attachment No. must have File Extension DOC or DOCX.';
        Text011: Label 'Attachment file error.';
        Text012: Label 'Creating merge source...';
        Text013: Label 'Microsoft Word is opening merge source...';
        Text014: Label 'Merging %1 in Microsoft Word...';
        Text015: Label 'FaxMailTo';
        Text017: Label 'The merge source file is locked by another process.\';
        Text018: Label 'Please try again later.';
        Text019: Label ' Mail Address';
        Text020: Label 'Document ';
        Text021: Label 'Import attachment ';
        Text022: Label 'Delete %1?';
        Text023: Label 'Another user has modified the record for this %1\after you retrieved it from the database.\\Enter the changes again in the updated document.';
        FileMgt: Codeunit "File Management";
        AttachmentManagement: Codeunit AttachmentManagement;
        [RunOnClient]
        WordHelper: DotNet WordHelper;
        [RunOnClient]
        TmpWordDocument: DotNet Document;
        Window: Dialog;
        Text030: Label 'Formal Salutation';
        Text031: Label 'Informal Salutation';
        MergeSourceBufferFile: File;
        MergeSourceBufferFileName: Text;
        Text032: Label '*.htm|*.htm';
        ImportAttachmentQst: Label 'Do you want to import attachment %1?', Comment = '%1: Text Caption';
        FieldCountMismatchErr: Label 'Number of fields in the word document header (%1) does not match number of fields with data (%2).', Comment = '%1 and %2 is a number';

    procedure Activate(var WordApplicationHandler: Codeunit WordApplicationHandler; HandlerID: Integer)
    begin
        if not IsActive then
            WordApplicationHandler.Activate(WordApplicationHandler, HandlerID);
    end;

    procedure IsActive() IsFound: Boolean
    begin
        OnFindActiveSubscriber(IsFound);
    end;

    procedure Deactivate(HandlerID: Integer)
    begin
        OnDeactivate(HandlerID);
    end;

    local procedure GetWord(var WordApplication: DotNet ApplicationClass)
    var
        IsFound: Boolean;
    begin
        OnGetWord(WordApplication, IsFound);
        if not IsFound then
            Clear(WordApplication);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure TryGetWord(var WordApplication: DotNet ApplicationClass)
    var
        IsFound: Boolean;
    begin
        OnGetWord(WordApplication, IsFound);
        if not IsFound then begin
            Clear(WordApplication);
            Error('');
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateWordAttachment(WordCaption: Text[260]; LanguageCode: Code[10]) NewAttachNo: Integer
    var
        Attachment: Record Attachment;
        WordApplicationHandler: Codeunit WordApplicationHandler;
        [RunOnClient]
        WordApplication: DotNet ApplicationClass;
        [RunOnClient]
        WordDocument: DotNet Document;
        [RunOnClient]
        WordMergefile: DotNet MergeHandler;
        FileName: Text;
        MergeFileName: Text;
        ParamInt: Integer;
    begin
        WordMergefile := WordMergefile.MergeHandler;

        MergeFileName := FileMgt.ClientTempFileName('HTM');
        CreateHeader(WordMergefile, true, MergeFileName, LanguageCode); // Header without data

        Activate(WordApplicationHandler, 505401);
        GetWord(WordApplication);
        Attachment."File Extension" := GetWordDocumentExtension(WordApplication.Version);
        WordDocument := WordHelper.AddDocument(WordApplication);
        WordDocument.MailMerge.MainDocumentType := 0; // 0 = wdFormLetters
        ParamInt := 7; // 7 = HTML
        WordHelper.CallMailMergeOpenDataSource(WordDocument, MergeFileName, ParamInt);

        FileName := Attachment.ConstFilename;
        WordHelper.CallSaveAs(WordDocument, FileName);
        if WordHandler(WordDocument, Attachment, WordCaption, false, FileName, false) then
            NewAttachNo := Attachment."No."
        else
            NewAttachNo := 0;

        Clear(WordMergefile);
        Clear(WordDocument);
        Deactivate(505401);

        DeleteFile(MergeFileName);
    end;

    [Scope('OnPrem')]
    procedure OpenWordAttachment(var Attachment: Record Attachment; FileName: Text; Caption: Text[260]; IsTemporary: Boolean; LanguageCode: Code[10])
    var
        WordApplicationHandler: Codeunit WordApplicationHandler;
        [RunOnClient]
        WordApplication: DotNet ApplicationClass;
        [RunOnClient]
        WordDocument: DotNet Document;
        [RunOnClient]
        WordMergefile: DotNet MergeHandler;
        MergeFileName: Text;
        ParamInt: Integer;
    begin
        WordMergefile := WordMergefile.MergeHandler;

        MergeFileName := FileMgt.ClientTempFileName('HTM');
        CreateHeader(WordMergefile, true, MergeFileName, LanguageCode);

        Activate(WordApplicationHandler, 505402);
        GetWord(WordApplication);
        WordDocument := WordHelper.CallOpen(WordApplication, FileName, false, Attachment."Read Only");

        if IsNull(WordDocument.MailMerge.MainDocumentType) then begin
            WordDocument.MailMerge.MainDocumentType := 0; // 0 = wdFormLetters
            WordHelper.CallMailMergeOpenDataSource(WordDocument, MergeFileName, ParamInt);
        end;

        if WordDocument.MailMerge.Fields.Count > 0 then begin
            ParamInt := 7; // 7 = HTML
            WordHelper.CallMailMergeOpenDataSource(WordDocument, MergeFileName, ParamInt);
        end;

        WordHandler(WordDocument, Attachment, Caption, IsTemporary, FileName, false);

        Clear(WordMergefile);
        Clear(WordDocument);
        Deactivate(505402);

        DeleteFile(MergeFileName);
    end;

    [Scope('OnPrem')]
    procedure Merge(var TempDeliverySorter: Record "Delivery Sorter" temporary)
    var
        TempDeliverySorter2: Record "Delivery Sorter" temporary;
        WordApplicationHandler: Codeunit WordApplicationHandler;
        [RunOnClient]
        WordApplication: DotNet ApplicationClass;
        LastAttachmentNo: Integer;
        LastCorrType: Integer;
        LastSubject: Text[100];
        LastSendWordDocsAsAttmt: Boolean;
        LineCount: Integer;
        NoOfRecords: Integer;
        WordHided: Boolean;
        FirstRecord: Boolean;
    begin
        Window.Open(
          Text003 +
          '#1############ @2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\' +
          '#3############ @4@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\' +
          '#5############ #6################################');

        Window.Update(1, Text004);
        Window.Update(5, Text005);

        Window.Update(6, Text006);
        TempDeliverySorter.SetCurrentKey(
          "Attachment No.", "Correspondence Type", Subject, "Send Word Docs. as Attmt.");
        TempDeliverySorter.SetFilter("Correspondence Type", '<>0');
        NoOfRecords := TempDeliverySorter.Count();
        TempDeliverySorter.Find('-');

        Activate(WordApplicationHandler, 505403);
        GetWord(WordApplication);
        if WordApplication.Documents.Count > 0 then begin
            WordApplication.Visible := false;
            WordHided := true;
        end;

        FirstRecord := true;
        repeat
            LineCount := LineCount + 1;
            Window.Update(2, Round(LineCount / NoOfRecords * 10000, 1));
            Window.Update(3, StrSubstNo('%1', TempDeliverySorter."Correspondence Type"));

            if not FirstRecord and
               ((TempDeliverySorter."Attachment No." <> LastAttachmentNo) or
                (TempDeliverySorter."Correspondence Type" <> LastCorrType) or
                (TempDeliverySorter.Subject <> LastSubject) or
                (TempDeliverySorter."Send Word Docs. as Attmt." <> LastSendWordDocsAsAttmt))
            then begin
                ExecuteMerge(WordApplication, TempDeliverySorter2);
                TempDeliverySorter2.DeleteAll();
                if TempDeliverySorter."Attachment No." <> LastAttachmentNo then
                    ImportMergeSourceFile(LastAttachmentNo)
            end;

            TempDeliverySorter2 := TempDeliverySorter;
            TempDeliverySorter2.Insert();
            LastAttachmentNo := TempDeliverySorter."Attachment No.";
            LastCorrType := TempDeliverySorter."Correspondence Type";
            LastSubject := TempDeliverySorter.Subject;
            LastSendWordDocsAsAttmt := TempDeliverySorter."Send Word Docs. as Attmt.";

            FirstRecord := false;
        until TempDeliverySorter.Next = 0;

        if TempDeliverySorter2.Find('-') then begin
            ExecuteMerge(WordApplication, TempDeliverySorter2);
            ImportMergeSourceFile(TempDeliverySorter2."Attachment No.")
        end;

        if WordHided then
            WordApplication.Visible := true
        else begin
            // Wait for print job to finish
            if WordApplication.BackgroundPrintingStatus <> 0 then
                repeat
                    Window.Update(6, Text007);
                    Sleep(500);
                until WordApplication.BackgroundPrintingStatus = 0;
        end;

        Deactivate(505403);
        Window.Close;
    end;

    local procedure ExecuteMerge(var WordApplication: DotNet ApplicationClass; var TempDeliverySorter: Record "Delivery Sorter" temporary)
    var
        Attachment: Record Attachment;
        InteractLogEntry: Record "Interaction Log Entry";
        TempSegLine: Record "Segment Line" temporary;
        [RunOnClient]
        WordDocument: DotNet Document;
        [RunOnClient]
        WordInlineShape: DotNet InlineShape;
        [RunOnClient]
        WordMergefile: DotNet MergeHandler;
        [RunOnClient]
        WordOLEFormat: DotNet OLEFormat;
        [RunOnClient]
        WordLinkFormat: DotNet LinkFormat;
        [RunOnClient]
        WordShape: DotNet Shape;
        MergeFile: File;
        MergeClientFileName: Text;
        MainFileName: Text;
        NoOfRecords: Integer;
        ParamBln: Boolean;
        ParamInt: Integer;
        Row: Integer;
        ShapesIndex: Integer;
        HeaderIsReady: Boolean;
        FaxMailToValue: Text;
        HeaderFieldCount: Integer;
    begin
        Window.Update(
          6, StrSubstNo(Text008,
            Format(TempDeliverySorter."Correspondence Type")));

        if TempDeliverySorter.Find('-') then
            NoOfRecords := TempDeliverySorter.Count();

        Attachment.Get(TempDeliverySorter."Attachment No.");
        Attachment.CalcFields("Attachment File");

        // Handle Word documents without mergefields
        if not DocumentContainMergefields(Attachment) and
           TempDeliverySorter."Send Word Docs. as Attmt."
        then begin
            SendAttachmentWithoutMergeFields(WordApplication, TempDeliverySorter, Attachment);
            exit;
        end;

        with TempDeliverySorter do begin
            SetCurrentKey("Attachment No.", "Correspondence Type", Subject);
            Find('-');
        end;
        Row := 2;

        MainFileName := FileMgt.ClientTempFileName('DOC');
        TempDeliverySorter.Find('-');
        Attachment.Get(TempDeliverySorter."Attachment No.");
        Attachment.CalcFields("Attachment File");
        if not IsWordDocumentExtension(Attachment."File Extension") then
            Error(Text010, Attachment.TableCaption, Attachment."No.", Attachment.FieldCaption("File Extension"));

        if not Attachment.ExportAttachmentToClientFile(MainFileName) then
            Error(Text011);

        Window.Update(6, Text012);
        Attachment.CalcFields("Merge Source");
        if Attachment."Merge Source".HasValue then begin
            CreateMergeSource(MergeFile);
            repeat
                PopulateInterLogEntryToMergeSource(
                  MergeFile, Attachment, TempDeliverySorter."No.", HeaderIsReady, TempDeliverySorter."Correspondence Type");
                Row := Row + 1;
                Window.Update(4, Round(Row / NoOfRecords * 10000, 1))
            until TempDeliverySorter.Next = 0;
            MergeClientFileName := CloseAndDownloadMergeSource(MergeFile);
        end else begin
            MergeClientFileName := FileMgt.ClientTempFileName('HTM');
            WordMergefile := WordMergefile.MergeHandler;
            HeaderFieldCount := CreateHeader(WordMergefile, false, MergeClientFileName, TempDeliverySorter."Language Code");
            repeat
                InteractLogEntry.Get(TempDeliverySorter."No.");

                // This field must come last in the merge source file
                case TempDeliverySorter."Correspondence Type" of
                    TempDeliverySorter."Correspondence Type"::Fax:
                        FaxMailToValue := AttachmentManagement.InteractionFax(InteractLogEntry);
                    TempDeliverySorter."Correspondence Type"::Email:
                        FaxMailToValue := AttachmentManagement.InteractionEMail(InteractLogEntry);
                    TempDeliverySorter."Correspondence Type"::"Hard Copy":
                        FaxMailToValue := '';
                    else
                        OnExecuteMergeFaxMailToValueCaseElse(TempDeliverySorter, FaxMailToValue);
                end;

                OnBeforeAddFieldsToMergeSource(TempSegLine, TempDeliverySorter);
                AddFieldsToMergeSource(WordMergefile, InteractLogEntry, TempSegLine, FaxMailToValue, HeaderFieldCount);
                Row := Row + 1;
                Window.Update(4, Round(Row / NoOfRecords * 10000, 1))
            until TempDeliverySorter.Next = 0;
            WordMergefile.CloseMergeFile;
        end;

        WordDocument := WordHelper.CallOpen(WordApplication, MainFileName, false, false);
        WordDocument.MailMerge.MainDocumentType := 0;

        Window.Update(6, Text013);
        ParamInt := 7; // 7 = HTML
        WordHelper.CallMailMergeOpenDataSource(WordDocument, MergeClientFileName, ParamInt);
        Window.Update(6, StrSubstNo(Text014, TempDeliverySorter."Correspondence Type"));

        for ShapesIndex := 1 to WordDocument.InlineShapes.Count do begin
            WordInlineShape := WordHelper.GetInlineShapeItem(WordDocument, ShapesIndex);
            WordInlineShape.Select;
            if not IsNull(WordInlineShape) then begin
                WordShape := WordInlineShape.ConvertToShape;
                WordLinkFormat := WordShape.LinkFormat;
                WordOLEFormat := WordShape.OLEFormat;
                if not IsNull(WordOLEFormat) then
                    WordDocument.MailMerge.MailAsAttachment := WordDocument.MailMerge.MailAsAttachment or WordOLEFormat.DisplayAsIcon;
                if not IsNull(WordLinkFormat) then begin
                    WordLinkFormat.SavePictureWithDocument := true;
                    WordLinkFormat.BreakLink;
                    WordLinkFormat.Update;
                end;
                WordInlineShape := WordShape.ConvertToInlineShape;
            end;
        end;

        case TempDeliverySorter."Correspondence Type" of
            TempDeliverySorter."Correspondence Type"::Fax:
                begin
                    WordDocument.MailMerge.Destination := 3;
                    WordDocument.MailMerge.MailAddressFieldName := Text015;
                    WordDocument.MailMerge.MailAsAttachment := true;
                    WordHelper.CallMailMergeExecute(WordDocument);
                end;
            TempDeliverySorter."Correspondence Type"::Email:
                begin
                    WordDocument.MailMerge.Destination := 2;
                    WordDocument.MailMerge.MailAddressFieldName := Text015;
                    WordDocument.MailMerge.MailSubject := TempDeliverySorter.Subject;
                    WordDocument.MailMerge.MailAsAttachment :=
                      WordDocument.MailMerge.MailAsAttachment or TempDeliverySorter."Send Word Docs. as Attmt.";
                    WordHelper.CallMailMergeExecute(WordDocument);
                end;
            TempDeliverySorter."Correspondence Type"::"Hard Copy":
                begin
                    WordDocument.MailMerge.Destination := 0; // 0 = wdSendToNewDocument
                    WordHelper.CallMailMergeExecute(WordDocument);
                    WordHelper.CallPrintOut(WordHelper.GetActiveDocument(WordApplication));
                end;
            else
                OnExecuteMergeWordDocumentCaseElse(TempDeliverySorter);
        end;

        // Update delivery status on Interaction Log Entry
        if TempDeliverySorter.Find('-') then begin
            InteractLogEntry.LockTable();
            repeat
                with InteractLogEntry do begin
                    Get(TempDeliverySorter."No.");
                    "Delivery Status" := "Delivery Status"::" ";
                    Modify;
                end;
            until TempDeliverySorter.Next = 0;
            Commit();
        end;

        ParamBln := false;
        WordHelper.CallClose(WordDocument, ParamBln);
        if not Attachment."Merge Source".HasValue then
            AppendToMergeSource(MergeClientFileName);
        DeleteFile(MainFileName);
        DeleteFile(MergeClientFileName);

        if not IsNull(WordLinkFormat) then
            Clear(WordLinkFormat);
        if not IsNull(WordOLEFormat) then
            Clear(WordOLEFormat);
        Clear(WordMergefile);
        Clear(WordDocument);
    end;

    [Scope('OnPrem')]
    procedure ShowMergedDocument(var SegLine: Record "Segment Line"; var Attachment: Record Attachment; WordCaption: Text[260]; IsTemporary: Boolean)
    begin
        RunMergedDocument(SegLine, Attachment, WordCaption, IsTemporary, true, true);
    end;

    [Scope('OnPrem')]
    procedure CreateHeader(var WordMergefile: DotNet MergeHandler; MergeFieldsOnly: Boolean; MergeFileName: Text; LanguageCode: Code[10]) FieldCount: Integer
    var
        Salesperson: Record "Salesperson/Purchaser";
        Country: Record "Country/Region";
        Contact: Record Contact;
        SegLine: Record "Segment Line";
        CompanyInfo: Record "Company Information";
        RMSetup: Record "Marketing Setup";
        InteractionLogEntry: Record "Interaction Log Entry";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        Language: Codeunit Language;
        I: Integer;
        MainLanguage: Integer;
    begin
        if not WordMergefile.CreateMergeFile(MergeFileName) then
            Error(Text017 + Text018);

        // Create HTML Header source
        with TempNameValueBuffer do begin
            DeleteAll();
            MainLanguage := GlobalLanguage;

            if LanguageCode = '' then begin
                RMSetup.Get();
                if RMSetup."Mergefield Language ID" <> 0 then
                    GlobalLanguage := RMSetup."Mergefield Language ID";
            end else
                GlobalLanguage := Language.GetLanguageIdOrDefault(LanguageCode);
            AddNewEntry(InteractionLogEntry.FieldCaption("Entry No."), '');
            AddNewEntry(Contact.TableCaption + Text019, '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("No."), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("Company Name"), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption(Name), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("Name 2"), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption(Address), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("Address 2"), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("Post Code"), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption(City), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption(County), '');
            AddNewEntry(Contact.TableCaption + ' ' + Country.TableCaption + ' ' + Country.FieldCaption(Name), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("Job Title"), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("Phone No."), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("Fax No."), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("E-Mail"), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("Mobile Phone No."), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("VAT Registration No."), '');
            AddNewEntry(Contact.TableCaption + ' ' + Contact.FieldCaption("Home Page"), '');
            AddNewEntry(Text030, '');
            AddNewEntry(Text031, '');
            AddNewEntry(Salesperson.TableCaption + ' ' + Salesperson.FieldCaption(Code), '');
            AddNewEntry(Salesperson.TableCaption + ' ' + Salesperson.FieldCaption(Name), '');
            AddNewEntry(Salesperson.TableCaption + ' ' + Salesperson.FieldCaption("Job Title"), '');
            AddNewEntry(Salesperson.TableCaption + ' ' + Salesperson.FieldCaption("Phone No."), '');
            AddNewEntry(Salesperson.TableCaption + ' ' + Salesperson.FieldCaption("E-Mail"), '');
            AddNewEntry(Text020 + SegLine.FieldCaption(Date), '');
            AddNewEntry(Text020 + SegLine.FieldCaption("Campaign No."), '');
            AddNewEntry(Text020 + SegLine.FieldCaption("Segment No."), '');
            AddNewEntry(Text020 + SegLine.FieldCaption(Description), '');
            AddNewEntry(Text020 + SegLine.FieldCaption(Subject), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption(Name), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Name 2"), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption(Address), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Address 2"), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Post Code"), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption(City), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption(County), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + Country.TableCaption + ' ' + Country.FieldCaption(Name), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("VAT Registration No."), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Registration No."), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Phone No."), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Fax No."), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Bank Branch No."), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Bank Name"), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Bank Account No."), '');
            AddNewEntry(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Giro No."), '');
            OnCreateHeaderAddFields(TempNameValueBuffer, Salesperson, Country, Contact, CompanyInfo, SegLine, InteractionLogEntry);
            GlobalLanguage := MainLanguage;
            AddNewEntry(Text015, '');

            Reset;
            FieldCount := Count;
            if Find('-') then
                repeat
                    WordMergefile.AddField(Name);
                until Next = 0;
        end;

        // Mergesource must be at least two lines
        WordMergefile.WriteLine;
        if MergeFieldsOnly then begin
            for I := 1 to FieldCount do
                WordMergefile.AddField('');
            WordMergefile.WriteLine;
            WordMergefile.CloseMergeFile;
        end;
    end;

    local procedure WordHandler(var WordDocument: DotNet Document; var Attachment: Record Attachment; Caption: Text[260]; IsTemporary: Boolean; FileName: Text; IsInherited: Boolean) DocImported: Boolean
    var
        Attachment2: Record Attachment;
        [RunOnClient]
        WordHandler: DotNet WordHandler;
        NewFileName: Text;
    begin
        WordDocument.ActiveWindow.Caption := Caption;
        WordDocument.Application.Visible := true; // Visible before WindowState KB176866 - http://support.microsoft.com/kb/176866
        WordDocument.ActiveWindow.WindowState := 1; // 1 = wdWindowStateMaximize
        WordDocument.Saved := true;
        NewFileName := WaitForDocument(WordDocument, WordHandler);

        if not Attachment."Read Only" then
            if WordHandler.IsDocumentClosed then
                if WordHandler.HasDocumentChanged then begin
                    Clear(WordHandler);
                    if Confirm(ImportAttachmentQst, true, Caption) then begin
                        if (not IsTemporary) and Attachment2.Get(Attachment."No.") then
                            if Attachment2."Last Time Modified" <> Attachment."Last Time Modified" then begin
                                DeleteFile(FileName);
                                if NewFileName <> FileName then
                                    if Confirm(StrSubstNo(Text022, NewFileName), false) then
                                        DeleteFile(NewFileName);
                                Error(Text023, Attachment.TableCaption);
                            end;
                        Attachment.ImportAttachmentFromClientFile(NewFileName, IsTemporary, IsInherited);
                        DeleteFile(NewFileName);
                        DocImported := true;
                    end;
                end;

        Clear(WordHandler);
        DeleteFile(FileName);
    end;

    local procedure DeleteFile(FileName: Text): Boolean
    var
        I: Integer;
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteFile(FileName, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        // Wait for Word to release the files
        if FileName = '' then
            exit(false);

        if not FileMgt.ClientFileExists(FileName) then
            exit(true);

        repeat
            Sleep(250);
            I := I + 1;
        until FileMgt.DeleteClientFile(FileName) or (I = 25);
        exit(not FileMgt.ClientFileExists(FileName));
    end;

    local procedure DocumentContainMergefields(var Attachment: Record Attachment) MergeFields: Boolean
    var
        [RunOnClient]
        WordApplication: DotNet ApplicationClass;
        [RunOnClient]
        WordDocument: DotNet Document;
        ParamBln: Boolean;
        FileName: Text;
    begin
        GetWord(WordApplication);
        if (UpperCase(Attachment."File Extension") <> 'DOC') and
           (UpperCase(Attachment."File Extension") <> 'DOCX')
        then
            exit(false);
        FileName := Attachment.ConstFilename;
        Attachment.ExportAttachmentToClientFile(FileName);
        WordDocument := WordHelper.CallOpen(WordApplication, FileName, false, false);

        MergeFields := (WordDocument.MailMerge.Fields.Count > 0);
        ParamBln := false;
        WordHelper.CallClose(WordDocument, ParamBln);
        DeleteFile(FileName);

        Clear(WordDocument);
    end;

    local procedure CreateMergeSource(var MergeFile: File)
    var
        MergeServerFileName: Text;
    begin
        MergeServerFileName := FileMgt.ServerTempFileName('HTM');
        MergeFile.WriteMode := true;
        MergeFile.TextMode := true;
        MergeFile.Create(MergeServerFileName);
    end;

    local procedure CloseAndDownloadMergeSource(var MergeFile: File) MergeClientFileName: Text
    var
        MergeServerFileName: Text;
    begin
        MergeServerFileName := MergeFile.Name;
        MergeFile.Write('</table>');
        MergeFile.Write('</body>');
        MergeFile.Write('</html>');
        MergeFile.Close;

        MergeClientFileName := FileMgt.DownloadTempFile(MergeServerFileName);

        // We don't need the file any more on ServiceTier
        Erase(MergeServerFileName);

        exit(MergeClientFileName);
    end;

    [Scope('OnPrem')]
    procedure PopulateInterLogEntryToMergeSource(var MergeFile: File; var Attachment: Record Attachment; EntryNo: Integer; var HeaderIsReady: Boolean; CorrespondenceType: Option ,"Hard Copy",Email,Fax)
    var
        InteractLogEntry: Record "Interaction Log Entry";
        InStreamBLOB: InStream;
        CurrentLine: Text[250];
        NewLine: Text[250];
        LineIsFound: Boolean;
    begin
        Attachment.CalcFields("Merge Source");
        Attachment."Merge Source".CreateInStream(InStreamBLOB);
        repeat
            InStreamBLOB.ReadText(CurrentLine);
            if (StrPos(CurrentLine, '<tr>') > 0) and HeaderIsReady then begin
                InStreamBLOB.ReadText(NewLine);
                if StrPos(NewLine, Format(EntryNo)) > 0 then begin
                    MergeFile.Write(CurrentLine);
                    MergeFile.Write(NewLine);
                    LineIsFound := true;
                end;
            end;

            if not HeaderIsReady then begin
                MergeFile.Write(CurrentLine);
                if StrPos(CurrentLine, '</tr>') > 0 then
                    HeaderIsReady := true
            end
        until LineIsFound or InStreamBLOB.EOS;

        if LineIsFound then begin
            InStreamBLOB.ReadText(NewLine);
            while StrPos(NewLine, '</tr>') = 0 do begin
                CurrentLine := NewLine;
                InStreamBLOB.ReadText(NewLine);
                MergeFile.Write(CurrentLine);
            end;
            if InteractLogEntry.Get(EntryNo) then begin
                case CorrespondenceType of
                    CorrespondenceType::Fax:
                        MergeFile.Write('<td>' + AttachmentManagement.InteractionFax(InteractLogEntry) + '</td>');
                    CorrespondenceType::Email:
                        MergeFile.Write('<td>' + AttachmentManagement.InteractionEMail(InteractLogEntry) + '</td>');
                    CorrespondenceType::"Hard Copy":
                        MergeFile.Write('<td></td>');
                end;
            end;
            MergeFile.Write(NewLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure AddFieldsToMergeSource(var WordMergefile: DotNet MergeHandler; var InteractLogEntry: Record "Interaction Log Entry"; var SegLine: Record "Segment Line"; FaxMailToValue: Text; HeaderFieldsCount: Integer)
    var
        Salesperson: Record "Salesperson/Purchaser";
        Country: Record "Country/Region";
        Country2: Record "Country/Region";
        Contact: Record Contact;
        CompanyInfo: Record "Company Information";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        ContactAltAddressCode: Code[10];
        LineNo: Text;
        SalesPersonCode: Code[20];
        ContactNo: Code[20];
        LanguageCode: Code[10];
        Date: Date;
        DataFieldsCount: Integer;
    begin
        if InteractLogEntry.IsEmpty then begin
            ContactNo := SegLine."Contact No.";
            SalesPersonCode := SegLine."Salesperson Code";
            LineNo := Format(SegLine."Line No.");
            ContactAltAddressCode := SegLine."Contact Alt. Address Code";
            Date := SegLine.Date;
            LanguageCode := SegLine."Language Code";
        end else begin
            ContactNo := InteractLogEntry."Contact No.";
            SalesPersonCode := InteractLogEntry."Salesperson Code";
            LineNo := Format(InteractLogEntry."Entry No.");
            ContactAltAddressCode := InteractLogEntry."Contact Alt. Address Code";
            Date := InteractLogEntry.Date;
            LanguageCode := InteractLogEntry."Interaction Language Code";
        end;

        CompanyInfo.Get();
        if not Country2.Get(CompanyInfo."Country/Region Code") then
            Clear(Country2);

        Contact.Get(ContactNo);
        if not Country.Get(Contact."Country/Region Code") then
            Clear(Country);

        if not Salesperson.Get(SalesPersonCode) then
            Clear(Salesperson);

        // This field must come first in the merge source file
        WordMergefile.AddField(LineNo);
        AddMultilineFieldData(WordMergefile, Contact, ContactAltAddressCode, Date);
        DataFieldsCount := 2;

        TempNameValueBuffer.DeleteAll();
        with TempNameValueBuffer do begin
            AddNewEntry(Contact."No.", '');
            AddNewEntry(Contact."Company Name", '');
            AddNewEntry(Contact.Name, '');
            AddNewEntry(Contact."Name 2", '');
            AddNewEntry(Contact.Address, '');
            AddNewEntry(Contact."Address 2", '');
            AddNewEntry(Contact."Post Code", '');
            AddNewEntry(Contact.City, '');
            AddNewEntry(Contact.County, '');
            AddNewEntry(Country.Name, '');
            AddNewEntry(Contact."Job Title", '');
            AddNewEntry(Contact."Phone No.", '');
            AddNewEntry(Contact."Fax No.", '');
            AddNewEntry(Contact."E-Mail", '');
            AddNewEntry(Contact."Mobile Phone No.", '');
            AddNewEntry(Contact."VAT Registration No.", '');
            AddNewEntry(Contact."Home Page", '');
            AddNewEntry(CopyStr(Contact.GetSalutation(0, LanguageCode), 1, MaxStrLen(Name)), '');
            AddNewEntry(CopyStr(Contact.GetSalutation(1, LanguageCode), 1, MaxStrLen(Name)), '');
            AddNewEntry(Salesperson.Code, '');
            AddNewEntry(Salesperson.Name, '');
            AddNewEntry(Salesperson."Job Title", '');
            AddNewEntry(Salesperson."Phone No.", '');
            AddNewEntry(Salesperson."E-Mail", '');

            if InteractLogEntry.IsEmpty then begin
                AddNewEntry(Format(SegLine.Date), '');
                AddNewEntry(SegLine."Campaign No.", '');
                AddNewEntry(SegLine."Segment No.", '');
                AddNewEntry(SegLine.Description, '');
                AddNewEntry(SegLine.Subject, '');
            end else begin
                AddNewEntry(Format(InteractLogEntry.Date), '');
                AddNewEntry(InteractLogEntry."Campaign No.", '');
                AddNewEntry(InteractLogEntry."Segment No.", '');
                AddNewEntry(InteractLogEntry.Description, '');
                AddNewEntry(InteractLogEntry.Subject, '');
            end;

            AddNewEntry(CompanyInfo.Name, '');
            AddNewEntry(CompanyInfo."Name 2", '');
            AddNewEntry(CompanyInfo.Address, '');
            AddNewEntry(CompanyInfo."Address 2", '');
            AddNewEntry(CompanyInfo."Post Code", '');
            AddNewEntry(CompanyInfo.City, '');
            AddNewEntry(CompanyInfo.County, '');
            AddNewEntry(Country2.Name, '');
            AddNewEntry(CompanyInfo."VAT Registration No.", '');
            AddNewEntry(CompanyInfo."Registration No.", '');
            AddNewEntry(CompanyInfo."Phone No.", '');
            AddNewEntry(CompanyInfo."Fax No.", '');
            AddNewEntry(CompanyInfo."Bank Branch No.", '');
            AddNewEntry(CompanyInfo."Bank Name", '');
            AddNewEntry(CompanyInfo."Bank Account No.", '');
            AddNewEntry(CompanyInfo."Giro No.", '');
            OnAddFieldsToMergeSource(TempNameValueBuffer, Salesperson, Country, Contact, CompanyInfo, SegLine, InteractLogEntry);
            AddNewEntry(CopyStr(FaxMailToValue, 1, MaxStrLen(Name)), '');
            DataFieldsCount += Count;
            if HeaderFieldsCount <> DataFieldsCount then
                Error(FieldCountMismatchErr, HeaderFieldsCount, DataFieldsCount);

            Reset;
            if Find('-') then
                repeat
                    WordMergefile.AddField(Name);
                until Next = 0;

            WordMergefile.WriteLine;
        end;
    end;

    local procedure AddMultilineFieldData(var WordMergefile: DotNet MergeHandler; Contact: Record Contact; ContactAltAddressCode: Code[10]; Date: Date)
    var
        FormatAddr: Codeunit "Format Address";
        ContAddr: array[8] of Text[100];
        ContAddr2: array[8] of Text[100];
        ContactAddressDimension: Integer;
    begin
        ContactAddressDimension := 1;
        FormatAddr.ContactAddrAlt(ContAddr, Contact, ContactAltAddressCode, Date);

        WordMergefile.OpenNewMultipleValueField;
        CopyArray(ContAddr2, ContAddr, 1);
        CompressArray(ContAddr2);
        while ContAddr2[1] <> '' do begin
            if ContAddr[ContactAddressDimension] <> '' then begin
                WordMergefile.AddDataToMultipleValueField(ContAddr[ContactAddressDimension]);
                ContAddr2[1] := '';
                CompressArray(ContAddr2);
            end else
                WordMergefile.AddDataToMultipleValueField('&nbsp;');
            ContactAddressDimension := ContactAddressDimension + 1;
        end;
        WordMergefile.CloseMultipleValueField;
    end;

    local procedure ImportMergeSourceFile(AttachmentNo: Integer)
    var
        Attachment: Record Attachment;
    begin
        Attachment.Get(AttachmentNo);
        Attachment.CalcFields("Merge Source", "Attachment File");
        if not Attachment."Merge Source".HasValue then begin
            if not DocumentContainMergefields(Attachment) then
                exit;
            MergeSourceBufferFile.Write('</table>');
            MergeSourceBufferFile.Write('</body>');
            MergeSourceBufferFile.Write('</html>');
            MergeSourceBufferFile.Close;
            Attachment."Merge Source".Import(MergeSourceBufferFileName);
            Attachment.Modify();
            DeleteFile(MergeSourceBufferFileName);
            MergeSourceBufferFileName := ''
        end
    end;

    local procedure AppendToMergeSource(MergeFileName: Text)
    var
        SourceFile: File;
        CurrentLine: Text[250];
        SkipHeader: Boolean;
        MergeFileNameServer: Text;
    begin
        if MergeSourceBufferFileName = '' then begin
            MergeSourceBufferFileName := FileMgt.ServerTempFileName('HTM');
            MergeSourceBufferFile.WriteMode := true;
            MergeSourceBufferFile.TextMode := true;
            MergeSourceBufferFile.Create(MergeSourceBufferFileName);
        end else
            SkipHeader := true;
        SourceFile.TextMode := true;

        MergeFileNameServer := FileMgt.ServerTempFileName('HTM');
        Upload(Text021, '', Text032, MergeFileName, MergeFileNameServer);

        SourceFile.Open(MergeFileNameServer);
        if SkipHeader then
            repeat
                SourceFile.Read(CurrentLine)
            until (StrPos(CurrentLine, '</tr>') <> 0);
        while (StrPos(CurrentLine, '</table>') = 0) and (SourceFile.Pos <> SourceFile.Len) do begin
            SourceFile.Read(CurrentLine);
            if StrPos(CurrentLine, '</table>') = 0 then
                MergeSourceBufferFile.Write(CurrentLine);
        end;
        SourceFile.Close;

        Erase(MergeFileNameServer);
    end;

    procedure GetWordDocumentExtension(VersionTxt: Text[30]): Code[4]
    var
        Version: Decimal;
        SeparatorPos: Integer;
        CommaStr: Code[1];
        DefaultStr: Code[10];
        EvalOK: Boolean;
    begin
        DefaultStr := 'DOC';
        SeparatorPos := StrPos(VersionTxt, '.');
        if SeparatorPos = 0 then
            SeparatorPos := StrPos(VersionTxt, ',');
        if SeparatorPos = 0 then
            EvalOK := Evaluate(Version, VersionTxt)
        else begin
            CommaStr := CopyStr(Format(11 / 10), 2, 1);
            EvalOK := Evaluate(Version, CopyStr(VersionTxt, 1, SeparatorPos - 1) + CommaStr + CopyStr(VersionTxt, SeparatorPos + 1));
        end;
        if EvalOK and (Version >= 12.0) then
            exit('DOCX');
        exit(DefaultStr);
    end;

    local procedure HandleWordDocumentWithoutMerge(var WordDocument: DotNet Document; var DeliverySorter: Record "Delivery Sorter"; MainFileName: Text)
    var
        InteractLogEntry: Record "Interaction Log Entry";
        Contact: Record Contact;
        Mail: Codeunit Mail;
        Handled: Boolean;
    begin
        with InteractLogEntry do
            repeat
                LockTable();
                Get(DeliverySorter."No.");
                case DeliverySorter."Correspondence Type" of
                    DeliverySorter."Correspondence Type"::Email:
                        begin
                            Contact.Get("Contact No.");
                            Mail.NewMessage(
                              AttachmentManagement.InteractionEMail(InteractLogEntry), '', '',
                              DeliverySorter.Subject, '', MainFileName, false);
                        end;
                    DeliverySorter."Correspondence Type"::"Hard Copy",
                    DeliverySorter."Correspondence Type"::Fax:
                        WordHelper.CallPrintOut(WordDocument);
                    else
                        OnHandleWordDocumentWithoutMergeCorrespondenceTypeCaseElse(InteractLogEntry, DeliverySorter);
                end;
                "Delivery Status" := "Delivery Status"::" ";
                Modify;
                Commit();
            until DeliverySorter.Next = 0;
    end;

    local procedure SendAttachmentWithoutMergeFields(var WordApplication: DotNet ApplicationClass; var TempDeliverySorter: Record "Delivery Sorter" temporary; var Attachment: Record Attachment)
    var
        [RunOnClient]
        WordDocument: DotNet Document;
        FileName: Text;
    begin
        FileName := FileMgt.ClientTempFileName('DOC');
        Attachment.ExportAttachmentToClientFile(FileName);
        case TempDeliverySorter."Correspondence Type" of
            TempDeliverySorter."Correspondence Type"::"Hard Copy":
                begin
                    WordDocument := WordHelper.CallOpen(WordApplication, FileName, false, false);
                    HandleWordDocumentWithoutMerge(WordDocument, TempDeliverySorter, FileName);
                    WordHelper.CallClose(WordDocument, false);
                end;
            TempDeliverySorter."Correspondence Type"::Email:
                begin
                    // Send attachment to all contacts in buffer
                    Window.Update(6, Text009);
                    Attachment.TestField("File Extension");
                    HandleWordDocumentWithoutMerge(WordDocument, TempDeliverySorter, FileName);
                    DeleteFile(FileName);
                end;
            else
                OnSendAttachmentWithoutMergeFieldsCorrespondenceTypeCaseElse(Attachment, TempDeliverySorter);
        end;
    end;

    procedure IsWordDocumentExtension(FileExtension: Text): Boolean
    begin
        if (UpperCase(FileExtension) <> 'DOC') and
           (UpperCase(FileExtension) <> 'DOCX') and
           (UpperCase(FileExtension) <> '.DOC') and
           (UpperCase(FileExtension) <> '.DOCX')
        then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure RunMergedDocument(var SegLine: Record "Segment Line"; var Attachment: Record Attachment; WordCaption: Text[260]; IsTemporary: Boolean; IsVisible: Boolean; Handler: Boolean)
    var
        TempInteractLogEntry: Record "Interaction Log Entry" temporary;
        WordApplicationHandler: Codeunit WordApplicationHandler;
        [RunOnClient]
        WordMergefile: DotNet MergeHandler;
        [RunOnClient]
        WordApplication: DotNet ApplicationClass;
        [RunOnClient]
        WordDocument: DotNet Document;
        MergeFile: File;
        MergeClientFileName: Text;
        MainFileName: Text;
        ParamInt: Integer;
        IsInherited: Boolean;
        HeaderIsReady: Boolean;
        HeaderFieldCount: Integer;
    begin
        if not IsWordDocumentExtension(Attachment."File Extension") then
            Error(Text010, Attachment.TableCaption, Attachment."No.", Attachment.FieldCaption("File Extension"));

        if SegLine.AttachmentInherited then
            IsInherited := true;

        MainFileName := FileMgt.ClientTempFileName('DOC');

        // Handle Word documents without mergefields
        Activate(WordApplicationHandler, 505404);
        GetWord(WordApplication);
        if not DocumentContainMergefields(Attachment) then begin
            Attachment.ExportAttachmentToClientFile(MainFileName);
            WordDocument := WordHelper.CallOpen(WordApplication, MainFileName, false, Attachment."Read Only");
        end else begin
            // Merge possible
            if not Attachment.ExportAttachmentToClientFile(MainFileName) then begin
                Deactivate(505404);
                Error(Text011);
            end;

            Attachment.CalcFields("Merge Source");
            if Attachment."Merge Source".HasValue then begin
                CreateMergeSource(MergeFile);
                PopulateInterLogEntryToMergeSource(MergeFile, Attachment, SegLine."Line No.", HeaderIsReady, 0);
                MergeClientFileName := CloseAndDownloadMergeSource(MergeFile);
            end else begin
                MergeClientFileName := FileMgt.ClientTempFileName('HTM');
                WordMergefile := WordMergefile.MergeHandler;
                HeaderFieldCount := CreateHeader(WordMergefile, false, MergeClientFileName, SegLine."Language Code");

                AddFieldsToMergeSource(WordMergefile, TempInteractLogEntry, SegLine, '', HeaderFieldCount);
                WordMergefile.CloseMergeFile;
            end;

            WordDocument := WordHelper.CallOpen(WordApplication, MainFileName, false, false);
            WordDocument.MailMerge.MainDocumentType := 0;
            ParamInt := 7; // 7 = HTML
            WordHelper.CallMailMergeOpenDataSource(WordDocument, MergeClientFileName, ParamInt);
            ParamInt := 9999998; // 9999998 = wdToggle
            WordDocument.MailMerge.ViewMailMergeFieldCodes(ParamInt);
        end;

        TmpWordDocument := WordHelper.AddDocument(WordApplication); // to keep the word instance alive after WordDocument is closed manually
        if Handler then
            WordHandler(WordDocument, Attachment, WordCaption, IsTemporary, MainFileName, IsInherited)
        else
            WordMerge(WordDocument, Attachment, WordCaption, IsTemporary, MainFileName, IsInherited, IsVisible);

        WordHelper.CallClose(TmpWordDocument, false);
        Clear(TmpWordDocument);
        Clear(WordMergefile);
        Clear(WordDocument);
        Deactivate(505404);

        DeleteFile(MergeClientFileName);
    end;

    local procedure WordMerge(var WordDocument: DotNet Document; var Attachment: Record Attachment; Caption: Text[260]; IsTemporary: Boolean; FileName: Text; IsInherited: Boolean; IsVisible: Boolean) DocImported: Boolean
    var
        FileManagement: Codeunit "File Management";
        [RunOnClient]
        WordHandler: DotNet WordHandler;
        TempFileName: Text;
        NewFileName: Text;
    begin
        if IsVisible then begin
            WordDocument.ActiveWindow.Caption := Caption;
            WordDocument.Application.Visible := true; // Visible before WindowState KB176866 - http://support.microsoft.com/kb/176866
            WordDocument.ActiveWindow.WindowState := 1; // 1 = wdWindowStateMaximize
            NewFileName := WaitForDocument(WordDocument, WordHandler);
            Clear(WordHandler);
        end else begin
            WordHelper.CallClose(WordDocument, true);
            NewFileName := FileName;
        end;

        if IsTemporary then begin
            TempFileName := FileManagement.ClientTempFileName(FileManagement.GetExtension(NewFileName));
            FileManagement.CopyClientFile(NewFileName, TempFileName, true);
            Attachment.ImportAttachmentFromClientFile(TempFileName, IsTemporary, IsInherited);
            FileManagement.DeleteClientFile(TempFileName);
            DeleteFile(NewFileName);
            DocImported := true;
        end;

        DeleteFile(FileName);
    end;

    local procedure WaitForDocument(var WordDocument: DotNet Document; var WordHandler: DotNet WordHandler): Text
    begin
        WordDocument.Application.Activate;
        if not IsNull(TmpWordDocument) then
            TmpWordDocument.ActiveWindow.Visible := false;
        WordHandler := WordHandler.WordHandler;
        exit(WordHandler.WaitForDocument(WordDocument));
    end;

    [Scope('OnPrem')]
    procedure CanRunWordApp() CanRunWord: Boolean
    var
        CanRunWordModified: Boolean;
    begin
        OnBeforeCheckCanRunWord(CanRunWord, CanRunWordModified);
        if CanRunWordModified then
            exit(CanRunWord);
        CanRunWord := IsActive;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddFieldsToMergeSource(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; Salesperson: Record "Salesperson/Purchaser"; Country: Record "Country/Region"; Contact: Record Contact; CompanyInfo: Record "Company Information"; SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateHeaderAddFields(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; Salesperson: Record "Salesperson/Purchaser"; Country: Record "Country/Region"; Contact: Record Contact; CompanyInfo: Record "Company Information"; SegmentLine: Record "Segment Line"; InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddFieldsToMergeSource(var TempSegmentLine: Record "Segment Line" temporary; var TempDeliverySorter: Record "Delivery Sorter" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCanRunWord(var CanRunWord: Boolean; var CanRunWordModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteFile(FileName: Text; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindActiveSubscriber(var IsFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetWord(var NewWordApplication: DotNet ApplicationClass; var IsFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeactivate(HandlerID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExecuteMergeFaxMailToValueCaseElse(var v: Record "Delivery Sorter"; var FaxMailToValue: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExecuteMergeWordDocumentCaseElse(var v: Record "Delivery Sorter")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleWordDocumentWithoutMergeCorrespondenceTypeCaseElse(var InteractionLogEntry: Record "Interaction Log Entry"; var DeliverySorter: Record "Delivery Sorter")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendAttachmentWithoutMergeFieldsCorrespondenceTypeCaseElse(var Attachment: Record Attachment; var DeliverySorter: Record "Delivery Sorter")
    begin
    end;
}

