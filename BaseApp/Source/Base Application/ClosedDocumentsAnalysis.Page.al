page 7000044 "Closed Documents Analysis"
{
    Caption = 'Closed Documents Analysis';
    DataCaptionExpression = GetFilter(Type);
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Closed Cartera Doc.";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CurrencyFilter; CurrencyFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency Filter';
                    TableRelation = Currency;
                    ToolTip = 'Specifies the currencies that the data is included for.';

                    trigger OnValidate()
                    begin
                        CurrencyFilterOnAfterValidate;
                    end;
                }
            }
            group(Control23)
            {
                ShowCaption = false;
                fixed(Control1902115401)
                {
                    ShowCaption = false;
                    group("No. of Documents")
                    {
                        Caption = 'No. of Documents';
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
                    }
                    group("Original Amount")
                    {
                        Caption = 'Original Amount';
                        field(Honored; HonoredAmt)
                        {
                            ApplicationArea = All;
                            AutoFormatExpression = ClosedDoc."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Original Amount';
                            Editable = false;
                            ToolTip = 'Specifies the initial amount of this closed document.';
                            Visible = HonoredVisible;
                        }
                        field(Rejected; RejectedAmt)
                        {
                            ApplicationArea = All;
                            AutoFormatExpression = ClosedDoc."Currency Code";
                            AutoFormatType = 1;
                            Editable = false;
                            Visible = RejectedVisible;
                        }
                        field(Rejected2; RedrawnAmt)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ClosedDoc."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Rejected';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is rejected.';
                        }
                    }
                    group("Original Amt. (LCY)")
                    {
                        Caption = 'Original Amt. (LCY)';
                        field(HonoredLCY; HonoredAmtLCY)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Original Amt. (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the initial amount of this closed document, in LCY.';
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
                        field(RejectedLCY2; RedrawnAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Rejected';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is rejected.';
                        }
                    }
                }
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
        RejectedVisible := true;
        HonoredVisible := true;
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
        [InDataSet]
        HonoredVisible: Boolean;
        [InDataSet]
        RejectedVisible: Boolean;
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
            RedrawnAmt := 0;
            RedrawnAmtLCY := 0;
            if FindSet then
                repeat
                    RedrawnAmt += "Original Amount";
                    RedrawnAmtLCY += "Original Amount (LCY)";
                until Next = 0;
            NoRedrawn := Count;

            SetRange(Redrawn, false);
            HonoredAmt := 0;
            HonoredAmtLCY := 0;
            if FindSet then
                repeat
                    HonoredAmt += "Original Amount";
                    HonoredAmtLCY += "Original Amount (LCY)";
                until Next = 0;
            NoHonored := Count;
            SetRange(Redrawn);

            SetRange(Status, Status::Rejected);
            RejectedAmt := 0;
            RejectedAmtLCY := 0;
            if FindSet then
                repeat
                    RejectedAmt += "Original Amount";
                    RejectedAmtLCY += "Original Amount (LCY)";
                until Next = 0;

            NoRejected := Count;
            SetRange(Status);

            if Find('=><') then;  // necessary to calculate decimal places

        end;
    end;

    local procedure CurrencyFilterOnAfterValidate()
    begin
        UpdateStatistics;
    end;
}

