page 416 "G/L Account Balance Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "G/L Acc. Balance Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period Start"; "Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Start';
                    Editable = false;
                    ToolTip = 'Specifies the start date of the period defined on the line for the bank account balance.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
                field(DebitAmount; "Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankNumbers = BlankZero;
                    Caption = 'Debit Amount';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the debit amount for the period on the line.';

                    trigger OnDrillDown()
                    begin
                        BalanceDrillDown;
                    end;
                }
                field(CreditAmount; "Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankNumbers = BlankZero;
                    Caption = 'Credit Amount';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the credit amount for the period on the line.';

                    trigger OnDrillDown()
                    begin
                        BalanceDrillDown();
                    end;
                }
                field(NetChange; "Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Net Change';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies changes in the actual general ledger amount.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        BalanceDrillDown();
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
        FoundDate := PeriodFormLinesMgt.FindDate(VariantRec, DateRec, Which, GLPeriodLength);
        Rec := VariantRec;
    end;

    trigger OnNextRecord(Steps: Integer) ResultSteps: Integer
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ResultSteps := PeriodFormLinesMgt.NextDate(VariantRec, DateRec, Steps, GLPeriodLength);
        Rec := VariantRec;
    end;

    trigger OnOpenPage()
    begin
        Reset();
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        GLAcc: Record "G/L Account";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        GLPeriodLength: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";
        ClosingEntryFilter: Option Include,Exclude;
        DebitCreditTotals: Boolean;

    procedure Set(var NewGLAcc: Record "G/L Account"; NewGLPeriodLength: Integer; NewAmountType: Option "Net Change",Balance; NewClosingEntryFilter: Option Include,Exclude; NewDebitCreditTotals: Boolean)
    begin
        GLAcc.Copy(NewGLAcc);
        DeleteAll();
        GLPeriodLength := NewGLPeriodLength;
        AmountType := NewAmountType;
        ClosingEntryFilter := NewClosingEntryFilter;
        DebitCreditTotals := NewDebitCreditTotals;
        CurrPage.Update(false);
    end;

    local procedure BalanceDrillDown()
    var
        GLEntry: Record "G/L Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBalanceDrillDown(GLAcc, GLPeriodLength, AmountType, ClosingEntryFilter, DebitCreditTotals, IsHandled);
        if IsHandled then
            exit;

        SetDateFilter();
        GLEntry.Reset();
        GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        GLEntry.SetRange("G/L Account No.", GLAcc."No.");
        if GLAcc.Totaling <> '' then
            GLEntry.SetFilter("G/L Account No.", GLAcc.Totaling);
        GLEntry.SetFilter("Posting Date", GLAcc.GetFilter("Date Filter"));
        GLEntry.SetFilter("Global Dimension 1 Code", GLAcc.GetFilter("Global Dimension 1 Filter"));
        GLEntry.SetFilter("Global Dimension 2 Code", GLAcc.GetFilter("Global Dimension 2 Filter"));
        GLEntry.SetFilter("Business Unit Code", GLAcc.GetFilter("Business Unit Filter"));
        PAGE.Run(0, GLEntry);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            GLAcc.SetRange("Date Filter", "Period Start", "Period End")
        else
            GLAcc.SetRange("Date Filter", 0D, "Period End");
        if ClosingEntryFilter = ClosingEntryFilter::Exclude then begin
            AccountingPeriod.SetCurrentKey("New Fiscal Year");
            AccountingPeriod.SetRange("New Fiscal Year", true);
            if GLAcc.GetRangeMin("Date Filter") = 0D then
                AccountingPeriod.SetRange("Starting Date", 0D, GLAcc.GetRangeMax("Date Filter"))
            else
                AccountingPeriod.SetRange(
                  "Starting Date",
                  GLAcc.GetRangeMin("Date Filter") + 1,
                  GLAcc.GetRangeMax("Date Filter"));
            if AccountingPeriod.Find('-') then
                repeat
                    GLAcc.SetFilter(
                      "Date Filter", GLAcc.GetFilter("Date Filter") + '&<>%1',
                      ClosingDate(AccountingPeriod."Starting Date" - 1));
                until AccountingPeriod.Next() = 0;
        end else
            GLAcc.SetRange(
              "Date Filter",
              GLAcc.GetRangeMin("Date Filter"),
              ClosingDate(GLAcc.GetRangeMax("Date Filter")));
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        if DebitCreditTotals then
            GLAcc.CalcFields("Net Change", "Debit Amount", "Credit Amount")
        else begin
            GLAcc.CalcFields("Net Change");
            if GLAcc."Net Change" > 0 then begin
                GLAcc."Debit Amount" := GLAcc."Net Change";
                GLAcc."Credit Amount" := 0
            end else begin
                GLAcc."Debit Amount" := 0;
                GLAcc."Credit Amount" := -GLAcc."Net Change"
            end
        end;

        "Debit Amount" := GLAcc."Debit Amount";
        "Credit Amount" := GLAcc."Credit Amount";
        "Net Change" := GLAcc."Net Change";

        OnAfterCalcLine(GLAcc, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBalanceDrillDown(var GLAccount: Record "G/L Account"; GLPeriodLength: Option Day,Week,Month,Quarter,Year,"Accounting Period"; AmountType: Option "Net Change","Balance at Date"; ClosingEntryFilter: Option Include,Exclude; DebitCreditTotals: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var GLAccount: Record "G/L Account"; var GLAccBalanceBuffer: Record "G/L Acc. Balance Buffer")
    begin
    end;
}

