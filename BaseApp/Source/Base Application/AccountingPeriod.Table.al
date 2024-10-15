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
                if not "New Fiscal Year" then
                    CheckPostingRangeInAccPeriod("Starting Date");

                if "New Fiscal Year" then begin
                    CheckOpenFiscalYears;
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
        field(10800; "Fiscally Closed"; Boolean)
        {
            Caption = 'Fiscally Closed';
            Editable = false;
        }
        field(10801; "Fiscal Closing Date"; Date)
        {
            Caption = 'Fiscal Closing Date';
            Editable = false;
        }
        field(10802; "Period Reopened Date"; Date)
        {
            Caption = 'Period Reopened Date';
            Editable = false;
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
        key(Key4; "New Fiscal Year", "Fiscally Closed")
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
        CheckPostingRangeInAccPeriod("Starting Date");
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
        Text10800: Label 'To delete the fiscal year from %1 to %2, you must first modify the fields %3 and %4 in the %5 and %6 so that they are outside the fiscal year that is being deleted.';
        GLSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        Text10801: Label 'It is not allowed to have more than two open fiscal years. Please fiscally close the oldest open fiscal year first.';
        Text10802: Label 'You will not be able to post transactions in a closed period. Are you sure you want to close the period with starting date %1?';
        Text10803: Label 'There are no open fiscal periods that can be closed.';
        Text10804: Label 'You cannot close the last period of a fiscal year. In order to close the last period of a fiscal year, you must fiscally close the fiscal year.';
        Text10805: Label 'The period you are trying to reopen belongs to a fiscal year that has been fiscally closed.\Once a fiscal year is fiscally closed, you cannot reopen any of the periods in that fiscal year.';
        Text10806: Label 'A closed fiscal period should normally not be reopened. Are you sure you want to reopen the fiscal period with starting date %1?';
        Text10807: Label 'There are no closed fiscal periods that can be reopened.';
        Text10809: Label 'You must create a new fiscal year before you can close this fiscal period.';
        EndingDate: Date;
        NoOfOpenFiscalYears: Integer;

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

    [Scope('OnPrem')]
    procedure CheckOpenFiscalYears()
    begin
        AccountingPeriod2.Reset();
        AccountingPeriod2.SetRange("New Fiscal Year", true);
        AccountingPeriod2.SetRange("Fiscally Closed", false);
        NoOfOpenFiscalYears := AccountingPeriod2.Count();
        if AccountingPeriod2.FindFirst then;

        // check last period of previous fiscal year
        AccountingPeriod2.SetRange("New Fiscal Year");
        AccountingPeriod2.SetRange("Fiscally Closed");
        if AccountingPeriod2.Find('<') then
            if not AccountingPeriod2."Fiscally Closed" then
                NoOfOpenFiscalYears := NoOfOpenFiscalYears + 1;
        if NoOfOpenFiscalYears > 2 then
            Error(Text10801);
    end;

    [Scope('OnPrem')]
    procedure CloseFiscalPeriod()
    begin
        AccountingPeriod2.Reset();
        AccountingPeriod2.SetRange("Fiscally Closed", false);
        if AccountingPeriod2.FindFirst then begin
            if not AccountingPeriod2.Find('>') then
                Error(Text10809);
            // check last period in fiscal year
            if AccountingPeriod2."New Fiscal Year" then
                Error(Text10804);
            EndingDate := CalcDate('<-1D>', AccountingPeriod2."Starting Date");
            AccountingPeriod2.Find('<');
            if Confirm(Text10802, true, AccountingPeriod2."Starting Date") then begin
                AccountingPeriod2."Fiscally Closed" := true;
                AccountingPeriod2."Fiscal Closing Date" := Today;
                AccountingPeriod2.Modify();
                // update allowed posting range
                UpdateGLSetup(EndingDate);
                UpdateUserSetup(EndingDate);
            end;
        end else
            Message(Text10803);
    end;

    [Scope('OnPrem')]
    procedure ReopenFiscalPeriod()
    var
        AccountingPeriod3: Record "Accounting Period";
    begin
        AccountingPeriod2.Reset();
        AccountingPeriod2.SetRange("Fiscally Closed", false);
        if AccountingPeriod2.FindFirst then
            if AccountingPeriod2."New Fiscal Year" then
                Error(Text10805);
        AccountingPeriod2.SetRange("Fiscally Closed", true);
        if AccountingPeriod2.FindLast then begin
            if not Confirm(Text10806, false, AccountingPeriod2."Starting Date") then
                exit;
            AccountingPeriod2."Fiscally Closed" := false;
            AccountingPeriod2."Period Reopened Date" := Today;
            AccountingPeriod2.Modify();
        end else
            Message(Text10807);
    end;

    [Scope('OnPrem')]
    procedure UpdateGLSetup(PeriodEndDate: Date)
    begin
        with GLSetup do begin
            Get;
            CalcFields("Posting Allowed From");
            if "Allow Posting From" <= PeriodEndDate then begin
                "Allow Posting From" := "Posting Allowed From";
                Modify;
            end;
            if ("Allow Posting To" <= PeriodEndDate) and ("Allow Posting To" <> 0D) then begin
                "Allow Posting To" := CalcDate('<+1M-1D>', "Posting Allowed From");
                Modify;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateUserSetup(PeriodEndDate: Date)
    begin
        with UserSetup do begin
            if FindFirst then
                repeat
                    if "Allow Posting From" <= PeriodEndDate then begin
                        "Allow Posting From" := GLSetup."Posting Allowed From";
                        Modify;
                    end;
                    if ("Allow Posting To" <= PeriodEndDate) and ("Allow Posting To" <> 0D) then begin
                        "Allow Posting To" := CalcDate('<+1M-1D>', GLSetup."Posting Allowed From");
                        Modify;
                    end;
                until Next = 0;
        end
    end;

    [Scope('OnPrem')]
    procedure CheckPostingRangeSetup(FYEndDate: Date): Boolean
    begin
        with GLSetup do begin
            Get;
            if ("Allow Posting From" > FYEndDate) or ("Allow Posting To" > FYEndDate) then
                exit(true);
        end;

        with UserSetup do
            if FindFirst then
                repeat
                    if ("Allow Posting From" > FYEndDate) or ("Allow Posting To" > FYEndDate) then
                        exit(true);
                until Next = 0;

        exit(false);
    end;

    local procedure CheckPostingRangeInAccPeriod(ExcludePeriod: Date)
    var
        OldPostingAllowedTo: Date;
        NewPostingAllowedTo: Date;
    begin
        GLSetup.CalcFields("Posting Allowed To");
        if GLSetup."Posting Allowed To" <> 0D then
            OldPostingAllowedTo := CalcDate('<-1D>', GLSetup."Posting Allowed To");

        NewPostingAllowedTo := GetPostingAllowedToDate(ExcludePeriod);
        AccountingPeriod2.SetRange("New Fiscal Year", true);
        AccountingPeriod2.SetFilter("Starting Date", '<>%1', ExcludePeriod);
        if AccountingPeriod2.FindLast then
            if NewPostingAllowedTo <> 0D then
                if CheckPostingRangeSetup(CalcDate('<-1D>', NewPostingAllowedTo)) then
                    Error(
                      Text10800,
                      AccountingPeriod2."Starting Date", OldPostingAllowedTo,
                      GLSetup.FieldCaption("Allow Posting From"), GLSetup.FieldCaption("Allow Posting To"),
                      GLSetup.TableCaption, UserSetup.TableCaption);
    end;

    local procedure GetPostingAllowedToDate(ExcludePeriod: Date): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange("Fiscally Closed", false);
        AccountingPeriod.SetFilter("Starting Date", '<>%1', ExcludePeriod);
        if AccountingPeriod.FindLast then
            exit(AccountingPeriod."Starting Date");

        exit(0D);
    end;

    procedure CorrespondingAccountingPeriodExists(var AccountingPeriod: Record "Accounting Period"; AccSchedDate: Date): Boolean
    begin
        AccountingPeriod.SetFilter("Starting Date", '%1', CalcDate('<-CM>', AccSchedDate));
        if AccountingPeriod.FindFirst() then
            exit(true);
        exit(false);
    end;
}

