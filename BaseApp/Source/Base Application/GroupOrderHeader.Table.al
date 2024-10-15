table 17366 "Group Order Header"
{
    Caption = 'Group Order Header';
    LookupPageID = "Group Order List";

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Hire,Transfer,,Dismissal';
            OptionMembers = Hire,Transfer,,Dismissal;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);

                if "No." <> xRec."No." then begin
                    HumanResSetup.Get();
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;
            end;
        }
        field(3; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(5; "HR Order No."; Code[20])
        {
            Caption = 'HR Order No.';
        }
        field(6; "HR Order Date"; Date)
        {
            Caption = 'HR Order Date';
        }
        field(7; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(10; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(15; Comment; Boolean)
        {
            CalcFormula = Exist ("HR Order Comment Line" WHERE("Table Name" = CONST("Absence Order"),
                                                               "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Approved';
            OptionMembers = Open,Approved;
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField(Status, Status::Open);

        GroupOrderLine.Reset();
        GroupOrderLine.SetRange("Document Type", "Document Type");
        GroupOrderLine.SetRange("Document No.", "No.");
        GroupOrderLine.DeleteAll();
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
        Error(Text003, TableCaption);
    end;

    var
        HumanResSetup: Record "Human Resources Setup";
        GroupOrderLine: Record "Group Order Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text003: Label 'You cannot rename a %1.';

    [Scope('OnPrem')]
    procedure InitRecord()
    begin
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(OldGroupOrderHeader: Record "Group Order Header"): Boolean
    var
        GroupOrderHeader: Record "Group Order Header";
    begin
        with GroupOrderHeader do begin
            Copy(Rec);
            HumanResSetup.Get();
            TestNoSeries;
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldGroupOrderHeader."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := GroupOrderHeader;
                exit(true);
            end;
        end;
    end;

    local procedure TestNoSeries()
    begin
        case "Document Type" of
            "Document Type"::Hire:
                HumanResSetup.TestField("Group Hire Order Nos.");
            "Document Type"::Transfer:
                HumanResSetup.TestField("Group Transfer Order Nos.");
            "Document Type"::Dismissal:
                HumanResSetup.TestField("Group Dismissal Order Nos.");
        end;
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        case "Document Type" of
            "Document Type"::Hire:
                exit(HumanResSetup."Group Hire Order Nos.");
            "Document Type"::Transfer:
                exit(HumanResSetup."Group Transfer Order Nos.");
            "Document Type"::Dismissal:
                exit(HumanResSetup."Group Dismissal Order Nos.");
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintOrder(NewGroupOrderHeader: Record "Group Order Header")
    var
        GroupOrderHeader: Record "Group Order Header";
        HROrderPrint: Codeunit "HR Order - Print";
    begin
        if GroupOrderHeader.Get(NewGroupOrderHeader."Document Type", NewGroupOrderHeader."No.") then
            case NewGroupOrderHeader."Document Type" of
                NewGroupOrderHeader."Document Type"::Hire:
                    HROrderPrint.PrintFormT1a(GroupOrderHeader);
                NewGroupOrderHeader."Document Type"::Transfer:
                    HROrderPrint.PrintFormT5a(GroupOrderHeader);
                NewGroupOrderHeader."Document Type"::Dismissal:
                    HROrderPrint.PrintFormT8a(GroupOrderHeader);
            end;
    end;
}

