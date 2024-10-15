table 5218 "Human Resources Setup"
{
    Caption = 'Human Resources Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Employee Nos."; Code[20])
        {
            Caption = 'Employee Nos.';
            TableRelation = "No. Series";
        }
        field(3; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Human Resource Unit of Measure";

            trigger OnValidate()
            var
                EmployeeAbsence: Record "Employee Absence";
                HumanResUnitOfMeasure: Record "Human Resource Unit of Measure";
            begin
                if "Base Unit of Measure" <> xRec."Base Unit of Measure" then begin
                    if not EmployeeAbsence.IsEmpty then
                        Error(Text001, FieldCaption("Base Unit of Measure"), EmployeeAbsence.TableCaption);
                end;

                HumanResUnitOfMeasure.Get("Base Unit of Measure");
                HumanResUnitOfMeasure.TestField("Qty. per Unit of Measure", 1);
            end;
        }
        field(4; "Automatically Create Resource"; Boolean)
        {
            Caption = 'Automatically Create Resource';
            DataClassification = SystemMetadata;
        }
        field(17340; "PF BASE Element Code"; Code[20])
        {
            Caption = 'PF BASE Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17341; "PF OVER Limit Element Code"; Code[20])
        {
            Caption = 'PF OVER Limit Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17342; "PF INS Limit Element Code"; Code[50])
        {
            Caption = 'PF INS Limit Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(17343; "PF SPECIAL 1 Element Code"; Code[20])
        {
            Caption = 'PF SPECIAL 1 Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17344; "PF SPECIAL 2 Element Code"; Code[20])
        {
            Caption = 'PF SPECIAL 2 Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17345; "PF MI NO TAX Element Code"; Code[20])
        {
            Caption = 'PF MI NO TAX Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17346; "TAX FED FMI Element Code"; Code[50])
        {
            Caption = 'TAX FED FMI Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Funds));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(17350; "Position Nos."; Code[20])
        {
            Caption = 'Position Nos.';
            TableRelation = "No. Series";
        }
        field(17351; "Person Nos."; Code[20])
        {
            Caption = 'Person Nos.';
            TableRelation = "No. Series";
        }
        field(17352; "Budgeted Position Nos."; Code[20])
        {
            Caption = 'Budgeted Position Nos.';
            TableRelation = "No. Series";
        }
        field(17353; "Vacation Request Nos."; Code[20])
        {
            Caption = 'Vacation Request Nos.';
            TableRelation = "No. Series";
        }
        field(17354; "Vacation Order Nos."; Code[20])
        {
            Caption = 'Vacation Order Nos.';
            TableRelation = "No. Series";
        }
        field(17355; "Sick Leave Order Nos."; Code[20])
        {
            Caption = 'Sick Leave Order Nos.';
            TableRelation = "No. Series";
        }
        field(17356; "Travel Order Nos."; Code[20])
        {
            Caption = 'Travel Order Nos.';
            TableRelation = "No. Series";
        }
        field(17357; "HR Order Nos."; Code[20])
        {
            Caption = 'HR Order Nos.';
            TableRelation = "No. Series";
        }
        field(17358; "Labor Contract Nos."; Code[20])
        {
            Caption = 'Labor Contract Nos.';
            TableRelation = "No. Series";
        }
        field(17359; "Other Absence Order Nos."; Code[20])
        {
            Caption = 'Other Absence Order Nos.';
            TableRelation = "No. Series";
        }
        field(17360; "Vacation Schedule Nos."; Code[20])
        {
            Caption = 'Vacation Schedule Nos.';
            TableRelation = "No. Series";
        }
        field(17361; "Depositor Card Nos."; Code[20])
        {
            Caption = 'Depositor Card Nos.';
            TableRelation = "No. Series";
        }
        field(17363; "Paysheet Nos."; Code[20])
        {
            Caption = 'Paysheet Nos.';
            TableRelation = "No. Series";
        }
        field(17364; "Calculation Sheet Nos."; Code[20])
        {
            Caption = 'Calculation Sheet Nos.';
            TableRelation = "No. Series";
        }
        field(17365; "Personal Information Nos."; Code[20])
        {
            Caption = 'Personal Information Nos.';
            TableRelation = "No. Series";
        }
        field(17366; "Tax Card Nos."; Code[20])
        {
            Caption = 'Tax Card Nos.';
            TableRelation = "No. Series";
        }
        field(17367; "Group Hire Order Nos."; Code[20])
        {
            Caption = 'Group Hire Order Nos.';
            TableRelation = "No. Series";
        }
        field(17368; "Group Transfer Order Nos."; Code[20])
        {
            Caption = 'Group Transfer Order Nos.';
            TableRelation = "No. Series";
        }
        field(17369; "Group Dismissal Order Nos."; Code[20])
        {
            Caption = 'Group Dismissal Order Nos.';
            TableRelation = "No. Series";
        }
        field(17370; "Staff List Change Nos."; Code[20])
        {
            Caption = 'Staff List Change Nos.';
            TableRelation = "No. Series";
        }
        field(17371; "Payroll Document Nos."; Code[20])
        {
            Caption = 'Payroll Document Nos.';
            TableRelation = "No. Series";
        }
        field(17372; "Posted Payroll Document Nos."; Code[20])
        {
            Caption = 'Posted Payroll Document Nos.';
            TableRelation = "No. Series";
        }
        field(17373; "Person Income Document Nos."; Code[20])
        {
            Caption = 'Person Income Document Nos.';
            TableRelation = "No. Series";
        }
        field(17374; "Payroll Vendor No."; Code[20])
        {
            Caption = 'Payroll Vendor No.';
            TableRelation = Vendor;
        }
        field(17376; "Income Tax 13%"; Code[20])
        {
            Caption = 'Income Tax 13%';
            TableRelation = "Payroll Element" WHERE(Type = CONST("Income Tax"));
        }
        field(17377; "Income Tax 30%"; Code[20])
        {
            Caption = 'Income Tax 30%';
            TableRelation = "Payroll Element" WHERE(Type = CONST("Income Tax"));
        }
        field(17378; "Income Tax 35%"; Code[20])
        {
            Caption = 'Income Tax 35%';
            TableRelation = "Payroll Element" WHERE(Type = CONST("Income Tax"));
        }
        field(17379; "Income Tax 9%"; Code[20])
        {
            Caption = 'Income Tax 9%';
            TableRelation = "Payroll Element" WHERE(Type = CONST("Income Tax"));
        }
        field(17380; "Official Calendar Code"; Code[10])
        {
            Caption = 'Official Calendar Code';
            TableRelation = "Payroll Calendar";
        }
        field(17381; "Default Calendar Code"; Code[10])
        {
            Caption = 'Default Calendar Code';
            TableRelation = "Payroll Calendar";
        }
        field(17382; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(17383; "Citizenship Country/Region"; Code[10])
        {
            Caption = 'Citizenship Country/Region';
            TableRelation = "Country/Region";
        }
        field(17384; "Tax Payer Category"; Code[20])
        {
            Caption = 'Tax Payer Category';
            TableRelation = "General Directory".Code WHERE(Type = FILTER("Tax Payer Category"));
        }
        field(17385; "Tax Inspection Code"; Text[4])
        {
            Caption = 'Tax Inspection Code';
        }
        field(17386; "Default Night Hours Code"; Code[10])
        {
            Caption = 'Default Night Hours Code';
            TableRelation = "Time Activity";
        }
        field(17387; "Local Country/Region Code"; Code[10])
        {
            Caption = 'Local Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(17390; "Element Code Salary Days"; Code[20])
        {
            Caption = 'Element Code Salary Days';
            TableRelation = "Payroll Element";
        }
        field(17391; "Element Code Salary Hours"; Code[20])
        {
            Caption = 'Element Code Salary Hours';
            TableRelation = "Payroll Element";
        }
        field(17392; "Element Code Salary Amount"; Code[20])
        {
            Caption = 'Element Code Salary Amount';
            TableRelation = "Payroll Element";
        }
        field(17393; "Element Code Base Wage"; Code[20])
        {
            Caption = 'Element Code Base Wage';
        }
        field(17394; "Tax Allowance Code for Child"; Code[20])
        {
            Caption = 'Tax Allowance Code for Child';
            TableRelation = "Payroll Element";
        }
        field(17395; "Tax Allowance Code for Taxpay"; Code[20])
        {
            Caption = 'Tax Allowance Code for Taxpay';
            TableRelation = "Payroll Element";
        }
        field(17396; "Tax Allowance 2 Code for Child"; Code[20])
        {
            Caption = 'Tax Allowance 2 Code for Child';
            TableRelation = "Payroll Element";
        }
        field(17397; "Employee Address Type"; Option)
        {
            Caption = 'Employee Address Type';
            OptionCaption = 'Permanent,Registration,Other';
            OptionMembers = Permanent,Registration,Other;
        }
        field(17400; "NDFL-1 Template Code"; Code[10])
        {
            Caption = 'NDFL-1 Template Code';
            TableRelation = "Excel Template";
        }
        field(17401; "NDFL-2 Template Code"; Code[10])
        {
            Caption = 'NDFL-2 Template Code';
            TableRelation = "Excel Template";
        }
        field(17402; "FSN-1 Template Code"; Code[10])
        {
            Caption = 'FSN-1 Template Code';
            TableRelation = "Excel Template";
        }
        field(17403; "PF Report Template Code"; Code[10])
        {
            Caption = 'PF Report Template Code';
            TableRelation = "Excel Template";
        }
        field(17404; "Form 4-FSI Template Code"; Code[10])
        {
            Caption = 'Form 4-FSI Template Code';
            TableRelation = "Excel Template";
        }
        field(17405; "PF Pers. Card Template Code"; Code[10])
        {
            Caption = 'PF Pers. Card Template Code';
            TableRelation = "Excel Template";
        }
        field(17406; "PF Summ. Card Template Code"; Code[10])
        {
            Caption = 'PF Summ. Card Template Code';
            TableRelation = "Excel Template";
        }
        field(17407; "Report 1-T Template Code"; Code[10])
        {
            Caption = 'Report 1-T Template Code';
            TableRelation = "Excel Template";
        }
        field(17408; "P-4 Template Code"; Code[10])
        {
            Caption = 'P-4 Template Code';
            TableRelation = "Excel Template";
        }
        field(17409; "Avg. Headcount Template Code"; Code[10])
        {
            Caption = 'Avg. Headcount Template Code';
            TableRelation = "Excel Template";
        }
        field(17410; "T-1 Template Code"; Code[10])
        {
            Caption = 'T-1 Template Code';
            TableRelation = "Excel Template";
        }
        field(17411; "T-1a Template Code"; Code[10])
        {
            Caption = 'T-1a Template Code';
            TableRelation = "Excel Template";
        }
        field(17412; "T-2 Template Code"; Code[10])
        {
            Caption = 'T-2 Template Code';
            TableRelation = "Excel Template";
        }
        field(17413; "T-3 Template Code"; Code[10])
        {
            Caption = 'T-3 Template Code';
            TableRelation = "Excel Template";
        }
        field(17414; "T-5 Template Code"; Code[10])
        {
            Caption = 'T-5 Template Code';
            TableRelation = "Excel Template";
        }
        field(17415; "T-5a Template Code"; Code[10])
        {
            Caption = 'T-5a Template Code';
            TableRelation = "Excel Template";
        }
        field(17416; "T-7 Template Code"; Code[10])
        {
            Caption = 'T-7 Template Code';
            TableRelation = "Excel Template";
        }
        field(17417; "T-8 Template Code"; Code[10])
        {
            Caption = 'T-8 Template Code';
            TableRelation = "Excel Template";
        }
        field(17418; "T-8a Template Code"; Code[10])
        {
            Caption = 'T-8a Template Code';
            TableRelation = "Excel Template";
        }
        field(17419; "T-9 Template Code"; Code[10])
        {
            Caption = 'T-9 Template Code';
            TableRelation = "Excel Template";
        }
        field(17420; "T-9a Template Code"; Code[10])
        {
            Caption = 'T-9a Template Code';
            TableRelation = "Excel Template";
        }
        field(17421; "T-10 Template Code"; Code[10])
        {
            Caption = 'T-10 Template Code';
            TableRelation = "Excel Template";
        }
        field(17422; "T-10a Template Code"; Code[10])
        {
            Caption = 'T-10a Template Code';
            TableRelation = "Excel Template";
        }
        field(17423; "T-11 Template Code"; Code[10])
        {
            Caption = 'T-11 Template Code';
            TableRelation = "Excel Template";
        }
        field(17424; "T-11a Template Code"; Code[10])
        {
            Caption = 'T-11a Template Code';
            TableRelation = "Excel Template";
        }
        field(17425; "T-6 Template Code"; Code[10])
        {
            Caption = 'T-6 Template Code';
            TableRelation = "Excel Template";
        }
        field(17426; "T-6a Template Code"; Code[10])
        {
            Caption = 'T-6a Template Code';
            TableRelation = "Excel Template";
        }
        field(17427; "T-60 Template Code"; Code[10])
        {
            Caption = 'T-60 Template Code';
            TableRelation = "Excel Template";
        }
        field(17428; "T-61 Template Code"; Code[10])
        {
            Caption = 'T-61 Template Code';
            TableRelation = "Excel Template";
        }
        field(17429; "T-73 Template Code"; Code[10])
        {
            Caption = 'T-73 Template Code';
            TableRelation = "Excel Template";
        }
        field(17430; "T-12 Template Code"; Code[10])
        {
            Caption = 'T-12 Template Code';
            TableRelation = "Excel Template";
        }
        field(17431; "T-13 Template Code"; Code[10])
        {
            Caption = 'T-13 Template Code';
            TableRelation = "Excel Template";
        }
        field(17432; "T-51 Template Code"; Code[10])
        {
            Caption = 'T-51 Template Code';
            TableRelation = "Excel Template";
        }
        field(17433; "T-53 Template Code"; Code[10])
        {
            Caption = 'T-53 Template Code';
            TableRelation = "Excel Template";
        }
        field(17434; "T-54 Template Code"; Code[10])
        {
            Caption = 'T-54 Template Code';
            TableRelation = "Excel Template";
        }
        field(17435; "T-54a Template Code"; Code[10])
        {
            Caption = 'T-54a Template Code';
            TableRelation = "Excel Template";
        }
        field(17436; "T-3a Template Code"; Code[10])
        {
            Caption = 'T-3a Template Code';
            TableRelation = "Excel Template";
        }
        field(17437; "Salary Reference Template Code"; Code[10])
        {
            Caption = 'Salary Reference Template Code';
            TableRelation = "Excel Template";
        }
        field(17438; "NDFL Register Template Code"; Code[10])
        {
            Caption = 'NDFL Register Template Code';
            TableRelation = "Excel Template";
        }
        field(17439; "Advance Statement Templ. Code"; Code[10])
        {
            Caption = 'Advance Statement Templ. Code';
            TableRelation = "Excel Template";
        }
        field(17442; "RSV Template Code"; Code[10])
        {
            Caption = 'RSV Template Code';
            TableRelation = "Excel Template";
        }
        field(17443; "SZV-6-4 Template Code"; Code[10])
        {
            Caption = 'SZV-6-4 Template Code';
            TableRelation = "Excel Template";
        }
        field(17444; "SZV-6-3 Template Code"; Code[10])
        {
            Caption = 'SZV-6-3 Template Code';
            TableRelation = "Excel Template";
        }
        field(17445; "Sick Leave Abs. Template Code"; Code[10])
        {
            Caption = 'Sick Leave Abs. Template Code';
            TableRelation = "Excel Template";
        }
        field(17446; "ADV-1 Template Code"; Code[10])
        {
            Caption = 'ADV-1 Template Code';
            TableRelation = "Excel Template";
        }
        field(17447; "SPV-1 Template Code"; Code[10])
        {
            Caption = 'SPV-1 Template Code';
            TableRelation = "Excel Template";
        }
        field(17448; "SZV-6-1 Template Code"; Code[10])
        {
            Caption = 'SZV-6-1 Template Code';
            TableRelation = "Excel Template";
        }
        field(17449; "SZV-6-2 Template Code"; Code[10])
        {
            Caption = 'SZV-6-2 Template Code';
            TableRelation = "Excel Template";
        }
        field(17450; "Work Time Group Code"; Code[20])
        {
            Caption = 'Work Time Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17451; "Tariff Work Group Code"; Code[20])
        {
            Caption = 'Tariff Work Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17452; "Task Work Group Code"; Code[20])
        {
            Caption = 'Task Work Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17453; "Teenager Work Group Code"; Code[20])
        {
            Caption = 'Teenager Work Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17454; "Night Work Group Code"; Code[20])
        {
            Caption = 'Night Work Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17455; "Overtime 1.5 Group Code"; Code[20])
        {
            Caption = 'Overtime 1.5 Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17456; "Overtime 2.0 Group Code"; Code[20])
        {
            Caption = 'Overtime 2.0 Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17457; "Weekend Work Group"; Code[20])
        {
            Caption = 'Weekend Work Group';
            TableRelation = "Time Activity Group";
        }
        field(17458; "Holiday Work Group"; Code[20])
        {
            Caption = 'Holiday Work Group';
            TableRelation = "Time Activity Group";
        }
        field(17459; "Average Headcount Group Code"; Code[20])
        {
            Caption = 'Average Headcount Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17460; "Absence Group Code"; Code[20])
        {
            Caption = 'Absence Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17461; "Person Vendor No. Series"; Code[20])
        {
            Caption = 'Person Vendor No. Series';
            TableRelation = "No. Series";
        }
        field(17462; "Person Vendor Posting Group"; Code[20])
        {
            Caption = 'Person Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(17463; "Pers. Vend.Gen.Bus. Posting Gr"; Code[20])
        {
            Caption = 'Pers. Vend.Gen.Bus. Posting Gr';
            TableRelation = "Gen. Business Posting Group";
        }
        field(17464; "Pers. Vend.VAT Bus. Posting Gr"; Code[20])
        {
            Caption = 'Pers. Vend.VAT Bus. Posting Gr';
            TableRelation = "VAT Business Posting Group";
        }
        field(17465; "Default Timesheet Code"; Code[10])
        {
            Caption = 'Default Timesheet Code';
            TableRelation = "Time Activity";
        }
        field(17466; "Employee Card Address"; Option)
        {
            Caption = 'Employee Card Address';
            OptionCaption = 'Actual,Registration';
            OptionMembers = Actual,Registration;
        }
        field(17467; "Employee Address Format"; Option)
        {
            Caption = 'Employee Address Format';
            OptionCaption = '2-NDFL,Pension Fund';
            OptionMembers = "2-NDFL","Pension Fund";
        }
        field(17468; "Excl. Days Group Code"; Code[20])
        {
            Caption = 'Excl. Days Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17470; "Future Period Vacat. Post. Gr."; Code[20])
        {
            Caption = 'Future Period Vacat. Post. Gr.';
            TableRelation = "Payroll Posting Group";
        }
        field(17471; "FSN-1 Salary Element Code"; Code[20])
        {
            Caption = 'FSN-1 Salary Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17472; "FSN-1 Bonus Element Code"; Code[20])
        {
            Caption = 'FSN-1 Bonus Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17473; "FSN-1 Work Time Group Code"; Code[20])
        {
            Caption = 'FSN-1 Work Time Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17474; "T-13 Weekend Work Group code"; Code[20])
        {
            Caption = 'T-13 Weekend Work Group code';
            TableRelation = "Time Activity Group";
        }
        field(17475; "AE Calculation Function Code"; Text[30])
        {
            Caption = 'AE Calculation Function Code';
            TableRelation = "Payroll Calculation Function";
        }
        field(17477; "Wages Element Code"; Code[20])
        {
            Caption = 'Wages Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17478; "Income Tax Element Code"; Code[20])
        {
            Caption = 'Income Tax Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17479; "Tax Deductions Element Code"; Code[20])
        {
            Caption = 'Tax Deductions Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17480; "Deductions Element Code"; Code[20])
        {
            Caption = 'Deductions Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17481; "PF Accum. Part Element Code"; Code[20])
        {
            Caption = 'PF Accum. Part Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17482; "PF Insur. Part Element Code"; Code[20])
        {
            Caption = 'PF Insur. Part Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17483; "Territorial FMI Element Code"; Code[20])
        {
            Caption = 'Territorial FMI Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17484; "Federal FMI Element Code"; Code[20])
        {
            Caption = 'Federal FMI Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17485; "FSI Element Code"; Code[20])
        {
            Caption = 'FSI Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17486; "FSI Injury Element Code"; Code[20])
        {
            Caption = 'FSI Injury Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17487; "Amt. to Pay Rounding Precision"; Decimal)
        {
            Caption = 'Amt. to Pay Rounding Precision';
        }
        field(17488; "Amt. to Pay Rounding Type"; Option)
        {
            Caption = 'Amt. to Pay Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(17489; "Bonus Element Code"; Code[20])
        {
            Caption = 'Bonus Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17490; "Use Staff List Change Orders"; Boolean)
        {
            Caption = 'Use Staff List Change Orders';
        }
        field(17491; "Change Vacation Accr. By Doc"; Code[20])
        {
            Caption = 'Change Vacation Accr. By Doc';
            TableRelation = "Time Activity Group";
        }
        field(17492; "Change Vacation Accr. Periodic"; Code[20])
        {
            Caption = 'Change Vacation Accr. Periodic';
            TableRelation = "Time Activity Group";
        }
        field(17493; "Annual Vacation Group Code"; Code[20])
        {
            Caption = 'Annual Vacation Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17494; "P-4 Salary Element Code"; Code[20])
        {
            Caption = 'P-4 Salary Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17495; "P-4 Benefits Element Code"; Code[20])
        {
            Caption = 'P-4 Benefits Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Reporting));
        }
        field(17496; "P-4 Work Time Group Code"; Code[20])
        {
            Caption = 'P-4 Work Time Group Code';
            TableRelation = "Time Activity Group";
        }
        field(17497; "TAX PF INS Element Code"; Code[50])
        {
            Caption = 'TAX PF INS Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Funds));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(17498; "TAX PF SAV Element Code"; Code[20])
        {
            Caption = 'TAX PF SAV Element Code';
            TableRelation = "Payroll Element" WHERE(Type = CONST(Funds));
        }
        field(17499; "Employee Paysheet Templ. Code"; Code[10])
        {
            Caption = 'Employee Paysheet Templ. Code';
            TableRelation = "Excel Template";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'You cannot change %1 because there are %2.';
        PayrollElement: Record "Payroll Element";

    [Scope('OnPrem')]
    procedure AmtToPayRoundingDirection(): Text[1]
    begin
        case "Amt. to Pay Rounding Type" of
            "Amt. to Pay Rounding Type"::Nearest:
                exit('=');
            "Amt. to Pay Rounding Type"::Up:
                exit('>');
            "Amt. to Pay Rounding Type"::Down:
                exit('<');
        end;
    end;
}

