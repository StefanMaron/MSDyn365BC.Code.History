table 17350 Person
{
    Caption = 'Person';
    LookupPageID = "Person List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    HumanResSetup.Get;
                    NoSeriesMgt.TestManual(HumanResSetup."Person Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "First Name"; Text[30])
        {
            Caption = 'First Name';

            trigger OnValidate()
            begin
                if (xRec."First Name" <> '') and UsedAsEmployee then
                    Error(Text007);

                if ("First Name" <> '') and ("Middle Name" <> '') then
                    Initials := CopyStr("First Name", 1, 1) + '.' + CopyStr("Middle Name", 1, 1) + '.';

                Validate("Full Name", GetFullName);

                if "First Name" <> xRec."First Name" then begin
                    Employee.Reset;
                    Employee.SetCurrentKey("Person No.");
                    Employee.SetRange("Person No.", "No.");
                    Employee.ModifyAll("First Name", "First Name");
                end;
            end;
        }
        field(3; "Middle Name"; Text[30])
        {
            Caption = 'Middle Name';

            trigger OnValidate()
            begin
                if (xRec."Middle Name" <> '') and UsedAsEmployee then
                    Error(Text007);

                if ("First Name" <> '') and ("Middle Name" <> '') then
                    Initials := CopyStr("First Name", 1, 1) + '.' + CopyStr("Middle Name", 1, 1) + '.';

                Validate("Full Name", GetFullName);

                if "Middle Name" <> xRec."Middle Name" then begin
                    Employee.Reset;
                    Employee.SetCurrentKey("Person No.");
                    Employee.SetRange("Person No.", "No.");
                    Employee.ModifyAll("Middle Name", "Middle Name");
                end;
            end;
        }
        field(4; "Last Name"; Text[30])
        {
            Caption = 'Last Name';

            trigger OnValidate()
            begin
                if (xRec."Last Name" <> '') and UsedAsEmployee then
                    Error(Text007);

                Validate("Full Name", GetFullName);

                if "Last Name" <> xRec."Last Name" then begin
                    Employee.Reset;
                    Employee.SetCurrentKey("Person No.");
                    Employee.SetRange("Person No.", "No.");
                    Employee.ModifyAll("Last Name", "Last Name");
                end;
            end;
        }
        field(5; Initials; Text[30])
        {
            Caption = 'Initials';

            trigger OnValidate()
            begin
                if ("Search Name" = UpperCase(xRec.Initials)) or ("Search Name" = '') then
                    "Search Name" := CopyStr(Initials, 1, MaxStrLen("Search Name"));
            end;
        }
        field(6; "Full Name"; Text[100])
        {
            Caption = 'Full Name';

            trigger OnValidate()
            begin
                "Search Name" := UpperCase(CopyStr("Full Name", 1, MaxStrLen("Search Name")));
            end;
        }
        field(7; "Search Name"; Text[50])
        {
            Caption = 'Search Name';
        }
        field(8; "Last Name Change Date"; Date)
        {
            Caption = 'Last Name Change Date';
            Editable = false;
        }
        field(13; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(14; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(15; "E-Mail"; Text[80])
        {
            Caption = 'E-Mail';
            ExtendedDatatype = EMail;
        }
        field(19; Picture; BLOB)
        {
            Caption = 'Picture';
            SubType = Bitmap;
        }
        field(20; "Birth Date"; Date)
        {
            Caption = 'Birth Date';

            trigger OnValidate()
            begin
                if "Birth Date" <> xRec."Birth Date" then begin
                    Employee.Reset;
                    Employee.SetCurrentKey("Person No.");
                    Employee.SetRange("Person No.", "No.");
                    Employee.ModifyAll("Birth Date", "Birth Date");
                end;
            end;
        }
        field(21; "Social Security No."; Text[14])
        {
            Caption = 'Social Security No.';

            trigger OnValidate()
            var
                Pos10: Integer;
                CheckSum: Integer;
            begin
                if "Social Security No." <> '' then begin
                    if StrLen("Social Security No.") <> 14 then
                        Error(Text003, FieldCaption("Social Security No."));
                    if "Social Security No." <> '000-000-000 00' then
                        if (CopyStr("Social Security No.", 4, 1) = '-') and
                           (CopyStr("Social Security No.", 8, 1) = '-') and
                           ((CopyStr("Social Security No.", 12, 1) = ' ') or (CopyStr("Social Security No.", 12, 1) = '-')) and
                           Evaluate(Pos10, CopyStr("Social Security No.", 13, 2)) and
                           (DelChr(DelChr(CopyStr("Social Security No.", 1, 11), '=', '-'), '=', '0987654321') = '')
                        then begin
                            CheckSum := ((101 - StrCheckSum(DelChr(CopyStr("Social Security No.", 1, 11), '=', '-'), '987654321', 101)) mod 101);
                            if ((CheckSum = 100) or (CheckSum = 101)) and (Pos10 <> 0) then
                                Error(Text005, FieldCaption("Social Security No."), 0);
                            if (CheckSum < 100) and (CheckSum <> Pos10) then
                                Error(Text005, FieldCaption("Social Security No."), CheckSum);
                        end else
                            Error(Text003);
                end;
            end;
        }
        field(22; "VAT Registration No."; Code[20])
        {
            Caption = 'VAT Registration No.';
            CharAllowed = '09';

            trigger OnValidate()
            var
                VATRegNoFormat: Record "VAT Registration No. Format";
            begin
                VATRegNoFormat.Test("VAT Registration No.", '', "No.", DATABASE::Person);
            end;
        }
        field(23; "Tax Inspection Code"; Code[4])
        {
            Caption = 'Tax Inspection Code';
        }
        field(24; Gender; Option)
        {
            Caption = 'Gender';
            OptionCaption = ' ,Female,Male';
            OptionMembers = " ",Female,Male;

            trigger OnValidate()
            begin
                if Gender <> xRec.Gender then begin
                    Employee.Reset;
                    Employee.SetCurrentKey("Person No.");
                    Employee.SetRange("Person No.", "No.");
                    Employee.ModifyAll(Gender, Gender);
                end;
            end;
        }
        field(25; "Single Parent"; Boolean)
        {
            Caption = 'Single Parent';
        }
        field(26; "Family Status"; Code[10])
        {
            Caption = 'Family Status';
            TableRelation = "Classificator OKIN".Code WHERE(Group = CONST('10'));
        }
        field(27; Citizenship; Code[10])
        {
            Caption = 'Citizenship';
            TableRelation = "Classificator OKIN".Code WHERE(Group = CONST('02'));
        }
        field(28; Nationality; Code[10])
        {
            Caption = 'Nationality';
            TableRelation = "Classificator OKIN".Code WHERE(Group = CONST('03'));
        }
        field(29; "Native Language"; Code[10])
        {
            Caption = 'Native Language';
            TableRelation = Language;
        }
        field(30; "Non-Resident"; Boolean)
        {
            Caption = 'Non-Resident';
        }
        field(31; "Identity Document Type"; Code[2])
        {
            Caption = 'Identity Document Type';
            TableRelation = "Taxpayer Document Type";
        }
        field(32; "Sick Leave Payment Benefit"; Boolean)
        {
            Caption = 'Sick Leave Payment Benefit';
        }
        field(33; "Citizenship Country/Region"; Code[10])
        {
            Caption = 'Citizenship Country/Region';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                if "Citizenship Country/Region" <> xRec."Citizenship Country/Region" then begin
                    Employee.Reset;
                    Employee.SetCurrentKey("Person No.");
                    Employee.SetRange("Person No.", "No.");
                    Employee.ModifyAll("Country/Region Code", "Citizenship Country/Region");
                end;
            end;
        }
        field(39; Comment; Boolean)
        {
            CalcFormula = Exist ("Human Resource Comment Line" WHERE("Table Name" = CONST(Person),
                                                                     "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(41; "Birthplace Type"; Option)
        {
            Caption = 'Birthplace Type';
            OptionCaption = 'Standard,Special';
            OptionMembers = Standard,Special;
        }
        field(53; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(80; "Military Status"; Option)
        {
            Caption = 'Military Status';
            OptionCaption = 'Not Liable,Liable,Dismissed';
            OptionMembers = "Not Liable",Liable,Dismissed;
        }
        field(81; "Military Rank"; Code[10])
        {
            Caption = 'Military Rank';
            TableRelation = "Classificator OKIN".Code WHERE(Group = CONST('17'));
        }
        field(82; "Military Speciality No."; Text[15])
        {
            Caption = 'Military Speciality No.';
        }
        field(83; "Military Agency"; Text[20])
        {
            Caption = 'Military Agency';
            TableRelation = "General Directory".Code WHERE(Type = CONST("Military Agency"));
        }
        field(84; "Military Retirement Category"; Option)
        {
            Caption = 'Military Retirement Category';
            OptionCaption = ' ,1,2,3';
            OptionMembers = " ","1","2","3";
        }
        field(85; "Military Structure"; Text[20])
        {
            Caption = 'Military Structure';
            TableRelation = "General Directory".Code WHERE(Type = CONST("Military Composition"));
        }
        field(86; "Military Fitness"; Option)
        {
            Caption = 'Military Fitness';
            OptionCaption = 'A-Valid,B-Valid with insignificant restrictions,V-Valid with restrictions,G-Temporary not valid,D-Not valid';
            OptionMembers = "A-Valid","B-Valid with insignificant restrictions","V-Valid with restrictions","G-Temporary not valid","D-Not valid";
        }
        field(87; "Military Registration No."; Text[15])
        {
            Caption = 'Military Registration No.';
        }
        field(88; "Military Registration Office"; Text[50])
        {
            Caption = 'Military Registration Office';
            TableRelation = "General Directory".Code WHERE(Type = CONST("Military Office"));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(89; Recruit; Boolean)
        {
            Caption = 'Recruit';
        }
        field(90; Reservist; Boolean)
        {
            Caption = 'Reservist';
        }
        field(91; "Mobilisation Order"; Boolean)
        {
            Caption = 'Mobilisation Order';
        }
        field(92; "Military Dismissal Reason"; Option)
        {
            Caption = 'Military Dismissal Reason';
            OptionCaption = ' ,Age,State of Health';
            OptionMembers = " ",Age,"State of Health";
        }
        field(93; "Military Dismissal Date"; Date)
        {
            Caption = 'Military Dismissal Date';
        }
        field(94; "Militaty Duty Relation"; Code[10])
        {
            Caption = 'Militaty Duty Relation';
            TableRelation = "Classificator OKIN".Code WHERE(Group = CONST('16'));
        }
        field(95; "Special Military Register"; Boolean)
        {
            Caption = 'Special Military Register';
        }
        field(100; "First Name (English)"; Text[30])
        {
            Caption = 'First Name (English)';
        }
        field(101; "Middle Name (English)"; Text[30])
        {
            Caption = 'Middle Name (English)';
        }
        field(102; "Last Name (English)"; Text[30])
        {
            Caption = 'Last Name (English)';
        }
        field(103; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor WHERE("Vendor Type" = CONST(Person));

            trigger OnLookup()
            var
                Vendor: Record Vendor;
                VendorList: Page "Vendor List";
            begin
                Vendor.SetCurrentKey("Vendor Type");
                Vendor.FilterGroup(2);
                Vendor.SetRange("Vendor Type", Vendor."Vendor Type"::Person);
                Vendor.FilterGroup(0);
                if "Vendor No." <> '' then begin
                    Vendor.Get("Vendor No.");
                    VendorList.SetRecord(Vendor);
                end;
                VendorList.SetTableView(Vendor);
                VendorList.LookupMode := true;
                if VendorList.RunModal = ACTION::LookupOK then begin
                    VendorList.GetRecord(Vendor);
                    "Vendor No." := Vendor."No.";
                end;
            end;

            trigger OnValidate()
            begin
                if ("Vendor No." <> xRec."Vendor No.") and
                   ("Vendor No." <> '')
                then begin
                    Person.Reset;
                    Person.SetRange("Vendor No.", "Vendor No.");
                    Person.SetFilter("No.", '<>%1', "No.");
                    if Person.FindFirst then
                        Error(Text006, Person."No.", "Vendor No.");
                end;
            end;
        }
        field(110; "Total Service (Days)"; Integer)
        {
            Caption = 'Total Service (Days)';
            MaxValue = 30;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckJobHistory;
            end;
        }
        field(111; "Total Service (Months)"; Integer)
        {
            Caption = 'Total Service (Months)';
            MaxValue = 11;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckJobHistory;
            end;
        }
        field(112; "Total Service (Years)"; Integer)
        {
            Caption = 'Total Service (Years)';
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckJobHistory;
            end;
        }
        field(113; "Insured Service (Days)"; Integer)
        {
            Caption = 'Insured Service (Days)';
            MaxValue = 30;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckJobHistory;
            end;
        }
        field(114; "Insured Service (Months)"; Integer)
        {
            Caption = 'Insured Service (Months)';
            MaxValue = 11;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckJobHistory;
            end;
        }
        field(115; "Insured Service (Years)"; Integer)
        {
            Caption = 'Insured Service (Years)';
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckJobHistory;
            end;
        }
        field(116; "Unbroken Service (Days)"; Integer)
        {
            Caption = 'Unbroken Service (Days)';
            MaxValue = 30;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckJobHistory;
            end;
        }
        field(117; "Unbroken Service (Months)"; Integer)
        {
            Caption = 'Unbroken Service (Months)';
            MaxValue = 11;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckJobHistory;
            end;
        }
        field(118; "Unbroken Service (Years)"; Integer)
        {
            Caption = 'Unbroken Service (Years)';
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckJobHistory;
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "VAT Registration No.")
        {
        }
        key(Key3; "Last Name", "First Name")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Last Name", "First Name", "Middle Name")
        {
        }
    }

    trigger OnDelete()
    begin
        PersonNameHistory.SetRange("Person No.", "No.");
        PersonNameHistory.DeleteAll;
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            HumanResSetup.Get;
            HumanResSetup.TestField("Person Nos.");
            NoSeriesMgt.InitSeries(HumanResSetup."Person Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;
    end;

    trigger OnModify()
    begin
        if Vendor.ReadPermission then
            PersonVendorUpdate.PersonToVendor(xRec, Rec);
    end;

    var
        Vendor: Record Vendor;
        HumanResSetup: Record "Human Resources Setup";
        Person: Record Person;
        Employee: Record Employee;
        AlternativeAddress: Record "Alternative Address";
        PersonMedicalInfo: Record "Person Medical Info";
        EmployeeRelative: Record "Employee Relative";
        PersonNameHistory: Record "Person Name History";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text003: Label '%1 format must be xxx-xxx-xxx xx.';
        Text005: Label 'Incorrect checksum for %1. Checksum must be %2.';
        Text006: Label 'Person No. %1 is already linked with %2.';
        PersonVendorUpdate: Codeunit "Person\Vendor Update";
        Text007: Label 'Please use function Change Name to modify person name.';

    [Scope('OnPrem')]
    procedure AssistEdit(OldPerson: Record Person): Boolean
    begin
        with Person do begin
            Person := Rec;
            HumanResSetup.Get;
            HumanResSetup.TestField("Position Nos.");
            if NoSeriesMgt.SelectSeries(HumanResSetup."Person Nos.", OldPerson."No. Series", "No. Series") then begin
                HumanResSetup.Get;
                HumanResSetup.TestField("Person Nos.");
                NoSeriesMgt.SetSeries("No.");
                Rec := Person;
                exit(true);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetFullName(): Text[100]
    begin
        exit("Last Name" + ' ' + "First Name" + ' ' + "Middle Name");
    end;

    [Scope('OnPrem')]
    procedure GetFullNameOnDate(CurrDate: Date): Text[100]
    var
        PersonNameHistory: Record "Person Name History";
    begin
        PersonNameHistory.SetRange("Person No.", "No.");
        if PersonNameHistory.IsEmpty then
            exit(GetFullName);

        PersonNameHistory.SetFilter("Start Date", '<=%1', CurrDate);
        PersonNameHistory.FindLast;
        exit(PersonNameHistory.GetFullName);
    end;

    [Scope('OnPrem')]
    procedure GetNameInitials(): Text[100]
    begin
        exit("Last Name" + ' ' + Initials);
    end;

    [Scope('OnPrem')]
    procedure GetNameInitialsOnDate(CurrDate: Date): Text[100]
    var
        PersonNameHistory: Record "Person Name History";
    begin
        PersonNameHistory.SetRange("Person No.", "No.");
        if PersonNameHistory.IsEmpty then
            exit(GetNameInitials);

        PersonNameHistory.SetFilter("Start Date", '<=%1', CurrDate);
        PersonNameHistory.FindLast;
        exit(PersonNameHistory.GetNameInitials);
    end;

    [Scope('OnPrem')]
    procedure GetEntireAge(BirthDate: Date; CurrDate: Date): Decimal
    var
        BD: array[3] of Integer;
        CD: array[3] of Integer;
        i: Integer;
        EntireAge: Integer;
    begin
        if CurrDate <= BirthDate then
            exit(0);
        for i := 1 to 3 do begin
            BD[i] := Date2DMY(BirthDate, i);
            CD[i] := Date2DMY(CurrDate, i);
        end;
        EntireAge := CD[3] - BD[3];
        if (CD[2] < BD[2]) or (CD[2] = BD[2]) and (CD[1] < BD[1]) then
            EntireAge -= 1;
        exit(EntireAge);
    end;

    [Scope('OnPrem')]
    procedure GetIdentityDoc(CurrDate: Date; var PersonDoc: Record "Person Document")
    begin
        TestField("Identity Document Type");
        PersonDoc.Reset;
        PersonDoc.SetRange("Person No.", "No.");
        PersonDoc.SetRange("Document Type", "Identity Document Type");
        PersonDoc.SetRange("Valid from Date", 0D, CurrDate);
        PersonDoc.SetFilter("Valid to Date", '%1|%2..', 0D, CurrDate);
        if not PersonDoc.FindLast then
            Clear(PersonDoc);
    end;

    [Scope('OnPrem')]
    procedure IsChild(CurrentDate: Date): Boolean
    begin
        TestField("Birth Date");
        exit(GetEntireAge("Birth Date", CurrentDate) < 18);
    end;

    [Scope('OnPrem')]
    procedure IsVeteran(Type: Option Chernobyl,Afganistan,Pensioneer; CurrentDate: Date): Boolean
    begin
        PersonMedicalInfo.SetRange("Person No.", "No.");
        PersonMedicalInfo.SetRange("Starting Date", 0D, CurrentDate);
        PersonMedicalInfo.SetFilter("Ending Date", '%1|%2..', 0D, CalcDate('<1D>', CurrentDate));
        case Type of
            Type::Chernobyl:
                PersonMedicalInfo.SetRange(Privilege, PersonMedicalInfo.Privilege::"Chernobyl Veteran");
            Type::Afganistan:
                PersonMedicalInfo.SetRange(Privilege, PersonMedicalInfo.Privilege::"Afghanistan Veteran");
            Type::Pensioneer:
                PersonMedicalInfo.SetRange(Privilege, PersonMedicalInfo.Privilege::Pensioner);
        end;
        exit(not PersonMedicalInfo.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure IsDisabled(CurrentDate: Date): Boolean
    begin
        PersonMedicalInfo.SetRange("Person No.", "No.");
        PersonMedicalInfo.SetRange("Starting Date", 0D, CurrentDate);
        PersonMedicalInfo.SetFilter("Ending Date", '%1|%2..', 0D, CalcDate('<1D>', CurrentDate));
        PersonMedicalInfo.SetFilter("Disability Group", '<>%1', 0);
        exit(not PersonMedicalInfo.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure GetDisabilityGroup(CurrentDate: Date): Integer
    begin
        PersonMedicalInfo.SetRange("Person No.", "No.");
        PersonMedicalInfo.SetRange("Starting Date", 0D, CurrentDate);
        PersonMedicalInfo.SetFilter("Ending Date", '%1|%2..', 0D, CalcDate('<1D>', CurrentDate));
        PersonMedicalInfo.SetFilter("Disability Group", '<>%1', 0);
        if PersonMedicalInfo.FindFirst then
            exit(PersonMedicalInfo."Disability Group");

        exit(0);
    end;

    [Scope('OnPrem')]
    procedure ChildrenNumber(CurrentDate: Date) Kids: Integer
    var
        Relative: Record Relative;
    begin
        Kids := 0;
        EmployeeRelative.Reset;
        EmployeeRelative.SetRange("Person No.", "No.");
        if EmployeeRelative.FindSet then
            repeat
                Relative.Get(EmployeeRelative."Relative Code");
                if (Relative."Relative Type" = Relative."Relative Type"::Child) and
                   (GetEntireAge(EmployeeRelative."Birth Date", CurrentDate) < 18)
                then
                    Kids := Kids + 1;
            until EmployeeRelative.Next = 0;
        exit(Kids);
    end;

    [Scope('OnPrem')]
    procedure UsedAsEmployee(): Boolean
    begin
        Employee.Reset;
        Employee.SetCurrentKey("Person No.");
        Employee.SetRange("Person No.", "No.");
        exit(not Employee.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure GetBirthPlace() BirthPlace: Text[50]
    begin
        AlternativeAddress.Reset;
        AlternativeAddress.SetRange("Person No.", "No.");
        AlternativeAddress.SetRange("Address Type", AlternativeAddress."Address Type"::Birthplace);
        if AlternativeAddress.FindFirst then
            BirthPlace := AlternativeAddress.City;
    end;

    [Scope('OnPrem')]
    procedure CheckJobHistory()
    var
        PersonJobHistory: Record "Person Job History";
    begin
        PersonJobHistory.SetRange("Person No.", "No.");
        if not PersonJobHistory.IsEmpty then
            case CurrFieldNo of
                FieldNo("Total Service (Days)"):
                    FieldError("Total Service (Days)");
                FieldNo("Total Service (Months)"):
                    FieldError("Total Service (Months)");
                FieldNo("Total Service (Years)"):
                    FieldError("Total Service (Years)");
                FieldNo("Insured Service (Days)"):
                    FieldError("Insured Service (Days)");
                FieldNo("Insured Service (Months)"):
                    FieldError("Insured Service (Months)");
                FieldNo("Insured Service (Years)"):
                    FieldError("Insured Service (Years)");
                FieldNo("Unbroken Service (Days)"):
                    FieldError("Unbroken Service (Days)");
                FieldNo("Unbroken Service (Months)"):
                    FieldError("Unbroken Service (Months)");
                FieldNo("Unbroken Service (Years)"):
                    FieldError("Unbroken Service (Years)");
            end;
    end;
}

