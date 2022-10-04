table 2156 "O365 Payment Instr. Transl."
{
    Caption = 'O365 Payment Instr. Transl.';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(3; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            DataClassification = SystemMetadata;
        }
        field(5; "Transl. Name"; Text[20])
        {
            Caption = 'Transl. Name';
        }
        field(6; "Transl. Payment Instructions"; Text[250])
        {
            Caption = 'Transl. Payment Instructions';
        }
        field(7; "Transl. Payment Instr. Blob"; BLOB)
        {
            Caption = 'Transl. Payment Instr. Blob';
        }
    }

    keys
    {
        key(Key1; Id, "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
#if not CLEAN21
    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetTransPaymentInstructions(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Transl. Payment Instr. Blob");
        if not "Transl. Payment Instr. Blob".HasValue() then
            exit("Transl. Payment Instructions");
        "Transl. Payment Instr. Blob".CreateInStream(InStream, TEXTENCODING::Windows);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SetTranslPaymentInstructions(NewParameter: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Transl. Payment Instr. Blob");
        "Transl. Payment Instructions" := CopyStr(NewParameter, 1, MaxStrLen("Transl. Payment Instructions"));
        if StrLen(NewParameter) <= MaxStrLen("Transl. Payment Instructions") then
            exit; // No need to store anything in the blob
        if NewParameter = '' then
            exit;

        "Transl. Payment Instr. Blob".CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(NewParameter);
        Modify();
    end;
#endif
}

