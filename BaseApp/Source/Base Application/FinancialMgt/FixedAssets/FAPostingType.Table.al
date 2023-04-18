table 5644 "FA Posting Type"
{
    Caption = 'FA Posting Type';
    LookupPageID = "FA Posting Types";

    fields
    {
        field(1; "FA Posting Type No."; Integer)
        {
            Caption = 'FA Posting Type No.';
        }
        field(2; "FA Posting Type Name"; Text[50])
        {
            Caption = 'FA Posting Type Name';
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
        key(Key1; "FA Posting Type No.", "FA Posting Type Name")
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
            InsertRec(1, FADeprBook.FieldNo("Acquisition Cost"), FADeprBook.FieldCaption("Acquisition Cost"));
            InsertRec(2, FADeprBook.FieldNo(Depreciation), FADeprBook.FieldCaption(Depreciation));
            InsertRec(3, FADeprBook.FieldNo("Write-Down"), FADeprBook.FieldCaption("Write-Down"));
            InsertRec(4, FADeprBook.FieldNo(Appreciation), FADeprBook.FieldCaption(Appreciation));
            InsertRec(5, FADeprBook.FieldNo("Custom 1"), FADeprBook.FieldCaption("Custom 1"));
            InsertRec(6, FADeprBook.FieldNo("Custom 2"), FADeprBook.FieldCaption("Custom 2"));
            InsertRec(7, FADeprBook.FieldNo("Proceeds on Disposal"), FADeprBook.FieldCaption("Proceeds on Disposal"));
            InsertRec(8, FADeprBook.FieldNo("Gain/Loss"), FADeprBook.FieldCaption("Gain/Loss"));
            "FA Entry" := true;
            "G/L Entry" := false;
            InsertRec(9, FADeprBook.FieldNo("Book Value"), FADeprBook.FieldCaption("Book Value"));
            InsertRec(10, FADeprBook.FieldNo("Depreciable Basis"), FADeprBook.FieldCaption("Depreciable Basis"));
            InsertRec(11, FADeprBook.FieldNo("Salvage Value"), FADeprBook.FieldCaption("Salvage Value"));
            "FA Entry" := false;
            "G/L Entry" := true;
            InsertRec(12, FADeprBook.FieldNo("Book Value on Disposal"), FADeprBook.FieldCaption("Book Value on Disposal"));
        end else begin
            SetCurrentKey("Entry No.");
            Find('-');
            repeat
                if "Entry No." = 1 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo("Acquisition Cost")) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption("Acquisition Cost"))
                    then begin
                        Delete();
                        InsertRec(1, FADeprBook.FieldNo("Acquisition Cost"), FADeprBook.FieldCaption("Acquisition Cost"));
                    end;
                if "Entry No." = 2 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo(Depreciation)) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption(Depreciation))
                    then begin
                        Delete();
                        InsertRec(2, FADeprBook.FieldNo(Depreciation), FADeprBook.FieldCaption(Depreciation));
                    end;
                if "Entry No." = 3 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo("Write-Down")) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption("Write-Down"))
                    then begin
                        Delete();
                        InsertRec(3, FADeprBook.FieldNo("Write-Down"), FADeprBook.FieldCaption("Write-Down"));
                    end;
                if "Entry No." = 4 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo(Appreciation)) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption(Appreciation))
                    then begin
                        Delete();
                        InsertRec(4, FADeprBook.FieldNo(Appreciation), FADeprBook.FieldCaption(Appreciation));
                    end;
                if "Entry No." = 5 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo("Custom 1")) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption("Custom 1"))
                    then begin
                        Delete();
                        InsertRec(5, FADeprBook.FieldNo("Custom 1"), FADeprBook.FieldCaption("Custom 1"));
                    end;
                if "Entry No." = 6 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo("Custom 2")) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption("Custom 2"))
                    then begin
                        Delete();
                        InsertRec(6, FADeprBook.FieldNo("Custom 2"), FADeprBook.FieldCaption("Custom 2"));
                    end;
                if "Entry No." = 7 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo("Proceeds on Disposal")) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption("Proceeds on Disposal"))
                    then begin
                        Delete();
                        InsertRec(7, FADeprBook.FieldNo("Proceeds on Disposal"), FADeprBook.FieldCaption("Proceeds on Disposal"));
                    end;
                if "Entry No." = 8 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo("Gain/Loss")) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption("Gain/Loss"))
                    then begin
                        Delete();
                        InsertRec(8, FADeprBook.FieldNo("Gain/Loss"), FADeprBook.FieldCaption("Gain/Loss"));
                    end;
                if "Entry No." = 9 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo("Book Value")) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption("Book Value"))
                    then begin
                        Delete();
                        InsertRec(9, FADeprBook.FieldNo("Book Value"), FADeprBook.FieldCaption("Book Value"));
                    end;
                if "Entry No." = 10 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo("Depreciable Basis")) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption("Depreciable Basis"))
                    then begin
                        Delete();
                        InsertRec(10, FADeprBook.FieldNo("Depreciable Basis"), FADeprBook.FieldCaption("Depreciable Basis"));
                    end;
                if "Entry No." = 11 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo("Salvage Value")) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption("Salvage Value"))
                    then begin
                        Delete();
                        InsertRec(11, FADeprBook.FieldNo("Salvage Value"), FADeprBook.FieldCaption("Salvage Value"));
                    end;
                if "Entry No." = 12 then
                    if ("FA Posting Type No." <> FADeprBook.FieldNo("Book Value on Disposal")) or
                       ("FA Posting Type Name" <> FADeprBook.FieldCaption("Book Value on Disposal"))
                    then begin
                        Delete();
                        InsertRec(12, FADeprBook.FieldNo("Book Value on Disposal"), FADeprBook.FieldCaption("Book Value on Disposal"));
                    end;
            until Next() = 0;
        end;
        OnAfterCreateTypes(Rec);
    end;

    local procedure InsertRec(EntryNo: Integer; FAPostingTypeNo: Integer; FAPostingTypeName: Text[80])
    begin
        "Entry No." := EntryNo;
        "FA Posting Type No." := FAPostingTypeNo;
        "FA Posting Type Name" := CopyStr(FAPostingTypeName, 1, MaxStrLen("FA Posting Type Name"));
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTypes(var FAPostingType: Record "FA Posting Type")
    begin
    end;
}

