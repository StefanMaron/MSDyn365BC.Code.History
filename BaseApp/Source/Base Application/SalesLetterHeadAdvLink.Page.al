page 31013 "Sales Letter Head. - Adv.Link."
{
    Caption = 'Sales Letter Head. - Adv.Link.';
    Editable = false;
    PageType = List;
    SourceTable = "Sales Advance Letter Header";
    SourceTableView = SORTING("No.");

    layout
    {
        area(content)
        {
            repeater(Control1220015)
            {
                Editable = false;
                ShowCaption = false;
                field(MARK; Mark)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mark';
                    Editable = false;
                    ToolTip = 'Specifies the funkction allows to mark the selected advance letters to link into invoice.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the sales advance letter.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the stage during advance process.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Template Code"; "Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an advance template code.';
                }
                field("Customer Posting Group"; "Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customerÍs market type to link business transakcions to.';
                }
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the document. The posting description also appers on customer and G/L entries.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ToolTip = 'Specifies the name of the salesperson who is addigned to the customes.';
                    Visible = false;
                }
                field("Order No."; "Order No.")
                {
                    ToolTip = 'Specifies the number of the sales order that this advance was posted from.';
                    Visible = false;
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                    Visible = false;
                }
                field("Document Linked Amount"; "Document Linked Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Other Doc. Linked Amount';
                    ToolTip = 'Specifies other doc. linked ';
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
                    SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
                    SalesAdvanceLetterHeader2: Record "Sales Advance Letter Header";
                begin
                    SalesAdvanceLetterHeader2 := Rec;
                    CurrPage.SetSelectionFilter(SalesAdvanceLetterHeader);
                    if SalesAdvanceLetterHeader.FindSet then
                        repeat
                            Rec := SalesAdvanceLetterHeader;
                            Mark := not Mark;
                        until SalesAdvanceLetterHeader.Next = 0;
                    Rec := SalesAdvanceLetterHeader2;
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
        TempSalesAdvanceLetterHeader.Copy(Rec);
        if TempSalesAdvanceLetterHeader.Find(Which) then begin
            Rec := TempSalesAdvanceLetterHeader;
            exit(true);
        end;
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        TempSalesAdvanceLetterHeader.Copy(Rec);
        ResultSteps := TempSalesAdvanceLetterHeader.Next(Steps);
        if ResultSteps <> 0 then
            Rec := TempSalesAdvanceLetterHeader;
        exit(ResultSteps);
    end;

    trigger OnOpenPage()
    begin
        Clear(Action1);
    end;

    var
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesAdvanceLetterHeader: Record "Sales Advance Letter Header" temporary;
        Action1: Option "None",Assigned;
        RemainingAmount: Decimal;
        LinkingType: Option "Invoiced Amount",Amount;

    [Scope('OnPrem')]
    procedure SetSalesHeader(SalesHeader: Record "Sales Header"; var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        TempSalesHeader := SalesHeader;
        TempSalesHeader.Insert;
        if SalesAdvanceLetterHeader.FindSet then
            repeat
                TempSalesAdvanceLetterHeader := SalesAdvanceLetterHeader;
                TempSalesAdvanceLetterHeader.Insert;
            until SalesAdvanceLetterHeader.Next = 0;
        SetFilter("Doc. No. Filter", '<%1|>%1', TempSalesHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure UpdateLetters(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        if SalesAdvanceLetterHeader.FindSet then
            repeat
                if TempSalesAdvanceLetterHeader.Get(SalesAdvanceLetterHeader."No.") then begin
                    TempSalesAdvanceLetterHeader := SalesAdvanceLetterHeader;
                    TempSalesAdvanceLetterHeader.Modify;
                end else begin
                    TempSalesAdvanceLetterHeader := SalesAdvanceLetterHeader;
                    TempSalesAdvanceLetterHeader.Insert;
                end;
            until SalesAdvanceLetterHeader.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure GetSelectedRecords(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
        TempSalesAdvanceLetterHeader.Copy(Rec);
        TempSalesAdvanceLetterHeader.MarkedOnly(true);
        if TempSalesAdvanceLetterHeader.FindSet then
            repeat
                SalesAdvanceLetterHeader := TempSalesAdvanceLetterHeader;
                SalesAdvanceLetterHeader.Insert;
            until TempSalesAdvanceLetterHeader.Next = 0
        else begin
            SalesAdvanceLetterHeader := Rec;
            SalesAdvanceLetterHeader.Insert;
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

