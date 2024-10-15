page 35296 "Closed Docs Analysis LCY FB"
{
    Caption = 'Closed Docs Analysis LCY FB';
    DataCaptionExpression = GetFilter(Type);
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    SourceTable = "Closed Cartera Doc.";

    layout
    {
        area(content)
        {
            field(NoHonored; NoHonored)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Honored';
                Editable = false;
                ToolTip = 'Specifies that the related payment is settled. ';
            }
            field(NoRejected; NoRejected)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Rejected';
                Editable = false;
                ToolTip = 'Specifies that the related payment is rejected.';
            }
            field(NoRedrawn; NoRedrawn)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Redrawn';
                Editable = false;
                ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
            }
            field(HonoredLCY; HonoredAmtLCY)
            {
                ApplicationArea = All;
                AutoFormatType = 1;
                Caption = 'Honored';
                Editable = false;
                ToolTip = 'Specifies that the related payment is settled. ';
                Visible = HonoredLCYVisible;
            }
            field(RejectedLCY; RejectedAmtLCY)
            {
                ApplicationArea = All;
                AutoFormatType = 1;
                Caption = 'Rejected';
                Editable = false;
                ToolTip = 'Specifies that the related payment is rejected.';
                Visible = RejectedLCYVisible;
            }
            field(RedrawnLCY; RedrawnAmtLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Redrawn';
                Editable = false;
                ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateStatistics;
    end;

    trigger OnInit()
    begin
        RejectedLCYVisible := true;
        HonoredLCYVisible := true;
    end;

    trigger OnOpenPage()
    begin
        CurrencyFilter := GetFilter("Currency Code");
        UpdateStatistics;
    end;

    var
        ClosedDoc: Record "Closed Cartera Doc.";
        HonoredAmt: Decimal;
        RejectedAmt: Decimal;
        RedrawnAmt: Decimal;
        HonoredAmtLCY: Decimal;
        RejectedAmtLCY: Decimal;
        RedrawnAmtLCY: Decimal;
        NoHonored: Integer;
        NoRejected: Integer;
        NoRedrawn: Integer;
        CurrencyFilter: Code[250];
        Show: Boolean;
        [InDataSet]
        HonoredLCYVisible: Boolean;
        [InDataSet]
        RejectedLCYVisible: Boolean;

    local procedure UpdateStatistics()
    begin
        with ClosedDoc do begin
            Copy(Rec);
            SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Status, Redrawn);
            SetFilter("Currency Code", CurrencyFilter);
            SetRange(Status, Status::Honored);
            SetRange(Redrawn, true);
            Show := CalcSums("Original Amount", "Original Amount (LCY)");
            if Show then begin
                RedrawnAmt := "Original Amount";
                RedrawnAmtLCY := "Original Amount (LCY)";
            end;
            NoRedrawn := Count;

            SetRange(Redrawn, false);
            if Show then begin
                CalcSums("Original Amount", "Original Amount (LCY)");
                HonoredAmt := "Original Amount";
                HonoredAmtLCY := "Original Amount (LCY)";
            end;
            NoHonored := Count;
            SetRange(Redrawn);

            SetRange(Status, Status::Rejected);
            if Show then begin
                CalcSums("Original Amount", "Original Amount (LCY)");
                RejectedAmt := "Original Amount";
                RejectedAmtLCY := "Original Amount (LCY)";
            end;
            NoRejected := Count;
            SetRange(Status);

            if Find('=><') then;  // necessary to calculate decimal places

            // CurrForm.Honored.VISIBLE(Show);
            // CurrForm.Rejected.VISIBLE(Show);
            HonoredLCYVisible := Show;
            RejectedLCYVisible := Show;
        end;
    end;
}

