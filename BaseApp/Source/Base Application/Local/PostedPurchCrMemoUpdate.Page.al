page 28066 "Posted Purch. Cr.Memo - Update"
{
    Caption = 'Posted Purch. Cr.Memo - Update';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Purch. Cr. Memo Hdr.";
    SourceTableTemporary = true;

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
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor';
                    Editable = false;
                    ToolTip = 'Specifies the name of the vendor who shipped the items.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date the credit memo was posted.';
                }
            }
            group("Adjustment Details")
            {
                Caption = 'Adjustment Details';
                field("Adjustment Applies-to"; Rec."Adjustment Applies-to")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the document that the adjustment was applied to.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the reason code for the document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xPurchCrMemoHdr := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Purch. Cr. Memo Hdr. - Edit", Rec);
    end;

    var
        xPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";

    local procedure RecordChanged(): Boolean
    begin
        exit(
          ("Adjustment Applies-to" <> xPurchCrMemoHdr."Adjustment Applies-to") or
          ("Reason Code" <> xPurchCrMemoHdr."Reason Code"));
    end;

    [Scope('OnPrem')]
    procedure SetRec(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        Rec := PurchCrMemoHdr;
        Insert();
    end;
}

