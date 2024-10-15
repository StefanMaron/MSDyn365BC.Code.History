table 5 "Finance Charge Terms"
{
    Caption = 'Finance Charge Terms';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Finance Charge Terms";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Interest Rate"; Decimal)
        {
            Caption = 'Interest Rate';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(3; "Minimum Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Minimum Amount (LCY)';
            MinValue = 0;
        }
        field(5; "Additional Fee (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Additional Fee (LCY)';
            MinValue = 0;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Interest Calculation Method"; Option)
        {
            Caption = 'Interest Calculation Method';
            OptionCaption = 'Average Daily Balance,Balance Due';
            OptionMembers = "Average Daily Balance","Balance Due";
        }
        field(9; "Interest Period (Days)"; Integer)
        {
            Caption = 'Interest Period (Days)';
        }
        field(10; "Grace Period"; DateFormula)
        {
            Caption = 'Grace Period';
        }
        field(11; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
        }
        field(12; "Interest Calculation"; Option)
        {
            Caption = 'Interest Calculation';
            OptionCaption = 'Open Entries,Closed Entries,All Entries';
            OptionMembers = "Open Entries","Closed Entries","All Entries";
        }
        field(13; "Post Interest"; Boolean)
        {
            Caption = 'Post Interest';
            InitValue = true;
        }
        field(14; "Post Additional Fee"; Boolean)
        {
            Caption = 'Post Additional Fee';
            InitValue = true;
        }
        field(15; "Line Description"; Text[100])
        {
            Caption = 'Line Description';
        }
        field(16; "Add. Line Fee in Interest"; Boolean)
        {
            Caption = 'Add. Line Fee in Interest';
        }
        field(30; "Detailed Lines Description"; Text[100])
        {
            Caption = 'Detailed Lines Description';
        }
        field(11760; "Detailed Line Description"; Text[50])
        {
            Caption = 'Detailed Line Description';
        }
        field(11761; "Grace Tax Period"; DateFormula)
        {
            Caption = 'Grace Tax Period';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Interest Rate")
        {
        }
    }

    trigger OnDelete()
    var
        MultipleInterestRate: Record "Multiple Interest Rate";
    begin
        FinChrgText.SetRange("Fin. Charge Terms Code", Code);
        FinChrgText.DeleteAll;

        CurrForFinChrgTerms.SetRange("Fin. Charge Terms Code", Code);
        CurrForFinChrgTerms.DeleteAll;
        // NAVCZ
        MultipleInterestRate.SetRange("Finance Charge Code", Code);
        MultipleInterestRate.DeleteAll;
        // NAVCZ
    end;

    var
        FinChrgText: Record "Finance Charge Text";
        CurrForFinChrgTerms: Record "Currency for Fin. Charge Terms";

    [Scope('OnPrem')]
    procedure SetRatesForCalc(PayDate: Date; ClosingDate: Date; var MultipleInterestCalcLine: Record "Multiple Interest Calc. Line")
    var
        MultipleInterestRate: Record "Multiple Interest Rate";
        SalesSetup: Record "Sales & Receivables Setup";
        StartDate: Date;
        InterestRate: Decimal;
        CreateRate: Boolean;
        RateFactor: Decimal;
    begin
        // NAVCZ
        SalesSetup.Get;
        if SalesSetup."Multiple Interest Rates" then begin
            FindMultipleInterestRate(PayDate, MultipleInterestRate);
            StartDate := CalcDate('<1D>', PayDate);
            MultipleInterestRate.TestField("Interest Rate");
            InterestRate := MultipleInterestRate."Interest Rate";
            RateFactor := 100 * MultipleInterestRate."Interest Period (Days)";
            if StartDate <= ClosingDate then begin
                CreateRate := true;
                MultipleInterestRate.SetRange("Valid from Date", CalcDate('<2D>', PayDate), ClosingDate);
                if MultipleInterestRate.FindSet then begin
                    repeat
                        if MultipleInterestRate."Valid from Date" < ClosingDate then begin
                            InsertMultInterestCalcRate(MultipleInterestCalcLine, StartDate, InterestRate,
                              MultipleInterestRate."Valid from Date" - StartDate, RateFactor);
                            StartDate := MultipleInterestRate."Valid from Date";
                            MultipleInterestRate.TestField("Interest Rate");
                            InterestRate := MultipleInterestRate."Interest Rate";
                        end else begin
                            InsertMultInterestCalcRate(MultipleInterestCalcLine, StartDate, InterestRate,
                              (ClosingDate - StartDate) + 1, RateFactor);
                            CreateRate := false;
                            exit;
                        end;
                    until MultipleInterestRate.Next = 0;
                end;
                if CreateRate then
                    InsertMultInterestCalcRate(MultipleInterestCalcLine, StartDate, InterestRate,
                      (ClosingDate - StartDate) + 1, RateFactor);
            end else
                InsertMultInterestCalcRate(MultipleInterestCalcLine, StartDate, InterestRate, 0, RateFactor);
        end else
            InsertMultInterestCalcRate(MultipleInterestCalcLine, PayDate, "Interest Rate",
              ClosingDate - PayDate, 100 * "Interest Period (Days)");
    end;

    [Scope('OnPrem')]
    procedure InsertMultInterestCalcRate(var MultipleInterestCalcLine: Record "Multiple Interest Calc. Line"; LineDate: Date; LineRate: Decimal; LineDays: Integer; LineRateFactor: Decimal)
    begin
        // NAVCZ
        with MultipleInterestCalcLine do begin
            Date := LineDate;
            "Interest Rate" := LineRate;
            Days := LineDays;
            "Rate Factor" := LineRateFactor;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure FindMultipleInterestRate(InterestStartDate: Date; var MultipleInterestRate: Record "Multiple Interest Rate")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // NAVCZ
        SalesSetup.Get;
        if SalesSetup."Multiple Interest Rates" then begin
            MultipleInterestRate.SetRange("Finance Charge Code", Code);
            MultipleInterestRate.SetRange("Valid from Date", 0D, CalcDate('<1D>', InterestStartDate));
            MultipleInterestRate.FindLast;
        end;
    end;
}

