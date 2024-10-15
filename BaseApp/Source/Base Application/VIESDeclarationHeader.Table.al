table 31066 "VIES Declaration Header"
{
    Caption = 'VIES Declaration Header';
    DataCaptionFields = "No.";
    DrillDownPageID = "VIES Declarations";
    LookupPageID = "VIES Declarations";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

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
        field(2; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(3; "Trade Type"; Option)
        {
            Caption = 'Trade Type';
            InitValue = Sales;
            OptionCaption = 'Purchases,Sales,Both';
            OptionMembers = Purchases,Sales,Both;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if LineExists then
                    Error(Text004Err, FieldCaption("Trade Type"));
                CheckPeriod;
            end;
        }
        field(4; "Period No."; Integer)
        {
            Caption = 'Period No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if "Period No." <> xRec."Period No." then begin
                    if LineExists then
                        Error(Text004Err, FieldCaption("Period No."));
                    SetPeriod;
                end;
            end;
        }
        field(5; Year; Integer)
        {
            Caption = 'Year';
            MaxValue = 9999;
            MinValue = 2000;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if Year <> xRec.Year then begin
                    if LineExists then
                        Error(Text004Err, FieldCaption(Year));
                    SetPeriod;
                end;
            end;
        }
        field(6; "Start Date"; Date)
        {
            Caption = 'Start Date';
            Editable = false;
        }
        field(7; "End Date"; Date)
        {
            Caption = 'End Date';
            Editable = false;
        }
        field(8; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(9; "Name 2"; Text[50])
        {
            Caption = 'Name 2';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(10; "Country/Region Name"; Text[50])
        {
            Caption = 'Country/Region Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(11; County; Text[30])
        {
            Caption = 'County';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(12; "Municipality No."; Text[30])
        {
            Caption = 'Municipality No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(13; Street; Text[50])
        {
            Caption = 'Street';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(14; "House No."; Text[30])
        {
            Caption = 'House No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(15; "Apartment No."; Text[30])
        {
            Caption = 'Apartment No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(16; City; Text[30])
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
        field(17; "Post Code"; Code[20])
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
        field(18; "Tax Office Number"; Code[20])
        {
            Caption = 'Tax Office Number';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(19; "Declaration Period"; Option)
        {
            Caption = 'Declaration Period';
            OptionCaption = 'Quarter,Month';
            OptionMembers = Quarter,Month;
            InitValue = Month;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if "Declaration Period" <> xRec."Declaration Period" then begin
                    if LineExists then
                        Error(Text004Err, FieldCaption("Declaration Period"));
                    SetPeriod;
                end;
            end;
        }
        field(20; "Declaration Type"; Option)
        {
            Caption = 'Declaration Type';
            OptionCaption = 'Normal,Corrective,Corrective-Supplementary';
            OptionMembers = Normal,Corrective,"Corrective-Supplementary";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if "Declaration Type" <> xRec."Declaration Type" then begin
                    if LineExists then
                        Error(Text004Err, FieldCaption("Declaration Type"));
                    if "Declaration Type" = "Declaration Type"::Normal then
                        "Corrected Declaration No." := '';
                end;
            end;
        }
        field(21; "Corrected Declaration No."; Code[20])
        {
            Caption = 'Corrected Declaration No.';
            TableRelation = "VIES Declaration Header" WHERE("Corrected Declaration No." = FILTER(''),
                                                             Status = CONST(Released));

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if "Corrected Declaration No." <> xRec."Corrected Declaration No." then begin
                    if "Declaration Type" = "Declaration Type"::Normal then
                        FieldError("Declaration Type");
                    if "No." = "Corrected Declaration No." then
                        FieldError("Corrected Declaration No.");
                    if LineExists then
                        Error(Text004Err, FieldCaption("Corrected Declaration No."));

                    CopyCorrDeclaration;
                end;
            end;
        }
        field(24; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(25; "Number of Pages"; Integer)
        {
            CalcFormula = Max("VIES Declaration Line"."Report Page Number" WHERE("VIES Declaration No." = FIELD("No.")));
            Caption = 'Number of Pages';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Number of Lines"; Integer)
        {
            CalcFormula = Count("VIES Declaration Line" WHERE("VIES Declaration No." = FIELD("No.")));
            Caption = 'Number of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; "Sign-off Place"; Text[30])
        {
            Caption = 'Sign-off Place';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(28; "Sign-off Date"; Date)
        {
            Caption = 'Sign-off Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(29; "EU Goods/Services"; Option)
        {
            Caption = 'EU Goods/Services';
            OptionCaption = 'Both,Goods,Services';
            OptionMembers = Both,Goods,Services;

            trigger OnValidate()
            begin
                if LineExists then
                    Error(Text004Err, FieldCaption("EU Goods/Services"));
            end;
        }
        field(30; "Purchase Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("VIES Declaration Line"."Amount (LCY)" WHERE("VIES Declaration No." = FIELD("No."),
                                                                            "Trade Type" = CONST(Purchase)));
            Caption = 'Purchase Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Sales Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("VIES Declaration Line"."Amount (LCY)" WHERE("VIES Declaration No." = FIELD("No."),
                                                                            "Trade Type" = CONST(Sale)));
            Caption = 'Sales Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("VIES Declaration Line"."Amount (LCY)" WHERE("VIES Declaration No." = FIELD("No.")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Number of Supplies"; Decimal)
        {
            CalcFormula = Sum("VIES Declaration Line"."Number of Supplies" WHERE("VIES Declaration No." = FIELD("No.")));
            Caption = 'Number of Supplies';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(51; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(70; "Authorized Employee No."; Code[20])
        {
            Caption = 'Authorized Employee No.';
            TableRelation = "Company Officials";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(71; "Filled by Employee No."; Code[20])
        {
            Caption = 'Filled by Employee No.';
            TableRelation = "Company Officials";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(80; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of VAT Registration in Other Countries has been removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11700; "Natural Person First Name"; Text[30])
        {
            Caption = 'Natural Person First Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(11701; "Natural Person Surname"; Text[30])
        {
            Caption = 'Natural Person Surname';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(11702; "Natural Person Title"; Text[30])
        {
            Caption = 'Natural Person Title';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(11703; "Taxpayer Type"; Option)
        {
            Caption = 'Taxpayer Type';
            OptionCaption = 'Corporation,Individual';
            OptionMembers = Corporation,Individual;

            trigger OnValidate()
            var
                StatReportingSetup: Record "Stat. Reporting Setup";
            begin
                TestField(Status, Status::Open);

                if "Taxpayer Type" <> xRec."Taxpayer Type" then begin
                    CompanyInfo.Get();
                    StatReportingSetup.Get();

                    case "Taxpayer Type" of
                        "Taxpayer Type"::Individual:
                            begin
                                Name := '';
                                "Name 2" := '';
                                "Company Trade Name Appendix" := '';
                                "Natural Person First Name" := StatReportingSetup."Natural Person First Name";
                                "Natural Person Surname" := StatReportingSetup."Natural Person Surname";
                                "Natural Person Title" := StatReportingSetup."Natural Person Title";
                            end;
                        "Taxpayer Type"::Corporation:
                            begin
                                Name := StatReportingSetup."Company Trade Name";
                                "Name 2" := '';
                                "Company Trade Name Appendix" := StatReportingSetup."Company Trade Name Appendix";
                                "Natural Person First Name" := '';
                                "Natural Person Surname" := '';
                                "Natural Person Title" := '';
                            end;
                    end;
                end;
            end;
        }
        field(11705; "Natural Employee No."; Code[20])
        {
            Caption = 'Natural Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(11734; "Company Trade Name Appendix"; Text[11])
        {
            Caption = 'Company Trade Name Appendix';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(31060; "Tax Office Region Number"; Code[20])
        {
            Caption = 'Tax Office Region Number';
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
        fieldgroup(DropDown; "EU Goods/Services", "Period No.", Year)
        {
        }
    }

    trigger OnDelete()
    var
        VIESDeclarationLine: Record "VIES Declaration Line";
    begin
        TestField(Status, Status::Open);

        VIESDeclarationLine.Reset();
        VIESDeclarationLine.SetRange("VIES Declaration No.", "No.");
        VIESDeclarationLine.DeleteAll();
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
        Error(Text003Err, TableCaption);
    end;

    var
        PostCode: Record "Post Code";
        CompanyInfo: Record "Company Information";
        Text001Err: Label 'Period from %1 till %2 already exists on %3 %4.', Comment = '%1=startdate;%2=enddate;%3=viesdeclarationheader.tablecaption;%4=viesdeclarationheader.number';
        Text002Err: Label '%1 should be earlier than %2.', Comment = '%1=fieldcaption.startingdate;%2=fieldcaptionenddate';
        Text003Err: Label 'You cannot rename a %1.';
        Text004Err: Label 'You cannot change %1 because you already have declaration lines.';
        Text005Err: Label 'The permitted values for %1 are from 1 to %2.', Comment = '%1=fieldcaption.periodnumber;%2=maxperiodnumber';

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure InitRecord()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        Country: Record "Country/Region";
    begin
        CompanyInfo.Get();
        StatReportingSetup.Get();
        "VAT Registration No." := CompanyInfo."VAT Registration No.";
        "Document Date" := WorkDate;
        Name := StatReportingSetup."Company Trade Name";
        "Name 2" := '';
        Country.Get(CompanyInfo."Country/Region Code");
        "Country/Region Name" := Country.Name;
        County := CompanyInfo.County;
        City := CompanyInfo.City;
        Street := StatReportingSetup.Street;
        "House No." := StatReportingSetup."House No.";
        "Apartment No." := StatReportingSetup."Apartment No.";
        "Municipality No." := StatReportingSetup."Municipality No.";
        "Post Code" := CompanyInfo."Post Code";
        "Tax Office Number" := StatReportingSetup."Tax Office Number";
        "Tax Office Region Number" := StatReportingSetup."Tax Office Region Number";
        "Taxpayer Type" := StatReportingSetup."Taxpayer Type";
        "Company Trade Name Appendix" := StatReportingSetup."Company Trade Name Appendix";
        "Natural Employee No." := StatReportingSetup."Natural Employee No.";
        "Authorized Employee No." := StatReportingSetup."VIES Decl. Auth. Employee No.";
        "Filled by Employee No." := StatReportingSetup."VIES Decl. Filled by Empl. No.";
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure AssistEdit(VIESDeclarationHeaderold: Record "VIES Declaration Header"): Boolean
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if NoSeriesMgt.SelectSeries(GetNoSeriesCode, VIESDeclarationHeaderold."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    local procedure GetNoSeriesCode(): Code[20]
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
    begin
        StatReportingSetup.Get();
        StatReportingSetup.TestField("VIES Declaration Nos.");
        exit(StatReportingSetup."VIES Declaration Nos.");
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
            Error(Text005Err, FieldCaption("Period No."), MaxPeriodNo);
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
        VIESDeclarationHeader: Record "VIES Declaration Header";
    begin
        if ("Start Date" = 0D) or ("End Date" = 0D) then
            exit;

        if "Start Date" >= "End Date" then
            Error(Text002Err, FieldCaption("Start Date"), FieldCaption("End Date"));

        if "Corrected Declaration No." = '' then begin
            VIESDeclarationHeader.Reset();
            VIESDeclarationHeader.SetCurrentKey("Start Date", "End Date");
            VIESDeclarationHeader.SetRange("Start Date", "Start Date");
            VIESDeclarationHeader.SetRange("End Date", "End Date");
            VIESDeclarationHeader.SetRange("Corrected Declaration No.", '');
            VIESDeclarationHeader.SetRange("VAT Registration No.", "VAT Registration No.");
            VIESDeclarationHeader.SetRange("Declaration Type", "Declaration Type");
            VIESDeclarationHeader.SetRange("Trade Type", "Trade Type");
            VIESDeclarationHeader.SetFilter("No.", '<>%1', "No.");
            if VIESDeclarationHeader.FindFirst then
                Error(Text001Err, "Start Date", "End Date", VIESDeclarationHeader.TableCaption, VIESDeclarationHeader."No.");
        end;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure GetVATRegNo(): Code[20]
    var
        VIESDeclarationLine: Record "VIES Declaration Line";
    begin
        CompanyInfo.Get();
        VIESDeclarationLine."VAT Registration No." := "VAT Registration No.";
        VIESDeclarationLine."Country/Region Code" := CompanyInfo."Country/Region Code";
        exit(VIESDeclarationLine.GetVATRegNo);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure PrintTestReport()
    var
        VIESDeclarationHeader: Record "VIES Declaration Header";
    begin
        VIESDeclarationHeader := Rec;
        VIESDeclarationHeader.SetRecFilter;
        REPORT.Run(REPORT::"VIES Declaration - Test", true, false, VIESDeclarationHeader);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure Print()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        VIESDeclarationHeader: Record "VIES Declaration Header";
        VIESDeclarationReportNo: Integer;
    begin
        TestField(Status, Status::Released);
        StatReportingSetup.Get();
        StatReportingSetup.TestField("VIES Declaration Report No.");
        VIESDeclarationReportNo := StatReportingSetup."VIES Declaration Report No.";
        VIESDeclarationHeader := Rec;
        VIESDeclarationHeader.SetRecFilter;
        Report.Run(StatReportingSetup."VIES Declaration Report No.", true, false, VIESDeclarationHeader);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure Export()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        VIESDeclarationHeader: Record "VIES Declaration Header";
        VIESDeclExpObjType: Option ,,,"Report",,"Codeunit";
        VIESDeclExpObjNo: Integer;
    begin
        TestField(Status, Status::Released);
        if "Declaration Type" = "Declaration Type"::"Corrective-Supplementary" then
            FieldError("Declaration Type");
        StatReportingSetup.Get();
        StatReportingSetup.TestField("VIES Decl. Exp. Obj. No.");
        VIESDeclExpObjType := StatReportingSetup."VIES Decl. Exp. Obj. Type";
        VIESDeclExpObjNo := StatReportingSetup."VIES Decl. Exp. Obj. No.";
        VIESDeclarationHeader := Rec;
        VIESDeclarationHeader.SetRecFilter;
        if StatReportingSetup."VIES Decl. Exp. Obj. Type" = StatReportingSetup."VIES Decl. Exp. Obj. Type"::Codeunit then
            Codeunit.Run(StatReportingSetup."VIES Decl. Exp. Obj. No.", VIESDeclarationHeader)
        else
            Report.Run(StatReportingSetup."VIES Decl. Exp. Obj. No.", true, false, VIESDeclarationHeader);
    end;

    local procedure LineExists(): Boolean
    var
        VIESDeclarationLine: Record "VIES Declaration Line";
    begin
        VIESDeclarationLine.Reset();
        VIESDeclarationLine.SetRange("VIES Declaration No.", "No.");
        exit(VIESDeclarationLine.FindFirst);
    end;

    local procedure CopyCorrDeclaration()
    var
        VIESDeclarationHeaderSaved: Record "VIES Declaration Header";
        VIESDeclarationHeader: Record "VIES Declaration Header";
    begin
        TestField("Corrected Declaration No.");
        VIESDeclarationHeader.Get("Corrected Declaration No.");
        VIESDeclarationHeaderSaved.TransferFields(Rec);
        TransferFields(VIESDeclarationHeader);
        Modify;
        "No." := VIESDeclarationHeaderSaved."No.";
        Status := VIESDeclarationHeaderSaved.Status::Open;
        "Document Date" := VIESDeclarationHeaderSaved."Document Date";
        "Declaration Type" := VIESDeclarationHeaderSaved."Declaration Type";
        "Corrected Declaration No." := VIESDeclarationHeaderSaved."Corrected Declaration No.";
    end;
}

