table 17367 "Group Order Line"
{
    Caption = 'Group Order Line';

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Hire,Transfer,,Dismissal';
            OptionMembers = Hire,Transfer,,Dismissal;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Labor Contract";

            trigger OnValidate()
            begin
                if "Contract No." <> '' then begin
                    LaborContract.Get("Contract No.");
                    Validate("Employee No.", LaborContract."Employee No.");
                    LaborContract.CalcFields("Person Name");
                    Validate("Employee Name", LaborContract."Person Name");
                    if "Document Type" = "Document Type"::Transfer then begin
                        LaborContractLine.Reset();
                        LaborContractLine.SetRange("Contract No.", "Contract No.");
                        LaborContractLine.SetRange("Operation Type", "Document Type");
                        if LaborContractLine.FindFirst then
                            Validate("Supplement No.", LaborContractLine."Supplement No.");
                    end;
                end else begin
                    Validate("Employee No.", '');
                    Validate("Employee Name", '');
                end;
            end;
        }
        field(5; "Supplement No."; Code[10])
        {
            Caption = 'Supplement No.';

            trigger OnLookup()
            begin
                LaborContractLine.Reset();
                if "Contract No." <> '' then
                    LaborContractLine.SetRange("Contract No.", "Contract No.");
                LaborContractLine.SetRange("Operation Type", "Document Type");

                Clear(LaborContractLines);
                LaborContractLines.SetTableView(LaborContractLine);
                LaborContractLines.LookupMode(true);
                if LaborContractLines.RunModal = ACTION::LookupOK then begin
                    LaborContractLines.GetRecord(LaborContractLine);
                    LaborContract.Get(LaborContractLine."Contract No.");
                    Validate("Contract No.", LaborContractLine."Contract No.");
                    Validate("Supplement No.", LaborContractLine."Supplement No.");
                end;
            end;
        }
        field(6; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            Editable = false;
            TableRelation = Employee;
        }
        field(7; "Employee Name"; Text[100])
        {
            Caption = 'Employee Name';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestStatusOpen;
    end;

    trigger OnInsert()
    begin
        TestStatusOpen;
    end;

    trigger OnModify()
    begin
        TestStatusOpen;
    end;

    trigger OnRename()
    begin
        Error('');
    end;

    var
        GroupOrderHeader: Record "Group Order Header";
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
        LaborContractLines: Page "Labor Contract Lines";

    local procedure TestStatusOpen()
    begin
        GroupOrderHeader.Get("Document Type", "Document No.");
        GroupOrderHeader.TestField(Status, GroupOrderHeader.Status::Open);
    end;
}

