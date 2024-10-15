table 17361 "Labor Contract Line"
{
    Caption = 'Labor Contract Line';

    fields
    {
        field(1; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Labor Contract";
        }
        field(2; "Supplement No."; Code[10])
        {
            Caption = 'Supplement No.';

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
                TestField("Operation Type", "Operation Type"::Transfer);
            end;
        }
        field(3; "Operation Type"; Option)
        {
            Caption = 'Operation Type';
            OptionCaption = 'Hire,Transfer,Combination,Dismissal';
            OptionMembers = Hire,Transfer,Combination,Dismissal;

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);

                GetContract;
                LaborContract.TestField("Person No.");
                "Person No." := LaborContract."Person No.";

                case "Operation Type" of
                    "Operation Type"::Hire:
                        begin
                            LaborContract.TestField("Starting Date");
                            "Starting Date" := LaborContract."Starting Date";
                            "Ending Date" := LaborContract."Ending Date";
                        end;
                    "Operation Type"::Dismissal:
                        begin
                            LaborContract.TestField("Ending Date");
                            "Starting Date" := LaborContract."Ending Date";
                            "Ending Date" := LaborContract."Ending Date";
                            Employee.Get(LaborContract."Employee No.");
                            "Position No." := Employee."Position No.";
                        end;
                end;
            end;
        }
        field(4; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            TableRelation = Person;

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
            end;
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
            end;
        }
        field(6; "Order Date"; Date)
        {
            Caption = 'Order Date';

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
            end;
        }
        field(7; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);

                GetContract;
                if "Operation Type" = "Operation Type"::Hire then begin
                    LaborContract.TestField("Starting Date");
                    "Starting Date" := LaborContract."Starting Date";
                end;
                if "Operation Type" = "Operation Type"::Dismissal then
                    TestField("Starting Date", 0D);

                if ("Starting Date" <> 0D) and ("Starting Date" < LaborContract."Starting Date") then
                    Error(Text14704,
                      "Starting Date",
                      LaborContract.FieldCaption("Starting Date"),
                      LaborContract.TableCaption);
            end;
        }
        field(8; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                CheckContractStatus;
                if "Operation Type" <> "Operation Type"::Combination then
                    TestField(Status, Status::Open);

                GetContract;
                if "Operation Type" = "Operation Type"::Dismissal then begin
                    LaborContract.TestField("Ending Date");
                    TestField("Ending Date", LaborContract."Ending Date");
                end else
                    if ("Ending Date" <> 0D) and (LaborContract."Ending Date" <> 0D) and
                       ("Ending Date" > LaborContract."Ending Date")
                    then
                        Error(Text14705,
                          "Ending Date",
                          LaborContract.FieldCaption("Ending Date"),
                          LaborContract.TableCaption);

                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Approved';
            OptionMembers = Open,Approved;
        }
        field(11; "Position No."; Code[20])
        {
            Caption = 'Position No.';
            TableRelation = Position;

            trigger OnLookup()
            var
                TempPosition: Record Position temporary;
            begin
                case Status of
                    Status::Open:
                        begin
                            TestField(Status, Status::Open);
                            if "Operation Type" = "Operation Type"::Hire then begin
                                GetContract;
                                LaborContract.TestField("Starting Date");
                                "Starting Date" := LaborContract."Starting Date";
                            end;
                            if "Operation Type" = "Operation Type"::Combination then
                                TestField("Ending Date");

                            GetContract;

                            TempPosition.DeleteAll();
                            TempPosition.Reset();

                            Position.Reset();
                            Position.SetRange(Status, Position.Status::Approved);
                            Position.SetRange("Budgeted Position", false);
                            case LaborContract."Contract Type" of
                                LaborContract."Contract Type"::"Labor Contract":
                                    Position.SetRange("Out-of-Staff", false);
                                LaborContract."Contract Type"::"Civil Contract":
                                    Position.SetRange("Out-of-Staff", true);
                            end;
                            Position.SetRange("Starting Date", 0D, "Starting Date");
                            Position.SetFilter("Ending Date", '%1|%2..', 0D, "Starting Date");
                            if Position.FindSet then
                                repeat
                                    Position.CalcFields("Filled Rate");
                                    if Position.Rate - Position."Filled Rate" >= "Position Rate" then begin
                                        TempPosition := Position;
                                        TempPosition.Insert();
                                    end;
                                until Position.Next() = 0;

                            if "Position No." <> '' then
                                TempPosition.Get("Position No.");
                            if PAGE.RunModal(PAGE::"Open Positions", TempPosition) = ACTION::LookupOK then
                                Validate("Position No.", TempPosition."No.");
                        end;
                    Status::Approved:
                        begin
                            Position.Reset();
                            Position.Get("Position No.");
                            PAGE.RunModal(0, Position);
                        end;
                end;
            end;

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
                if "Position No." <> '' then begin
                    TestField("Starting Date");
                    ValidateFieldValue(CurrFieldNo);

                    Position.Get("Position No.");
                    Position.TestField(Status, Position.Status::Approved);
                    Position.TestField("Budgeted Position", false);
                    Position.TestField("Job Title Code");
                    Position.TestField("Org. Unit Code");
                    Position.TestField("Category Code");
                    Position.TestField("Kind of Work");
                    Position.TestField("Conditions of Work");
                    Position.TestField("Calc Group Code");
                    Position.TestField("Posting Group");
                    Position.TestField(Rate);
                    Position.CalcFields("Filled Rate");

                    GetContract;
                    case LaborContract."Contract Type" of
                        LaborContract."Contract Type"::"Labor Contract":
                            Position.TestField("Out-of-Staff", false);
                        LaborContract."Contract Type"::"Civil Contract":
                            Position.TestField("Out-of-Staff", true);
                    end;

                    if (("Operation Type" = "Operation Type"::Hire) or ("Operation Type" = "Operation Type"::Transfer)) and
                       ("Position Rate" = 0)
                    then
                        "Position Rate" := Position.Rate;

                    if "Position No." <> xRec."Position No." then begin
                        LaborContractTerms.Reset();
                        LaborContractTerms.SetRange("Labor Contract No.", "Contract No.");
                        LaborContractTerms.SetRange("Operation Type", "Operation Type");
                        LaborContractTerms.SetRange("Supplement No.", "Supplement No.");
                        if not LaborContractTerms.IsEmpty() then
                            if Confirm(Text14706, true, LaborContractTerms.TableCaption) then begin
                                LaborContractTerms.DeleteAll();
                                CheckFillRate;
                            end else
                                "Position No." := xRec."Position No."
                        else
                            CheckFillRate;
                    end;

                    if Position."Use Trial Period" then begin
                        Position.TestField("Trial Period Formula");
                        "Trial Period Start Date" := "Starting Date";
                        "Trial Period End Date" := CalcDate(Position."Trial Period Formula", "Starting Date");
                        "Trial Period Description" := Position."Trial Period Description";
                    end else begin
                        "Trial Period Start Date" := 0D;
                        "Trial Period End Date" := 0D;
                        "Trial Period Description" := '';
                    end;
                end else begin
                    "Position Rate" := 0;

                    "Trial Period Start Date" := 0D;
                    "Trial Period End Date" := 0D;
                    "Trial Period Description" := '';

                    LaborContractTerms.Reset();
                    LaborContractTerms.SetRange("Labor Contract No.", "Contract No.");
                    LaborContractTerms.SetRange("Operation Type", "Operation Type");
                    LaborContractTerms.SetRange("Supplement No.", "Supplement No.");
                    if not LaborContractTerms.IsEmpty() then
                        LaborContractTerms.DeleteAll();
                end;
            end;
        }
        field(14; "Dismissal Reason"; Code[10])
        {
            Caption = 'Dismissal Reason';
            TableRelation = "Grounds for Termination";

            trigger OnValidate()
            begin
                CheckContractStatus;

                TestField(Status, Status::Open);
                TestField("Operation Type", "Operation Type"::Dismissal);
                ValidateFieldValue(CurrFieldNo);

                if "Dismissal Reason" <> xRec."Dismissal Reason" then begin
                    if TerminationGround.Get(xRec."Dismissal Reason") then begin
                        LaborContractTerms.Reset();
                        LaborContractTerms.SetRange("Labor Contract No.", "Contract No.");
                        LaborContractTerms.SetRange("Operation Type", "Operation Type");
                        LaborContractTerms.SetRange("Supplement No.", "Supplement No.");
                        LaborContractTerms.SetRange("Element Code", TerminationGround."Element Code");
                        LaborContractTerms.DeleteAll();
                    end;
                    if TerminationGround.Get("Dismissal Reason") then
                        if TerminationGround."Element Code" <> '' then begin
                            LaborContractTerms.Reset();
                            LaborContractTerms."Labor Contract No." := "Contract No.";
                            LaborContractTerms."Operation Type" := "Operation Type";
                            LaborContractTerms."Supplement No." := "Supplement No.";
                            LaborContractTerms."Line Type" := LaborContractTerms."Line Type"::"Payroll Element";
                            LaborContractTerms.Validate("Element Code", TerminationGround."Element Code");
                            LaborContractTerms.Validate("Starting Date", "Starting Date");
                            LaborContractTerms.Validate("Ending Date", "Ending Date");
                            LaborContractTerms.Validate(Quantity, 1);
                            Employee.Get(LaborContract."Employee No.");
                            Position.Get(Employee."Position No.");
                            LaborContractTerms.Validate("Posting Group", Position."Posting Group");
                            LaborContractTerms.Insert();
                        end;
                end;
            end;
        }
        field(15; "Dismissal Document"; Text[50])
        {
            Caption = 'Dismissal Document';

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(16; "Position Rate"; Decimal)
        {
            Caption = 'Position Rate';

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
            end;
        }
        field(17; "Salary Terms"; Boolean)
        {
            CalcFormula = Exist ("Labor Contract Terms" WHERE("Labor Contract No." = FIELD("Contract No."),
                                                              "Supplement No." = FIELD("Supplement No."),
                                                              "Operation Type" = FIELD("Operation Type"),
                                                              "Line Type" = CONST("Payroll Element")));
            Caption = 'Salary Terms';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Vacation Terms"; Boolean)
        {
            CalcFormula = Exist ("Labor Contract Terms" WHERE("Labor Contract No." = FIELD("Contract No."),
                                                              "Supplement No." = FIELD("Supplement No."),
                                                              "Operation Type" = FIELD("Operation Type"),
                                                              "Line Type" = CONST("Vacation Accrual")));
            Caption = 'Vacation Terms';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(22; "Order No."; Code[20])
        {
            Caption = 'Order No.';

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
            end;
        }
        field(30; "Trial Period Start Date"; Date)
        {
            Caption = 'Trial Period Start Date';

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(31; "Trial Period End Date"; Date)
        {
            Caption = 'Trial Period End Date';

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(32; "Trial Period Description"; Text[50])
        {
            Caption = 'Trial Period Description';

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
                ValidateFieldValue(CurrFieldNo);
            end;
        }
        field(35; "Territorial Conditions"; Code[20])
        {
            Caption = 'Territorial Conditions';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Territor. Condition"));

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
            end;
        }
        field(36; "Special Conditions"; Code[20])
        {
            Caption = 'Special Conditions';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Special Work Condition"));

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
            end;
        }
        field(37; "Record of Service Reason"; Code[20])
        {
            Caption = 'Calc Seniority: Reason';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Countable Service Reason"));

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
            end;
        }
        field(38; "Record of Service Additional"; Code[20])
        {
            Caption = 'Calc Seniority: Addition';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Countable Service Addition"));

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
            end;
        }
        field(39; "Service Years Reason"; Code[20])
        {
            Caption = 'Long Service: Reason';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Long Service Reason"));

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
            end;
        }
        field(40; "Service Years Additional"; Code[20])
        {
            Caption = 'Long Service: Addition';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Long Service Addition"));

            trigger OnValidate()
            begin
                CheckContractStatus;
                TestField(Status, Status::Open);
            end;
        }
    }

    keys
    {
        key(Key1; "Contract No.", "Operation Type", "Supplement No.")
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
        CheckContractStatus;

        LaborContractTerms.Reset();
        LaborContractTerms.SetRange("Labor Contract No.", "Contract No.");
        LaborContractTerms.SetRange("Operation Type", "Operation Type");
        LaborContractTerms.SetRange("Supplement No.", "Supplement No.");
        LaborContractTerms.DeleteAll();
    end;

    trigger OnInsert()
    begin
        CheckContractStatus;

        if ("Operation Type" = "Operation Type"::Transfer) and ("Supplement No." = '') then
            if xRec."Supplement No." = '' then
                "Supplement No." := '001'
            else
                "Supplement No." := IncStr(xRec."Supplement No.");

        Validate("Operation Type");

        LaborContractLine.Reset();
        LaborContractLine.SetRange("Contract No.", "Contract No.");
        if LaborContractLine.IsEmpty() then
            TestField("Operation Type", "Operation Type"::Hire);
    end;

    trigger OnRename()
    begin
        Error('');
    end;

    var
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
        LaborContractTerms: Record "Labor Contract Terms";
        Position: Record Position;
        Text14700: Label 'Filled Rate must be 0 for position %1.';
        Text14704: Label '%1 should not be earlier than %2 in %3.';
        Text14705: Label '%1 should not be later than %2 in %3.';
        Text14706: Label '%1 will be deleted. Continue?';
        Text14707: Label 'First contract line must have Operation Type %1.';
        Text14708: Label '%1 cannot be changed if Operation Type is %2.';
        Text14709: Label 'Amount and Quantity should not be equal 0 simultaneously.';
        Employee: Record Employee;
        TerminationGround: Record "Grounds for Termination";

    [Scope('OnPrem')]
    procedure GetContract()
    begin
        if LaborContract."No." <> "Contract No." then
            LaborContract.Get("Contract No.");
    end;

    [Scope('OnPrem')]
    procedure CheckPosition(LaborContractLine: Record "Labor Contract Line")
    begin
        with LaborContractLine do begin
            Position.Get("Position No.");
            Position.TestField("Job Title Code");
            Position.TestField("Org. Unit Code");
            Position.TestField(Status, Position.Status::Approved);
            Position.TestField(Rate);
            Position.TestField("Base Salary");
            Position.TestField("Monthly Salary");
            Position.TestField("Category Code");
            Position.TestField("Statistical Group Code");
            Position.TestField("Calendar Code");
            Position.TestField("Calc Group Code");
            Position.TestField("Posting Group");
            Position.TestField("Kind of Work");
            Position.TestField("Conditions of Work");
            Position.TestField("Starting Date");
            CheckFillRate;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckFillRate()
    begin
        Position.CalcFields("Filled Rate");
        if Position."Filled Rate" <> 0 then
            Error(Text14700, "Position No.");
    end;

    [Scope('OnPrem')]
    procedure CheckLine()
    var
        Vendor: Record Vendor;
        Person: Record Person;
        VendorAgreement: Record "Vendor Agreement";
    begin
        GetContract;
        LaborContract.TestField("Person No.");
        LaborContract.TestField("Starting Date");

        TestField("Position Rate");
        TestField("Position No.");
        TestField("Starting Date");
        CheckContractStatus;
        TestField(Status, Status::Open);

        Person.Get(LaborContract."Person No.");
        Person.TestField("Vendor No.");
        Vendor.Get(Person."Vendor No.");
        if Vendor."Agreement Posting" = Vendor."Agreement Posting"::Mandatory then
            LaborContract.TestField("Vendor Agreement No.");

        if LaborContract."Vendor Agreement No." <> '' then begin
            VendorAgreement.Get(Vendor."No.", LaborContract."Vendor Agreement No.");
            if "Starting Date" < VendorAgreement."Starting Date" then
                Error(Text14704,
                  FieldCaption("Starting Date"), VendorAgreement.FieldCaption("Starting Date"), VendorAgreement.TableCaption);
        end;

        if "Starting Date" < LaborContract."Starting Date" then
            Error(Text14704,
              FieldCaption("Starting Date"), LaborContract.FieldCaption("Starting Date"), LaborContract.TableCaption);

        if ("Starting Date" > LaborContract."Ending Date") and (LaborContract."Ending Date" <> 0D) then
            Error(Text14705,
              FieldCaption("Starting Date"), LaborContract.FieldCaption("Ending Date"), LaborContract.TableCaption);

        if ("Ending Date" > LaborContract."Ending Date") and (LaborContract."Ending Date" <> 0D) then
            Error(Text14704,
              FieldCaption("Ending Date"), LaborContract.FieldCaption("Ending Date"), LaborContract.TableCaption);

        if "Operation Type" <> "Operation Type"::Hire then begin
            LaborContractLine.Reset();
            LaborContractLine.SetRange("Contract No.", "Contract No.");
            LaborContractLine.FindFirst;
            if LaborContractLine."Operation Type" <> LaborContractLine."Operation Type"::Hire then
                Error(Text14707, "Operation Type"::Hire);
        end;

        LaborContractTerms.Reset();
        LaborContractTerms.SetRange("Labor Contract No.", "Contract No.");
        LaborContractTerms.SetRange("Operation Type", "Operation Type");
        LaborContractTerms.SetRange("Supplement No.", "Supplement No.");
        if LaborContractTerms.FindSet then
            repeat
                LaborContractTerms.TestField("Element Code");
                LaborContractTerms.TestField("Starting Date");
                case LaborContractTerms."Line Type" of
                    LaborContractTerms."Line Type"::"Payroll Element":
                        if (LaborContractTerms.Amount = 0) and (LaborContractTerms.Quantity = 0) then
                            Error(Text14709);
                    LaborContractTerms."Line Type"::"Vacation Accrual":
                        begin
                            LaborContractTerms.TestField(Amount, 0);
                            LaborContractTerms.TestField(Quantity);
                        end;
                end;
            until LaborContractTerms.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckDateOrder()
    begin
        LaborContractLine.Reset();
        LaborContractLine.SetRange("Contract No.", "Contract No.");
        if LaborContractLine.FindLast then
            if LaborContractLine."Starting Date" > "Starting Date" then
                Error(Text14704,
                  FieldCaption("Starting Date"), LaborContractLine.TableCaption, LaborContractLine.FieldCaption("Starting Date"));
    end;

    [Scope('OnPrem')]
    procedure ShowContractTerms()
    var
        LaborContractTerms: Record "Labor Contract Terms";
        LaborContractTermsPage: Page "Labor Contract Terms";
    begin
        LaborContractTerms.Reset();
        LaborContractTerms.SetRange("Labor Contract No.", "Contract No.");
        LaborContractTerms.SetRange("Operation Type", "Operation Type");
        LaborContractTerms.SetRange("Supplement No.", "Supplement No.");
        LaborContractTermsPage.SetTableView(LaborContractTerms);
        LaborContractTermsPage.Run;
        Clear(LaborContractTermsPage);
    end;

    [Scope('OnPrem')]
    procedure ShowComments()
    var
        HRComment: Record "Human Resource Comment Line";
        HRCommentList: Page "Human Resource Comment List";
    begin
        HRComment.Reset();
        HRComment.SetRange("Table Name", HRComment."Table Name"::"Labor Contract");
        HRComment.SetRange("No.", "Contract No.");
        HRComment.SetRange("Alternative Address Code", "Supplement No.");
        HRCommentList.SetTableView(HRComment);
        HRCommentList.Run;
        Clear(HRCommentList);
    end;

    [Scope('OnPrem')]
    procedure PrintOrder()
    var
        LaborContractLine: Record "Labor Contract Line";
        HROrderPrint: Codeunit "HR Order - Print";
    begin
        LaborContractLine.Reset();
        LaborContractLine.SetRange("Contract No.", "Contract No.");
        LaborContractLine.SetRange("Operation Type", "Operation Type");
        LaborContractLine.SetRange("Supplement No.", "Supplement No.");
        if LaborContractLine.FindFirst then
            case "Operation Type" of
                "Operation Type"::Hire:
                    HROrderPrint.PrintFormT1(LaborContractLine);
                "Operation Type"::Transfer:
                    HROrderPrint.PrintFormT5(LaborContractLine);
                "Operation Type"::Combination:
                    ;
                "Operation Type"::Dismissal:
                    HROrderPrint.PrintFormT8(LaborContractLine);
            end;
    end;

    [Scope('OnPrem')]
    procedure ValidateFieldValue(FieldNumber: Integer)
    var
        "Field": Record "Field";
        UpdateForbidden: Boolean;
    begin
        if FieldNumber = 0 then
            exit;

        if not IsValueChanged(FieldNumber) then
            exit;

        Field.Get(DATABASE::"Labor Contract Line", FieldNumber);

        case "Operation Type" of
            "Operation Type"::Hire,
          "Operation Type"::Transfer:
                UpdateForbidden := FieldNumber in [
                                                   FieldNo("Dismissal Reason"),
                                                   FieldNo("Dismissal Document")
                                                   ];
            "Operation Type"::Combination:
                UpdateForbidden := FieldNumber in [
                                                   FieldNo("Dismissal Reason"),
                                                   FieldNo("Dismissal Document"),
                                                   FieldNo("Dismissal Reason"),
                                                   FieldNo("Trial Period Start Date"),
                                                   FieldNo("Trial Period End Date"),
                                                   FieldNo("Trial Period Description")
                                                   ];
            "Operation Type"::Dismissal:
                UpdateForbidden := FieldNumber in [
                                                   FieldNo("Starting Date"),
                                                   FieldNo("Position No."),
                                                   FieldNo("Trial Period Start Date"),
                                                   FieldNo("Trial Period End Date"),
                                                   FieldNo("Trial Period Description")
                                                   ];
        end;

        if UpdateForbidden then
            Error(Text14708, Field."Field Caption", "Operation Type");
    end;

    [Scope('OnPrem')]
    procedure IsValueChanged(FieldNumber: Integer): Boolean
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
        FieldRef: FieldRef;
        xFieldRef: FieldRef;
    begin
        RecRef.GetTable(Rec);
        xRecRef.GetTable(xRec);
        FieldRef := RecRef.Field(FieldNumber);
        xFieldRef := xRecRef.Field(FieldNumber);
        exit(Format(FieldRef.Value) <> Format(xFieldRef.Value));
    end;

    [Scope('OnPrem')]
    procedure CheckContractStatus()
    begin
        GetContract;
        if LaborContract.Status = LaborContract.Status::Closed then
            LaborContract.FieldError(Status);
    end;

    [Scope('OnPrem')]
    procedure CheckTransferDate(SupplementNo: Code[10]; OrderNo: Code[20]; OrderDate: Date)
    begin
        LaborContractLine.Reset();
        LaborContractLine.SetRange("Contract No.", "Contract No.");
        LaborContractLine.SetRange(
          "Operation Type",
          LaborContractLine."Operation Type"::Hire,
          LaborContractLine."Operation Type"::Transfer);
        LaborContractLine.SetRange("Supplement No.", SupplementNo);
        LaborContractLine.SetRange("Order No.", OrderNo);
        LaborContractLine.SetRange("Order Date", OrderDate);
        if LaborContractLine.FindLast then
            if LaborContractLine."Starting Date" > "Starting Date" then
                Error(
                  Text14704,
                  FieldCaption("Starting Date"), LaborContractLine.TableCaption, LaborContractLine.FieldCaption("Starting Date"));
    end;

    [Scope('OnPrem')]
    procedure HasSpecialWorkConditions(): Boolean
    var
        GeneralDirectory: Record "General Directory";
    begin
        if (GetGeneralDirectoryXMLType("Territorial Conditions", GeneralDirectory.Type::"Territor. Condition") > 0) or
           (GetGeneralDirectoryXMLType("Special Conditions", GeneralDirectory.Type::"Special Work Condition") > 0) or
           (GetGeneralDirectoryXMLType("Record of Service Reason", GeneralDirectory.Type::"Countable Service Reason") > 0) or
           (GetGeneralDirectoryXMLType("Record of Service Additional", GeneralDirectory.Type::"Countable Service Addition") > 0)
        then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetGeneralDirectoryXMLType(GeneralDirectoryCode: Code[20]; GeneralDirectoryType: Option): Integer
    var
        GeneralDirectory: Record "General Directory";
    begin
        if GeneralDirectoryCode <> '' then begin
            GeneralDirectory.SetRange(Code, GeneralDirectoryCode);
            GeneralDirectory.SetRange(Type, GeneralDirectoryType);
            GeneralDirectory.FindFirst;
            exit(GeneralDirectory."XML Element Type");
        end;
        exit(GeneralDirectory."XML Element Type"::" ");
    end;
}

