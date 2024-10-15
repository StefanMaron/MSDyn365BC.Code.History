#if not CLEAN19
page 31032 "Purch. Adv. Letter Link. Card"
{
    Caption = 'Purch. Adv. Letter Link. Card (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Adv. Letter Line Rel. Buffer";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

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
                    ToolTip = 'Specifies the number of line of purchase document (order, invoice).';
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
                        DrilldownLetterHeaders();
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
                        DrilldownLetterLines();
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
                    ToolTip = 'Specifies the amount of line of purchase document (order, invoice).';
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
                    ToolTip = 'Specifies the amount of line of purchase document (order, invoice).';

                    trigger OnValidate()
                    begin
                        ChangeTypes();
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
                        ChangeTypes();
                    end;
                }
            }
            repeater(Control1220013)
            {
                ShowCaption = false;
                field(Select; Select)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies selected sales line';

                    trigger OnValidate()
                    begin
                        PrepmtLinksMgtAdv.ChangeLineSelection("Doc Line No.", Select);
                        CurrPage.Update(false);
                    end;
                }
                field("Doc Line No."; Rec."Doc Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of line of purchase document (order, invoice).';
                }
                field("Doc. Line Description"; Rec."Doc. Line Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description of line of purchase document (order, invoice).';
                }
                field("Doc. Line VAT Prod. Post. Gr."; Rec."Doc. Line VAT Prod. Post. Gr.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT posting group of line of purchase document (order, invoice).';
                }
                field("Doc. Line VAT %"; Rec."Doc. Line VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT % of line of purchase document (order, invoice).';
                }
                field("Letter No."; Rec."Letter No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of letter.';
                }
                field("Letter Line No."; Rec."Letter Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies letter line number.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of line of purchase document (order, invoice).';

                    trigger OnValidate()
                    begin
                        if LinkingType = LinkingType::"Invoiced Amount" then
                            Error(Text001Err);
                    end;
                }
                field("Invoiced Amount"; Rec."Invoiced Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of line of purchase advance letter.';

                    trigger OnValidate()
                    begin
                        if LinkingType = LinkingType::Amount then
                            Error(Text002Err);
                    end;
                }
                field("Doc. Line Amount"; Rec."Doc. Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of line of purchase document (order, invoice).';
                    Visible = false;
                }
                field("Let. Line VAT Prod. Post. Gr."; Rec."Let. Line VAT Prod. Post. Gr.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT posting group of line of purchase advance letter.';
                }
                field("Let. Line VAT %"; Rec."Let. Line VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT % of line of purchase advance letter.';
                }
                field("Let. Line Description"; Rec."Let. Line Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description of line of purchase advance letter.';
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
                        UpdateSubForm();
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
                        PrepmtLinksMgtAdv.UnlinkAll();
                        UpdateSubForm();
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
        UpdateSubForm();
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(PrepmtLinksMgtAdv.OnNextRecord(Steps, Rec));
    end;

    trigger OnOpenPage()
    var
        TempPurchAdvanceLetterHeader: Record "Purch. Advance Letter Header" temporary;
        TempPurchAdvanceLetterLine: Record "Purch. Advance Letter Line" temporary;
    begin
        InitLinking();
        PrepmtLinksMgtAdv.GetPurchLetters(TempPurchAdvanceLetterHeader, TempPurchAdvanceLetterLine);
        PurchLetHeadAdvLink.SetPurchHeader(TempPurchHeader, TempPurchAdvanceLetterHeader);
        PurchLetterLineAdvLink.SetPurchHeader(TempPurchHeader, TempPurchAdvanceLetterLine);
        CurrPage.Caption := StrSubstNo(Text003Msg, CurrPage.Caption, TempPurchHeader."Document Type", TempPurchHeader."No.");
        PrepmtLinksMgtAdv.GetStatistics(DocLineNo, LetterNo, LetterLinesNo, NotLinkedLines,
          NotLinkedAmount, LinkedAmount, DocPrepmtAmount);
        CurrencyCode := TempPurchHeader."Currency Code";
        CurrPage.Update(false);
    end;

    var
        TempPurchHeader: Record "Purchase Header" temporary;
        PrepmtLinksMgtAdv: Codeunit "Prepmt Links Mgt. Adv.";
        PurchLetHeadAdvLink: Page "Purch.Let.Head. - Adv.Link.";
        PurchLetterLineAdvLink: Page "Purch. Letter Line - Adv.Link.";
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
        Text003Msg: Label '%1 %2 %3', Comment = '%1=currpage.caption;%2=purchheader.documenttype;%3=purchheader.documentnumber';
        Text101Msg: Label 'Links saved.';

    [Scope('OnPrem')]
    procedure SetPurchDoc(DocType: Option " ","Order",Invoice; DocNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Get(DocType, DocNo);
        TempPurchHeader := PurchHeader;
        TempPurchHeader.Insert();
        CurrencyCode := PurchHeader."Currency Code";
    end;

    [Scope('OnPrem')]
    procedure UpdateSubform()
    var
        TempPurchAdvanceLetterHeader: Record "Purch. Advance Letter Header" temporary;
        TempPurchAdvanceLetterLine: Record "Purch. Advance Letter Line" temporary;
    begin
        if not (QtyType in [QtyType::Invoicing, QtyType::Remaining]) then
            exit;
        PrepmtLinksMgtAdv.GetPurchLetters(TempPurchAdvanceLetterHeader, TempPurchAdvanceLetterLine);
        Clear(PurchLetHeadAdvLink);
        PurchLetHeadAdvLink.SetLinkingType(LinkingType);
        PurchLetHeadAdvLink.UpdateLetters(TempPurchAdvanceLetterHeader);
        Clear(PurchLetterLineAdvLink);
        PurchLetterLineAdvLink.SetLinkingType(LinkingType);
        PurchLetterLineAdvLink.UpdateLetters(TempPurchAdvanceLetterLine);
        PrepmtLinksMgtAdv.GetStatistics(DocLineNo, LetterNo, LetterLinesNo, NotLinkedLines,
          NotLinkedAmount, LinkedAmount, DocPrepmtAmount);
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure WriteChanges()
    begin
        if PrepmtLinksMgtAdv.WriteChangesToDocument() then
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
        PrepmtLinksMgtAdv.SetPurchDoc(TempPurchHeader);
        PrepmtLinksMgtAdv.SetPurchLetters();
        PrepmtLinksMgtAdv.SetAdvLetterLineRelations();
        PrepmtLinksMgtAdv.CompleteAdvanceLetterRelations();
        PrepmtLinksMgtAdv.UpdLetterSemiFinishedAmounts(false, '');
    end;

    [Scope('OnPrem')]
    procedure DrilldownLetterHeaders()
    var
        TempPurchAdvanceLetterHeader: Record "Purch. Advance Letter Header" temporary;
        TempAdvanceLinkBufferEntry: Record "Advance Link Buffer - Entry" temporary;
    begin
        PurchLetHeadAdvLink.RunModal();
        if PurchLetHeadAdvLink.IsAssigned() then begin
            PurchLetHeadAdvLink.GetSelectedRecords(TempPurchAdvanceLetterHeader);
            PrepmtLinksMgtAdv.FillAdvLnkBuffFromPurchLetHead(TempPurchAdvanceLetterHeader, TempAdvanceLinkBufferEntry);
            PrepmtLinksMgtAdv.SuggestAdvLetterLinking(TempAdvanceLinkBufferEntry,
              ApplyByVATGroups,
              ApplyByVATPerc,
              ApplyAll);
        end;
        UpdateSubForm();
    end;

    [Scope('OnPrem')]
    procedure DrilldownLetterLines()
    var
        TempPurchAdvanceLetterLine: Record "Purch. Advance Letter Line" temporary;
        TempAdvanceLinkBufferEntry: Record "Advance Link Buffer - Entry" temporary;
    begin
        PurchLetterLineAdvLink.RunModal();
        if PurchLetterLineAdvLink.IsAssigned() then begin
            PurchLetterLineAdvLink.GetSelectedRecords(TempPurchAdvanceLetterLine);
            PrepmtLinksMgtAdv.FillAdvLnkBuffFromPurchLetLine(TempPurchAdvanceLetterLine, TempAdvanceLinkBufferEntry);
            PrepmtLinksMgtAdv.SuggestAdvLetterLinking(TempAdvanceLinkBufferEntry,
              ApplyByVATGroups,
              ApplyByVATPerc,
              ApplyAll);
        end;
        UpdateSubForm();
    end;

    local procedure ChangeTypes()
    begin
        InitLinking();
        UpdateSubForm();
    end;
}
#endif
