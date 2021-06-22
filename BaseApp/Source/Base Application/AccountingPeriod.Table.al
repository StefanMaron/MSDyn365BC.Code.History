table 50 "Accounting Period"
{
    Caption = 'Accounting Period';
    LookupPageID = "Accounting Periods";

    fields
    {
        field(1; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                Name := Format("Starting Date", 0, Text000);
            end;
        }
        field(2; Name; Text[10])
        {
            Caption = 'Name';
        }
        field(3; "New Fiscal Year"; Boolean)
        {
            Caption = 'New Fiscal Year';

            trigger OnValidate()
            begin
                TestField("Date Locked", false);
                if "New Fiscal Year" then begin
                    if not InvtSetup.Get then
                        exit;
                    "Average Cost Calc. Type" := InvtSetup."Average Cost Calc. Type";
                    "Average Cost Period" := InvtSetup."Average Cost Period";
                end else begin
                    "Average Cost Calc. Type" := "Average Cost Calc. Type"::" ";
                    "Average Cost Period" := "Average Cost Period"::" ";
                end;
            end;
        }
        field(4; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
        field(5; "Date Locked"; Boolean)
        {
            Caption = 'Date Locked';
            Editable = false;
        }
        field(5804; "Average Cost Calc. Type"; Option)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Average Cost Calc. Type';
            Editable = false;
            OptionCaption = ' ,Item,Item & Location & Variant';
            OptionMembers = " ",Item,"Item & Location & Variant";
        }
        field(5805; "Average Cost Period"; Option)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Average Cost Period';
            Editable = false;
            OptionCaption = ' ,Day,Week,Month,Quarter,Year,Accounting Period';
            OptionMembers = " ",Day,Week,Month,Quarter,Year,"Accounting Period";
        }
    }

    keys
    {
        key(Key1; "Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "New Fiscal Year", "Date Locked")
        {
        }
        key(Key3; Closed)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Starting Date", Name, "New Fiscal Year", Closed)
        {
        }
    }

    trigger OnDelete()
    begin
        TestField("Date Locked", false);
    end;

    trigger OnInsert()
    begin
        AccountingPeriod2 := Rec;
        if AccountingPeriod2.Find('>') then
            AccountingPeriod2.TestField("Date Locked", false);
    end;

    trigger OnRename()
    begin
        TestField("Date Locked", false);
        AccountingPeriod2 := Rec;
        if AccountingPeriod2.Find('>') then
            AccountingPeriod2.TestField("Date Locked", false);
    end;

    var
        Text000: Label '<Month Text,10>', Locked = true;
        AccountingPeriod2: Record "Accounting Period";
        InvtSetup: Record "Inventory Setup";

    procedure UpdateAvgItems()
    var
        ChangeAvgCostSetting: Codeunit "Change Average Cost Setting";
    begin
        ChangeAvgCostSetting.UpdateAvgCostFromAccPeriodChg(Rec);
    end;

    procedure GetFiscalYearEndDate(ReferenceDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty then
            exit(CalcDate('<CY>', ReferenceDate));

        with AccountingPeriod do begin
            SetRange("New Fiscal Year", true);
            SetRange("Starting Date", 0D, ReferenceDate);
            if FindLast then
                SetRange("Starting Date");
            if Find('>') then
                exit("Starting Date" - 1);
        end;
    end;

    procedure GetFiscalYearStartDate(ReferenceDate: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.IsEmpty then
            exit(CalcDate('<-CY>', ReferenceDate));

        with AccountingPeriod do begin
            SetRange("New Fiscal Year", true);
            SetRange("Starting Date", 0D, ReferenceDate);
            if FindLast then
                exit("Starting Date")
        end;
    end;
}

