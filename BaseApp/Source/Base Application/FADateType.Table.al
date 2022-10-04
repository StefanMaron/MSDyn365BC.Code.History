table 5645 "FA Date Type"
{
    Caption = 'FA Date Type';
    LookupPageID = "FA Date Types";

    fields
    {
        field(1; "FA Date Type No."; Integer)
        {
            Caption = 'FA Date Type No.';
        }
        field(2; "FA Date Type Name"; Text[50])
        {
            Caption = 'FA Date Type Name';
        }
        field(3; "FA Entry"; Boolean)
        {
            Caption = 'FA Entry';
        }
        field(4; "G/L Entry"; Boolean)
        {
            Caption = 'G/L Entry';
        }
        field(5; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
    }

    keys
    {
        key(Key1; "FA Date Type No.", "FA Date Type Name")
        {
            Clustered = true;
        }
        key(Key2; "Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure CreateTypes()
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        LockTable();
        if not Find('-') then begin
            "FA Entry" := true;
            "G/L Entry" := true;
            InsertRec(1, FADeprBook.FieldNo("Last Acquisition Cost Date"), FADeprBook.FieldCaption("Last Acquisition Cost Date"));
            InsertRec(2, FADeprBook.FieldNo("Last Depreciation Date"), FADeprBook.FieldCaption("Last Depreciation Date"));
            InsertRec(3, FADeprBook.FieldNo("Last Write-Down Date"), FADeprBook.FieldCaption("Last Write-Down Date"));
            InsertRec(4, FADeprBook.FieldNo("Last Appreciation Date"), FADeprBook.FieldCaption("Last Appreciation Date"));
            InsertRec(5, FADeprBook.FieldNo("Last Custom 1 Date"), FADeprBook.FieldCaption("Last Custom 1 Date"));
            InsertRec(6, FADeprBook.FieldNo("Last Custom 2 Date"), FADeprBook.FieldCaption("Last Custom 2 Date"));
            InsertRec(7, FADeprBook.FieldNo("Disposal Date"), FADeprBook.FieldCaption("Disposal Date"));
            InsertRec(8, FADeprBook.FieldNo("Last Salvage Value Date"), FADeprBook.FieldCaption("Last Salvage Value Date"));
            "G/L Entry" := false;
            InsertRec(9, FADeprBook.FieldNo("Acquisition Date"), FADeprBook.FieldCaption("Acquisition Date"));
            "FA Entry" := false;
            "G/L Entry" := true;
            InsertRec(10, FADeprBook.FieldNo("G/L Acquisition Date"), FADeprBook.FieldCaption("G/L Acquisition Date"));
        end else begin
            SetCurrentKey("Entry No.");
            Find('-');
            repeat
                if "Entry No." = 1 then
                    if ("FA Date Type No." <> FADeprBook.FieldNo("Last Acquisition Cost Date")) or
                       ("FA Date Type Name" <> FADeprBook.FieldCaption("Last Acquisition Cost Date"))
                    then begin
                        Delete();
                        InsertRec(1, FADeprBook.FieldNo("Last Acquisition Cost Date"), FADeprBook.FieldCaption("Last Acquisition Cost Date"));
                    end;
                if "Entry No." = 2 then
                    if ("FA Date Type No." <> FADeprBook.FieldNo("Last Depreciation Date")) or
                       ("FA Date Type Name" <> FADeprBook.FieldCaption("Last Depreciation Date"))
                    then begin
                        Delete();
                        InsertRec(2, FADeprBook.FieldNo("Last Depreciation Date"), FADeprBook.FieldCaption("Last Depreciation Date"));
                    end;
                if "Entry No." = 3 then
                    if ("FA Date Type No." <> FADeprBook.FieldNo("Last Write-Down Date")) or
                       ("FA Date Type Name" <> FADeprBook.FieldCaption("Last Write-Down Date"))
                    then begin
                        Delete();
                        InsertRec(3, FADeprBook.FieldNo("Last Write-Down Date"), FADeprBook.FieldCaption("Last Write-Down Date"));
                    end;
                if "Entry No." = 4 then
                    if ("FA Date Type No." <> FADeprBook.FieldNo("Last Appreciation Date")) or
                       ("FA Date Type Name" <> FADeprBook.FieldCaption("Last Appreciation Date"))
                    then begin
                        Delete();
                        InsertRec(4, FADeprBook.FieldNo("Last Appreciation Date"), FADeprBook.FieldCaption("Last Appreciation Date"));
                    end;
                if "Entry No." = 5 then
                    if ("FA Date Type No." <> FADeprBook.FieldNo("Last Custom 1 Date")) or
                       ("FA Date Type Name" <> FADeprBook.FieldCaption("Last Custom 1 Date"))
                    then begin
                        Delete();
                        InsertRec(5, FADeprBook.FieldNo("Last Custom 1 Date"), FADeprBook.FieldCaption("Last Custom 1 Date"));
                    end;
                if "Entry No." = 6 then
                    if ("FA Date Type No." <> FADeprBook.FieldNo("Last Custom 2 Date")) or
                       ("FA Date Type Name" <> FADeprBook.FieldCaption("Last Custom 2 Date"))
                    then begin
                        Delete();
                        InsertRec(6, FADeprBook.FieldNo("Last Custom 2 Date"), FADeprBook.FieldCaption("Last Custom 2 Date"));
                    end;
                if "Entry No." = 7 then
                    if ("FA Date Type No." <> FADeprBook.FieldNo("Disposal Date")) or
                       ("FA Date Type Name" <> FADeprBook.FieldCaption("Disposal Date"))
                    then begin
                        Delete();
                        InsertRec(7, FADeprBook.FieldNo("Disposal Date"), FADeprBook.FieldCaption("Disposal Date"));
                    end;
                if "Entry No." = 8 then
                    if ("FA Date Type No." <> FADeprBook.FieldNo("Last Salvage Value Date")) or
                       ("FA Date Type Name" <> FADeprBook.FieldCaption("Last Salvage Value Date"))
                    then begin
                        Delete();
                        InsertRec(8, FADeprBook.FieldNo("Last Salvage Value Date"), FADeprBook.FieldCaption("Last Salvage Value Date"));
                    end;
                if "Entry No." = 9 then
                    if ("FA Date Type No." <> FADeprBook.FieldNo("Acquisition Date")) or
                       ("FA Date Type Name" <> FADeprBook.FieldCaption("Acquisition Date"))
                    then begin
                        Delete();
                        InsertRec(9, FADeprBook.FieldNo("Acquisition Date"), FADeprBook.FieldCaption("Acquisition Date"));
                    end;
                if "Entry No." = 10 then
                    if ("FA Date Type No." <> FADeprBook.FieldNo("G/L Acquisition Date")) or
                       ("FA Date Type Name" <> FADeprBook.FieldCaption("G/L Acquisition Date"))
                    then begin
                        Delete();
                        InsertRec(10, FADeprBook.FieldNo("G/L Acquisition Date"), FADeprBook.FieldCaption("G/L Acquisition Date"));
                    end;
            until Next() = 0;
        end;

        OnAfterCreateTypes(Rec);
    end;

    local procedure InsertRec(FAEntryNo: Integer; FADateTypeNo: Integer; FADateTypeName: Text[80])
    begin
        "Entry No." := FAEntryNo;
        "FA Date Type No." := FADateTypeNo;
        "FA Date Type Name" := CopyStr(FADateTypeName, 1, MaxStrLen("FA Date Type Name"));
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTypes(var FADateType: Record "FA Date Type")
    begin
    end;
}

