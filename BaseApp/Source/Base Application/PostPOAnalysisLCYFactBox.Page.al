page 35299 "Post. PO Analysis LCY Fact Box"
{
    Caption = 'Post. PO Analysis LCY Fact Box';
    DataCaptionExpression = Caption;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    SourceTable = "Posted Payment Order";

    layout
    {
        area(content)
        {
            field("Currency Code"; "Currency Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the currency code associated with this posted payment order.';
            }
            field("Amount Grouped"; "Amount Grouped")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the grouped amount for this posted payment order.';
            }
            field("Remaining Amount"; "Remaining Amount")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the pending amounts left to pay for documents that are part of this posted payment order.';
            }
            group("No. of Documents")
            {
                Caption = 'No. of Documents';
                field(NoOpen; NoOpen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is not processed yet. ';
                }
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
            group("Amount (LCY)")
            {
                Caption = 'Amount (LCY)';
                field(OpenAmtLCY; OpenAmtLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is not processed yet. ';
                }
                field(HonoredAmtLCY; HonoredAmtLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Honored';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is settled. ';
                }
                field(RejectedAmtLCY; RejectedAmtLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rejected';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is rejected.';
                }
                field(RedrawnAmtLCY; RedrawnAmtLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Redrawn';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
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

    var
        PostedDoc: Record "Posted Cartera Doc.";
        OpenAmt: Decimal;
        HonoredAmt: Decimal;
        RejectedAmt: Decimal;
        RedrawnAmt: Decimal;
        OpenAmtLCY: Decimal;
        HonoredAmtLCY: Decimal;
        RejectedAmtLCY: Decimal;
        RedrawnAmtLCY: Decimal;
        NoOpen: Integer;
        NoHonored: Integer;
        NoRejected: Integer;
        NoRedrawn: Integer;

    local procedure UpdateStatistics()
    begin
        with PostedDoc do begin
            SetCurrentKey("Bill Gr./Pmt. Order No.", Status, "Category Code", Redrawn, "Due Date");
            SetRange(Type, Type::Payable);
            SetRange("Bill Gr./Pmt. Order No.", Rec."No.");
            Rec.CopyFilter("Due Date Filter", "Due Date");
            Rec.CopyFilter("Global Dimension 1 Filter", "Global Dimension 1 Code");
            Rec.CopyFilter("Global Dimension 2 Filter", "Global Dimension 2 Code");
            Rec.CopyFilter("Category Filter", "Category Code");

            SetRange(Status, Status::Open);
            CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
            OpenAmt := "Amount for Collection";
            OpenAmtLCY := "Amt. for Collection (LCY)";
            NoOpen := Count;

            SetRange(Status);
            SetRange(Redrawn, true);
            CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
            RedrawnAmt := "Amount for Collection";
            RedrawnAmtLCY := "Amt. for Collection (LCY)";
            NoRedrawn := Count;
            SetRange(Redrawn);

            SetRange(Status, Status::Honored);
            CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
            HonoredAmt := "Amount for Collection" - RedrawnAmt;
            HonoredAmtLCY := "Amt. for Collection (LCY)" - RedrawnAmtLCY;
            NoHonored := Count - NoRedrawn;

            SetRange(Status, Status::Rejected);
            CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
            RejectedAmt := "Amount for Collection";
            RejectedAmtLCY := "Amt. for Collection (LCY)";
            NoRejected := Count;
        end;
    end;
}

