page 7000058 "Post. Pmt. Ord. Maturity Lin."
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
                field(DocAmount; DocAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = PostedPmtOrd."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the amount for the posted payment order for the period.';

                    trigger OnDrillDown()
                    begin
                        ShowDocEntries;
                    end;
                }
                field(DocAmountLCY; DocAmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Amount (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the amount for the posted payment order for the period.';

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
        if PostedPmtOrd."No." <> '' then begin
            PostedPmtOrd.CalcFields("Amount Grouped", "Amount Grouped (LCY)");
            DocAmount := PostedPmtOrd."Amount Grouped";
            DocAmountLCY := PostedPmtOrd."Amount Grouped (LCY)";
        end else begin
            DocAmount := 0;
            DocAmountLCY := 0;
        end;
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
    end;

    var
        PostedPmtOrd: Record "Posted Payment Order";
        PostedDoc: Record "Posted Cartera Doc.";
        PeriodFormManagement: Codeunit PeriodFormManagement;
        PeriodLength: Option Day,Week,Month,Quarter,Year,Period;
        AmountType: Option "Net Change","Balance at Date";
        DocAmount: Decimal;
        DocAmountLCY: Decimal;

    [Scope('OnPrem')]
    procedure Set(var NewPostedPmtOrd: Record "Posted Payment Order"; NewPeriodLength: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        PostedPmtOrd.Copy(NewPostedPmtOrd);
        PeriodLength := NewPeriodLength;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            PostedPmtOrd.SetRange("Due Date Filter", "Period Start", "Period End")
        else
            PostedPmtOrd.SetRange("Due Date Filter", 0D, "Period End");
    end;

    local procedure ShowDocEntries()
    begin
        SetDateFilter;
        PostedDoc.SetRange("Bill Gr./Pmt. Order No.", PostedPmtOrd."No.");
        PostedDoc.SetRange("Collection Agent", PostedDoc."Collection Agent"::Bank);
        PostedDoc.SetFilter("Due Date", PostedPmtOrd.GetFilter("Due Date Filter"));
        PostedDoc.SetFilter("Global Dimension 1 Code", PostedPmtOrd.GetFilter("Global Dimension 1 Filter"));
        PostedDoc.SetFilter("Global Dimension 2 Code", PostedPmtOrd.GetFilter("Global Dimension 2 Filter"));
        PostedDoc.SetFilter("Category Code", PostedPmtOrd.GetFilter("Category Filter"));
        PAGE.RunModal(0, PostedDoc);
    end;
}

