#if not CLEAN19
page 31033 "Purch.Let.Head. - Adv.Link."
{
    Caption = 'Purch.Let.Head. - Adv.Link. (Obsolete)';
    Editable = false;
    PageType = List;
    SourceTable = "Purch. Advance Letter Header";
    SourceTableView = SORTING("No.");
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220015)
            {
                Editable = false;
                ShowCaption = false;
                field(MARK; Mark())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mark';
                    Editable = false;
                    ToolTip = 'Specifies the funkction allows to mark the selected advance letters to link into invoice.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the purchase advance letter.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the stage during advance process.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Template Code"; Rec."Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an advance template code.';
                }
                field("Vendor Posting Group"; Rec."Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                }
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the document. The posting description also appers on vendor and G/L entries.';
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the salesperson who is addigned to the vendor.';
                    Visible = false;
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the purchase order that this advance was posted from.';
                    Visible = false;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                    Visible = false;
                }
                field("Document Linked Amount"; Rec."Document Linked Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Other Doc. Linked Amount';
                    ToolTip = 'Specifies other doc. linked amount';
                    Visible = false;
                }
                field("Amount Invoiced"; Rec."Amount Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount with advance VAT document.';
                }
                field("Document Linked Inv. Amount"; Rec."Document Linked Inv. Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies document linked inv. amount';
                }
                field("Semifinished Linked Amount"; Rec."Semifinished Linked Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the semifinished linked amount.';
                }
                field(RemainingAmount; RemainingAmount)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Remaining Amount to Link';
                    ToolTip = 'Specifies the remaining amount of general ledger entries to link';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Mark)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark';
                Image = CompleteLine;
                ShortCutKey = 'Ctrl+F1';
                ToolTip = 'The funkction allows to mark the selected advance letters to link into invoice.';

                trigger OnAction()
                var
                    PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
                    PurchAdvanceLetterHeader2: Record "Purch. Advance Letter Header";
                begin
                    PurchAdvanceLetterHeader2 := Rec;
                    CurrPage.SetSelectionFilter(PurchAdvanceLetterHeader);
                    if PurchAdvanceLetterHeader.FindSet() then
                        repeat
                            Rec := PurchAdvanceLetterHeader;
                            Mark := not Mark();
                        until PurchAdvanceLetterHeader.Next() = 0;
                    Rec := PurchAdvanceLetterHeader2;
                end;
            }
            action("Marked only")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Marked only';
                Image = FilterLines;
                ToolTip = 'Specifies only the marked advance letters.';

                trigger OnAction()
                begin
                    MarkedOnly := not MarkedOnly;
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Link Selected Advance Letters")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Link Selected Advance Letters';
                    Image = LinkWithExisting;
                    ShortCutKey = 'F7';
                    ToolTip = 'The funkction allows to link the selected advance letters into invoice.';

                    trigger OnAction()
                    begin
                        Action1 := Action1::Assigned;
                        CurrPage.Close();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Mark_Promoted; Mark)
                {
                }
                actionref("Marked only_Promoted"; "Marked only")
                {
                }
                actionref("Link Selected Advance Letters_Promoted"; "Link Selected Advance Letters")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        RemainingAmount1: Decimal;
        RemainingInvAmount: Decimal;
    begin
        CalcFields("Amount Including VAT", "Document Linked Amount", "Document Linked Inv. Amount",
          "Document Linked Ded. Amount", "Amount Deducted");
        RemainingInvAmount := "Amount Invoiced" - "Document Linked Inv. Amount" - "Semifinished Linked Amount" -
          "Amount Deducted" + "Document Linked Ded. Amount";
        RemainingAmount1 := "Amount Including VAT" - "Document Linked Amount" - "Semifinished Linked Amount" -
          "Amount Deducted" + "Document Linked Ded. Amount";
        if (LinkingType = LinkingType::Amount) or (RemainingAmount1 < RemainingInvAmount) then
            RemainingAmount := RemainingAmount1
        else
            RemainingAmount := RemainingInvAmount;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        TempPurchAdvanceLetterHeader.Copy(Rec);
        if TempPurchAdvanceLetterHeader.Find(Which) then begin
            Rec := TempPurchAdvanceLetterHeader;
            exit(true);
        end;
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        TempPurchAdvanceLetterHeader.Copy(Rec);
        ResultSteps := TempPurchAdvanceLetterHeader.Next(Steps);
        if ResultSteps <> 0 then
            Rec := TempPurchAdvanceLetterHeader;
        exit(ResultSteps);
    end;

    trigger OnOpenPage()
    begin
        Clear(Action1);
    end;

    var
        TempPurchHeader: Record "Purchase Header" temporary;
        TempPurchAdvanceLetterHeader: Record "Purch. Advance Letter Header" temporary;
        Action1: Option "None",Assigned;
        RemainingAmount: Decimal;
        LinkingType: Option "Invoiced Amount",Amount;

    [Scope('OnPrem')]
    procedure SetPurchHeader(PurchHeader: Record "Purchase Header"; var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        TempPurchHeader := PurchHeader;
        TempPurchHeader.Insert();
        if PurchAdvanceLetterHeader.FindSet() then
            repeat
                TempPurchAdvanceLetterHeader := PurchAdvanceLetterHeader;
                TempPurchAdvanceLetterHeader.Insert();
            until PurchAdvanceLetterHeader.Next() = 0;
        SetFilter("Doc. No. Filter", '<%1|>%1', TempPurchHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure UpdateLetters(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        if PurchAdvanceLetterHeader.FindSet() then
            repeat
                if TempPurchAdvanceLetterHeader.Get(PurchAdvanceLetterHeader."No.") then begin
                    TempPurchAdvanceLetterHeader := PurchAdvanceLetterHeader;
                    TempPurchAdvanceLetterHeader.Modify();
                end else begin
                    TempPurchAdvanceLetterHeader := PurchAdvanceLetterHeader;
                    TempPurchAdvanceLetterHeader.Insert();
                end;
            until PurchAdvanceLetterHeader.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetSelectedRecords(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
        TempPurchAdvanceLetterHeader.Copy(Rec);
        TempPurchAdvanceLetterHeader.MarkedOnly(true);
        if TempPurchAdvanceLetterHeader.FindSet() then
            repeat
                PurchAdvanceLetterHeader := TempPurchAdvanceLetterHeader;
                PurchAdvanceLetterHeader.Insert();
            until TempPurchAdvanceLetterHeader.Next() = 0
        else begin
            PurchAdvanceLetterHeader := Rec;
            PurchAdvanceLetterHeader.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure IsAssigned(): Boolean
    begin
        exit(Action1 = Action1::Assigned);
    end;

    [Scope('OnPrem')]
    procedure SetLinkingType(LinkingType1: Option "Invoiced Amount",Amount)
    begin
        LinkingType := LinkingType1;
    end;
}
#endif
