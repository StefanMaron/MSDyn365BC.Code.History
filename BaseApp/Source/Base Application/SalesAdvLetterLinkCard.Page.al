page 31012 "Sales Adv. Letter Link. Card"
{
    Caption = 'Sales Adv. Letter Link. Card';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Adv. Letter Line Rel. Buffer";

    layout
    {
        area(content)
        {
            group(Setup)
            {
                Caption = 'Setup';
                field(DocLineNo; DocLineNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Line No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of line of sales document (order, invoice).';
                }
                field(LetterNo; LetterNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Advance Letter No.';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the number of advance letter.';

                    trigger OnDrillDown()
                    begin
                        DrilldownLetterHeaders;
                    end;
                }
                field(LetterLinesNo; LetterLinesNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adv. Letter Line No.';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the number of advance letter line.';

                    trigger OnDrillDown()
                    begin
                        DrilldownLetterLines;
                    end;
                }
                field(NotLinkedLines; NotLinkedLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Not Linked Doc. Lines No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of document lines, which cann''t be applied by advance.';
                }
                field(DocPrepmtAmount; DocPrepmtAmount)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Doc. Amount to Link Letter';
                    Editable = false;
                    ToolTip = 'Specifies the applied amount between invoice and advance.';
                }
                field(LinkedAmount; LinkedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Linked Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount of line of sales document (order, invoice).';
                }
                field(NotLinkedAmount; NotLinkedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Not Linked Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice amount, which cann''t be applied by advance.';
                }
                field(CurrencyCode; CurrencyCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency Code';
                    Editable = false;
                    ToolTip = 'Specifies the currency code.';
                }
                field(ApplyByVATGroups; ApplyByVATGroups)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply by VAT Groups';
                    ToolTip = 'Specifies that invoices and advance letters with the same VAT groups will be applied.';
                }
                field(ApplyByVATPerc; ApplyByVATPerc)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply by VAT %';
                    ToolTip = 'Specifies that invoices and advance letters with the same VAT % will be applied.';
                }
                field(ApplyAll; ApplyAll)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply All';
                    ToolTip = 'Specifies that invoices and advance letters with the same VAT % or with the same VAT groups will be applied.';
                }
                field(QtyType; QtyType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Link Amount';
                    OptionCaption = ' ,Invoicing,,Remaining';
                    ToolTip = 'Specifies the amount of line of sales document (order, invoice).';

                    trigger OnValidate()
                    begin
                        ChangeTypes;
                    end;
                }
                field(LinkingType; LinkingType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Linking Type';
                    OptionCaption = 'Invoiced Amount,Amount';
                    ToolTip = 'Specifies selecting if the invoice will be applied with advance as invoiced amount or amount.';

                    trigger OnValidate()
                    begin
                        ChangeTypes;
                    end;
                }
            }
            repeater(Control1220013)
            {
                ShowCaption = false;
                field(Select; Select)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies selected purchase line';

                    trigger OnValidate()
                    begin
                        PrepmtLinksMgtAdv.ChangeLineSelection("Doc Line No.", Select);
                        CurrPage.Update(false);
                    end;
                }
                field("Doc Line No."; "Doc Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of line of sales document (order, invoice).';
                }
                field("Doc. Line Description"; "Doc. Line Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description of line of sales document (order, invoice).';
                }
                field("Doc. Line VAT Prod. Post. Gr."; "Doc. Line VAT Prod. Post. Gr.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT posting group of line of sales document (order, invoice).';
                }
                field("Doc. Line VAT %"; "Doc. Line VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT % of line of sales document (order, invoice).';
                }
                field("Letter No."; "Letter No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of letter.';
                }
                field("Letter Line No."; "Letter Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies letter line number.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of line of sales document (order, invoice).';

                    trigger OnValidate()
                    begin
                        if LinkingType = LinkingType::"Invoiced Amount" then
                            Error(Text001Err);
                    end;
                }
                field("Invoiced Amount"; "Invoiced Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of line of sales advance letter.';

                    trigger OnValidate()
                    begin
                        if LinkingType = LinkingType::Amount then
                            Error(Text002Err);
                    end;
                }
                field("Doc. Line Amount"; "Doc. Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of line of sales document (order, invoice).';
                    Visible = false;
                }
                field("Let. Line VAT Prod. Post. Gr."; "Let. Line VAT Prod. Post. Gr.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT posting group of line of sales advance letter.';
                }
                field("Let. Line VAT %"; "Let. Line VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT % of line of sales advance letter.';
                }
                field("Let. Line Description"; "Let. Line Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description of line of sales advance letter.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Unlink Current Line")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unlink Current Line';
                    Image = CancelLine;
                    ToolTip = 'Unlink current line';

                    trigger OnAction()
                    begin
                        PrepmtLinksMgtAdv.UnlinkCurrentLine(Rec, true);
                        UpdateSubform;
                    end;
                }
                action("Unlink All Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unlink All Lines';
                    Image = CancelAllLines;
                    ToolTip = 'Unlink all lines';

                    trigger OnAction()
                    begin
                        PrepmtLinksMgtAdv.UnlinkAll;
                        UpdateSubform;
                    end;
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(PrepmtLinksMgtAdv.OnFindRecord(Which, Rec));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        PrepmtLinksMgtAdv.OnModifyRecord(Rec);
        UpdateSubform;
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(PrepmtLinksMgtAdv.OnNextRecord(Steps, Rec));
    end;

    trigger OnOpenPage()
    var
        TempSalesAdvanceLetterHeader: Record "Sales Advance Letter Header" temporary;
        TempSalesAdvanceLetterLine: Record "Sales Advance Letter Line" temporary;
    begin
        InitLinking;
        PrepmtLinksMgtAdv.GetSalesLetters(TempSalesAdvanceLetterHeader, TempSalesAdvanceLetterLine);
        SalesLetterHeadAdvLink.SetSalesHeader(TempSalesHeader, TempSalesAdvanceLetterHeader);
        SalesLetterLineAdvLink.SetSalesHeader(TempSalesHeader, TempSalesAdvanceLetterLine);
        CurrPage.Caption := StrSubstNo(Text003Txt, CurrPage.Caption, TempSalesHeader."Document Type", TempSalesHeader."No.");
        PrepmtLinksMgtAdv.GetStatistics(DocLineNo, LetterNo, LetterLinesNo, NotLinkedLines,
          NotLinkedAmount, LinkedAmount, DocPrepmtAmount);
        CurrencyCode := TempSalesHeader."Currency Code";
        CurrPage.Update(false)
    end;

    var
        TempSalesHeader: Record "Sales Header" temporary;
        PrepmtLinksMgtAdv: Codeunit "Prepmt Links Mgt. Adv.";
        SalesLetterHeadAdvLink: Page "Sales Letter Head. - Adv.Link.";
        SalesLetterLineAdvLink: Page "Sales Letter Line - Adv.Link.";
        DocLineNo: Integer;
        LetterNo: Integer;
        LetterLinesNo: Integer;
        NotLinkedLines: Integer;
        NotLinkedAmount: Decimal;
        DocPrepmtAmount: Decimal;
        LinkedAmount: Decimal;
        ApplyByVATGroups: Boolean;
        ApplyByVATPerc: Boolean;
        ApplyAll: Boolean;
        CurrencyCode: Code[10];
        QtyType: Option " ",Invoicing,,Remaining;
        LinkingType: Option "Invoiced Amount",Amount;
        Text001Err: Label 'Linking Type must be Amount.';
        Text002Err: Label 'Linking Type must be Invoiced Amount.';
        Text003Txt: Label '%1 %2 %3', Comment = '%1=currpage.caption;%2=salesheader.documenttype;%3=salesheader.number';
        Text101Msg: Label 'Links saved.';

    [Scope('OnPrem')]
    procedure SetSalesDoc(DocType: Option " ","Order",Invoice; DocNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocType, DocNo);
        TempSalesHeader := SalesHeader;
        TempSalesHeader.Insert;
        CurrencyCode := SalesHeader."Currency Code";
    end;

    [Scope('OnPrem')]
    procedure UpdateSubform()
    var
        TempSalesAdvanceLetterHeader: Record "Sales Advance Letter Header" temporary;
        TempSalesAdvanceLetterLine: Record "Sales Advance Letter Line" temporary;
    begin
        if not (QtyType in [QtyType::Invoicing, QtyType::Remaining]) then
            exit;
        PrepmtLinksMgtAdv.GetSalesLetters(TempSalesAdvanceLetterHeader, TempSalesAdvanceLetterLine);
        Clear(SalesLetterHeadAdvLink);
        SalesLetterHeadAdvLink.SetLinkingType(LinkingType);
        SalesLetterHeadAdvLink.UpdateLetters(TempSalesAdvanceLetterHeader);
        Clear(SalesLetterLineAdvLink);
        SalesLetterLineAdvLink.SetLinkingType(LinkingType);
        SalesLetterLineAdvLink.UpdateLetters(TempSalesAdvanceLetterLine);
        PrepmtLinksMgtAdv.GetStatistics(DocLineNo, LetterNo, LetterLinesNo, NotLinkedLines,
          NotLinkedAmount, LinkedAmount, DocPrepmtAmount);
        CurrPage.Update(false)
    end;

    [Scope('OnPrem')]
    procedure WriteChanges()
    begin
        if PrepmtLinksMgtAdv.WriteChangesToDocument then
            Message(Text101Msg);
    end;

    [Scope('OnPrem')]
    procedure InitLinking()
    begin
        Clear(PrepmtLinksMgtAdv);

        PrepmtLinksMgtAdv.SetQtyType(QtyType);
        PrepmtLinksMgtAdv.SetLinkingType(LinkingType);
        if not (QtyType in [QtyType::Invoicing, QtyType::Remaining]) then
            exit;
        PrepmtLinksMgtAdv.SetSalesDoc(TempSalesHeader);
        PrepmtLinksMgtAdv.SetSalesLetters;
        PrepmtLinksMgtAdv.SetAdvLetterLineRelations;
        PrepmtLinksMgtAdv.CompleteAdvanceLetterRelations;
        PrepmtLinksMgtAdv.UpdLetterSemiFinishedAmounts(false, '');
    end;

    [Scope('OnPrem')]
    procedure DrilldownLetterHeaders()
    var
        TempSalesAdvanceLetterHeader: Record "Sales Advance Letter Header" temporary;
        TempAdvanceLinkBufferEntry: Record "Advance Link Buffer - Entry" temporary;
    begin
        SalesLetterHeadAdvLink.RunModal;
        if SalesLetterHeadAdvLink.IsAssigned then begin
            SalesLetterHeadAdvLink.GetSelectedRecords(TempSalesAdvanceLetterHeader);
            PrepmtLinksMgtAdv.FillAdvLnkBuffFromSalesLetHead(TempSalesAdvanceLetterHeader, TempAdvanceLinkBufferEntry);
            PrepmtLinksMgtAdv.SuggestAdvLetterLinking(TempAdvanceLinkBufferEntry,
              ApplyByVATGroups,
              ApplyByVATPerc,
              ApplyAll);
        end;
        UpdateSubform;
    end;

    [Scope('OnPrem')]
    procedure DrilldownLetterLines()
    var
        TempSalesAdvanceLetterLine: Record "Sales Advance Letter Line" temporary;
        TempAdvanceLinkBufferEntry: Record "Advance Link Buffer - Entry" temporary;
    begin
        SalesLetterLineAdvLink.RunModal;
        if SalesLetterLineAdvLink.IsAssigned then begin
            SalesLetterLineAdvLink.GetSelectedRecords(TempSalesAdvanceLetterLine);
            PrepmtLinksMgtAdv.FillAdvLnkBuffFromSalesLetLine(TempSalesAdvanceLetterLine, TempAdvanceLinkBufferEntry);
            PrepmtLinksMgtAdv.SuggestAdvLetterLinking(TempAdvanceLinkBufferEntry,
              ApplyByVATGroups,
              ApplyByVATPerc,
              ApplyAll);
        end;
        UpdateSubform;
    end;

    local procedure ChangeTypes()
    begin
        InitLinking;
        UpdateSubform;
    end;
}

