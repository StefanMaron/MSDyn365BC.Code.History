page 378 "Bank Account Balance Lines"
{
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Bank Account Balance Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Period Start"; "Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the start date of the period defined on the line for the summary of the bank account balance.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
                field(NetChange; "Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = BankAcc."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Net Change';
                    DrillDown = true;
                    ToolTip = 'Specifies the net value of entries for the period shown in the left column.';

                    trigger OnDrillDown()
                    begin
                        ShowBankAccEntries();
                    end;
                }
                field("BankAcc.""Net Change (LCY)"""; "Net Change (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Net Change (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the net value of entries in LCY for the period shown in the left column.';

                    trigger OnDrillDown()
                    begin
                        ShowBankAccEntries();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if DateRec.Get("Period Type", "Period Start") then;
        CalcLine();
    end;

    trigger OnFindRecord(Which: Text) FoundDate: Boolean
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        FoundDate := PeriodFormLinesMgt.FindDate(VariantRec, DateRec, Which, PeriodType);
        Rec := VariantRec;
    end;

    trigger OnNextRecord(Steps: Integer) ResultSteps: Integer
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ResultSteps := PeriodFormLinesMgt.NextDate(VariantRec, DateRec, Steps, PeriodType);
        Rec := VariantRec;
    end;

    trigger OnOpenPage()
    begin
        Reset;
    end;

    var
        BankAcc: Record "Bank Account";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    procedure Set(var NewBankAcc: Record "Bank Account"; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        BankAcc.Copy(NewBankAcc);
        DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure ShowBankAccEntries()
    begin
        SetDateFilter;
        BankAccLedgEntry.Reset();
        BankAccLedgEntry.SetCurrentKey("Bank Account No.", "Posting Date");
        BankAccLedgEntry.SetRange("Bank Account No.", BankAcc."No.");
        BankAccLedgEntry.SetFilter("Posting Date", BankAcc.GetFilter("Date Filter"));
        BankAccLedgEntry.SetFilter("Global Dimension 1 Code", BankAcc.GetFilter("Global Dimension 1 Filter"));
        BankAccLedgEntry.SetFilter("Global Dimension 2 Code", BankAcc.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, BankAccLedgEntry);
    end;

    procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            BankAcc.SetRange("Date Filter", "Period Start", "Period End")
        else
            BankAcc.SetRange("Date Filter", 0D, "Period End");
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        BankAcc.CalcFields("Net Change", "Net Change (LCY)");
        "Net Change" := BankAcc."Net Change";
        "Net Change (LCY)" := BankAcc."Net Change (LCY)";

        OnAfterCalcLine(BankAcc, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var BankAccount: Record "Bank Account"; var BankAccountBalanceBuffer: Record "Bank Account Balance Buffer")
    begin
    end;
}

