table 31044 "FA History Entry"
{
    Caption = 'FA History Entry';
    LookupPageID = "FA History Entries";
    Permissions = TableData "FA History Entry" = rimd;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            Editable = false;
            OptionCaption = 'Location,Responsible Employee';
            OptionMembers = Location,"Responsible Employee";
        }
        field(3; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            Editable = false;
            TableRelation = "Fixed Asset"."No.";
        }
        field(4; "Old Value"; Code[20])
        {
            Caption = 'Old Value';
            Editable = false;
            TableRelation = IF (Type = CONST(Location)) "FA Location".Code
            ELSE
            IF (Type = CONST("Responsible Employee")) Employee."No.";
        }
        field(5; "New Value"; Code[20])
        {
            Caption = 'New Value';
            Editable = false;
            TableRelation = IF (Type = CONST(Location)) "FA Location".Code
            ELSE
            IF (Type = CONST("Responsible Employee")) Employee."No.";
        }
        field(6; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(7; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            Editable = false;
        }
        field(8; Disposal; Boolean)
        {
            Caption = 'Disposal';
            Editable = false;
        }
        field(9; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
            Editable = false;
        }
        field(10; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "FA No.")
        {
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure InsertEntry(FAHType: Option Location,"Responsible Employee"; FANo: Code[20]; OldValue: Code[20]; NewValue: Code[20]; ClosedByEntryNo: Integer; Disp: Boolean): Integer
    var
        FAHistoryEntry: Record "FA History Entry";
    begin
        FAHistoryEntry.Init;
        FAHistoryEntry.Type := FAHType;
        FAHistoryEntry."FA No." := FANo;
        FAHistoryEntry."Old Value" := OldValue;
        FAHistoryEntry."New Value" := NewValue;
        FAHistoryEntry."Closed by Entry No." := ClosedByEntryNo;
        FAHistoryEntry.Disposal := Disp;
        FAHistoryEntry."Creation Date" := Today;
        FAHistoryEntry."User ID" := UserId;
        FAHistoryEntry."Creation Time" := Time;
        FAHistoryEntry.Insert;

        exit(FAHistoryEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure InitializeFAHistory(FixedAsset: Record "Fixed Asset"; CreationDate: Date)
    var
        FAHistoryEntry: Record "FA History Entry";
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        NextEntryNo: Integer;
        Counter: Integer;
    begin
        with FixedAsset do begin
            FAHistoryEntry.SetRange("FA No.", "No.");
            if FAHistoryEntry.FindFirst or (("FA Location Code" = '') and ("Responsible Employee" = '')) then
                exit;

            Counter := 0;
            NextEntryNo := 0;

            FASetup.Get();
            FADeprBook.SetRange("FA No.", "No.");
            FADeprBook.SetRange("Depreciation Book Code", FASetup."Default Depr. Book");

            FAHistoryEntry.Reset;
            while Counter < 2 do begin
                if NextEntryNo = 0 then begin
                    if FAHistoryEntry.FindLast then
                        NextEntryNo := FAHistoryEntry."Entry No.";
                end;
                FAHistoryEntry."FA No." := "No.";
                FAHistoryEntry."Creation Date" := CreationDate;
                FAHistoryEntry."User ID" := UserId;
                FAHistoryEntry."Creation Time" := Time;
                FAHistoryEntry."Closed by Entry No." := 0;
                if FADeprBook.FindLast then
                    if FADeprBook."Disposal Date" > 0D then
                        FAHistoryEntry.Disposal := true
                    else
                        FAHistoryEntry.Disposal := false;
                if (Counter = 0) and ("FA Location Code" <> '') then begin
                    NextEntryNo := NextEntryNo + 1;
                    FAHistoryEntry."Entry No." := NextEntryNo;
                    FAHistoryEntry.Type := FAHistoryEntry.Type::Location;
                    FAHistoryEntry."Old Value" := '';
                    FAHistoryEntry."New Value" := "FA Location Code";
                    FAHistoryEntry.Insert;
                end else
                    if (Counter = 1) and ("Responsible Employee" <> '') then begin
                        NextEntryNo := NextEntryNo + 1;
                        FAHistoryEntry."Entry No." := NextEntryNo;
                        FAHistoryEntry.Type := FAHistoryEntry.Type::"Responsible Employee";
                        FAHistoryEntry."Old Value" := '';
                        FAHistoryEntry."New Value" := "Responsible Employee";
                        FAHistoryEntry.Insert;
                    end;
                Counter := Counter + 1;
            end;
        end;
    end;
}

