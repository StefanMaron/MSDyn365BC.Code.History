page 12435 "Posted Sales Cr. Memo - Update"
{
    Caption = 'Posted Sales Cr. Memo - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Sales Cr.Memo Header";
    SourceTableTemporary = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with page 1354 Pstd. Sales Cr. Memo - Update';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the posted credit memo number.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that you shipped the items on the credit memo to.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the credit memo was posted.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Consignor No."; Rec."Consignor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the number of the party who consigned the transportation.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xSalesCrMemoHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Sales Cr.Memo Header - Edit", Rec);
    end;

    var
        xSalesCrMemoHeader: Record "Sales Cr.Memo Header";

    local procedure RecordChanged(): Boolean
    begin
        exit(Rec."Consignor No." <> xSalesCrMemoHeader."Consignor No.");
    end;

    [Scope('OnPrem')]
    procedure SetRec(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        Rec := SalesCrMemoHeader;
        Rec.Insert();
    end;
}

