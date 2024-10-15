table 17373 "Staff List Order Header"
{
    Caption = 'Staff List Order Header';
    LookupPageID = "Staff List Orders";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    HumanResSetup.Get();
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;

                if "HR Order No." = '' then
                    "HR Order No." := "No.";
            end;
        }
        field(2; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);

                if "HR Order Date" = 0D then
                    "HR Order Date" := "Document Date";
            end;
        }
        field(4; "HR Manager No."; Code[20])
        {
            Caption = 'HR Manager No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(5; "Chief Accountant No."; Code[20])
        {
            Caption = 'Chief Accountant No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(7; Description; Text[50])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(8; "HR Order No."; Code[20])
        {
            Caption = 'HR Order No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(9; "HR Order Date"; Date)
        {
            Caption = 'HR Order Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(10; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(15; Comment; Boolean)
        {
            CalcFormula = Exist ("HR Order Comment Line" WHERE("Table Name" = CONST("SL Order"),
                                                               "No." = FIELD("No."),
                                                               "Line No." = CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        StaffListOrderLine.Reset();
        StaffListOrderLine.SetRange("Document No.", "No.");
        StaffListOrderLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        HumanResSetup.Get();

        if "No." = '' then begin
            TestNoSeries;
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", "Posting Date", "No.", "No. Series");
        end;

        InitRecord;
    end;

    trigger OnRename()
    begin
        Error('');
    end;

    var
        CompanyInfo: Record "Company Information";
        HumanResSetup: Record "Human Resources Setup";
        StaffListOrderLine: Record "Staff List Order Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;

    [Scope('OnPrem')]
    procedure InitRecord()
    begin
        CompanyInfo.Get();
        Validate("HR Manager No.", CompanyInfo."HR Manager No.");
        Validate("Chief Accountant No.", CompanyInfo."Accountant No.");

        "HR Order No." := "No.";
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(OldStaffListOrderHeader: Record "Staff List Order Header"): Boolean
    var
        StaffListOrderHeader: Record "Staff List Order Header";
    begin
        with StaffListOrderHeader do begin
            Copy(Rec);
            HumanResSetup.Get();
            TestNoSeries;
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldStaffListOrderHeader."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := StaffListOrderHeader;
                exit(true);
            end;
        end;
    end;

    local procedure TestNoSeries()
    begin
        HumanResSetup.TestField("Staff List Change Nos.");
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        exit(HumanResSetup."Staff List Change Nos.");
    end;

    [Scope('OnPrem')]
    procedure PrintOrder()
    begin
        // reserved for FP
    end;
}

