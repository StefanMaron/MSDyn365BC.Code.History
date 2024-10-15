table 17385 "Absence Header"
{
    Caption = 'Absence Header';
    LookupPageID = "Absence Order List";

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Vacation,Sick Leave,Travel,Other Absence';
            OptionMembers = Vacation,"Sick Leave",Travel,"Other Absence";
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    HumanResSetup.Get;
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;

                if "HR Order No." = '' then
                    "HR Order No." := "No.";
            end;
        }
        field(3; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);

                if "Document Date" <> 0D then begin
                    GetEmployee("Employee No.");
                    if "Document Date" < Employee."Employment Date" then
                        LocMgt.DateMustBeLater(FieldCaption("Document Date"), Employee."Employment Date");
                    if "Posting Date" = 0D then
                        "Posting Date" := "Document Date";
                end;

                if "HR Order Date" = 0D then
                    "HR Order Date" := "Document Date";

                if "Period Code" = '' then
                    "Period Code" := PayrollPeriod.PeriodByDate("Document Date");
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
        field(5; "Calendar Days"; Decimal)
        {
            CalcFormula = Sum ("Absence Line"."Calendar Days" WHERE("Document Type" = FIELD("Document Type"),
                                                                    "Document No." = FIELD("No.")));
            Caption = 'Calendar Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Working Days"; Decimal)
        {
            CalcFormula = Sum ("Absence Line"."Working Days" WHERE("Document Type" = FIELD("Document Type"),
                                                                   "Document No." = FIELD("No.")));
            Caption = 'Working Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(8; "Start Date"; Date)
        {
            CalcFormula = Min ("Absence Line"."Start Date" WHERE("Document Type" = FIELD("Document Type"),
                                                                 "Document No." = FIELD("No.")));
            Caption = 'Start Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "End Date"; Date)
        {
            CalcFormula = Max ("Absence Line"."End Date" WHERE("Document Type" = FIELD("Document Type"),
                                                               "Document No." = FIELD("No.")));
            Caption = 'End Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(12; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);

                AbsenceLine.Reset;
                AbsenceLine.SetRange("Document Type", "Document Type");
                AbsenceLine.SetRange("Document No.", "No.");
                if not AbsenceLine.IsEmpty then
                    Error(Text000, FieldCaption("Employee No."));
            end;
        }
        field(13; "HR Order No."; Code[20])
        {
            Caption = 'HR Order No.';
        }
        field(14; "HR Order Date"; Date)
        {
            Caption = 'HR Order Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(15; Comment; Boolean)
        {
            CalcFormula = Exist ("HR Order Comment Line" WHERE("Table Name" = CONST("Absence Order"),
                                                               "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(24; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(25; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(26; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(29; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(30; Note; Text[50])
        {
            Caption = 'Note';
        }
        field(31; "Travel Destination"; Text[100])
        {
            Caption = 'Travel Destination';
        }
        field(32; "Travel Purpose"; Text[100])
        {
            Caption = 'Travel Purpose';
        }
        field(33; "Travel Paid by No."; Code[20])
        {
            Caption = 'Travel Paid by No.';
            TableRelation = IF ("Travel Paid By Type" = CONST(Customer)) Customer
            ELSE
            IF ("Travel Paid By Type" = CONST(Vendor)) Vendor;
        }
        field(34; "Payment Days"; Decimal)
        {
            Caption = 'Payment Days';
        }
        field(35; "Payment Hours"; Decimal)
        {
            Caption = 'Payment Hours';
        }
        field(37; "Allocation Type"; Option)
        {
            Caption = 'Allocation Type';
            OptionCaption = ' 3,12';
            OptionMembers = " 3","12";
        }
        field(38; "Travel Reason Document"; Text[100])
        {
            Caption = 'Travel Reason Document';
        }
        field(39; "Travel Paid By Type"; Option)
        {
            Caption = 'Travel Paid By Type';
            OptionCaption = 'Company,Customer,Vendor';
            OptionMembers = Company,Customer,Vendor;
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(44; "Use Salary Indexation"; Boolean)
        {
            Caption = 'Use Salary Indexation';
        }
        field(52; "Sick Certificate Series"; Text[10])
        {
            Caption = 'Sick Certificate Series';
        }
        field(53; "Sick Certificate No."; Text[30])
        {
            Caption = 'Sick Certificate No.';
        }
        field(54; "Sick Certificate Date"; Date)
        {
            Caption = 'Sick Certificate Date';
        }
        field(55; "Sick Certificate Reason"; Text[50])
        {
            Caption = 'Sick Certificate Reason';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDocDim;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
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

        AbsenceLine.Reset;
        AbsenceLine.SetRange("Document Type", "Document Type");
        AbsenceLine.SetRange("Document No.", "No.");
        AbsenceLine.DeleteAll;
    end;

    trigger OnInsert()
    begin
        HumanResSetup.Get;

        if "No." = '' then begin
            TestNoSeries;
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", "Posting Date", "No.", "No. Series");
        end;

        InitRecord;
    end;

    trigger OnRename()
    begin
        Error(Text003, "Document Type");
    end;

    var
        HumanResSetup: Record "Human Resources Setup";
        AbsenceLine: Record "Absence Line";
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text000: Label 'You cannot change %1 while order lines exist.';
        Text003: Label 'You cannot rename a %1.';
        LocMgt: Codeunit "Localisation Management";
        DimMgt: Codeunit DimensionManagement;
        Text064: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    [Scope('OnPrem')]
    procedure InitRecord()
    begin
        "HR Order No." := "No.";
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(OldAbsenceHeader: Record "Absence Header"): Boolean
    var
        AbsenceHeader: Record "Absence Header";
    begin
        with AbsenceHeader do begin
            Copy(Rec);
            HumanResSetup.Get;
            TestNoSeries;
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldAbsenceHeader."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := AbsenceHeader;
                exit(true);
            end;
        end;
    end;

    local procedure TestNoSeries()
    begin
        case "Document Type" of
            "Document Type"::Vacation:
                HumanResSetup.TestField("Vacation Order Nos.");
            "Document Type"::"Sick Leave":
                HumanResSetup.TestField("Sick Leave Order Nos.");
            "Document Type"::Travel:
                HumanResSetup.TestField("Travel Order Nos.");
            "Document Type"::"Other Absence":
                HumanResSetup.TestField("Other Absence Order Nos.");
        end;
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        case "Document Type" of
            "Document Type"::Vacation:
                exit(HumanResSetup."Vacation Order Nos.");
            "Document Type"::"Sick Leave":
                exit(HumanResSetup."Sick Leave Order Nos.");
            "Document Type"::Travel:
                exit(HumanResSetup."Travel Order Nos.");
            "Document Type"::"Other Absence":
                exit(HumanResSetup."Other Absence Order Nos.");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetEmployee(EmployeeNo: Code[20])
    begin
        if (Employee."No." = '') and (EmployeeNo <> '') then
            Employee.Get("Employee No.");
    end;

    [Scope('OnPrem')]
    procedure AbsenceLinesExist(): Boolean
    begin
        AbsenceLine.Reset;
        AbsenceLine.SetRange("Document Type", "Document Type");
        AbsenceLine.SetRange("Document No.", "No.");
        exit(AbsenceLine.FindFirst);
    end;

    [Scope('OnPrem')]
    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Document Date", "No.");
        NavigateForm.Run;
    end;

    [Scope('OnPrem')]
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20]; Type5: Integer; No5: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        OldDimSetID: Integer;
    begin
        SourceCodeSetup.Get;
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        TableID[4] := Type4;
        No[4] := No4;
        TableID[5] := Type5;
        No[5] := No5;
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetDefaultDimID(TableID, No, SourceCodeSetup.Sales, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        if (OldDimSetID <> "Dimension Set ID") and AbsenceLinesExist then begin
            Modify;
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify;

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if AbsenceLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if AbsenceLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        NewDimSetID: Integer;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not Confirm(Text064) then
            exit;

        AbsenceLine.Reset;
        AbsenceLine.SetRange("Document Type", "Document Type");
        AbsenceLine.SetRange("Document No.", "No.");
        AbsenceLine.LockTable;
        if AbsenceLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(AbsenceLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if AbsenceLine."Dimension Set ID" <> NewDimSetID then begin
                    AbsenceLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      AbsenceLine."Dimension Set ID", AbsenceLine."Shortcut Dimension 1 Code", AbsenceLine."Shortcut Dimension 2 Code");
                    AbsenceLine.Modify;
                end;
            until AbsenceLine.Next = 0;
    end;
}

