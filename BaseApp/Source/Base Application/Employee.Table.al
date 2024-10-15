table 5200 Employee
{
    Caption = 'Employee';
    DataCaptionFields = "No.", "First Name", "Middle Name", "Last Name";
    DrillDownPageID = "Employee List";
    LookupPageID = "Employee List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    HumanResSetup.Get();
                    NoSeriesMgt.TestManual(HumanResSetup."Employee Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "First Name"; Text[30])
        {
            Caption = 'First Name';

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("First Name") then
                    TestField("Person No.", '');

                if ("First Name" <> '') and ("Middle Name" <> '') then
                    Initials := CopyStr("First Name", 1, 1) + '.' + CopyStr("Middle Name", 1, 1) + '.';

                "Short Name" := StrSubstNo('%1 %2', "Last Name", Initials);
            end;
        }
        field(3; "Middle Name"; Text[30])
        {
            Caption = 'Middle Name';

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Middle Name") then
                    TestField("Person No.", '');

                if ("First Name" <> '') and ("Middle Name" <> '') then
                    Initials := CopyStr("First Name", 1, 1) + '.' + CopyStr("Middle Name", 1, 1) + '.';

                "Short Name" := CopyStr(StrSubstNo('%1 %2', "Last Name", Initials), 1, MaxStrLen("Short Name"));
            end;
        }
        field(4; "Last Name"; Text[30])
        {
            Caption = 'Last Name';

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Last Name") then
                    TestField("Person No.", '');

                "Search Name" := "Last Name";

                "Short Name" := CopyStr(StrSubstNo('%1 %2', "Last Name", Initials), 1, MaxStrLen("Short Name"));
            end;
        }
        field(5; Initials; Text[30])
        {
            Caption = 'Initials';

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo(Initials) then
                    TestField("Person No.", '');

                if ("Search Name" = UpperCase(xRec.Initials)) or ("Search Name" = '') then
                    "Search Name" := Initials;

                "Short Name" := CopyStr(StrSubstNo('%1 %2', "Last Name", Initials), 1, MaxStrLen("Short Name"));
            end;
        }
        field(6; "Job Title"; Text[50])
        {
            Caption = 'Job Title';
        }
        field(7; "Search Name"; Code[50])
        {
            Caption = 'Search Name';

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Search Name") then
                    TestField("Person No.", '');
            end;
        }
        field(8; Address; Text[100])
        {
            Caption = 'Address';

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo(Address) then
                    TestField("Person No.", '');
            end;
        }
        field(9; "Address 2"; Text[50])
        {
            Caption = 'Address 2';

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Address 2") then
                    TestField("Person No.", '');
            end;
        }
        field(10; City; Text[30])
        {
            Caption = 'City';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                if CurrFieldNo = FieldNo(City) then
                    TestField("Person No.", '');
            end;
        }
        field(11; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                if CurrFieldNo = FieldNo("Post Code") then
                    TestField("Person No.", '');
            end;
        }
        field(12; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo(County) then
                    TestField("Person No.", '');
            end;
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
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(16; "Alt. Address Code"; Code[10])
        {
            Caption = 'Alt. Address Code';
            TableRelation = "Alternative Address".Code WHERE("Person No." = FIELD("Person No."));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(17; "Alt. Address Start Date"; Date)
        {
            Caption = 'Alt. Address Start Date';
        }
        field(18; "Alt. Address End Date"; Date)
        {
            Caption = 'Alt. Address End Date';
        }
        field(19; Picture; BLOB)
        {
            Caption = 'Picture';
            ObsoleteReason = 'Replaced by Image field';
            ObsoleteState = Pending;
            SubType = Bitmap;
            ObsoleteTag = '15.0';
        }
        field(20; "Birth Date"; Date)
        {
            Caption = 'Birth Date';

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Birth Date") then
                    TestField("Person No.", '');
            end;
        }
        field(21; "Social Security No."; Text[30])
        {
            Caption = 'Social Security No.';

            trigger OnValidate()
            var
                Pos10: Integer;
                CheckSum: Integer;
            begin
                if CurrFieldNo = FieldNo("Social Security No.") then
                    TestField("Person No.", '');

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
        field(22; "Union Code"; Code[10])
        {
            Caption = 'Union Code';
            TableRelation = Union;
        }
        field(23; "Union Membership No."; Text[30])
        {
            Caption = 'Union Membership No.';
        }
        field(24; Gender; Enum "Employee Gender")
        {
            Caption = 'Gender';

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo(Gender) then
                    TestField("Person No.", '');
            end;
        }
        field(25; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Country/Region Code") then
                    TestField("Person No.", '');
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(26; "Manager No."; Code[20])
        {
            Caption = 'Manager No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Manager No.") then
                    TestField("Position No.", '');
            end;
        }
        field(27; "Emplymt. Contract Code"; Code[10])
        {
            Caption = 'Emplymt. Contract Code';
            TableRelation = "Employment Contract";
        }
        field(28; "Statistics Group Code"; Code[10])
        {
            Caption = 'Statistics Group Code';
            TableRelation = "Employee Statistics Group";

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Statistics Group Code") then
                    TestField("Contract No.", '');
            end;
        }
        field(29; "Employment Date"; Date)
        {
            Caption = 'Employment Date';

            trigger OnValidate()
            var
                LaborContract: Record "Labor Contract";
            begin
                if CurrFieldNo = FieldNo("Employment Date") then
                    TestField("Contract No.", '');

                if "Employment Date" <> 0D then begin
                    PayrollPeriod.Reset();
                    LaborContract.Get("Contract No.");
                    if LaborContract."Ending Date" = 0D then
                        PayrollPeriod.SetFilter(Code, '%1..',
                          PayrollPeriod.PeriodByDate("Employment Date"))
                    else
                        if PayrollPeriod.PeriodByDate(LaborContract."Ending Date") = '' then
                            PayrollPeriod.SetFilter(
                              Code, '%1..', PayrollPeriod.PeriodByDate("Employment Date"))
                        else
                            PayrollPeriod.SetRange(Code,
                              PayrollPeriod.PeriodByDate("Employment Date"),
                              PayrollPeriod.PeriodByDate(LaborContract."Ending Date"));
                    if PayrollPeriod.FindSet then
                        repeat
                            TimesheetMgmt.CreateTimesheet(Rec, PayrollPeriod);
                            if not PayrollStatus.Get(PayrollPeriod.Code, "No.") then begin
                                PayrollStatus.Init();
                                PayrollStatus."Period Code" := PayrollPeriod.Code;
                                PayrollStatus."Employee No." := "No.";
                                PayrollStatus.Insert();
                            end;
                        until PayrollPeriod.Next = 0;
                end;
            end;
        }
        field(31; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Active,Inactive,Terminated';
            OptionMembers = Active,Inactive,Terminated;

            trigger OnValidate()
            begin
                EmployeeQualification.SetRange("Person No.", "No.");
                EmployeeQualification.ModifyAll("Employee Status", Status);
                Modify;
            end;
        }
        field(32; "Inactive Date"; Date)
        {
            Caption = 'Inactive Date';
        }
        field(33; "Cause of Inactivity Code"; Code[10])
        {
            Caption = 'Cause of Inactivity Code';
            TableRelation = "Cause of Inactivity";
        }
        field(34; "Termination Date"; Date)
        {
            Caption = 'Termination Date';

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Termination Date") then
                    TestField("Contract No.", '');
            end;
        }
        field(35; "Grounds for Term. Code"; Code[10])
        {
            Caption = 'Grounds for Term. Code';
            TableRelation = "Grounds for Termination";

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Grounds for Term. Code") then
                    TestField("Contract No.", '');
            end;
        }
        field(36; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(37; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(38; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource WHERE(Type = CONST(Person));

            trigger OnValidate()
            begin
                if ("Resource No." <> '') and Res.WritePermission then begin
                    CheckIfAnEmployeeIsLinkedToTheResource("Resource No.");
                    EmployeeResUpdate.ResUpdate(Rec);
                end;
            end;
        }
        field(39; Comment; Boolean)
        {
            CalcFormula = Exist ("Human Resource Comment Line" WHERE("Table Name" = CONST(Employee),
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
        field(41; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(42; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(43; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(44; "Time Activity Filter"; Code[10])
        {
            Caption = 'Time Activity Filter';
            FieldClass = FlowFilter;
            TableRelation = "Time Activity";
        }
        field(45; "Absence Days"; Decimal)
        {
            CalcFormula = Sum ("Employee Absence Entry"."Calendar Days" WHERE("Employee No." = FIELD("No."),
                                                                              "Time Activity Code" = FIELD("Time Activity Filter"),
                                                                              "Start Date" = FIELD("Date Filter")));
            Caption = 'Absence Days';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(46; Extension; Text[30])
        {
            Caption = 'Extension';
        }
        field(47; "Employee No. Filter"; Code[20])
        {
            Caption = 'Employee No. Filter';
            FieldClass = FlowFilter;
            TableRelation = Employee;
        }
        field(48; Pager; Text[30])
        {
            Caption = 'Pager';
        }
        field(49; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(50; "Company E-Mail"; Text[80])
        {
            Caption = 'Company Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("Company E-Mail");
            end;
        }
        field(51; Title; Text[30])
        {
            Caption = 'Title';
        }
        field(52; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(53; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(54; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(56; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';
        }
        field(57; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
        }
        field(58; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(60; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        field(80; "Application Method"; Option)
        {
            Caption = 'Application Method';
            OptionCaption = 'Manual,Apply to Oldest';
            OptionMembers = Manual,"Apply to Oldest";
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
            ExtendedDatatype = Person;
        }
        field(150; "Privacy Blocked"; Boolean)
        {
            Caption = 'Privacy Blocked';

            trigger OnValidate()
            begin
                if "Privacy Blocked" then
                    Blocked := true
                else
                    Blocked := false;
            end;
        }
        field(1100; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
            TableRelation = "Cost Center";
        }
        field(1101; "Cost Object Code"; Code[20])
        {
            Caption = 'Cost Object Code';
            TableRelation = "Cost Object";
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
        }
        field(17350; "Org. Unit Code"; Code[10])
        {
            Caption = 'Org. Unit Code';
            Editable = false;
            TableRelation = "Organizational Unit";

            trigger OnValidate()
            begin
                if OrgUnit.Get("Org. Unit Code") then
                    "Org. Unit Name" := OrgUnit.Name
                else
                    "Org. Unit Name" := '';
            end;
        }
        field(17351; "Job Title Code"; Code[10])
        {
            Caption = 'Job Title Code';
            TableRelation = "Job Title";

            trigger OnValidate()
            begin
                if JobTitle.Get("Job Title Code") then
                    "Job Title" := JobTitle.Name
                else
                    "Job Title" := '';
            end;
        }
        field(17352; "Person No."; Code[20])
        {
            Caption = 'Person No.';
            Editable = false;
            TableRelation = Person;

            trigger OnValidate()
            begin
                if Person.Get("Person No.") then begin
                    Validate("First Name", Person."First Name");
                    Validate("Middle Name", Person."Middle Name");
                    Validate("Last Name", Person."Last Name");
                    Validate("Search Name", Person."Search Name");
                    Validate("Birth Date", Person."Birth Date");
                    Validate(Gender, Person.Gender);
                    Validate("Social Security No.", Person."Social Security No.");
                    Validate("Country/Region Code", Person."Citizenship Country/Region");
                end;
            end;
        }
        field(17353; "Position No."; Code[20])
        {
            Caption = 'Position No.';
            Editable = false;
            TableRelation = Position;

            trigger OnValidate()
            begin
                if Position.Get("Position No.") then begin
                    Validate("Org. Unit Code", Position."Org. Unit Code");
                    Validate("Job Title Code", Position."Job Title Code");
                    Validate("Category Code", Position."Category Code");
                    Validate("Statistics Group Code", Position."Statistical Group Code");
                    Validate("Payroll Calc Group", Position."Calc Group Code");
                    Validate("Calendar Code", Position."Calendar Code");
                    Validate("Posting Group", Position."Posting Group");
                    Validate("Int. Fnds Sick Leave Post. Gr.", Position."Posting Group");
                    Validate("Future Period Vacat. Post. Gr.", Position."Future Period Vacat. Post. Gr.");
                end;
            end;
        }
        field(17354; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            Editable = false;
            TableRelation = "Labor Contract" WHERE("Employee No." = FIELD("No."));
        }
        field(17355; "Employee Vendor No."; Code[20])
        {
            Caption = 'Employee Vendor No.';
        }
        field(17356; "Tax Payer Category"; Code[20])
        {
            Caption = 'Tax Payer Category';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Tax Payer Category"));
        }
        field(17357; "Employee Bank Code"; Code[20])
        {
            Caption = 'Employee Bank Code';
            TableRelation = "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Employee Vendor No."));
        }
        field(17358; "Category Code"; Code[10])
        {
            Caption = 'Category Code';
            Editable = false;
            TableRelation = "Employee Category";
        }
        field(17359; "Payroll Calc Group"; Code[10])
        {
            Caption = 'Payroll Calc Group';
            Editable = false;
            TableRelation = "Payroll Calc Group";
        }
        field(17360; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            Editable = false;
            TableRelation = "Payroll Calendar";
        }
        field(17361; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = "Payroll Posting Group";
        }
        field(17362; "Skip for Avg. HC Calculation"; Boolean)
        {
            Caption = 'Skip for Avg. HC Calculation';
        }
        field(17363; Blocked; Boolean)
        {
            Caption = 'Blocked';

            trigger OnValidate()
            begin
                if not Blocked and "Privacy Blocked" then
                    if GuiAllowed then
                        if Confirm(ConfirmBlockedPrivacyBlockedQst) then
                            "Privacy Blocked" := false
                        else
                            Error('')
                    else
                        Error(CanNotChangeBlockedDueToPrivacyBlockedErr);
            end;
        }
        field(17364; "Int. Fnds Sick Leave Post. Gr."; Code[20])
        {
            Caption = 'Int. Fnds Sick Leave Post. Gr.';
            TableRelation = "Payroll Posting Group";
        }
        field(17365; "Short Name"; Text[50])
        {
            Caption = 'Short Name';
        }
        field(17366; "Manufacturing Type"; Option)
        {
            Caption = 'Manufacturing Type';
            OptionCaption = ' ,Basic,Additional,Contract';
            OptionMembers = " ",Basic,Additional,Contract;
        }
        field(17370; "Future Period Vacat. Post. Gr."; Code[20])
        {
            Caption = 'Future Period Vacat. Post. Gr.';
            TableRelation = "Payroll Posting Group";
        }
        field(17400; "Payroll Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Detailed Payroll Ledger Entry"."Payroll Amount" WHERE("Employee No." = FIELD("Employee No. Filter"),
                                                                                      "Element Type" = FIELD("Element Type Filter"),
                                                                                      "Element Group" = FIELD("Element Group Filter"),
                                                                                      "Element Code" = FIELD("Element Code Filter"),
                                                                                      "Posting Type" = FIELD("Posting Type Filter"),
                                                                                      "Posting Group" = FIELD("Posting Group Filter"),
                                                                                      "Directory Code" = FIELD("Directory Code Filter"),
                                                                                      "Period Code" = FIELD("Payroll Period Filter"),
                                                                                      "Wage Period Code" = FIELD("Wage Period Filter"),
                                                                                      "Posting Date" = FIELD("Date Filter")));
            Caption = 'Payroll Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17401; "Taxable Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Detailed Payroll Ledger Entry"."Taxable Amount" WHERE("Employee No." = FIELD("Employee No. Filter"),
                                                                                      "Element Type" = FIELD("Element Type Filter"),
                                                                                      "Element Group" = FIELD("Element Group Filter"),
                                                                                      "Element Code" = FIELD("Element Code Filter"),
                                                                                      "Posting Type" = FIELD("Posting Type Filter"),
                                                                                      "Posting Group" = FIELD("Posting Group Filter"),
                                                                                      "Directory Code" = FIELD("Directory Code Filter"),
                                                                                      "Period Code" = FIELD("Payroll Period Filter"),
                                                                                      "Wage Period Code" = FIELD("Wage Period Filter"),
                                                                                      "Posting Date" = FIELD("Date Filter")));
            Caption = 'Taxable Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17402; "Base Amount"; Decimal)
        {
            CalcFormula = Sum ("Payroll Ledger Base Amount".Amount WHERE("Employee No." = FIELD("Employee No. Filter"),
                                                                         "Base Type" = FIELD("Base Type Filter"),
                                                                         "Detailed Base Type" = FIELD("Detailed Base Type Filter"),
                                                                         "Element Type" = FIELD("Element Type Filter"),
                                                                         "Element Code" = FIELD("Element Code Filter"),
                                                                         "Payroll Directory Code" = FIELD("Directory Code Filter"),
                                                                         "Period Code" = FIELD("Payroll Period Filter"),
                                                                         "Posting Date" = FIELD("Date Filter")));
            Caption = 'Base Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17403; Counter; Integer)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Count ("Detailed Payroll Ledger Entry" WHERE("Employee No." = FIELD("Employee No. Filter"),
                                                                       "Element Type" = FIELD("Element Type Filter"),
                                                                       "Element Group" = FIELD("Element Group Filter"),
                                                                       "Element Code" = FIELD("Element Code Filter"),
                                                                       "Posting Type" = FIELD("Posting Type Filter"),
                                                                       "Posting Group" = FIELD("Posting Group Filter"),
                                                                       "Directory Code" = FIELD("Directory Code Filter"),
                                                                       "Period Code" = FIELD("Payroll Period Filter"),
                                                                       "Wage Period Code" = FIELD("Wage Period Filter"),
                                                                       "Posting Date" = FIELD("Date Filter")));
            Caption = 'Counter';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17410; "Planned Hours"; Decimal)
        {
            CalcFormula = Sum ("Timesheet Line"."Planned Hours" WHERE("Employee No." = FIELD("No."),
                                                                      "Org. Unit Code" = FIELD("Org. Unit Filter"),
                                                                      Date = FIELD("Date Filter")));
            Caption = 'Planned Hours';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17411; "Actual Hours"; Decimal)
        {
            CalcFormula = Sum ("Timesheet Detail"."Actual Hours" WHERE("Employee No." = FIELD("Employee No. Filter"),
                                                                       "Org. Unit Code" = FIELD("Org. Unit Filter"),
                                                                       "Timesheet Code" = FIELD("Timesheet Code Filter"),
                                                                       "Time Activity Code" = FIELD("Time Activity Filter"),
                                                                       Date = FIELD("Date Filter")));
            Caption = 'Actual Hours';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17412; "Overtime Hours"; Decimal)
        {
            CalcFormula = Sum ("Timesheet Detail"."Actual Hours" WHERE("Employee No." = FIELD("Employee No. Filter"),
                                                                       "Org. Unit Code" = FIELD("Org. Unit Filter"),
                                                                       "Timesheet Code" = FIELD("Timesheet Code Filter"),
                                                                       "Time Activity Code" = FIELD("Time Activity Filter"),
                                                                       Date = FIELD("Date Filter"),
                                                                       Overtime = CONST(true)));
            Caption = 'Overtime Hours';
            FieldClass = FlowField;
        }
        field(17413; "Accrued Absence"; Decimal)
        {
            CalcFormula = Sum ("Employee Absence Entry"."Calendar Days" WHERE("Entry Type" = CONST(Usage),
                                                                              "Employee No." = FIELD("No."),
                                                                              "Time Activity Code" = FIELD("Time Activity Filter"),
                                                                              "Start Date" = FIELD("Date Filter")));
            Caption = 'Accrued Absence';
            FieldClass = FlowField;
        }
        field(17414; "Used Absence"; Decimal)
        {
            CalcFormula = Sum ("Employee Absence Entry"."Calendar Days" WHERE("Entry Type" = CONST(Accrual),
                                                                              "Employee No." = FIELD("No."),
                                                                              "Time Activity Code" = FIELD("Time Activity Filter"),
                                                                              "Start Date" = FIELD("Date Filter")));
            Caption = 'Used Absence';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17420; "Element Type Filter"; Option)
        {
            Caption = 'Element Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,Funds,Reporting';
            OptionMembers = Wage,Bonus,"Income Tax","Netto Salary","Tax Deduction",Deduction,Other,Funds,Reporting;
        }
        field(17421; "Element Code Filter"; Code[20])
        {
            Caption = 'Element Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Payroll Element";
        }
        field(17423; "Posting Type Filter"; Option)
        {
            Caption = 'Posting Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Not Post,Charge,Liability,Liability Charge,Information Only';
            OptionMembers = "Not Post",Charge,Liability,"Liability Charge","Information Only";
        }
        field(17424; "Posting Group Filter"; Code[20])
        {
            Caption = 'Posting Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Payroll Posting Group";
        }
        field(17425; "Fund Type Filter"; Option)
        {
            Caption = 'Fund Type Filter';
            OptionCaption = ' ,FSI,FSI Injury,Federal FMI,Territorial FMI,PF Accum. Part,PF Insur. Part';
            OptionMembers = " ",FSI,"FSI Injury","Federal FMI","Territorial FMI","PF Accum. Part","PF Insur. Part";
        }
        field(17427; "Directory Code Filter"; Code[10])
        {
            Caption = 'Directory Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Payroll Directory".Code;
        }
        field(17428; "Base Type Filter"; Option)
        {
            Caption = 'Base Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Income Tax,Social Insurance Fund,Medical Insurance Fund,Employment Fund,Pension Fund,Injury Insurance,Sick Leave Payment,Average Earnings';
            OptionMembers = "Income Tax","Social Insurance Fund","Medical Insurance Fund","Employment Fund","Pension Fund","Injury Insurance","Sick Leave Payment","Average Earnings";
        }
        field(17429; "Detailed Base Type Filter"; Option)
        {
            Caption = 'Detailed Base Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Salary,Bonus,Quarter Bonus,Year Bonus';
            OptionMembers = " ",Salary,Bonus,"Quarter Bonus","Year Bonus";
        }
        field(17430; "Source Pay Filter"; Option)
        {
            Caption = 'Source Pay Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Cost,Profit,FSI,FOSI';
            OptionMembers = " ",Cost,Profit,FSI,FOSI;
        }
        field(17431; "Org. Unit Filter"; Code[10])
        {
            Caption = 'Org. Unit Filter';
            FieldClass = FlowFilter;
            TableRelation = "Organizational Unit";
        }
        field(17432; "Payroll Period Filter"; Code[10])
        {
            Caption = 'Payroll Period Filter';
            FieldClass = FlowFilter;
            TableRelation = "Payroll Period";
        }
        field(17433; "Timesheet Code Filter"; Code[10])
        {
            Caption = 'Timesheet Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Timesheet Code";
        }
        field(17434; "Wage Period Filter"; Code[10])
        {
            Caption = 'Wage Period Filter';
            FieldClass = FlowFilter;
            TableRelation = "Payroll Period";
        }
        field(17435; "Org. Unit Name"; Text[50])
        {
            Caption = 'Org. Unit Name';
            Editable = false;
        }
        field(17438; "Element Group Filter"; Code[20])
        {
            Caption = 'Element Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Payroll Element Group";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; Status, "Union Code")
        {
        }
        key(Key4; Status, "Emplymt. Contract Code")
        {
        }
        key(Key5; "Last Name", "First Name", "Middle Name")
        {
        }
        key(Key6; "Employee Bank Code")
        {
        }
        key(Key7; "Calendar Code")
        {
        }
        key(Key8; "Posting Group")
        {
        }
        key(Key9; "Org. Unit Code", "Job Title Code", Status)
        {
        }
        key(Key10; "Org. Unit Code", "Last Name", "First Name", "Middle Name")
        {
        }
        key(Key11; "Birth Date", Gender, "Last Name", "No.")
        {
        }
        key(Key12; "Last Name", "First Name", "Middle Name", "Birth Date")
        {
        }
        key(Key13; "Statistics Group Code")
        {
        }
        key(Key14; "Person No.")
        {
        }
        key(Key15; "Position No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "First Name", "Last Name", Initials, "Job Title")
        {
        }
        fieldgroup(Brick; "Last Name", "First Name", "Job Title", Image)
        {
        }
    }

    trigger OnDelete()
    begin
        CheckRemoveLaborContract;

        AlternativeAddr.SetRange("Person No.", "Person No.");
        AlternativeAddr.DeleteAll();

        EmployeeQualification.SetRange("Person No.", "Person No.");
        EmployeeQualification.DeleteAll();

        Relative.SetRange("Person No.", "Person No.");
        Relative.DeleteAll();

        EmployeeAbsence.SetRange("Employee No.", "No.");
        EmployeeAbsence.DeleteAll();

        MiscArticleInformation.SetRange("Employee No.", "No.");
        MiscArticleInformation.DeleteAll();

        ConfidentialInformation.SetRange("Employee No.", "No.");
        ConfidentialInformation.DeleteAll();

        HumanResComment.SetRange("No.", "No.");
        HumanResComment.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::Employee, "No.");
    end;

    trigger OnInsert()
    var
        ResourcesSetup: Record "Resources Setup";
        Resource: Record Resource;
    begin
        "Last Modified Date Time" := CurrentDateTime;
        HumanResSetup.Get();
        if "No." = '' then begin
            HumanResSetup.TestField("Employee Nos.");
            NoSeriesMgt.InitSeries(HumanResSetup."Employee Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;
        if HumanResSetup."Automatically Create Resource" then begin
            ResourcesSetup.Get();
            Resource.Init();
            if NoSeriesMgt.ManualNoAllowed(ResourcesSetup."Resource Nos.") then begin
                Resource."No." := "No.";
                Resource.Insert(true);
            end else
                Resource.Insert(true);
            "Resource No." := Resource."No.";
        end;

        DimMgt.UpdateDefaultDim(
          DATABASE::Employee, "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");

        HumanResSetup.Get();
        if "Country/Region Code" = '' then
            "Country/Region Code" := HumanResSetup."Country/Region Code";
        if "Tax Payer Category" = '' then
            "Tax Payer Category" := HumanResSetup."Tax Payer Category";
    end;

    trigger OnModify()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        "Last Date Modified" := Today;
        if Res.ReadPermission then
            EmployeeResUpdate.HumanResToRes(xRec, Rec);
        if SalespersonPurchaser.ReadPermission then
            EmployeeSalespersonUpdate.HumanResToSalesPerson(xRec, Rec);

        EmpVendUpdate.OnModify(Rec);
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::Employee, xRec."No.", "No.");
        "Last Modified Date Time" := CurrentDateTime;
        "Last Date Modified" := Today;
    end;

    var
        HumanResSetup: Record "Human Resources Setup";
        Res: Record Resource;
        PostCode: Record "Post Code";
        AlternativeAddr: Record "Alternative Address";
        EmployeeQualification: Record "Employee Qualification";
        Relative: Record "Employee Relative";
        EmployeeAbsence: Record "Employee Absence";
        MiscArticleInformation: Record "Misc. Article Information";
        ConfidentialInformation: Record "Confidential Information";
        HumanResComment: Record "Human Resource Comment Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        OrgUnit: Record "Organizational Unit";
        JobTitle: Record "Job Title";
        PayrollPeriod: Record "Payroll Period";
        PayrollStatus: Record "Payroll Status";
        Person: Record Person;
        Position: Record Position;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        EmployeeResUpdate: Codeunit "Employee/Resource Update";
        EmployeeSalespersonUpdate: Codeunit "Employee/Salesperson Update";
        DimMgt: Codeunit DimensionManagement;
        Text000: Label 'Before you can use Online Map, you must fill in the Online Map Setup window.\See Setting Up Online Map in Help.';
        BlockedEmplForJnrlErr: Label 'You cannot create this document because employee %1 is blocked due to privacy.', Comment = '%1 = employee no.';
        BlockedEmplForJnrlPostingErr: Label 'You cannot post this document because employee %1 is blocked due to privacy.', Comment = '%1 = employee no.';
        EmployeeLinkedToResourceErr: Label 'You cannot link multiple employees to the same resource. Employee %1 is already linked to that resource.', Comment = '%1 = employee no.';
        EmpVendUpdate: Codeunit "EmployeeVendor-Update";
        Text003: Label '%1 format must be xxx-xxx-xxx xx.';
        Text005: Label 'Incorrect checksum for %1';
        Text006: Label 'There are %1 job entries for employee %2 as of %3.';
        TimesheetMgmt: Codeunit "Timesheet Management RU";
        ConfirmBlockedPrivacyBlockedQst: Label 'If you change the Blocked field, the Privacy Blocked field is changed to No. Do you want to continue?';
        CanNotChangeBlockedDueToPrivacyBlockedErr: Label 'The Blocked field cannot be changed because the user is blocked for privacy reasons.';

    procedure AssistEdit(): Boolean
    begin
        HumanResSetup.Get();
        HumanResSetup.TestField("Employee Nos.");
        if NoSeriesMgt.SelectSeries(HumanResSetup."Employee Nos.", xRec."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    procedure FullName(): Text[100]
    var
        NewFullName: Text[100];
        Handled: Boolean;
    begin
        OnBeforeGetFullName(Rec, NewFullName, Handled);
        if Handled then
            exit(NewFullName);

        if "Middle Name" = '' then
            exit("First Name" + ' ' + "Last Name");

        exit("First Name" + ' ' + "Middle Name" + ' ' + "Last Name");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Employee, "No.", FieldNumber, ShortcutDimCode);
            Modify;
        end;
	
        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure DisplayMap()
    var
        MapPoint: Record "Online Map Setup";
        MapMgt: Codeunit "Online Map Management";
    begin
        if MapPoint.FindFirst then
            MapMgt.MakeSelection(DATABASE::Employee, GetPosition)
        else
            Message(Text000);
    end;

    [Scope('OnPrem')]
    procedure GetFullName(): Text[100]
    begin
        exit("Last Name" + ' ' + "First Name" + ' ' + "Middle Name");
    end;

    [Scope('OnPrem')]
    procedure GetFullNameOnDate(CurrDate: Date): Text[100]
    begin
        TestField("Person No.");
        Person.Get("Person No.");
        exit(Person.GetFullNameOnDate(CurrDate));
    end;

    [Scope('OnPrem')]
    procedure GetNameInitials(): Text[100]
    begin
        exit("Last Name" + ' ' + Initials);
    end;

    [Scope('OnPrem')]
    procedure GetNameInitialsOnDate(CurrDate: Date): Text[100]
    begin
        TestField("Person No.");
        Person.Get("Person No.");
        exit(Person.GetNameInitialsOnDate(CurrDate));
    end;

    [Scope('OnPrem')]
    procedure GetDepartmentName(): Text[50]
    begin
        exit("Org. Unit Name");
    end;

    [Scope('OnPrem')]
    procedure GetJobTitleName(): Text[50]
    begin
        exit("Job Title");
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
    procedure GetJobEntry(EmployeeNo: Code[20]; CurrDate: Date; var EmplJobEntry: Record "Employee Job Entry"): Boolean
    begin
        EmplJobEntry.Reset();
        EmplJobEntry.SetCurrentKey("Employee No.", "Starting Date", "Ending Date");
        EmplJobEntry.SetRange("Employee No.", EmployeeNo);
        EmplJobEntry.SetFilter("Starting Date", '..%1', CurrDate);
        EmplJobEntry.SetFilter("Ending Date", '%1|%2..', 0D, CurrDate);
        EmplJobEntry.SetRange("Position Changed", true);
        case EmplJobEntry.Count of
            0:
                exit(false);
            1:
                begin
                    EmplJobEntry.FindFirst;
                    exit(true);
                end;
            2:
                begin
                    EmplJobEntry.FindFirst;
                    exit(true);
                end;
            else
                Error(Text006, EmplJobEntry.Count, "No.", CurrDate);
        end;
    end;

    [Scope('OnPrem')]
    procedure IsEmployed(CurrentDate: Date): Boolean
    begin
        if ("Employment Date" <> 0D) and ("Employment Date" <= CurrentDate) and
           (("Termination Date" = 0D) or ("Termination Date" > CurrentDate))
        then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure IsTerminated(CurrentDate: Date): Boolean
    begin
        if "Termination Date" = 0D then
            exit(false);

        exit("Termination Date" < CurrentDate);
    end;

    [Scope('OnPrem')]
    procedure IsInvalid(CurrentDate: Date): Boolean
    var
        PersonMedicalInfo: Record "Person Medical Info";
    begin
        PersonMedicalInfo.SetRange("Person No.", "Person No.");
        PersonMedicalInfo.SetRange(Type, PersonMedicalInfo.Type::Disability);
        PersonMedicalInfo.SetFilter("Starting Date", '..%1', CurrentDate);
        PersonMedicalInfo.SetFilter("Ending Date", '%1|%2..', 0D, CurrentDate);
        PersonMedicalInfo.SetFilter("Disability Group", '<>%1', 0);
        exit(not PersonMedicalInfo.IsEmpty);
    end;

    local procedure CheckRemoveLaborContract()
    var
        LaborContract: Record "Labor Contract";
    begin
        if "Contract No." = '' then
            exit;

        if not LaborContract.Get("Contract No.") then
            exit;

        LaborContract.Delete(true);
    end;

    procedure CheckBlockedEmployeeOnJnls(IsPosting: Boolean)
    begin
        if IsOnBeforeCheckBlockedEmployeeHandled(IsPosting) then
            exit;
        if "Privacy Blocked" then begin
            if IsPosting then
                Error(BlockedEmplForJnrlPostingErr, "No.");
            Error(BlockedEmplForJnrlErr, "No.")
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFullName(Employee: Record Employee; var NewFullName: Text[100]; var Handled: Boolean)
    begin
    end;

    local procedure CheckIfAnEmployeeIsLinkedToTheResource(ResourceNo: Code[20])
    var
        Employee: Record Employee;
    begin
        Employee.SetFilter("No.", '<>%1', "No.");
        Employee.SetRange("Resource No.", ResourceNo);
        if Employee.FindFirst then
            Error(EmployeeLinkedToResourceErr, Employee."No.");
    end;

    local procedure IsOnBeforeCheckBlockedEmployeeHandled(IsPosting: Boolean) IsHandled: Boolean
    begin
        OnBeforeCheckBlockedEmployee(Rec, IsPosting, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var Employee: Record Employee; var xEmployee: Record Employee; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var Employee: Record Employee; var xEmployee: Record Employee; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlockedEmployee(Employee: Record Employee; IsPosting: Boolean; var IsHandled: Boolean)
    begin
    end;
}

