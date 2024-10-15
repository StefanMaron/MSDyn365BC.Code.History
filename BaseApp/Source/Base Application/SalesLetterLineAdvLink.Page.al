page 31014 "Sales Letter Line - Adv.Link."
{
    Caption = 'Sales Letter Line - Adv.Link.';
    Editable = false;
    PageType = List;
    SourceTable = "Sales Advance Letter Line";
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for sales advance.';
                    Visible = false;
                }
                field("Customer Posting Group"; "Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customerÍs market type to link business transakcions to.';
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                    Visible = false;
                }
                field("Document Linked Amount"; "Document Linked Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Other Doc. Linked Amount';
                    ToolTip = 'Specifies other doc. linked amount';
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
                    SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
                    SalesAdvanceLetterLine2: Record "Sales Advance Letter Line";
                begin
                    SalesAdvanceLetterLine2 := Rec;
                    CurrPage.SetSelectionFilter(SalesAdvanceLetterLine);
                    if SalesAdvanceLetterLine.FindSet then
                        repeat
                            Rec := SalesAdvanceLetterLine;
                            Mark := not Mark;
                        until SalesAdvanceLetterLine.Next = 0;
                    Rec := SalesAdvanceLetterLine2;
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
        CalcFields("Document Linked Amount", "Document Linked Inv. Amount",
          "Document Linked Ded. Amount");
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
        TempSalesAdvanceLetterLine.Copy(Rec);
        if TempSalesAdvanceLetterLine.Find(Which) then begin
            Rec := TempSalesAdvanceLetterLine;
            exit(true);
        end;
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        TempSalesAdvanceLetterLine.Copy(Rec);
        ResultSteps := TempSalesAdvanceLetterLine.Next(Steps);
        if ResultSteps <> 0 then
            Rec := TempSalesAdvanceLetterLine;
        exit(ResultSteps);
    end;

    trigger OnOpenPage()
    begin
        Clear(Action1);
    end;

    var
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesAdvanceLetterLine: Record "Sales Advance Letter Line" temporary;
        Action1: Option "None",Assigned;
        RemainingAmount: Decimal;
        LinkingType: Option "Invoiced Amount",Amount;

    [Scope('OnPrem')]
    procedure SetSalesHeader(SalesHeader: Record "Sales Header"; var SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
        TempSalesHeader := SalesHeader;
        TempSalesHeader.Insert;
        if SalesAdvanceLetterLine.FindSet then
            repeat
                TempSalesAdvanceLetterLine := SalesAdvanceLetterLine;
                TempSalesAdvanceLetterLine.Insert;
            until SalesAdvanceLetterLine.Next = 0;
        SetFilter("Doc. No. Filter", '<%1|>%1', TempSalesHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure UpdateLetters(var SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
        if SalesAdvanceLetterLine.FindSet then
            repeat
                if TempSalesAdvanceLetterLine.Get(SalesAdvanceLetterLine."Letter No.", SalesAdvanceLetterLine."Line No.") then begin
                    TempSalesAdvanceLetterLine := SalesAdvanceLetterLine;
                    TempSalesAdvanceLetterLine.Modify;
                end else begin
                    TempSalesAdvanceLetterLine := SalesAdvanceLetterLine;
                    TempSalesAdvanceLetterLine.Insert;
                end;
            until SalesAdvanceLetterLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure GetSelectedRecords(var SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
        TempSalesAdvanceLetterLine.Copy(Rec);
        TempSalesAdvanceLetterLine.MarkedOnly(true);
        if TempSalesAdvanceLetterLine.FindSet then
            repeat
                SalesAdvanceLetterLine := TempSalesAdvanceLetterLine;
                SalesAdvanceLetterLine.Insert;
            until TempSalesAdvanceLetterLine.Next = 0
        else begin
            SalesAdvanceLetterLine := Rec;
            SalesAdvanceLetterLine.Insert;
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

