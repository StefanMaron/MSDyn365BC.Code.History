table 17360 "Labor Contract"
{
    Caption = 'Labor Contract';
    LookupPageID = "Labor Contracts";

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
            end;
        }
        field(2; "Contract Type"; Option)
        {
            Caption = 'Contract Type';
            OptionCaption = 'Labor Contract,Civil Contract';
            OptionMembers = "Labor Contract","Civil Contract";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);

                "Work Mode" := "Work Mode"::"Primary Job";
            end;
        }
        field(3; "Work Mode"; Option)
        {
            Caption = 'Work Mode';
            OptionCaption = 'Primary Job,Internal Co-work,External Co-work';
            OptionMembers = "Primary Job","Internal Co-work","External Co-work";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);

                if "Contract Type" = "Contract Type"::"Civil Contract" then
                    TestField("Work Mode", "Work Mode"::"Primary Job")
                else
                    if "Person No." <> '' then begin
                        LaborContract.Reset();
                        LaborContract.SetRange("Person No.", "Person No.");
                        LaborContract.SetRange("Contract Type", "Contract Type"::"Labor Contract");
                        LaborContract.SetRange(Status, Status::Approved);
                        if "Work Mode" = "Work Mode"::"Internal Co-work" then
                            if LaborContract.IsEmpty then
                                Error(Text14704, "Person No.");
                        if ("Work Mode" = "Work Mode"::"Primary Job") or ("Work Mode" = "Work Mode"::"External Co-work") then
                            if not LaborContract.IsEmpty then
                                Error(Text14705, "Person No.");
                    end;
            end;
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(6; "Contract Type Code"; Code[10])
        {
            Caption = 'Contract Type Code';
            TableRelation = "Employment Contract";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(7; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(8; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Approved,Closed';
            OptionMembers = Open,Approved,Closed;
        }
        field(12; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            TableRelation = Person;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);

                CalcFields("Person Name");

                LaborContractLine.Reset();
                LaborContractLine.SetRange("Contract No.", "No.");
                if not LaborContractLine.IsEmpty then
                    Error(Text000, FieldCaption("Person No."));

                Validate("Work Mode");

                if "Person No." <> xRec."Person No." then
                    "Vendor Agreement No." := '';

                if "Person No." <> '' then begin
                    Person.Get("Person No.");
                    Person.TestField("Vendor No.");
                    "Vendor No." := Person."Vendor No.";
                end else begin
                    "Vendor No." := '';
                    "Vendor Agreement No." := '';
                end;
            end;
        }
        field(13; "Person Name"; Text[100])
        {
            CalcFormula = Lookup (Person."Full Name" WHERE("No." = FIELD("Person No.")));
            Caption = 'Person Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; Comment; Boolean)
        {
            CalcFormula = Exist ("Human Resource Comment Line" WHERE("Table Name" = CONST("Labor Contract"),
                                                                     "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Uninterrupted Service"; Boolean)
        {
            Caption = 'Uninterrupted Service';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(18; "Insured Service"; Boolean)
        {
            Caption = 'Insured Service';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(19; "Unmeasured Work Time"; Boolean)
        {
            Caption = 'Unmeasured Work Time';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(20; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(21; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(22; "Open Contract Lines"; Integer)
        {
            CalcFormula = Count ("Labor Contract Line" WHERE("Contract No." = FIELD("No."),
                                                             Status = CONST(Open)));
            Caption = 'Open Contract Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(41; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            Editable = false;
        }
        field(42; "Vendor Agreement No."; Code[20])
        {
            Caption = 'Vendor Agreement No.';
            TableRelation = "Vendor Agreement"."No." WHERE("Vendor No." = FIELD("Vendor No."));

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Contract Type", "Person No.", "Starting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Person No.", "Person Name")
        {
        }
    }

    trigger OnDelete()
    begin
        TestField(Status, Status::Open);

        LaborContractLine.SetRange("Contract No.", "No.");
        LaborContractLine.DeleteAll();

        LaborContractTerms.SetRange("Labor Contract No.", "No.");
        LaborContractTerms.DeleteAll();
    end;

    trigger OnInsert()
    begin
        HumanResSetup.Get();
        if "No." = '' then begin
            TestNoSeries;
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", Today, "No.", "No. Series");
        end;

        InitRecord;
    end;

    var
        HumanResSetup: Record "Human Resources Setup";
        Person: Record Person;
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
        LaborContractTerms: Record "Labor Contract Terms";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text000: Label 'You cannot change %1 while order lines exist.';
        Text14704: Label 'Primary labor contract is not found for person %1.';
        Text14705: Label 'Primary labor contract already exist for person %1.';

    [Scope('OnPrem')]
    procedure InitRecord()
    begin
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(OldLaborContract: Record "Labor Contract"): Boolean
    begin
        with LaborContract do begin
            Copy(Rec);
            HumanResSetup.Get();
            TestNoSeries;
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldLaborContract."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := LaborContract;
                exit(true);
            end;
        end;
    end;

    local procedure TestNoSeries()
    begin
        HumanResSetup.TestField("Labor Contract Nos.");
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        exit(HumanResSetup."Labor Contract Nos.");
    end;
}

