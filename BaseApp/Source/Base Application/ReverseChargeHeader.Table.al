table 31093 "Reverse Charge Header"
{
    Caption = 'Reverse Charge Header';
    DataCaptionFields = "No.";
    DrillDownPageID = "Reverse Charges";
    LookupPageID = "Reverse Charges";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                NoSeriesMgt: Codeunit NoSeriesManagement;
            begin
                if "No." <> xRec."No." then begin
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;
            end;
        }
        field(5; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(10; "Period No."; Integer)
        {
            Caption = 'Period No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if "Period No." <> xRec."Period No." then begin
                    if LineExists then
                        Error(ChangeErr, FieldCaption("Period No."));
                    SetPeriod;
                end;
            end;
        }
        field(11; Year; Integer)
        {
            Caption = 'Year';
            MaxValue = 9999;
            MinValue = 2000;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if Year <> xRec.Year then begin
                    if LineExists then
                        Error(ChangeErr, FieldCaption(Year));
                    SetPeriod;
                end;
            end;
        }
        field(15; "Start Date"; Date)
        {
            Caption = 'Start Date';
            Editable = false;
        }
        field(16; "End Date"; Date)
        {
            Caption = 'End Date';
            Editable = false;
        }
        field(20; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(21; "Country/Region Name"; Text[50])
        {
            Caption = 'Country/Region Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(22; County; Text[30])
        {
            Caption = 'County';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(23; Street; Text[50])
        {
            Caption = 'Street';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(24; "House No."; Text[30])
        {
            Caption = 'House No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(25; "Municipality No."; Text[30])
        {
            Caption = 'Municipality No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(26; City; Text[30])
        {
            Caption = 'City';
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                CountryCode: Code[10];
            begin
                TestField(Status, Status::Open);
                PostCode.ValidateCity(City, "Post Code", County, CountryCode, (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(27; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                CountryCode: Code[10];
            begin
                TestField(Status, Status::Open);
                PostCode.ValidatePostCode(City, "Post Code", County, CountryCode, (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(30; "Tax Office No."; Code[20])
        {
            Caption = 'Tax Office No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(31; "Tax Office Region No."; Code[20])
        {
            Caption = 'Tax Office Region No.';
        }
        field(35; "Declaration Period"; Option)
        {
            Caption = 'Declaration Period';
            OptionCaption = 'Month,Quarter';
            OptionMembers = Month,Quarter;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if "Declaration Period" <> xRec."Declaration Period" then begin
                    if LineExists then
                        Error(ChangeErr, FieldCaption("Declaration Period"));
                    SetPeriod;
                end;
            end;
        }
        field(36; "Declaration Type"; Option)
        {
            Caption = 'Declaration Type';
            OptionCaption = 'Normal,Corrective';
            OptionMembers = Normal,Corrective;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if "Declaration Type" <> xRec."Declaration Type" then begin
                    if LineExists then
                        Error(ChangeErr, FieldCaption("Declaration Type"));
                end;
            end;
        }
        field(40; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(45; "Number of Lines"; Integer)
        {
            CalcFormula = Count ("Reverse Charge Line" WHERE("Reverse Charge No." = FIELD("No.")));
            Caption = 'Number of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(55; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(60; "Natural Employee No."; Code[20])
        {
            Caption = 'Natural Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(61; "Authorized Employee No."; Code[20])
        {
            Caption = 'Authorized Employee No.';
            TableRelation = "Company Officials";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(65; "Filled by Employee No."; Code[20])
        {
            Caption = 'Filled by Employee No.';
            TableRelation = "Company Officials";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(75; "VAT Base Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Reverse Charge Line"."VAT Base Amount (LCY)" WHERE("Reverse Charge No." = FIELD("No.")));
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80; "Statement Type"; Option)
        {
            Caption = 'Statement Type';
            OptionCaption = 'Vendor,Customer';
            OptionMembers = Vendor,Customer;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if LineExists then
                    Error(ChangeErr, FieldCaption("Statement Type"));

                CheckPeriod;
            end;
        }
        field(85; "Part Period From"; Date)
        {
            Caption = 'Part Period From';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Start Date");
                TestField("End Date");
                if "Part Period From" <> 0D then
                    if ("Part Period From" < "Start Date") or ("Part Period From" > "End Date") or
                       (("Part Period To" <> 0D) and ("Part Period To" < "Part Period From"))
                    then
                        FieldError("Part Period From");
            end;
        }
        field(86; "Part Period To"; Date)
        {
            Caption = 'Part Period To';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Start Date");
                TestField("End Date");
                if "Part Period To" <> 0D then
                    if ("Part Period To" < "Start Date") or ("Part Period To" > "End Date") or
                       (("Part Period From" <> 0D) and ("Part Period To" < "Part Period From"))
                    then
                        FieldError("Part Period To");
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Start Date", "End Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "VAT Registration No.")
        {
        }
    }

    trigger OnDelete()
    var
        ReverseChargeLine: Record "Reverse Charge Line";
    begin
        TestField(Status, Status::Open);

        ReverseChargeLine.Reset;
        ReverseChargeLine.SetRange("Reverse Charge No.", "No.");
        ReverseChargeLine.DeleteAll;
    end;

    trigger OnInsert()
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if "No." = '' then
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", WorkDate, "No.", "No. Series");

        InitRecord;
    end;

    trigger OnRename()
    begin
        Error(RenameErr, TableCaption);
    end;

    var
        PostCode: Record "Post Code";
        CompanyInfo: Record "Company Information";
        PeriodExistsErr: Label 'Period from %1 till %2 already exists on %3 %4.', Comment = '%1=Start Date;%2=End Date;%3=TABLECAPTION;%4=No.';
        EarlierThanErr: Label '%1 should be earlier than %2.', Comment = '%1=FIELDCAPTION("Start Date");%2=FIELDCAPTION("End Date")';
        RenameErr: Label 'You cannot rename a %1.', Comment = '%1=TABLECAPTION';
        ChangeErr: Label 'You cannot change %1 because you already have declaration lines.', Comment = '%1=FIELDCAPTION';
        PermittedValuesErr: Label 'The permitted values for %1 are from 1 to %2.', Comment = '%1=FIELDCAPTION;%2=MaxPeriodNo';

    [Scope('OnPrem')]
    procedure InitRecord()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        Country: Record "Country/Region";
    begin
        CompanyInfo.Get;
        StatReportingSetup.Get;

        "Document Date" := WorkDate;

        Country.Get(CompanyInfo."Country/Region Code");
        "Country/Region Name" := Country.Name;
        "VAT Registration No." := CompanyInfo."VAT Registration No.";
        County := CompanyInfo.County;
        City := CompanyInfo.City;
        "Post Code" := CompanyInfo."Post Code";

        Name := StatReportingSetup."Company Trade Name";
        Street := StatReportingSetup.Street;
        "House No." := StatReportingSetup."House No.";
        "Municipality No." := StatReportingSetup."Municipality No.";
        "Tax Office No." := StatReportingSetup."Tax Office Number";
        "Tax Office Region No." := StatReportingSetup."Tax Office Region Number";
        "Natural Employee No." := StatReportingSetup."Natural Employee No.";
        "Authorized Employee No." := StatReportingSetup."Reverse Charge Auth. Emp. No.";
        "Filled by Employee No." := StatReportingSetup."Rvrs. Chrg. Filled by Emp. No.";
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(OldReverseChargeHdr: Record "Reverse Charge Header"): Boolean
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldReverseChargeHdr."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    local procedure GetNoSeriesCode(): Code[20]
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
    begin
        StatReportingSetup.Get;
        StatReportingSetup.TestField("Reverse Charge Nos.");
        exit(StatReportingSetup."Reverse Charge Nos.");
    end;

    local procedure CheckPeriodNo()
    var
        MaxPeriodNo: Integer;
    begin
        if "Declaration Period" = "Declaration Period"::Month then
            MaxPeriodNo := 12
        else
            MaxPeriodNo := 4;

        if not ("Period No." in [1 .. MaxPeriodNo]) then
            Error(PermittedValuesErr, FieldCaption("Period No."), MaxPeriodNo);
    end;

    local procedure SetPeriod()
    begin
        if "Period No." <> 0 then
            CheckPeriodNo;

        if ("Period No." = 0) or (Year = 0) then begin
            "Start Date" := 0D;
            "End Date" := 0D;
        end else
            if "Declaration Period" = "Declaration Period"::Month then begin
                "Start Date" := DMY2Date(1, "Period No.", Year);
                "End Date" := CalcDate('<CM>', "Start Date");
            end else begin
                "Start Date" := DMY2Date(1, "Period No." * 3 - 2, Year);
                "End Date" := CalcDate('<CQ>', "Start Date");
            end;

        CheckPeriod;
    end;

    local procedure CheckPeriod()
    var
        ReverseChargeHdr: Record "Reverse Charge Header";
    begin
        if ("Start Date" = 0D) or ("End Date" = 0D) then
            exit;

        if "Start Date" >= "End Date" then
            Error(EarlierThanErr, FieldCaption("Start Date"), FieldCaption("End Date"));

        ReverseChargeHdr.Reset;
        ReverseChargeHdr.SetCurrentKey("Start Date", "End Date");
        ReverseChargeHdr.SetRange("Start Date", "Start Date");
        ReverseChargeHdr.SetRange("End Date", "End Date");
        ReverseChargeHdr.SetRange("Declaration Type", "Declaration Type");
        ReverseChargeHdr.SetRange("Statement Type", "Statement Type");
        ReverseChargeHdr.SetRange("VAT Registration No.", "VAT Registration No.");
        ReverseChargeHdr.SetFilter("No.", '<>%1', "No.");
        if ReverseChargeHdr.FindFirst then
            Error(PeriodExistsErr, "Start Date", "End Date", ReverseChargeHdr.TableCaption, ReverseChargeHdr."No.");
    end;

    [Scope('OnPrem')]
    procedure GetVATRegNo(): Code[20]
    var
        ReverseChargeLn: Record "Reverse Charge Line";
    begin
        CompanyInfo.Get;
        ReverseChargeLn."VAT Registration No." := "VAT Registration No.";
        ReverseChargeLn."Country/Region Code" := CompanyInfo."Country/Region Code";
        exit(ReverseChargeLn.GetVATRegNo);
    end;

    local procedure LineExists(): Boolean
    var
        ReverseChargeLn: Record "Reverse Charge Line";
    begin
        ReverseChargeLn.SetRange("Reverse Charge No.", "No.");
        exit(not ReverseChargeLn.IsEmpty);
    end;
}

