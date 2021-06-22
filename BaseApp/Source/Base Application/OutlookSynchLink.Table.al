table 5302 "Outlook Synch. Link"
{
    Caption = 'Outlook Synch. Link';
    ReplicateData = false;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(2; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Outlook Entry ID"; BLOB)
        {
            Caption = 'Outlook Entry ID';
        }
        field(4; "Outlook Entry ID Hash"; Text[32])
        {
            Caption = 'Outlook Entry ID Hash';
        }
        field(5; "Search Record ID"; Code[250])
        {
            Caption = 'Search Record ID';
        }
        field(6; "Synchronization Date"; DateTime)
        {
            Caption = 'Synchronization Date';
        }
    }

    keys
    {
        key(Key1; "User ID", "Record ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Search Record ID" := Format("Record ID");
    end;

    trigger OnRename()
    begin
        if Format("Record ID") <> Format(xRec."Record ID") then
            "Search Record ID" := Format("Record ID");
    end;

    procedure GetEntryID(var EntryID: Text): Boolean
    var
        InStrm: InStream;
    begin
        CalcFields("Outlook Entry ID");
        "Outlook Entry ID".CreateInStream(InStrm);

        InStrm.ReadText(EntryID);

        exit("Outlook Entry ID".HasValue);
    end;

    [Scope('OnPrem')]
    procedure PutEntryID(EntryID: Text; OEntryIDHash: Text[32]): Boolean
    begin
        "Outlook Entry ID Hash" := OEntryIDHash;
        FillEntryID(Rec, EntryID);
        Modify;
        exit("Outlook Entry ID".HasValue);
    end;

    [Scope('OnPrem')]
    procedure InsertOSynchLink(UserID: Code[50]; EntryID: Text; RecRef: RecordRef; OEntryIDHash: Text[32])
    var
        RecID: RecordID;
    begin
        Evaluate(RecID, Format(RecRef.RecordId));
        if Get(UserID, RecID) then
            exit;

        Init;
        "User ID" := UserID;
        "Record ID" := RecID;
        "Search Record ID" := Format(RecID);
        "Outlook Entry ID Hash" := OEntryIDHash;
        FillEntryID(Rec, EntryID);
        Insert;
    end;

    local procedure FillEntryID(var OSynchLink: Record "Outlook Synch. Link"; EntryID: Text)
    var
        OutStrm: OutStream;
    begin
        OSynchLink."Outlook Entry ID".CreateOutStream(OutStrm);
        OutStrm.WriteText(EntryID);
    end;
}

