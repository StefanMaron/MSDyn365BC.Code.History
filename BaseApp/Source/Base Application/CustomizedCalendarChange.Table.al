table 7602 "Customized Calendar Change"
{
    Caption = 'Customized Calendar Change';

    fields
    {
        field(1; "Source Type"; Enum "Calendar Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(2; "Source Code"; Code[20])
        {
            Caption = 'Source Code';
            Editable = false;
        }
        field(3; "Additional Source Code"; Code[20])
        {
            Caption = 'Additional Source Code';
        }
        field(4; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            Editable = false;
            TableRelation = "Base Calendar";
        }
        field(5; "Recurring System"; Option)
        {
            Caption = 'Recurring System';
            OptionCaption = ' ,Annual Recurring,Weekly Recurring';
            OptionMembers = " ","Annual Recurring","Weekly Recurring";

            trigger OnValidate()
            begin
                if "Recurring System" <> xRec."Recurring System" then
                    case "Recurring System" of
                        "Recurring System"::"Annual Recurring":
                            Day := Day::" ";
                        "Recurring System"::"Weekly Recurring":
                            Date := 0D;
                    end;
            end;
        }
        field(6; Date; Date)
        {
            Caption = 'Date';

            trigger OnValidate()
            begin
                if ("Recurring System" = "Recurring System"::" ") or
                   ("Recurring System" = "Recurring System"::"Annual Recurring")
                then
                    TestField(Date)
                else
                    TestField(Date, 0D);
                UpdateDayName;
            end;
        }
        field(7; Day; Option)
        {
            Caption = 'Day';
            OptionCaption = ' ,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
            OptionMembers = " ",Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;

            trigger OnValidate()
            begin
                if "Recurring System" = "Recurring System"::"Weekly Recurring" then
                    TestField(Day);
                UpdateDayName;
            end;
        }
        field(8; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(9; Nonworking; Boolean)
        {
            Caption = 'Nonworking';
            InitValue = true;
        }
        field(10; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
    }

    keys
    {
        key(Key1; "Source Type", "Source Code", "Additional Source Code", "Base Calendar Code", "Recurring System", Date, Day, "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Entry No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Source Type", "Source Code", "Additional Source Code")
        {
        }
    }

    trigger OnInsert()
    begin
        CheckEntryLine;
    end;

    trigger OnModify()
    begin
        CheckEntryLine;
    end;

    trigger OnRename()
    begin
        CheckEntryLine;
    end;

    procedure GetCaption(): Text[250]
    var
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
    begin
        CustomizedCalendarEntry.CopyFromCustomizedCalendarChange(Rec);
        exit(CustomizedCalendarEntry.GetCaption());
    end;

    local procedure UpdateDayName()
    var
        DateTable: Record Date;
    begin
        if (Date > 0D) and
           ("Recurring System" = "Recurring System"::"Annual Recurring")
        then
            Day := Day::" "
        else begin
            DateTable.SetRange("Period Type", DateTable."Period Type"::Date);
            DateTable.SetRange("Period Start", Date);
            if DateTable.FindFirst then
                Day := DateTable."Period No.";
        end;
        if (Date = 0D) and (Day = Day::" ") then begin
            Day := xRec.Day;
            Date := xRec.Date;
        end;
        if "Recurring System" = "Recurring System"::"Annual Recurring" then
            TestField(Day, Day::" ");
    end;

    local procedure CheckEntryLine()
    begin
        case "Recurring System" of
            "Recurring System"::" ":
                begin
                    TestField(Date);
                    TestField(Day);
                end;
            "Recurring System"::"Annual Recurring":
                begin
                    TestField(Date);
                    TestField(Day, Day::" ");
                end;
            "Recurring System"::"Weekly Recurring":
                begin
                    TestField(Date, 0D);
                    TestField(Day);
                end;
        end;
    end;

    procedure IsEqualSource(CustCalChange: Record "Customized Calendar Change"): Boolean;
    begin
        exit(
            ("Source Type" = CustCalChange."Source Type") and
            ("Source Code" = CustCalChange."Source Code") and
            ("Additional Source Code" = CustCalChange."Additional Source Code") and
            ("Base Calendar Code" = CustCalChange."Base Calendar Code"));
    end;

    procedure IsBlankSource(): Boolean;
    begin
        exit(("Source Type" = 0) and ("Source Code" = '') and ("Additional Source Code" = '') and ("Base Calendar Code" = ''));
    end;

    procedure SetSource(SourceType: Option; SourceCode: Code[20]; AdditionalSourceCode: code[20]; BaseCalendarCode: code[10])
    begin
        Clear(Rec);
        "Source Type" := SourceType;
        "Source Code" := SourceCode;
        "Additional Source Code" := AdditionalSourceCode;
        "Base Calendar Code" := BaseCalendarCode;
    end;

    procedure AdjustSourceType()
    begin
        case "Source Type" of
            "Source Type"::"Shipping Agent":
                if ("Source Code" = '') or ("Additional Source Code" = '') then begin
                    "Source Type" := "Source Type"::Company;
                    "Source Code" := '';
                    "Additional Source Code" := '';
                end;
            "Source Type"::Location:
                if "Source Code" = '' then begin
                    "Source Type" := "Source Type"::Company;
                    "Additional Source Code" := '';
                end;
        end;
    end;

    procedure CalcCalendarCode()
    var
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Location: Record Location;
        ShippingAgentService: Record "Shipping Agent Services";
        ServMgtSetup: Record "Service Mgt. Setup";
    begin
        case "Source Type" of
            "Source Type"::Company:
                if CompanyInfo.Get then
                    "Base Calendar Code" := CompanyInfo."Base Calendar Code";
            "Source Type"::Customer:
                if Customer.Get("Source Code") then
                    "Base Calendar Code" := Customer."Base Calendar Code";
            "Source Type"::Vendor:
                if Vendor.Get("Source Code") then
                    "Base Calendar Code" := Vendor."Base Calendar Code";
            "Source Type"::"Shipping Agent":
                begin
                    if ShippingAgentService.Get("Source Code", "Additional Source Code") then
                        "Base Calendar Code" := ShippingAgentService."Base Calendar Code"
                    else
                        if CompanyInfo.Get then
                            "Base Calendar Code" := CompanyInfo."Base Calendar Code";
                end;
            "Source Type"::Location:
                begin
                    if Location.Get("Source Code") then begin
                        if Location."Base Calendar Code" <> '' then
                            "Base Calendar Code" := Location."Base Calendar Code";
                    end else
                        if CompanyInfo.Get then
                            "Base Calendar Code" := CompanyInfo."Base Calendar Code";
                end;
            "Source Type"::Service:
                if ServMgtSetup.Get then
                    "Base Calendar Code" := ServMgtSetup."Base Calendar Code";
        end;
    end;

    procedure IsDateCustomized(TargetDate: date): Boolean
    begin
        case "Recurring System" of
            "Recurring System"::" ":
                exit(TargetDate = Date);
            "Recurring System"::"Weekly Recurring":
                exit(Date2DWY(TargetDate, 1) = Day);
            "Recurring System"::"Annual Recurring":
                exit((Date2DMY(TargetDate, 2) = Date2DMY(Date, 2)) and (Date2DMY(TargetDate, 1) = Date2DMY(Date, 1)));
        end;
    end;
}

