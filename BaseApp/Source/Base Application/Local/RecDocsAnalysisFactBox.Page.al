page 35290 "Rec. Docs Analysis Fact Box"
{
    Caption = 'Rec. Docs Analysis Fact Box';
    DataCaptionExpression = GetFilter(Type);
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    SaveValues = true;
    SourceTable = "Cartera Doc.";

    layout
    {
        area(content)
        {
            field(BillCount; DocCount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'No. of Documents';
                Editable = false;
                ToolTip = 'Specifies the number of documents included.';
            }
            field(Total; TotalAmt)
            {
                ApplicationArea = All;
                AutoFormatExpression = Doc."Currency Code";
                AutoFormatType = 1;
                Caption = 'Amount';
                DrillDown = true;
                Editable = false;
                ToolTip = 'Specifies the sum of amounts on the documents.';
                Visible = TotalVisible;

                trigger OnDrillDown()
                begin
                    PAGE.RunModal(0, Doc);
                end;
            }
            field(TotalLCY; TotalAmtLCY)
            {
                ApplicationArea = All;
                AutoFormatType = 1;
                Caption = 'Amount (LCY)';
                DrillDown = true;
                Editable = false;
                ToolTip = 'Specifies the sum of amounts on the documents.';
                Visible = TotalLCYVisible;

                trigger OnDrillDown()
                begin
                    PAGE.RunModal(0, Doc);
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        TotalLCYVisible := true;
        TotalVisible := true;
    end;

    trigger OnOpenPage()
    begin
        CategoryFilter := GetFilter("Category Code");
        CurrencyFilter := GetFilter("Currency Code");
        UpdateStatistics();
    end;

    var
        Doc: Record "Cartera Doc.";
        CategoryFilter: Code[250];
        CurrencyFilter: Code[250];
        DocCount: Integer;
        TotalAmt: Decimal;
        TotalAmtLCY: Decimal;
        Show: Boolean;
        [InDataSet]
        TotalVisible: Boolean;
        [InDataSet]
        TotalLCYVisible: Boolean;

    local procedure UpdateStatistics()
    begin
        with Doc do begin
            Copy(Rec);
            SetCurrentKey(Type, "Bill Gr./Pmt. Order No.", "Category Code", "Currency Code");
            SetFilter("Category Code", CategoryFilter);
            SetFilter("Currency Code", CurrencyFilter);
            Show := CalcSums("Remaining Amount", "Remaining Amt. (LCY)");
            if Show then begin
                TotalAmt := "Remaining Amount";
                TotalAmtLCY := "Remaining Amt. (LCY)";
            end;
            DocCount := Count;
            TotalVisible := Show;
            TotalLCYVisible := Show;

            if Find('=><') then;  // necessary to calculate decimal places
        end;
    end;
}

