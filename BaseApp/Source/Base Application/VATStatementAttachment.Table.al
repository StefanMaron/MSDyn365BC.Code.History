table 11773 "VAT Statement Attachment"
{
    Caption = 'VAT Statement Attachment';
#if CLEAN17
    ObsoleteState = Removed;
#else
    DrillDownPageID = "VAT Statement Attachment List";
    LookupPageID = "VAT Statement Attachment List";
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "VAT Statement Template Name"; Code[10])
        {
            Caption = 'VAT Statement Template Name';
            NotBlank = true;
            TableRelation = "VAT Statement Template";
        }
        field(2; "VAT Statement Name"; Code[10])
        {
            Caption = 'VAT Statement Name';
            NotBlank = true;
            TableRelation = "VAT Statement Name".Name;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(6; Attachment; BLOB)
        {
            Caption = 'Attachment';
        }
        field(7; "File Name"; Text[250])
        {
            Caption = 'File Name';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "VAT Statement Template Name", "VAT Statement Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
#if not CLEAN17

    trigger OnInsert()
    begin
        CheckAllowance;
    end;

    var
        ReplaceQst: Label 'Do you want to replace the existing attachment?';
        SizeErr: Label 'The file size must not exceed 4 Mb.';

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CheckAllowance()
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        VATStatementTemplate.Get("VAT Statement Template Name");
        VATStatementTemplate.TestField("Allow Comments/Attachments");
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure Import(): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        RecordRef: RecordRef;
        AttachmentExists: Boolean;
        FullFileName: Text;
        ServerFileName: Text;
    begin
        CalcFields(Attachment);
        AttachmentExists := Attachment.HasValue;
        FullFileName := FileMgt.BLOBImport(TempBlob, '*.*');
        if FullFileName = '' then
            exit(false);

        ServerFileName := FileMgt.ServerTempFileName('');
        FileMgt.BLOBExportToServerFile(TempBlob, ServerFileName);

        CheckSize(ServerFileName);

        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo(Attachment));
        RecordRef.SetTable(Rec);

        if AttachmentExists then
            if not Confirm(ReplaceQst, false) then
                exit(false);

        if FullFileName <> '' then
            "File Name" := CopyStr(RemovePathName(FullFileName), 1, MaxStrLen("File Name"));

        Erase(ServerFileName);

        CheckFileNameDuplicates;
        exit(true);
    end;

    local procedure RemovePathName(FileName: Text): Text
    var
        Pos: Integer;
        Found: Boolean;
    begin
        Pos := StrLen(FileName);
        while (Pos > 0) and not Found do begin
            Found := FileName[Pos] = '\';
            if not Found then
                Pos -= 1;
        end;
        exit(CopyStr(FileName, Pos + 1));
    end;

    local procedure CheckSize(FileName: Text)
    var
        FileMgt: Codeunit "File Management";
        MaxSize: Integer;
    begin
        MaxSize := 4194304;

        if FileMgt.ServerFileExists(FileName) then
            if MaxSize < FileMgt.GetServerFileSize(FileName) then
                Error(SizeErr);
    end;

    local procedure CheckFileNameDuplicates()
    var
        VATStatementAttachment: Record "VAT Statement Attachment";
    begin
        VATStatementAttachment.SetRange("VAT Statement Template Name", "VAT Statement Template Name");
        VATStatementAttachment.SetRange("VAT Statement Name", "VAT Statement Name");
        VATStatementAttachment.SetFilter("Line No.", '<>%1', "Line No.");
        VATStatementAttachment.SetRange("File Name", "File Name");
        if not VATStatementAttachment.IsEmpty() then
            FieldError("File Name");
    end;
#endif
}