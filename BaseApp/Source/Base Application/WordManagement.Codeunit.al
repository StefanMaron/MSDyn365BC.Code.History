#if not CLEAN19
codeunit 5054 WordManagement
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Word DotNet libraries do not work in any of the supported clients. The functionality is replaced with Word Template Interactions codeunit.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
    end;

    var
        AttachmentManagement: Codeunit AttachmentManagement;
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
        ActiveDate: Date;
        DataFieldsCount: Integer;
    begin
        InitMergeFields(InteractLogEntry, SegLine, ContactAltAddressCode, LineNo, SalesPersonCode, ContactNo, LanguageCode, ActiveDate);

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
        AddMultilineFieldData(WordMergefile, Contact, ContactAltAddressCode, ActiveDate);
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
            AddNewEntry(CopyStr(Contact.GetSalutation("Salutation Formula Salutation Type"::Formal, LanguageCode), 1, MaxStrLen(Name)), '');
            AddNewEntry(CopyStr(Contact.GetSalutation("Salutation Formula Salutation Type"::Informal, LanguageCode), 1, MaxStrLen(Name)), '');
            AddNewEntry(Salesperson.Code, '');
            AddNewEntry(Salesperson.Name, '');
            AddNewEntry(Salesperson."Job Title", '');
            AddNewEntry(Salesperson."Phone No.", '');
            AddNewEntry(Salesperson."E-Mail", '');

            if InteractLogEntry.IsEmpty() then begin
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
                until Next() = 0;

            WordMergefile.WriteLine;
        end;
    end;

    local procedure InitMergeFields(var InteractionLogEntry: Record "Interaction Log Entry"; var SegmentLine: Record "Segment Line";
          var ContactAltAddressCode: Code[10]; var LineNo: Text; var SalesPersonCode: Code[20]; var ContactNo: Code[20]; var LanguageCode: Code[10]; var ActiveDate: Date)
    begin
        OnBeforeInitMergeFields(InteractionLogEntry, SegmentLine);

        if InteractionLogEntry.IsEmpty() then begin
            ContactNo := SegmentLine."Contact No.";
            SalesPersonCode := SegmentLine."Salesperson Code";
            LineNo := Format(SegmentLine."Line No.");
            ContactAltAddressCode := SegmentLine."Contact Alt. Address Code";
            LanguageCode := SegmentLine."Language Code";
            ActiveDate := SegmentLine.Date;
        end else begin
            ContactNo := InteractionLogEntry."Contact No.";
            SalesPersonCode := InteractionLogEntry."Salesperson Code";
            LineNo := Format(InteractionLogEntry."Entry No.");
            ContactAltAddressCode := InteractionLogEntry."Contact Alt. Address Code";
            LanguageCode := InteractionLogEntry."Interaction Language Code";
            ActiveDate := InteractionLogEntry.Date;
        end;
    end;

    local procedure AddMultilineFieldData(var WordMergefile: DotNet MergeHandler; Contact: Record Contact; ContactAltAddressCode: Code[10]; Date: Date)
    var
        FormatAddr: Codeunit "Format Address";
        ContAddr: array[8] of Text[100];
        ContAddr2: array[8] of Text[100];
        ContactAddressDimension: Integer;
        IsHandled: Boolean;
    begin
        ContactAddressDimension := 1;
        IsHandled := false;
        OnAddMultilineFieldDataOnBeforeFormatContactAddr(ContAddr, Contact, ContactAltAddressCode, Date, IsHandled);
        if not IsHandled then
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
    local procedure OnAddMultilineFieldDataOnBeforeFormatContactAddr(var ContAddr: array[8] of Text[100]; Contact: Record Contact; ContactAltAddressCode: Code[10]; Date: Date; var Ishandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCanRunWord(var CanRunWord: Boolean; var CanRunWordModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitMergeFields(var InteractionLogEntry: Record "Interaction Log Entry"; var SegmentLine: Record "Segment Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindActiveSubscriber(var IsFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeactivate(HandlerID: Integer)
    begin
    end;

}
#endif