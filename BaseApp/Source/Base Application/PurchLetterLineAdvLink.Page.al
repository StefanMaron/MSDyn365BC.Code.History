page 31034 "Purch. Letter Line - Adv.Link."
{
    Caption = 'Purch. Letter Line - Adv.Link.';
    Editable = false;
    PageType = List;
    SourceTable = "Purch. Advance Letter Line";
    SourceTableView = SORTING("Letter No.", "Line No.");

    layout
    {
        area(content)
        {
            repeater(Control1220014)
            {
                ShowCaption = false;
                field(MARK; Mark)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mark';
                    Editable = false;
                    ToolTip = 'Specifies the funkction allows to mark the selected advance letters to link into invoice.';
                }
                field("Letter No."; "Letter No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of letter.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the stage during advance process.';
                }
                field(Description; Description)
                {
                    ToolTip = 'Specifies description for purchase advance.';
                    Visible = false;
                }
                field("Vendor Posting Group"; "Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT product posting group code for the VAT Statement.';
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT percentage used to calculate Amount Including VAT on this line.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                    Visible = false;
                }
                field("Document Linked Amount"; "Document Linked Amount")
                {
                    Caption = 'Other Doc. Linked Amount';
                    ToolTip = 'Specifies other doc. linked amount';
                    Visible = false;
                }
                field("Amount Invoiced"; "Amount Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount with advance VAT document.';
                }
                field("Document Linked Inv. Amount"; "Document Linked Inv. Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies document linked inv. amount';
                }
                field("Semifinished Linked Amount"; "Semifinished Linked Amount")
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
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Ctrl+F1';
                ToolTip = 'The funkction allows to mark the selected advance letters to link into invoice.';

                trigger OnAction()
                var
                    PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
                    PurchAdvanceLetterLine2: Record "Purch. Advance Letter Line";
                begin
                    PurchAdvanceLetterLine2 := Rec;
                    CurrPage.SetSelectionFilter(PurchAdvanceLetterLine);
                    if PurchAdvanceLetterLine.FindSet then
                        repeat
                            Rec := PurchAdvanceLetterLine;
                            Mark := not Mark;
                        until PurchAdvanceLetterLine.Next = 0;
                    Rec := PurchAdvanceLetterLine2;
                end;
            }
            action("Marked only")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Marked only';
                Image = FilterLines;
                Promoted = true;
                PromotedCategory = Process;
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
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';
                    ToolTip = 'The funkction allows to link the selected advance letters into invoice.';

                    trigger OnAction()
                    begin
                        Action1 := Action1::Assigned;
                        CurrPage.Close;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        RemainingAmount1: Decimal;
        RemainingInvAmount: Decimal;
    begin
        CalcFields("Document Linked Amount", "Document Linked Inv. Amount", "Document Linked Ded. Amount");
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
        TempPurchAdvanceLetterLine.Copy(Rec);
        if TempPurchAdvanceLetterLine.Find(Which) then begin
            Rec := TempPurchAdvanceLetterLine;
            exit(true);
        end;
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        TempPurchAdvanceLetterLine.Copy(Rec);
        ResultSteps := TempPurchAdvanceLetterLine.Next(Steps);
        if ResultSteps <> 0 then
            Rec := TempPurchAdvanceLetterLine;
        exit(ResultSteps);
    end;

    trigger OnOpenPage()
    begin
        Clear(Action1);
    end;

    var
        TempPurchHeader: Record "Purchase Header" temporary;
        TempPurchAdvanceLetterLine: Record "Purch. Advance Letter Line" temporary;
        Action1: Option "None",Assigned;
        RemainingAmount: Decimal;
        LinkingType: Option "Invoiced Amount",Amount;

    [Scope('OnPrem')]
    procedure SetPurchHeader(PurchHeader: Record "Purchase Header"; var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
        TempPurchHeader := PurchHeader;
        TempPurchHeader.Insert;
        if PurchAdvanceLetterLine.FindSet then
            repeat
                TempPurchAdvanceLetterLine := PurchAdvanceLetterLine;
                TempPurchAdvanceLetterLine.Insert;
            until PurchAdvanceLetterLine.Next = 0;
        SetFilter("Doc. No. Filter", '<%1|>%1', TempPurchHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure UpdateLetters(var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
        if PurchAdvanceLetterLine.FindSet then
            repeat
                if TempPurchAdvanceLetterLine.Get(PurchAdvanceLetterLine."Letter No.", PurchAdvanceLetterLine."Line No.") then begin
                    TempPurchAdvanceLetterLine := PurchAdvanceLetterLine;
                    TempPurchAdvanceLetterLine.Modify;
                end else begin
                    TempPurchAdvanceLetterLine := PurchAdvanceLetterLine;
                    TempPurchAdvanceLetterLine.Insert;
                end;
            until PurchAdvanceLetterLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure GetSelectedRecords(var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
        TempPurchAdvanceLetterLine.Copy(Rec);
        TempPurchAdvanceLetterLine.MarkedOnly(true);
        if TempPurchAdvanceLetterLine.FindSet then
            repeat
                PurchAdvanceLetterLine := TempPurchAdvanceLetterLine;
                PurchAdvanceLetterLine.Insert;
            until TempPurchAdvanceLetterLine.Next = 0
        else begin
            PurchAdvanceLetterLine := Rec;
            PurchAdvanceLetterLine.Insert;
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

