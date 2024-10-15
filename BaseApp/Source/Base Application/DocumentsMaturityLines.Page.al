page 7000030 "Documents Maturity Lines"
{
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = Date;

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
                    ToolTip = 'Specifies the starting date of the period that you want to view.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the period shown on the line.';
                }
                field("Doc.""Remaining Amt. (LCY)"""; Doc."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Amount (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the sum of amounts on the matured documents.';

                    trigger OnDrillDown()
                    begin
                        ShowDocEntries;
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
        SetDateFilter;
        Doc.CalcSums("Remaining Amt. (LCY)");
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(PeriodFormManagement.FindDate(Which, Rec, PeriodLength));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(PeriodFormManagement.NextDate(Steps, Rec, PeriodLength));
    end;

    trigger OnOpenPage()
    begin
        Reset;
        Doc.SetCurrentKey(
          Type, "Bill Gr./Pmt. Order No.", "Category Code", "Currency Code", Accepted, "Due Date");
    end;

    var
        Doc: Record "Cartera Doc.";
        PeriodFormManagement: Codeunit PeriodFormManagement;
        PeriodLength: Option Day,Week,Month,Quarter,Year,Period;
        AmountType: Option "Net Change","Balance at Date";

    [Scope('OnPrem')]
    procedure Set(var NewDoc: Record "Cartera Doc."; NewPeriodLength: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        NewDoc.CopyFilter(Type, Doc.Type);
        NewDoc.CopyFilter("Bill Gr./Pmt. Order No.", Doc."Bill Gr./Pmt. Order No.");
        NewDoc.CopyFilter("Category Code", Doc."Category Code");
        NewDoc.CopyFilter("Currency Code", Doc."Currency Code");
        PeriodLength := NewPeriodLength;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Doc.SetRange("Due Date", "Period Start", "Period End")
        else
            Doc.SetRange("Due Date", 0D, "Period End");
    end;

    local procedure ShowDocEntries()
    begin
        SetDateFilter;
        PAGE.RunModal(0, Doc);
    end;
}

