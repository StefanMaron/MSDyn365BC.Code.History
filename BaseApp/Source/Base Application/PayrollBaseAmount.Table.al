table 17409 "Payroll Base Amount"
{
    Caption = 'Payroll Base Amount';
    LookupPageID = "Payroll Base Amounts";

    fields
    {
        field(1; "Element Code"; Code[20])
        {
            Caption = 'Element Code';
            NotBlank = true;
            TableRelation = "Payroll Element";
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(4; "Period Code"; Code[10])
        {
            Caption = 'Period Code';
            TableRelation = "Payroll Period";
        }
        field(11; "Element Code Filter"; Text[250])
        {
            Caption = 'Element Code Filter';
            TableRelation = "Payroll Element";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                if "Element Code Filter" <> '' then begin
                    Change := GetChangeFilter;
                    if Change > 0 then
                        "Element Code Filter" := "Element Code Filter" + DelChr(CopyStr(SelectStr(Change, MenuText), 1, 2), '>')
                    else
                        exit;
                end;

                if "Element Group Filter" <> '' then
                    PayrollElement.SetFilter("Element Group", "Element Group Filter");
                if "Posting Type Filter" <> '' then
                    PayrollElement.SetFilter("Posting Type", "Posting Type Filter");

                if PAGE.RunModal(0, PayrollElement) = ACTION::LookupOK then
                    "Element Code Filter" := "Element Code Filter" + PayrollElement.Code;
            end;
        }
        field(12; "Element Type Filter"; Text[250])
        {
            Caption = 'Element Type Filter';

            trigger OnLookup()
            begin
                if "Element Type Filter" <> '' then begin
                    Change := GetChangeFilter;
                    if Change > 0 then
                        "Element Type Filter" := "Element Type Filter" + DelChr(CopyStr(SelectStr(Change, MenuText), 1, 2), '>')
                    else
                        exit;
                end;
                MenuText := Text000;
                Change := StrMenu(MenuText);
                if Change > 0 then
                    "Element Type Filter" := "Element Type Filter" + Format(Change - 1);
            end;
        }
        field(13; "Element Group Filter"; Text[250])
        {
            Caption = 'Element Group Filter';
            TableRelation = "Payroll Element Group";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                if "Element Group Filter" <> '' then begin
                    Change := GetChangeFilter;
                    if Change > 0 then
                        "Element Group Filter" := "Element Group Filter" + DelChr(CopyStr(SelectStr(Change, MenuText), 1, 2), '>')
                    else
                        exit;
                end;

                if "Posting Type Filter" <> '' then
                    PayrollElement.SetFilter("Posting Type", "Posting Type Filter");

                if PAGE.RunModal(0, PayrollElementGroup) = ACTION::LookupOK then
                    "Element Group Filter" := "Element Group Filter" + PayrollElementGroup.Code;
            end;
        }
        field(17; "Posting Type Filter"; Text[250])
        {
            Caption = 'Posting Type Filter';

            trigger OnLookup()
            begin
                if "Posting Type Filter" <> '' then begin
                    Change := GetChangeFilter;
                    if Change > 0 then
                        "Posting Type Filter" := "Posting Type Filter" + DelChr(CopyStr(SelectStr(Change, MenuText), 1, 2), '>')
                    else
                        exit;
                end;
                MenuText := Text002;
                Change := StrMenu(MenuText);
                if Change > 0 then
                    "Posting Type Filter" := "Posting Type Filter" + Format(Change - 1);
            end;
        }
        field(18; "Income Tax Base Filter"; Option)
        {
            Caption = 'Income Tax Base Filter';
            OptionCaption = ' ,Impose,Not Impose';
            OptionMembers = " ",Impose,"Not Impose";
        }
        field(19; "PF Base Filter"; Option)
        {
            Caption = 'PF Base Filter';
            OptionCaption = ' ,Impose,Not Impose';
            OptionMembers = " ",Impose,"Not Impose";
        }
        field(20; "FSI Base Filter"; Option)
        {
            Caption = 'FSI Base Filter';
            OptionCaption = ' ,Impose,Not Impose';
            OptionMembers = " ",Impose,"Not Impose";
        }
        field(22; "Federal FMI Base Filter"; Option)
        {
            Caption = 'Federal FMI Base Filter';
            OptionCaption = ' ,Impose,Not Impose';
            OptionMembers = " ",Impose,"Not Impose";
        }
        field(23; "Territorial FMI Base Filter"; Option)
        {
            Caption = 'Territorial FMI Base Filter';
            OptionCaption = ' ,Impose,Not Impose';
            OptionMembers = " ",Impose,"Not Impose";
        }
        field(24; "FSI Injury Base Filter"; Option)
        {
            Caption = 'FSI Injury Base Filter';
            OptionCaption = ' ,Impose,Not Impose';
            OptionMembers = " ",Impose,"Not Impose";
        }
    }

    keys
    {
        key(Key1; "Element Code", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label 'Wage,Bonus,Income Tax,Netto Salary,Tax Deduction,Deduction,Other,Funds,Reporting';
        Text002: Label 'Not Post,Charge,Liability,Liability Charge';
        Text003: Label '..,&& AND,| OR,>,<,<>';
        PayrollElement: Record "Payroll Element";
        PayrollElementGroup: Record "Payroll Element Group";
        MenuText: Text[250];
        Change: Integer;

    [Scope('OnPrem')]
    procedure GetChangeFilter(): Integer
    begin
        MenuText := Text003;
        exit(StrMenu(MenuText));
    end;
}

