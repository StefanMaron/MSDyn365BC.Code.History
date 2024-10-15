codeunit 31030 "Prepmt Links Mgt. Adv."
{

    trigger OnRun()
    begin
    end;

    var
        Currency: Record Currency;
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLineInv: Record "Sales Line" temporary;
        TempPurchHeader: Record "Purchase Header" temporary;
        TempPurchLine: Record "Purchase Line" temporary;
        TempPurchLineInv: Record "Purchase Line" temporary;
        TempAdvanceLetterLineRelation: Record "Advance Letter Line Relation" temporary;
        TempAdvLetterLineRelBuf: Record "Adv. Letter Line Rel. Buffer" temporary;
        TempSalesAdvanceLetterHeader: Record "Sales Advance Letter Header" temporary;
        TempSalesAdvanceLetterLine: Record "Sales Advance Letter Line" temporary;
        TempPurchAdvanceLetterHeader: Record "Purch. Advance Letter Header" temporary;
        TempPurchAdvanceLetterLine: Record "Purch. Advance Letter Line" temporary;
        Text001Err: Label 'There is nothing to Link.';
        Text002Err: Label 'There is no doc. line to link.';
        Type: Option Sale,Purchase;
        CVNo: Code[20];
        DocType: Option " ","Order",Invoice;
        DocNo: Code[20];
        QtyType: Option General,Invoicing,Shipping,Remaining;
        LinkingType: Option "Invoiced Amount",Amount;
        DocLineNo: Integer;
        LetterNo: Integer;
        LetterLinesNo: Integer;
        NotLinkedLines: Integer;
        NotLinkedAmount: Decimal;
        DocPrepmtAmount: Decimal;
        LinkedAmount: Decimal;
        Text003Err: Label 'You can not change amount without linked letter.';
        Text004Err: Label 'Amount can not be higher than remaining letter amount.';
        Text005Err: Label '%1 can not be lower than zero.';
        Text006Err: Label 'Current Line is not linked with any advance letter.';
        Text007Err: Label 'Document link has been changed by another user.';
        Text008Err: Label 'Letter line document linked inv. amount %1 %2 is greater than Invoiced Amount.', Comment = '%1=letter number;%2=letter Line number';
        Text009Err: Label 'Letter line document linked inv. amount %1 %2 is greater than Amount including VAT.', Comment = '%1=letter number;%2=letter Line number';

    [Scope('OnPrem')]
    procedure GetCurrency(CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(CurrencyCode);
    end;

    [Scope('OnPrem')]
    procedure SetQtyType(QtyTypeNew: Option " ",Invoicing,,Remaining)
    begin
        QtyType := QtyTypeNew;
    end;

    [Scope('OnPrem')]
    procedure SetLinkingType(LinkingTypeNew: Option "Invoiced Amount",Amount)
    begin
        LinkingType := LinkingTypeNew;
    end;

    [Scope('OnPrem')]
    procedure SetSalesDoc(SalesHeader: Record "Sales Header")
    begin
        Type := Type::Sale;
        DocType := SalesHeader."Document Type";
        DocNo := SalesHeader."No.";
        CVNo := SalesHeader."Bill-to Customer No.";
        if not (QtyType in [QtyType::Invoicing, QtyType::Remaining]) then
            exit;

        GetCurrency(SalesHeader."Currency Code");
        TempSalesHeader := SalesHeader;
        TempSalesHeader.Insert;

        TempSalesHeader.GetPostingLineImage(TempSalesLine, QtyType::General, false);
        case QtyType of
            QtyType::Remaining:
                TempSalesHeader.GetPostingLineImage(TempSalesLineInv, QtyType::Remaining, false);
            QtyType::Invoicing:
                TempSalesHeader.GetPostingLineImage(TempSalesLineInv, QtyType::Invoicing, false);
        end;

        TempSalesLine.SetRange("Prepmt. Line Amount", 0);
        TempSalesLine.DeleteAll;
        TempSalesLine.SetRange("Prepmt. Line Amount");
        if QtyType = QtyType::Invoicing then begin
            TempSalesLine.SetRange("Qty. to Invoice", 0);
            TempSalesLine.SetRange("Has Letter Line Relation", false);
            TempSalesLine.DeleteAll;
            TempSalesLine.SetRange("Qty. to Invoice");
            TempSalesLine.SetRange("Has Letter Line Relation");
        end;
    end;

    [Scope('OnPrem')]
    procedure SetPurchDoc(PurchHeader: Record "Purchase Header")
    begin
        Type := Type::Purchase;
        DocType := PurchHeader."Document Type";
        DocNo := PurchHeader."No.";
        CVNo := PurchHeader."Pay-to Vendor No.";
        if not (QtyType in [QtyType::Invoicing, QtyType::Remaining]) then
            exit;

        GetCurrency(PurchHeader."Currency Code");
        TempPurchHeader := PurchHeader;
        TempPurchHeader.Insert;

        TempPurchHeader.GetPostingLineImage(TempPurchLine, QtyType::General, false);
        case QtyType of
            QtyType::Remaining:
                TempPurchHeader.GetPostingLineImage(TempPurchLineInv, QtyType::Remaining, false);
            QtyType::Invoicing:
                TempPurchHeader.GetPostingLineImage(TempPurchLineInv, QtyType::Invoicing, false);
        end;

        TempPurchLine.SetRange("Prepmt. Line Amount", 0);
        TempPurchLine.DeleteAll;
        TempPurchLine.SetRange("Prepmt. Line Amount");
        if QtyType = QtyType::Invoicing then begin
            TempPurchLine.SetRange("Qty. to Invoice", 0);
            TempPurchLine.SetRange("Has Letter Line Relation", false);
            TempPurchLine.DeleteAll;
            TempPurchLine.SetRange("Qty. to Invoice");
            TempPurchLine.SetRange("Has Letter Line Relation");
        end;
    end;

    [Scope('OnPrem')]
    procedure SetSalesLetters()
    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        // Letters for linking
        SalesAdvanceLetterHeader.SetCurrentKey("Bill-to Customer No.", "Currency Code", Closed);
        SalesAdvanceLetterHeader.SetRange("Bill-to Customer No.", CVNo);
        SalesAdvanceLetterHeader.SetRange("Currency Code", Currency.Code);
        SalesAdvanceLetterHeader.SetRange(Closed, false);
        if LinkingType = LinkingType::"Invoiced Amount" then
            SalesAdvanceLetterHeader.SetFilter("Amount Invoiced", '<>0')
        else
            SalesAdvanceLetterHeader.SetFilter("Amount Including VAT", '<>0');
        if SalesAdvanceLetterHeader.FindSet then
            repeat
                TempSalesAdvanceLetterHeader := SalesAdvanceLetterHeader;
                TempSalesAdvanceLetterHeader."Semifinished Linked Amount" := 0;
                TempSalesAdvanceLetterHeader.Insert;
                TempSalesAdvanceLetterHeader.TestField(Closed, false);
                LetterNo := LetterNo + 1;
                SalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
                if LinkingType = LinkingType::"Invoiced Amount" then
                    SalesAdvanceLetterLine.SetFilter("Amount Invoiced", '<>0')
                else
                    SalesAdvanceLetterLine.SetFilter("Amount Including VAT", '<>0');
                if SalesAdvanceLetterLine.FindSet then
                    repeat
                        TempSalesAdvanceLetterLine := SalesAdvanceLetterLine;
                        TempSalesAdvanceLetterLine."Semifinished Linked Amount" := 0;
                        TempSalesAdvanceLetterLine.Insert;
                        LetterLinesNo := LetterLinesNo + 1;
                    until SalesAdvanceLetterLine.Next = 0;
            until SalesAdvanceLetterHeader.Next = 0;

        // Linked Letters
        SalesAdvanceLetterHeader.Reset;
        SalesAdvanceLetterLine.Reset;
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
        AdvanceLetterLineRelation.SetRange("Document Type", TempSalesHeader."Document Type");
        AdvanceLetterLineRelation.SetRange("Document No.", TempSalesHeader."No.");
        if AdvanceLetterLineRelation.FindSet then
            repeat
                if TempSalesLine.Get(AdvanceLetterLineRelation."Document Type",
                     AdvanceLetterLineRelation."Document No.",
                     AdvanceLetterLineRelation."Document Line No.")
                then begin
                    if not TempSalesAdvanceLetterHeader.Get(AdvanceLetterLineRelation."Letter No.") then begin
                        SalesAdvanceLetterHeader.Get(AdvanceLetterLineRelation."Letter No.");
                        TempSalesAdvanceLetterHeader := SalesAdvanceLetterHeader;
                        TempSalesAdvanceLetterHeader.Insert;
                        LetterNo := LetterNo + 1;
                    end;
                    if not TempSalesAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.",
                         AdvanceLetterLineRelation."Letter Line No.")
                    then begin
                        SalesAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                        TempSalesAdvanceLetterLine := SalesAdvanceLetterLine;
                        TempSalesAdvanceLetterLine.Insert;
                        LetterLinesNo := LetterLinesNo + 1;
                    end;
                end;
            until AdvanceLetterLineRelation.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure SetPurchLetters()
    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        // Letters for linking
        PurchAdvanceLetterHeader.SetCurrentKey("Pay-to Vendor No.", "Currency Code", Closed);
        PurchAdvanceLetterHeader.SetRange("Pay-to Vendor No.", CVNo);
        PurchAdvanceLetterHeader.SetRange("Currency Code", Currency.Code);
        PurchAdvanceLetterHeader.SetRange(Closed, false);
        if LinkingType = LinkingType::"Invoiced Amount" then
            PurchAdvanceLetterHeader.SetFilter("Amount Invoiced", '<>0')
        else
            PurchAdvanceLetterHeader.SetFilter("Amount Including VAT", '<>0');
        if PurchAdvanceLetterHeader.FindSet then
            repeat
                TempPurchAdvanceLetterHeader := PurchAdvanceLetterHeader;
                TempPurchAdvanceLetterHeader."Semifinished Linked Amount" := 0;
                TempPurchAdvanceLetterHeader.Insert;
                TempPurchAdvanceLetterHeader.TestField(Closed, false);
                LetterNo := LetterNo + 1;
                PurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
                if LinkingType = LinkingType::"Invoiced Amount" then
                    PurchAdvanceLetterLine.SetFilter("Amount Invoiced", '<>0')
                else
                    PurchAdvanceLetterLine.SetFilter("Amount Including VAT", '<>0');
                if PurchAdvanceLetterLine.FindSet then
                    repeat
                        TempPurchAdvanceLetterLine := PurchAdvanceLetterLine;
                        TempPurchAdvanceLetterLine."Semifinished Linked Amount" := 0;
                        TempPurchAdvanceLetterLine.Insert;
                        LetterLinesNo := LetterLinesNo + 1;
                    until PurchAdvanceLetterLine.Next = 0;
            until PurchAdvanceLetterHeader.Next = 0;

        // Linked Letters
        PurchAdvanceLetterHeader.Reset;
        PurchAdvanceLetterLine.Reset;
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
        AdvanceLetterLineRelation.SetRange("Document Type", TempPurchHeader."Document Type");
        AdvanceLetterLineRelation.SetRange("Document No.", TempPurchHeader."No.");
        if AdvanceLetterLineRelation.FindSet then
            repeat
                if TempPurchLine.Get(AdvanceLetterLineRelation."Document Type",
                     AdvanceLetterLineRelation."Document No.",
                     AdvanceLetterLineRelation."Document Line No.")
                then begin
                    if not TempPurchAdvanceLetterHeader.Get(AdvanceLetterLineRelation."Letter No.") then begin
                        PurchAdvanceLetterHeader.Get(AdvanceLetterLineRelation."Letter No.");
                        TempPurchAdvanceLetterHeader := PurchAdvanceLetterHeader;
                        TempPurchAdvanceLetterHeader.Insert;
                        LetterNo := LetterNo + 1;
                    end;
                    if not TempPurchAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.",
                         AdvanceLetterLineRelation."Letter Line No.")
                    then begin
                        PurchAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                        TempPurchAdvanceLetterLine := PurchAdvanceLetterLine;
                        TempPurchAdvanceLetterLine.Insert;
                        LetterLinesNo := LetterLinesNo + 1;
                    end;
                end;
            until AdvanceLetterLineRelation.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure SetAdvLetterLineRelations()
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        LastDocLineNo: Integer;
        LinkedAmountTmp: Decimal;
    begin
        AdvanceLetterLineRelation.SetRange(Type, Type);
        AdvanceLetterLineRelation.SetRange("Document No.", DocNo);
        AdvanceLetterLineRelation.SetRange("Document Type", DocType);
        if AdvanceLetterLineRelation.FindSet then
            repeat
                TempAdvanceLetterLineRelation := AdvanceLetterLineRelation;
                TempAdvanceLetterLineRelation.Insert;
                TempAdvLetterLineRelBuf.Init;
                TempAdvLetterLineRelBuf."Doc Line No." := AdvanceLetterLineRelation."Document Line No.";
                TempAdvLetterLineRelBuf."Letter No." := AdvanceLetterLineRelation."Letter No.";
                TempAdvLetterLineRelBuf."Letter Line No." := AdvanceLetterLineRelation."Letter Line No.";
                TempAdvLetterLineRelBuf.Amount := AdvanceLetterLineRelation.Amount -
                  AdvanceLetterLineRelation."Deducted Amount";
                TempAdvLetterLineRelBuf."Invoiced Amount" := AdvanceLetterLineRelation."Invoiced Amount" -
                  AdvanceLetterLineRelation."Deducted Amount";
                TempAdvLetterLineRelBuf."Document Type" := AdvanceLetterLineRelation."Document Type";
                if TempAdvLetterLineRelBuf.Amount <> 0 then begin
                    if LastDocLineNo <> AdvanceLetterLineRelation."Document Line No." then begin
                        LastDocLineNo := AdvanceLetterLineRelation."Document Line No.";
                        LinkedAmountTmp := TempAdvLetterLineRelBuf.Amount;
                    end else
                        LinkedAmountTmp += TempAdvLetterLineRelBuf.Amount;
                    FillDocFields(TempAdvLetterLineRelBuf);
                    FillLetterFields(TempAdvLetterLineRelBuf);
                    if TempAdvLetterLineRelBuf."Doc. Line Amount" < LinkedAmountTmp then
                        AdvanceLetterLineRelation.Amount -= TempAdvLetterLineRelBuf."Doc. Line Amount" - LinkedAmountTmp;
                    TempAdvLetterLineRelBuf.Insert;
                    LinkedAmount += AdvanceLetterLineRelation.Amount - AdvanceLetterLineRelation."Deducted Amount";
                end;
            until AdvanceLetterLineRelation.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure FillDocFields(var AdvLetterLineRelBuf: Record "Adv. Letter Line Rel. Buffer")
    begin
        if Type = Type::Sale then begin
            TempSalesLine.Get(TempSalesHeader."Document Type",
              TempSalesHeader."No.",
              AdvLetterLineRelBuf."Doc Line No.");
            TempSalesLineInv.Get(TempSalesHeader."Document Type",
              TempSalesHeader."No.",
              AdvLetterLineRelBuf."Doc Line No.");
            TempSalesLine.CalcFields("Adv.Letter Linked Ded. Amount");
            AdvLetterLineRelBuf."Doc. Line VAT Bus. Post. Gr." := TempSalesLine."VAT Bus. Posting Group";
            AdvLetterLineRelBuf."Doc. Line VAT Prod. Post. Gr." := TempSalesLine."VAT Prod. Posting Group";
            AdvLetterLineRelBuf."Doc. Line VAT %" := TempSalesLine."VAT %";
            AdvLetterLineRelBuf."Doc. Line Description" := TempSalesLine.Description;
            if TempSalesHeader."Prices Including VAT" then
                AdvLetterLineRelBuf."Doc. Line Amount" := TempSalesLine."Prepmt. Line Amount"
            else
                AdvLetterLineRelBuf."Doc. Line Amount" :=
                  TempSalesLine."Prepmt. Line Amount" * (1 + TempSalesLine."VAT %" / 100);
            AdvLetterLineRelBuf."Doc. Line Amount" -= TempSalesLine."Adv.Letter Linked Ded. Amount";
            if QtyType = QtyType::Invoicing then
                TempAdvLetterLineRelBuf."Doc. Line Amount" := TempAdvLetterLineRelBuf."Doc. Line Amount" *
                  TempSalesLine."Qty. to Invoice" / (TempSalesLine.Quantity - TempSalesLine."Quantity Invoiced");
            if TempSalesLineInv."Amount Including VAT" < TempAdvLetterLineRelBuf."Doc. Line Amount" then
                TempAdvLetterLineRelBuf."Doc. Line Amount" := TempSalesLineInv."Amount Including VAT";
            TempAdvLetterLineRelBuf."Doc. Line Amount" :=
              Round(TempAdvLetterLineRelBuf."Doc. Line Amount", Currency."Amount Rounding Precision");
            if TempSalesLineInv."Amount Including VAT" > TempAdvLetterLineRelBuf."Doc. Line Amount" then
                if TempSalesLine."Adjust Prepmt. Relation" and
                   (TempSalesLineInv."Amount Including VAT" <=
                    TempAdvLetterLineRelBuf."Doc. Line Amount" + Currency."Amount Rounding Precision")
                then
                    TempAdvLetterLineRelBuf."Doc. Line Amount" := TempSalesLineInv."Amount Including VAT";
        end else begin
            TempPurchLine.Get(TempPurchHeader."Document Type",
              TempPurchHeader."No.",
              AdvLetterLineRelBuf."Doc Line No.");
            TempPurchLineInv.Get(TempPurchHeader."Document Type",
              TempPurchHeader."No.",
              AdvLetterLineRelBuf."Doc Line No.");
            TempPurchLine.CalcFields("Adv.Letter Linked Ded. Amount");
            AdvLetterLineRelBuf."Doc. Line VAT Bus. Post. Gr." := TempPurchLine."VAT Bus. Posting Group";
            AdvLetterLineRelBuf."Doc. Line VAT Prod. Post. Gr." := TempPurchLine."VAT Prod. Posting Group";
            AdvLetterLineRelBuf."Doc. Line VAT %" := TempPurchLine."VAT %";
            AdvLetterLineRelBuf."Doc. Line Description" := TempPurchLine.Description;
            if TempPurchHeader."Prices Including VAT" then
                AdvLetterLineRelBuf."Doc. Line Amount" := TempPurchLine."Prepmt. Line Amount"
            else
                AdvLetterLineRelBuf."Doc. Line Amount" :=
                  Round(TempPurchLine."Prepmt. Line Amount" * (1 + TempPurchLine."VAT %" / 100));
            AdvLetterLineRelBuf."Doc. Line Amount" -= TempPurchLine."Adv.Letter Linked Ded. Amount";
            if QtyType = QtyType::Invoicing then
                TempAdvLetterLineRelBuf."Doc. Line Amount" := TempAdvLetterLineRelBuf."Doc. Line Amount" *
                  TempPurchLine."Qty. to Invoice" / (TempPurchLine.Quantity - TempPurchLine."Quantity Invoiced");
            if TempPurchLineInv."Amount Including VAT" < TempAdvLetterLineRelBuf."Doc. Line Amount" then
                TempAdvLetterLineRelBuf."Doc. Line Amount" := TempPurchLineInv."Amount Including VAT";
            TempAdvLetterLineRelBuf."Doc. Line Amount" :=
              Round(TempAdvLetterLineRelBuf."Doc. Line Amount", Currency."Amount Rounding Precision");
            if TempPurchLineInv."Amount Including VAT" > TempAdvLetterLineRelBuf."Doc. Line Amount" then
                if TempPurchLine."Adjust Prepmt. Relation" and
                   (TempPurchLineInv."Amount Including VAT" <=
                    TempAdvLetterLineRelBuf."Doc. Line Amount" + Currency."Amount Rounding Precision")
                then
                    TempAdvLetterLineRelBuf."Doc. Line Amount" := TempPurchLineInv."Amount Including VAT";
        end;
    end;

    [Scope('OnPrem')]
    procedure FillLetterFields(var AdvLetterLineRelBuf: Record "Adv. Letter Line Rel. Buffer")
    begin
        if Type = Type::Sale then begin
            TempSalesAdvanceLetterLine.Get(AdvLetterLineRelBuf."Letter No.",
              AdvLetterLineRelBuf."Letter Line No.");
            AdvLetterLineRelBuf."Let. Line VAT Bus. Post. Gr." := TempSalesAdvanceLetterLine."VAT Bus. Posting Group";
            AdvLetterLineRelBuf."Let. Line VAT Prod. Post. Gr." := TempSalesAdvanceLetterLine."VAT Prod. Posting Group";
            AdvLetterLineRelBuf."Let. Line VAT %" := TempSalesAdvanceLetterLine."VAT %";
            AdvLetterLineRelBuf."Let. Line Description" := TempSalesAdvanceLetterLine.Description;
        end else begin
            TempPurchAdvanceLetterLine.Get(AdvLetterLineRelBuf."Letter No.",
              AdvLetterLineRelBuf."Letter Line No.");
            AdvLetterLineRelBuf."Let. Line VAT Bus. Post. Gr." := TempPurchAdvanceLetterLine."VAT Bus. Posting Group";
            AdvLetterLineRelBuf."Let. Line VAT Prod. Post. Gr." := TempPurchAdvanceLetterLine."VAT Prod. Posting Group";
            AdvLetterLineRelBuf."Let. Line VAT %" := TempPurchAdvanceLetterLine."VAT %";
            AdvLetterLineRelBuf."Let. Line Description" := TempPurchAdvanceLetterLine.Description;
        end;
    end;

    [Scope('OnPrem')]
    procedure CompleteAdvanceLetterRelations()
    var
        Amount2: Decimal;
        InvAmount: Decimal;
        DocLineAmount: Decimal;
    begin
        TempAdvLetterLineRelBuf.Reset;
        if Type = Type::Sale then begin
            if TempSalesLine.FindSet then
                repeat
                    if TempSalesLine.Quantity <> TempSalesLine."Quantity Invoiced" then begin
                        TempSalesLine.CalcFields("Adv.Letter Linked Ded. Amount");
                        TempSalesLineInv.Get(TempSalesHeader."Document Type",
                          TempSalesHeader."No.",
                          TempSalesLine."Line No.");
                        InvAmount := 0;
                        Amount2 := 0;
                        TempAdvLetterLineRelBuf.SetRange("Doc Line No.", TempSalesLine."Line No.");
                        if TempAdvLetterLineRelBuf.FindSet then
                            repeat
                                InvAmount += TempAdvLetterLineRelBuf."Invoiced Amount";
                                Amount2 += TempAdvLetterLineRelBuf.Amount;
                            until TempAdvLetterLineRelBuf.Next = 0;
                        if TempSalesHeader."Prices Including VAT" then
                            DocLineAmount := TempSalesLine."Prepmt. Line Amount"
                        else
                            DocLineAmount := TempSalesLine."Prepmt. Line Amount" * (1 + TempSalesLine."VAT %" / 100);
                        DocLineAmount -= TempSalesLine."Adv.Letter Linked Ded. Amount";
                        if QtyType = QtyType::Invoicing then
                            DocLineAmount := DocLineAmount *
                              TempSalesLine."Qty. to Invoice" / (TempSalesLine.Quantity - TempSalesLine."Quantity Invoiced");
                        if TempSalesLineInv."Amount Including VAT" < DocLineAmount then
                            DocLineAmount := TempSalesLineInv."Amount Including VAT";
                        DocLineAmount := Round(DocLineAmount, Currency."Amount Rounding Precision");
                        if TempSalesLineInv."Amount Including VAT" > DocLineAmount then
                            if TempSalesLine."Adjust Prepmt. Relation" and
                               (TempSalesLineInv."Amount Including VAT" <= DocLineAmount + Currency."Amount Rounding Precision")
                            then
                                DocLineAmount := TempSalesLineInv."Amount Including VAT";
                        DocLineNo := DocLineNo + 1;
                        DocPrepmtAmount += DocLineAmount;
                        if DocLineAmount > Amount2 then begin
                            TempAdvLetterLineRelBuf.Init;
                            TempAdvLetterLineRelBuf."Doc Line No." := TempSalesLine."Line No.";
                            TempAdvLetterLineRelBuf."Letter No." := '';
                            TempAdvLetterLineRelBuf."Letter Line No." := 0;
                            TempAdvLetterLineRelBuf.Amount := DocLineAmount - Amount2;
                            TempAdvLetterLineRelBuf."Document Type" := DocType;
                            FillDocFields(TempAdvLetterLineRelBuf);
                            TempAdvLetterLineRelBuf.Insert;
                            NotLinkedLines := NotLinkedLines + 1;
                            NotLinkedAmount += TempAdvLetterLineRelBuf.Amount;
                        end;
                    end;
                until TempSalesLine.Next = 0;
        end else begin
            if TempPurchLine.FindSet then
                repeat
                    if TempPurchLine.Quantity <> TempPurchLine."Quantity Invoiced" then begin
                        TempPurchLine.CalcFields("Adv.Letter Linked Ded. Amount");
                        TempPurchLineInv.Get(TempPurchHeader."Document Type",
                          TempPurchHeader."No.",
                          TempPurchLine."Line No.");
                        InvAmount := 0;
                        Amount2 := 0;
                        TempAdvLetterLineRelBuf.SetRange("Doc Line No.", TempPurchLine."Line No.");
                        if TempAdvLetterLineRelBuf.FindSet then
                            repeat
                                InvAmount += TempAdvLetterLineRelBuf."Invoiced Amount";
                                Amount2 += TempAdvLetterLineRelBuf.Amount;
                            until TempAdvLetterLineRelBuf.Next = 0;
                        if TempPurchHeader."Prices Including VAT" then
                            DocLineAmount := TempPurchLine."Prepmt. Line Amount"
                        else
                            DocLineAmount := Round(TempPurchLine."Prepmt. Line Amount" * (1 + TempPurchLine."VAT %" / 100));
                        DocLineAmount -= TempPurchLine."Adv.Letter Linked Ded. Amount";
                        if QtyType = QtyType::Invoicing then
                            DocLineAmount := DocLineAmount *
                              TempPurchLine."Qty. to Invoice" / (TempPurchLine.Quantity - TempPurchLine."Quantity Invoiced");
                        if TempPurchLineInv."Amount Including VAT" < DocLineAmount then
                            DocLineAmount := TempPurchLineInv."Amount Including VAT";
                        DocLineAmount := Round(DocLineAmount, Currency."Amount Rounding Precision");
                        if TempPurchLineInv."Amount Including VAT" > DocLineAmount then
                            if TempPurchLine."Adjust Prepmt. Relation" and
                               (TempPurchLineInv."Amount Including VAT" <= DocLineAmount + Currency."Amount Rounding Precision")
                            then
                                DocLineAmount := TempPurchLineInv."Amount Including VAT";
                        DocLineNo := DocLineNo + 1;
                        DocPrepmtAmount += DocLineAmount;
                        if DocLineAmount > InvAmount then begin
                            TempAdvLetterLineRelBuf.Init;
                            TempAdvLetterLineRelBuf."Doc Line No." := TempPurchLine."Line No.";
                            TempAdvLetterLineRelBuf."Letter No." := '';
                            TempAdvLetterLineRelBuf."Letter Line No." := 0;
                            TempAdvLetterLineRelBuf.Amount := DocLineAmount - InvAmount;
                            TempAdvLetterLineRelBuf."Document Type" := DocType;
                            FillDocFields(TempAdvLetterLineRelBuf);
                            TempAdvLetterLineRelBuf.Insert;
                            NotLinkedLines := NotLinkedLines + 1;
                            NotLinkedAmount += TempAdvLetterLineRelBuf.Amount;
                        end;
                    end;
                until TempPurchLine.Next = 0;
        end;
        TempAdvLetterLineRelBuf.Reset;
    end;

    [Scope('OnPrem')]
    procedure GetSalesLetters(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; var SalesAdvanceLetterLine: Record "Sales Advance Letter Line")
    begin
        TempAdvLetterLineRelBuf.Reset;
        if TempSalesAdvanceLetterHeader.FindSet then
            repeat
                SalesAdvanceLetterHeader := TempSalesAdvanceLetterHeader;
                SalesAdvanceLetterHeader.Insert;
            until TempSalesAdvanceLetterHeader.Next = 0;
        if TempSalesAdvanceLetterLine.FindSet then
            repeat
                SalesAdvanceLetterLine := TempSalesAdvanceLetterLine;
                SalesAdvanceLetterLine.Insert;
            until TempSalesAdvanceLetterLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure GetPurchLetters(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line")
    begin
        TempAdvLetterLineRelBuf.Reset;
        if TempPurchAdvanceLetterHeader.FindSet then
            repeat
                PurchAdvanceLetterHeader := TempPurchAdvanceLetterHeader;
                PurchAdvanceLetterHeader.Insert;
            until TempPurchAdvanceLetterHeader.Next = 0;
        if TempPurchAdvanceLetterLine.FindSet then
            repeat
                PurchAdvanceLetterLine := TempPurchAdvanceLetterLine;
                PurchAdvanceLetterLine.Insert;
            until TempPurchAdvanceLetterLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure GetStatistics(var DocLineNoNew: Integer; var LetterNoNew: Integer; var LetterLinesNoNew: Integer; var NotLinkedLinesNew: Integer; var NotLinkedAmountNew: Decimal; var LinkedAmountNew: Decimal; var DocPrepmtAmountNew: Decimal)
    begin
        DocLineNoNew := DocLineNo;
        LetterNoNew := LetterNo;
        LetterLinesNoNew := LetterLinesNo;
        NotLinkedLinesNew := NotLinkedLines;
        NotLinkedAmountNew := NotLinkedAmount;
        LinkedAmountNew := LinkedAmount;
        DocPrepmtAmountNew := DocPrepmtAmount;
    end;

    [Scope('OnPrem')]
    procedure OnFindRecord(WhichText: Text[1024]; var AdvLetterLineRefBuf: Record "Adv. Letter Line Rel. Buffer"): Boolean
    begin
        TempAdvLetterLineRelBuf.Copy(AdvLetterLineRefBuf);
        if TempAdvLetterLineRelBuf.Find(WhichText) then begin
            AdvLetterLineRefBuf := TempAdvLetterLineRelBuf;
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure OnNextRecord(Steps: Integer; var AdvLetterLineRefBuf: Record "Adv. Letter Line Rel. Buffer"): Integer
    var
        ResultSteps: Integer;
    begin
        TempAdvLetterLineRelBuf.Copy(AdvLetterLineRefBuf);
        ResultSteps := TempAdvLetterLineRelBuf.Next(Steps);
        if ResultSteps <> 0 then
            AdvLetterLineRefBuf := TempAdvLetterLineRelBuf;
        exit(ResultSteps);
    end;

    [Scope('OnPrem')]
    procedure OnModifyRecord(var AdvLetterLineRefBuf: Record "Adv. Letter Line Rel. Buffer"): Boolean
    var
        FreeInvAmount: Decimal;
        FreeAmount: Decimal;
        Diference: Decimal;
        InvDiference: Decimal;
    begin
        TempAdvLetterLineRelBuf.Get(AdvLetterLineRefBuf."Doc Line No.", AdvLetterLineRefBuf."Letter No.",
          AdvLetterLineRefBuf."Letter Line No.");
        if LinkingType = LinkingType::"Invoiced Amount" then begin
            if TempAdvLetterLineRelBuf."Invoiced Amount" = AdvLetterLineRefBuf."Invoiced Amount" then
                exit(false);

            InvDiference := AdvLetterLineRefBuf."Invoiced Amount" - TempAdvLetterLineRelBuf."Invoiced Amount";
            Diference := InvDiference;
            if AdvLetterLineRefBuf."Invoiced Amount" < 0 then
                Error(Text005Err, AdvLetterLineRefBuf.FieldCaption("Invoiced Amount"));
        end else begin
            if TempAdvLetterLineRelBuf.Amount = AdvLetterLineRefBuf.Amount then
                exit(false);

            Diference := AdvLetterLineRefBuf.Amount - TempAdvLetterLineRelBuf.Amount;
            if AdvLetterLineRefBuf."Invoiced Amount" > AdvLetterLineRefBuf.Amount then
                InvDiference := AdvLetterLineRefBuf.Amount - AdvLetterLineRefBuf."Invoiced Amount";
            if AdvLetterLineRefBuf.Amount < 0 then
                Error(Text005Err, AdvLetterLineRefBuf.FieldCaption(Amount));
        end;
        if AdvLetterLineRefBuf."Letter No." = '' then begin
            AdvLetterLineRefBuf := TempAdvLetterLineRelBuf;
            Error(Text003Err);
        end;
        case Type of
            Type::Sale:
                begin
                    TempSalesAdvanceLetterLine.Get(AdvLetterLineRefBuf."Letter No.", AdvLetterLineRefBuf."Letter Line No.");
                    TempSalesAdvanceLetterLine.SetFilter("Doc. No. Filter", '<%1|>%1', DocNo);
                    TempSalesAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount",
                      "Document Linked Ded. Amount");
                    FreeAmount := TempSalesAdvanceLetterLine."Amount Including VAT" -
                      TempSalesAdvanceLetterLine."Document Linked Amount" -
                      TempSalesAdvanceLetterLine."Semifinished Linked Amount" -
                      TempSalesAdvanceLetterLine."Amount Deducted" +
                      TempSalesAdvanceLetterLine."Document Linked Ded. Amount";
                    FreeInvAmount := TempSalesAdvanceLetterLine."Amount Invoiced" -
                      TempSalesAdvanceLetterLine."Document Linked Inv. Amount" -
                      TempSalesAdvanceLetterLine."Semifinished Linked Amount" -
                      TempSalesAdvanceLetterLine."Amount Deducted" +
                      TempSalesAdvanceLetterLine."Document Linked Ded. Amount";
                    if (LinkingType = LinkingType::"Invoiced Amount") and (FreeAmount > FreeInvAmount) then
                        FreeAmount := FreeInvAmount;
                    if (Diference > 0) and (Diference > FreeAmount) then
                        Error(Text004Err);

                    TempAdvLetterLineRelBuf."Invoiced Amount" += InvDiference;
                    TempAdvLetterLineRelBuf.Amount += Diference;
                    if TempAdvLetterLineRelBuf.Amount = 0 then
                        TempAdvLetterLineRelBuf.Delete
                    else
                        TempAdvLetterLineRelBuf.Modify;
                    if TempAdvLetterLineRelBuf.Get(AdvLetterLineRefBuf."Doc Line No.", '', 0) then begin
                        TempAdvLetterLineRelBuf.Amount -= Diference;
                        if TempAdvLetterLineRelBuf.Amount = 0 then begin
                            TempAdvLetterLineRelBuf.Delete;
                            NotLinkedLines := NotLinkedLines - 1;
                        end else
                            TempAdvLetterLineRelBuf.Modify;
                    end else begin
                        TempAdvLetterLineRelBuf.Init;
                        TempAdvLetterLineRelBuf."Doc Line No." := AdvLetterLineRefBuf."Doc Line No.";
                        TempAdvLetterLineRelBuf."Letter No." := '';
                        TempAdvLetterLineRelBuf."Letter Line No." := 0;
                        TempAdvLetterLineRelBuf.Amount := -Diference;
                        TempAdvLetterLineRelBuf."Document Type" := AdvLetterLineRefBuf."Document Type";
                        TempAdvLetterLineRelBuf."Doc. Line VAT Bus. Post. Gr." := AdvLetterLineRefBuf."Doc. Line VAT Bus. Post. Gr.";
                        TempAdvLetterLineRelBuf."Doc. Line VAT Prod. Post. Gr." := AdvLetterLineRefBuf."Doc. Line VAT Prod. Post. Gr.";
                        TempAdvLetterLineRelBuf."Doc. Line VAT %" := AdvLetterLineRefBuf."Doc. Line VAT %";
                        TempAdvLetterLineRelBuf."Doc. Line Description" := AdvLetterLineRefBuf."Doc. Line Description";
                        TempAdvLetterLineRelBuf."Doc. Line Amount" := AdvLetterLineRefBuf."Doc. Line Amount";
                        if Diference <> 0 then begin
                            TempAdvLetterLineRelBuf.Insert;
                            NotLinkedLines := NotLinkedLines + 1;
                        end;
                        TempAdvLetterLineRelBuf.Reset;
                    end;
                    NotLinkedAmount -= Diference;
                    LinkedAmount += Diference;
                end;
            Type::Purchase:
                begin
                    TempPurchAdvanceLetterLine.Get(AdvLetterLineRefBuf."Letter No.", AdvLetterLineRefBuf."Letter Line No.");
                    TempPurchAdvanceLetterLine.SetFilter("Doc. No. Filter", '<%1|>%1', DocNo);
                    TempPurchAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount",
                      "Document Linked Ded. Amount");
                    FreeAmount := TempPurchAdvanceLetterLine."Amount Including VAT" -
                      TempPurchAdvanceLetterLine."Document Linked Amount" -
                      TempPurchAdvanceLetterLine."Semifinished Linked Amount" -
                      TempPurchAdvanceLetterLine."Amount Deducted" +
                      TempPurchAdvanceLetterLine."Document Linked Ded. Amount";
                    FreeInvAmount := TempPurchAdvanceLetterLine."Amount Invoiced" -
                      TempPurchAdvanceLetterLine."Document Linked Inv. Amount" -
                      TempPurchAdvanceLetterLine."Semifinished Linked Amount" -
                      TempPurchAdvanceLetterLine."Amount Deducted" +
                      TempPurchAdvanceLetterLine."Document Linked Ded. Amount";
                    if (LinkingType = LinkingType::"Invoiced Amount") and (FreeAmount > FreeInvAmount) then
                        FreeAmount := FreeInvAmount;
                    if (Diference > 0) and (Diference > FreeAmount) then
                        Error(Text004Err);

                    TempAdvLetterLineRelBuf."Invoiced Amount" += InvDiference;
                    TempAdvLetterLineRelBuf.Amount += Diference;
                    if TempAdvLetterLineRelBuf.Amount = 0 then
                        TempAdvLetterLineRelBuf.Delete
                    else
                        TempAdvLetterLineRelBuf.Modify;
                    if TempAdvLetterLineRelBuf.Get(AdvLetterLineRefBuf."Doc Line No.", '', 0) then begin
                        TempAdvLetterLineRelBuf.Amount -= Diference;
                        if TempAdvLetterLineRelBuf.Amount = 0 then begin
                            TempAdvLetterLineRelBuf.Delete;
                            NotLinkedLines := NotLinkedLines - 1;
                        end else
                            TempAdvLetterLineRelBuf.Modify;
                    end else begin
                        TempAdvLetterLineRelBuf.Init;
                        TempAdvLetterLineRelBuf."Doc Line No." := AdvLetterLineRefBuf."Doc Line No.";
                        TempAdvLetterLineRelBuf."Letter No." := '';
                        TempAdvLetterLineRelBuf."Letter Line No." := 0;
                        TempAdvLetterLineRelBuf.Amount := -Diference;
                        TempAdvLetterLineRelBuf."Document Type" := AdvLetterLineRefBuf."Document Type";
                        TempAdvLetterLineRelBuf."Doc. Line VAT Bus. Post. Gr." := AdvLetterLineRefBuf."Doc. Line VAT Bus. Post. Gr.";
                        TempAdvLetterLineRelBuf."Doc. Line VAT Prod. Post. Gr." := AdvLetterLineRefBuf."Doc. Line VAT Prod. Post. Gr.";
                        TempAdvLetterLineRelBuf."Doc. Line VAT %" := AdvLetterLineRefBuf."Doc. Line VAT %";
                        TempAdvLetterLineRelBuf."Doc. Line Description" := AdvLetterLineRefBuf."Doc. Line Description";
                        TempAdvLetterLineRelBuf."Doc. Line Amount" := AdvLetterLineRefBuf."Doc. Line Amount";
                        if Diference <> 0 then begin
                            TempAdvLetterLineRelBuf.Insert;
                            NotLinkedLines := NotLinkedLines + 1;
                        end;
                        TempAdvLetterLineRelBuf.Reset;
                    end;
                    NotLinkedAmount -= Diference;
                    LinkedAmount += Diference;
                end;
        end;
        UpdLetterSemiFinishedAmounts(true, AdvLetterLineRefBuf."Letter No.");
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ChangeLineSelection(LineNo: Integer; IsSelect: Boolean)
    begin
        TempAdvLetterLineRelBuf.SetRange("Doc Line No.", LineNo);
        if TempAdvLetterLineRelBuf.FindSet then
            repeat
                if TempAdvLetterLineRelBuf.Select <> IsSelect then begin
                    TempAdvLetterLineRelBuf.Select := IsSelect;
                    TempAdvLetterLineRelBuf.Modify;
                end;
            until TempAdvLetterLineRelBuf.Next = 0;
        TempAdvLetterLineRelBuf.SetRange("Doc Line No.");
    end;

    [Scope('OnPrem')]
    procedure UpdLetterSemiFinishedAmounts(Init: Boolean; LetterDocNo: Code[20])
    begin
        TempAdvLetterLineRelBuf.Reset;
        case Type of
            Type::Sale:
                begin
                    if LetterDocNo <> '' then
                        TempSalesAdvanceLetterHeader.SetRange("No.", LetterDocNo);
                    if Init then
                        if TempSalesAdvanceLetterHeader.FindSet then
                            repeat
                                TempSalesAdvanceLetterHeader."Semifinished Linked Amount" := 0;
                                TempSalesAdvanceLetterHeader.Modify;
                                TempSalesAdvanceLetterLine.SetRange("Letter No.", TempSalesAdvanceLetterHeader."No.");
                                if TempSalesAdvanceLetterLine.FindSet then
                                    repeat
                                        TempSalesAdvanceLetterLine."Semifinished Linked Amount" := 0;
                                        TempSalesAdvanceLetterLine.Modify;
                                    until TempSalesAdvanceLetterLine.Next = 0;
                            until TempSalesAdvanceLetterHeader.Next = 0;
                    TempAdvLetterLineRelBuf.SetCurrentKey("Letter No.");
                    TempAdvLetterLineRelBuf.SetFilter("Letter No.", '<>''''');
                    if LetterDocNo <> '' then
                        TempAdvLetterLineRelBuf.SetRange("Letter No.", LetterDocNo);
                    if TempAdvLetterLineRelBuf.FindSet then
                        repeat
                            if TempAdvLetterLineRelBuf."Letter No." <> TempSalesAdvanceLetterHeader."No." then
                                TempSalesAdvanceLetterHeader.Get(TempAdvLetterLineRelBuf."Letter No.");
                            TempSalesAdvanceLetterHeader."Semifinished Linked Amount" += TempAdvLetterLineRelBuf.Amount;
                            TempSalesAdvanceLetterHeader.Modify;
                            if (TempAdvLetterLineRelBuf."Letter No." <> TempSalesAdvanceLetterLine."Letter No.") or
                               (TempAdvLetterLineRelBuf."Letter Line No." <> TempSalesAdvanceLetterLine."Line No.")
                            then
                                TempSalesAdvanceLetterLine.Get(TempAdvLetterLineRelBuf."Letter No.", TempAdvLetterLineRelBuf."Letter Line No.");
                            TempSalesAdvanceLetterLine."Semifinished Linked Amount" += TempAdvLetterLineRelBuf.Amount;
                            TempSalesAdvanceLetterLine.Modify
                        until TempAdvLetterLineRelBuf.Next = 0;
                    TempSalesAdvanceLetterHeader.Reset;
                    TempSalesAdvanceLetterLine.Reset;
                    TempAdvLetterLineRelBuf.Reset;
                end;
            Type::Purchase:
                begin
                    if LetterDocNo <> '' then
                        TempPurchAdvanceLetterHeader.SetRange("No.", LetterDocNo);
                    if Init then
                        if TempPurchAdvanceLetterHeader.FindSet then
                            repeat
                                TempPurchAdvanceLetterHeader."Semifinished Linked Amount" := 0;
                                TempPurchAdvanceLetterHeader.Modify;
                                TempPurchAdvanceLetterLine.SetRange("Letter No.", TempPurchAdvanceLetterHeader."No.");
                                if TempPurchAdvanceLetterLine.FindSet then
                                    repeat
                                        TempPurchAdvanceLetterLine."Semifinished Linked Amount" := 0;
                                        TempPurchAdvanceLetterLine.Modify;
                                    until TempPurchAdvanceLetterLine.Next = 0;
                            until TempPurchAdvanceLetterHeader.Next = 0;
                    TempAdvLetterLineRelBuf.SetCurrentKey("Letter No.");
                    TempAdvLetterLineRelBuf.SetFilter("Letter No.", '<>''''');
                    if LetterDocNo <> '' then
                        TempAdvLetterLineRelBuf.SetRange("Letter No.", LetterDocNo);
                    if TempAdvLetterLineRelBuf.FindSet then
                        repeat
                            if TempAdvLetterLineRelBuf."Letter No." <> TempPurchAdvanceLetterHeader."No." then
                                TempPurchAdvanceLetterHeader.Get(TempAdvLetterLineRelBuf."Letter No.");
                            TempPurchAdvanceLetterHeader."Semifinished Linked Amount" += TempAdvLetterLineRelBuf.Amount;
                            TempPurchAdvanceLetterHeader.Modify;
                            if (TempAdvLetterLineRelBuf."Letter No." <> TempPurchAdvanceLetterLine."Letter No.") or
                               (TempAdvLetterLineRelBuf."Letter Line No." <> TempPurchAdvanceLetterLine."Line No.")
                            then
                                TempPurchAdvanceLetterLine.Get(TempAdvLetterLineRelBuf."Letter No.", TempAdvLetterLineRelBuf."Letter Line No.");
                            TempPurchAdvanceLetterLine."Semifinished Linked Amount" += TempAdvLetterLineRelBuf.Amount;
                            TempPurchAdvanceLetterLine.Modify
                        until TempAdvLetterLineRelBuf.Next = 0;
                    TempPurchAdvanceLetterHeader.Reset;
                    TempPurchAdvanceLetterLine.Reset;
                    TempAdvLetterLineRelBuf.Reset;
                end;
        end;
        TempAdvLetterLineRelBuf.Reset;
    end;

    [Scope('OnPrem')]
    procedure FillAdvLnkBuffFromSalesLetLine(var SalesAdvanceLetterLine: Record "Sales Advance Letter Line"; var AdvanceLinkBufferEntry: Record "Advance Link Buffer - Entry")
    var
        ldeAmount: Decimal;
        ldeInvAmount: Decimal;
    begin
        if SalesAdvanceLetterLine.FindSet then
            repeat
                SalesAdvanceLetterLine.SetFilter("Doc. No. Filter", '<%1|>%1', DocNo);
                SalesAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount",
                  "Document Linked Ded. Amount");
                SalesAdvanceLetterLine.SetFilter(Status, '<%1', SalesAdvanceLetterLine.Status::Closed);
                ldeInvAmount := SalesAdvanceLetterLine."Amount Invoiced" -
                  SalesAdvanceLetterLine."Document Linked Inv. Amount" -
                  SalesAdvanceLetterLine."Semifinished Linked Amount" -
                  SalesAdvanceLetterLine."Amount Deducted" +
                  SalesAdvanceLetterLine."Document Linked Ded. Amount";
                ldeAmount := SalesAdvanceLetterLine."Amount Including VAT" -
                  SalesAdvanceLetterLine."Document Linked Amount" -
                  SalesAdvanceLetterLine."Semifinished Linked Amount" -
                  SalesAdvanceLetterLine."Amount Deducted" +
                  SalesAdvanceLetterLine."Document Linked Ded. Amount";
                if (LinkingType = LinkingType::"Invoiced Amount") and (ldeAmount > ldeInvAmount) then
                    ldeAmount := ldeInvAmount;
                if ldeAmount > 0 then begin
                    AdvanceLinkBufferEntry.Init;
                    AdvanceLinkBufferEntry."VAT Bus. Posting Group" := SalesAdvanceLetterLine."VAT Bus. Posting Group";
                    AdvanceLinkBufferEntry."VAT Prod. Posting Group" := SalesAdvanceLetterLine."VAT Prod. Posting Group";
                    AdvanceLinkBufferEntry."VAT %" := SalesAdvanceLetterLine."VAT %";
                    AdvanceLinkBufferEntry."Advance Letter No." := SalesAdvanceLetterLine."Letter No.";
                    AdvanceLinkBufferEntry."Advance Letter Line No." := SalesAdvanceLetterLine."Line No.";
                    AdvanceLinkBufferEntry.Amount := ldeAmount;
                    AdvanceLinkBufferEntry.Insert;
                end;
            until SalesAdvanceLetterLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure FillAdvLnkBuffFromSalesLetHead(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header"; var AdvanceLinkBufferEntry: Record "Advance Link Buffer - Entry")
    var
        Amount2: Decimal;
        InvAmount: Decimal;
    begin
        if SalesAdvanceLetterHeader.FindSet then
            repeat
                TempSalesAdvanceLetterLine.SetRange("Letter No.", SalesAdvanceLetterHeader."No.");
                TempSalesAdvanceLetterLine.SetFilter("Doc. No. Filter", '<%1|>%1', DocNo);
                TempSalesAdvanceLetterLine.SetFilter(Status, '<%1', TempSalesAdvanceLetterLine.Status::Closed);
                if TempSalesAdvanceLetterLine.FindSet then
                    repeat
                        TempSalesAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount",
                          "Document Linked Ded. Amount");
                        InvAmount := TempSalesAdvanceLetterLine."Amount Invoiced" -
                          TempSalesAdvanceLetterLine."Document Linked Inv. Amount" -
                          TempSalesAdvanceLetterLine."Semifinished Linked Amount" -
                          TempSalesAdvanceLetterLine."Amount Deducted" +
                          TempSalesAdvanceLetterLine."Document Linked Ded. Amount";
                        Amount2 := TempSalesAdvanceLetterLine."Amount Including VAT" -
                          TempSalesAdvanceLetterLine."Document Linked Amount" -
                          TempSalesAdvanceLetterLine."Semifinished Linked Amount" -
                          TempSalesAdvanceLetterLine."Amount Deducted" +
                          TempSalesAdvanceLetterLine."Document Linked Ded. Amount";
                        if (LinkingType = LinkingType::"Invoiced Amount") and (Amount2 > InvAmount) then
                            Amount2 := InvAmount;
                        if Amount2 > 0 then begin
                            AdvanceLinkBufferEntry.Init;
                            AdvanceLinkBufferEntry."VAT Bus. Posting Group" := TempSalesAdvanceLetterLine."VAT Bus. Posting Group";
                            AdvanceLinkBufferEntry."VAT Prod. Posting Group" := TempSalesAdvanceLetterLine."VAT Prod. Posting Group";
                            AdvanceLinkBufferEntry."VAT %" := TempSalesAdvanceLetterLine."VAT %";
                            AdvanceLinkBufferEntry."Advance Letter No." := TempSalesAdvanceLetterLine."Letter No.";
                            AdvanceLinkBufferEntry."Advance Letter Line No." := TempSalesAdvanceLetterLine."Line No.";
                            AdvanceLinkBufferEntry.Amount := Amount2;
                            AdvanceLinkBufferEntry.Insert;
                        end;
                    until TempSalesAdvanceLetterLine.Next = 0;
            until SalesAdvanceLetterHeader.Next = 0;
        TempSalesAdvanceLetterLine.Reset;
    end;

    [Scope('OnPrem')]
    procedure FillAdvLnkBuffFromPurchLetLine(var PurchAdvanceLetterLine: Record "Purch. Advance Letter Line"; var AdvanceLinkBufferEntry: Record "Advance Link Buffer - Entry")
    var
        InvAmount: Decimal;
        Amount2: Decimal;
    begin
        if PurchAdvanceLetterLine.FindSet then
            repeat
                PurchAdvanceLetterLine.SetFilter("Doc. No. Filter", '<%1|>%1', DocNo);
                PurchAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount",
                  "Document Linked Ded. Amount");
                PurchAdvanceLetterLine.SetFilter(Status, '<%1', PurchAdvanceLetterLine.Status::Closed);
                InvAmount := PurchAdvanceLetterLine."Amount Invoiced" -
                  PurchAdvanceLetterLine."Document Linked Inv. Amount" -
                  PurchAdvanceLetterLine."Semifinished Linked Amount" -
                  PurchAdvanceLetterLine."Amount Deducted" +
                  PurchAdvanceLetterLine."Document Linked Ded. Amount";
                Amount2 := PurchAdvanceLetterLine."Amount Including VAT" -
                  PurchAdvanceLetterLine."Document Linked Amount" -
                  PurchAdvanceLetterLine."Semifinished Linked Amount" -
                  PurchAdvanceLetterLine."Amount Deducted" +
                  PurchAdvanceLetterLine."Document Linked Ded. Amount";
                if (LinkingType = LinkingType::"Invoiced Amount") and (Amount2 > InvAmount) then
                    Amount2 := InvAmount;
                if Amount2 > 0 then begin
                    AdvanceLinkBufferEntry.Init;
                    AdvanceLinkBufferEntry."VAT Bus. Posting Group" := PurchAdvanceLetterLine."VAT Bus. Posting Group";
                    AdvanceLinkBufferEntry."VAT Prod. Posting Group" := PurchAdvanceLetterLine."VAT Prod. Posting Group";
                    AdvanceLinkBufferEntry."VAT %" := PurchAdvanceLetterLine."VAT %";
                    AdvanceLinkBufferEntry."Advance Letter No." := PurchAdvanceLetterLine."Letter No.";
                    AdvanceLinkBufferEntry."Advance Letter Line No." := PurchAdvanceLetterLine."Line No.";
                    AdvanceLinkBufferEntry.Amount := Amount2;
                    AdvanceLinkBufferEntry.Insert;
                end;
            until PurchAdvanceLetterLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure FillAdvLnkBuffFromPurchLetHead(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header"; var AdvanceLinkBufferEntry: Record "Advance Link Buffer - Entry")
    var
        InvAmount: Decimal;
        Amount2: Decimal;
    begin
        if PurchAdvanceLetterHeader.FindSet then
            repeat
                TempPurchAdvanceLetterLine.SetRange("Letter No.", PurchAdvanceLetterHeader."No.");
                TempPurchAdvanceLetterLine.SetFilter("Doc. No. Filter", '<%1|>%1', DocNo);
                TempPurchAdvanceLetterLine.SetFilter(Status, '<%1', TempPurchAdvanceLetterLine.Status::Closed);
                if TempPurchAdvanceLetterLine.FindSet then
                    repeat
                        TempPurchAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount",
                          "Document Linked Ded. Amount");
                        InvAmount := TempPurchAdvanceLetterLine."Amount Invoiced" -
                          TempPurchAdvanceLetterLine."Document Linked Inv. Amount" -
                          TempPurchAdvanceLetterLine."Semifinished Linked Amount" -
                          TempPurchAdvanceLetterLine."Amount Deducted" +
                          TempPurchAdvanceLetterLine."Document Linked Ded. Amount";
                        Amount2 := TempPurchAdvanceLetterLine."Amount Including VAT" -
                          TempPurchAdvanceLetterLine."Document Linked Amount" -
                          TempPurchAdvanceLetterLine."Semifinished Linked Amount" -
                          TempPurchAdvanceLetterLine."Amount Deducted" +
                          TempPurchAdvanceLetterLine."Document Linked Ded. Amount";
                        if (LinkingType = LinkingType::"Invoiced Amount") and (Amount2 > InvAmount) then
                            Amount2 := InvAmount;
                        if Amount2 > 0 then begin
                            AdvanceLinkBufferEntry.Init;
                            AdvanceLinkBufferEntry."VAT Bus. Posting Group" := TempPurchAdvanceLetterLine."VAT Bus. Posting Group";
                            AdvanceLinkBufferEntry."VAT Prod. Posting Group" := TempPurchAdvanceLetterLine."VAT Prod. Posting Group";
                            AdvanceLinkBufferEntry."VAT %" := TempPurchAdvanceLetterLine."VAT %";
                            AdvanceLinkBufferEntry."Advance Letter No." := TempPurchAdvanceLetterLine."Letter No.";
                            AdvanceLinkBufferEntry."Advance Letter Line No." := TempPurchAdvanceLetterLine."Line No.";
                            AdvanceLinkBufferEntry.Amount := Amount2;
                            AdvanceLinkBufferEntry.Insert;
                        end;
                    until TempPurchAdvanceLetterLine.Next = 0;
            until PurchAdvanceLetterHeader.Next = 0;
        TempPurchAdvanceLetterLine.Reset;
    end;

    [Scope('OnPrem')]
    procedure SuggestAdvLetterLinking(var AdvanceLinkBufferEntry: Record "Advance Link Buffer - Entry"; LinkByVATGroup: Boolean; LinkByVATPerc: Boolean; LinkAll: Boolean)
    var
        TempAdvanceLinkBufferEntryDoc: Record "Advance Link Buffer - Entry" temporary;
        TempAdvanceLinkBufferEntryApply: Record "Advance Link Buffer - Entry" temporary;
    begin
        // Fill buffer from doc. lines
        TempAdvLetterLineRelBuf.Reset;
        TempAdvLetterLineRelBuf.SetRange(Select, true);
        if not TempAdvLetterLineRelBuf.FindFirst then
            TempAdvLetterLineRelBuf.SetRange(Select);
        TempAdvLetterLineRelBuf.SetRange("Letter No.", '');
        if TempAdvLetterLineRelBuf.FindSet then
            repeat
                TempAdvanceLinkBufferEntryDoc.Init;
                TempAdvanceLinkBufferEntryDoc."VAT Bus. Posting Group" := TempAdvLetterLineRelBuf."Doc. Line VAT Bus. Post. Gr.";
                TempAdvanceLinkBufferEntryDoc."VAT Prod. Posting Group" := TempAdvLetterLineRelBuf."Doc. Line VAT Prod. Post. Gr.";
                TempAdvanceLinkBufferEntryDoc."VAT %" := TempAdvLetterLineRelBuf."Doc. Line VAT %";
                TempAdvanceLinkBufferEntryDoc."Document Line No." := TempAdvLetterLineRelBuf."Doc Line No.";
                TempAdvanceLinkBufferEntryDoc.Amount := TempAdvLetterLineRelBuf.Amount;
                TempAdvanceLinkBufferEntryDoc.Insert;
            until TempAdvLetterLineRelBuf.Next = 0;

        if not AdvanceLinkBufferEntry.FindFirst then
            Error(Text001Err);

        if not TempAdvanceLinkBufferEntryDoc.FindFirst then
            Error(Text002Err);

        // Link by VAT Groups
        if LinkByVATGroup then begin
            if TempAdvanceLinkBufferEntryDoc.FindSet then
                repeat
                    AdvanceLinkBufferEntry.SetRange("VAT Bus. Posting Group", TempAdvanceLinkBufferEntryDoc."VAT Bus. Posting Group");
                    AdvanceLinkBufferEntry.SetRange("VAT Prod. Posting Group", TempAdvanceLinkBufferEntryDoc."VAT Prod. Posting Group");
                    if AdvanceLinkBufferEntry.FindSet then
                        repeat
                            ApplyAL(TempAdvanceLinkBufferEntryDoc, AdvanceLinkBufferEntry, TempAdvanceLinkBufferEntryApply);
                        until AdvanceLinkBufferEntry.Next = 0;
                until TempAdvanceLinkBufferEntryDoc.Next = 0;
            AdvanceLinkBufferEntry.SetRange("VAT Bus. Posting Group");
            AdvanceLinkBufferEntry.SetRange("VAT Prod. Posting Group");
        end;

        // Link by VAT %
        if LinkByVATPerc then begin
            if TempAdvanceLinkBufferEntryDoc.FindSet then
                repeat
                    AdvanceLinkBufferEntry.SetRange("VAT %", TempAdvanceLinkBufferEntryDoc."VAT %");
                    if AdvanceLinkBufferEntry.FindSet then
                        repeat
                            ApplyAL(TempAdvanceLinkBufferEntryDoc, AdvanceLinkBufferEntry, TempAdvanceLinkBufferEntryApply);
                        until AdvanceLinkBufferEntry.Next = 0;
                until TempAdvanceLinkBufferEntryDoc.Next = 0;
            AdvanceLinkBufferEntry.SetRange("VAT %");
        end;

        // Link All
        if LinkAll then begin
            if TempAdvanceLinkBufferEntryDoc.FindSet then
                repeat
                    if AdvanceLinkBufferEntry.FindSet then
                        repeat
                            ApplyAL(TempAdvanceLinkBufferEntryDoc, AdvanceLinkBufferEntry, TempAdvanceLinkBufferEntryApply);
                        until AdvanceLinkBufferEntry.Next = 0;
                until TempAdvanceLinkBufferEntryDoc.Next = 0;
        end;

        // Write to Advance Linking Buffer
        if TempAdvanceLinkBufferEntryApply.FindSet then
            repeat
                if TempAdvLetterLineRelBuf.Get(TempAdvanceLinkBufferEntryApply."Document Line No.",
                     TempAdvanceLinkBufferEntryApply."Advance Letter No.",
                     TempAdvanceLinkBufferEntryApply."Advance Letter Line No.")
                then begin
                    TempAdvLetterLineRelBuf.Amount += TempAdvanceLinkBufferEntryApply.Amount;
                    if LinkingType = LinkingType::"Invoiced Amount" then
                        TempAdvLetterLineRelBuf."Invoiced Amount" += TempAdvanceLinkBufferEntryApply.Amount;
                    TempAdvLetterLineRelBuf.Modify;
                end else begin
                    TempAdvLetterLineRelBuf.Get(TempAdvanceLinkBufferEntryApply."Document Line No.", '', 0);
                    TempAdvLetterLineRelBuf."Letter No." := TempAdvanceLinkBufferEntryApply."Advance Letter No.";
                    TempAdvLetterLineRelBuf."Letter Line No." := TempAdvanceLinkBufferEntryApply."Advance Letter Line No.";
                    FillLetterFields(TempAdvLetterLineRelBuf);
                    TempAdvLetterLineRelBuf.Amount := TempAdvanceLinkBufferEntryApply.Amount;
                    if LinkingType = LinkingType::"Invoiced Amount" then
                        TempAdvLetterLineRelBuf."Invoiced Amount" := TempAdvanceLinkBufferEntryApply.Amount;
                    TempAdvLetterLineRelBuf.Insert;
                end;
                TempAdvLetterLineRelBuf.Get(TempAdvanceLinkBufferEntryApply."Document Line No.", '', 0);
                if TempAdvLetterLineRelBuf.Amount > TempAdvanceLinkBufferEntryApply.Amount then begin
                    TempAdvLetterLineRelBuf.Amount -= TempAdvanceLinkBufferEntryApply.Amount;
                    TempAdvLetterLineRelBuf.Modify;
                end else begin
                    TempAdvLetterLineRelBuf.Delete;
                    NotLinkedLines := NotLinkedLines - 1;
                end;
                NotLinkedAmount -= TempAdvanceLinkBufferEntryApply.Amount;
                LinkedAmount += TempAdvanceLinkBufferEntryApply.Amount;
            until TempAdvanceLinkBufferEntryApply.Next = 0;

        UpdLetterSemiFinishedAmounts(true, '');
        TempAdvLetterLineRelBuf.Reset;
    end;

    local procedure ApplyAL(var AdvanceLinkBufferEntryApplyFrom: Record "Advance Link Buffer - Entry"; var AdvanceLinkBufferEntryApplyTo: Record "Advance Link Buffer - Entry"; var AdvanceLinkBufferEntryApplyBuf: Record "Advance Link Buffer - Entry")
    var
        Amount2: Decimal;
    begin
        if AdvanceLinkBufferEntryApplyTo.Amount >= AdvanceLinkBufferEntryApplyFrom.Amount then begin
            Amount2 := AdvanceLinkBufferEntryApplyFrom.Amount;
            if Amount2 = 0 then
                exit;
            AdvanceLinkBufferEntryApplyTo.Amount := AdvanceLinkBufferEntryApplyTo.Amount - AdvanceLinkBufferEntryApplyFrom.Amount;
            AdvanceLinkBufferEntryApplyTo.Modify;
            AdvanceLinkBufferEntryApplyFrom.Amount := 0;
            AdvanceLinkBufferEntryApplyFrom.Modify;
            if AdvanceLinkBufferEntryApplyBuf.Get('', '', 0, AdvanceLinkBufferEntryApplyTo."Advance Letter No.",
                 AdvanceLinkBufferEntryApplyTo."Advance Letter Line No.", AdvanceLinkBufferEntryApplyFrom."Document Line No.")
            then begin
                AdvanceLinkBufferEntryApplyBuf.Amount := AdvanceLinkBufferEntryApplyBuf.Amount + Amount2;
                AdvanceLinkBufferEntryApplyBuf.Modify;
            end else begin
                AdvanceLinkBufferEntryApplyBuf.Init;
                AdvanceLinkBufferEntryApplyBuf."Advance Letter No." := AdvanceLinkBufferEntryApplyTo."Advance Letter No.";
                AdvanceLinkBufferEntryApplyBuf."Advance Letter Line No." := AdvanceLinkBufferEntryApplyTo."Advance Letter Line No.";
                AdvanceLinkBufferEntryApplyBuf."Document Line No." := AdvanceLinkBufferEntryApplyFrom."Document Line No.";
                AdvanceLinkBufferEntryApplyBuf.Amount := Amount2;
                AdvanceLinkBufferEntryApplyBuf.Insert;
            end;
        end else begin
            Amount2 := AdvanceLinkBufferEntryApplyTo.Amount;
            if Amount2 = 0 then
                exit;
            AdvanceLinkBufferEntryApplyTo.Amount := 0;
            AdvanceLinkBufferEntryApplyTo.Modify;
            AdvanceLinkBufferEntryApplyFrom.Amount := AdvanceLinkBufferEntryApplyFrom.Amount - Amount2;
            AdvanceLinkBufferEntryApplyFrom.Modify;
            if AdvanceLinkBufferEntryApplyBuf.Get('', '', 0, AdvanceLinkBufferEntryApplyTo."Advance Letter No.",
                 AdvanceLinkBufferEntryApplyTo."Advance Letter Line No.", AdvanceLinkBufferEntryApplyFrom."Document Line No.")
            then begin
                AdvanceLinkBufferEntryApplyBuf.Amount := AdvanceLinkBufferEntryApplyBuf.Amount + Amount2;
                AdvanceLinkBufferEntryApplyBuf.Modify;
            end else begin
                AdvanceLinkBufferEntryApplyBuf.Init;
                AdvanceLinkBufferEntryApplyBuf."Advance Letter No." := AdvanceLinkBufferEntryApplyTo."Advance Letter No.";
                AdvanceLinkBufferEntryApplyBuf."Advance Letter Line No." := AdvanceLinkBufferEntryApplyTo."Advance Letter Line No.";
                AdvanceLinkBufferEntryApplyBuf."Document Line No." := AdvanceLinkBufferEntryApplyFrom."Document Line No.";
                AdvanceLinkBufferEntryApplyBuf.Amount := Amount2;
                AdvanceLinkBufferEntryApplyBuf.Insert;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UnlinkCurrentLine(AdvLetterLineRelBuf: Record "Adv. Letter Line Rel. Buffer"; IsUpdateLetterBuf: Boolean)
    begin
        if AdvLetterLineRelBuf."Letter No." = '' then
            Error(Text006Err);
        TempAdvLetterLineRelBuf.Reset;
        TempAdvLetterLineRelBuf.Get(AdvLetterLineRelBuf."Doc Line No.", AdvLetterLineRelBuf."Letter No.",
          AdvLetterLineRelBuf."Letter Line No.");
        TempAdvLetterLineRelBuf.Delete;
        if TempAdvLetterLineRelBuf.Get(AdvLetterLineRelBuf."Doc Line No.", '', 0) then begin
            TempAdvLetterLineRelBuf.Amount += AdvLetterLineRelBuf.Amount;
            TempAdvLetterLineRelBuf.Modify;
        end else begin
            TempAdvLetterLineRelBuf.Init;
            TempAdvLetterLineRelBuf."Doc Line No." := AdvLetterLineRelBuf."Doc Line No.";
            TempAdvLetterLineRelBuf."Letter No." := '';
            TempAdvLetterLineRelBuf."Letter Line No." := 0;
            TempAdvLetterLineRelBuf.Amount := AdvLetterLineRelBuf.Amount;
            TempAdvLetterLineRelBuf."Document Type" := AdvLetterLineRelBuf."Document Type";
            TempAdvLetterLineRelBuf."Doc. Line Description" := AdvLetterLineRelBuf."Doc. Line Description";
            TempAdvLetterLineRelBuf.Insert;
            NotLinkedLines := NotLinkedLines + 1;
        end;
        NotLinkedAmount += AdvLetterLineRelBuf.Amount;
        LinkedAmount -= AdvLetterLineRelBuf.Amount;
        if IsUpdateLetterBuf then
            UpdLetterSemiFinishedAmounts(true, AdvLetterLineRelBuf."Letter No.");
    end;

    [Scope('OnPrem')]
    procedure UnlinkAll()
    var
        AdvLetterLineRelBuf: Record "Adv. Letter Line Rel. Buffer";
    begin
        TempAdvLetterLineRelBuf.Reset;
        TempAdvLetterLineRelBuf.SetFilter("Letter No.", '<>''''');
        if TempAdvLetterLineRelBuf.FindSet then begin
            repeat
                AdvLetterLineRelBuf := TempAdvLetterLineRelBuf;
                UnlinkCurrentLine(TempAdvLetterLineRelBuf, false);
                TempAdvLetterLineRelBuf := AdvLetterLineRelBuf;
                TempAdvLetterLineRelBuf.SetFilter("Letter No.", '<>''''');
            until TempAdvLetterLineRelBuf.Next = 0;
            UpdLetterSemiFinishedAmounts(true, '');
        end;
        TempAdvLetterLineRelBuf.Reset;
    end;

    [Scope('OnPrem')]
    procedure WriteChangesToDocument(): Boolean
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        AdvanceLetterLineRelation2: Record "Advance Letter Line Relation";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        WriteChanges: Boolean;
    begin
        case Type of
            Type::Sale:
                SalesHeader.Get(DocType, DocNo);
            Type::Purchase:
                PurchHeader.Get(DocType, DocNo);
        end;
        AdvanceLetterLineRelation.SetRange(Type, Type);
        AdvanceLetterLineRelation.SetRange("Document Type", DocType);
        AdvanceLetterLineRelation.SetRange("Document No.", DocNo);
        if AdvanceLetterLineRelation.FindSet then
            repeat
                if not TempAdvanceLetterLineRelation.Get(AdvanceLetterLineRelation.Type,
                     AdvanceLetterLineRelation."Document Type",
                     AdvanceLetterLineRelation."Document No.",
                     AdvanceLetterLineRelation."Document Line No.",
                     AdvanceLetterLineRelation."Letter No.",
                     AdvanceLetterLineRelation."Letter Line No.")
                then
                    Error(Text007Err);
                case true of
                    AdvanceLetterLineRelation.Amount <> TempAdvanceLetterLineRelation.Amount:
                        Error(Text007Err);
                    AdvanceLetterLineRelation."Invoiced Amount" <> TempAdvanceLetterLineRelation."Invoiced Amount":
                        Error(Text007Err);
                    else
                        TempAdvanceLetterLineRelation.Delete;
                end;
            until AdvanceLetterLineRelation.Next = 0;
        if TempAdvanceLetterLineRelation.FindFirst then
            Error(Text007Err);
        TempAdvLetterLineRelBuf.Reset;
        if AdvanceLetterLineRelation.FindSet then
            repeat
                if not TempAdvLetterLineRelBuf.Get(AdvanceLetterLineRelation."Document Line No.",
                     AdvanceLetterLineRelation."Letter No.",
                     AdvanceLetterLineRelation."Letter Line No.")
                then begin
                    AdvanceLetterLineRelation2 := AdvanceLetterLineRelation;
                    AdvanceLetterLineRelation2.CancelRelation(AdvanceLetterLineRelation2, true, true, true);
                    WriteChanges := true;
                end;
            until AdvanceLetterLineRelation.Next = 0;
        TempAdvLetterLineRelBuf.SetFilter("Letter No.", '<>''''');
        if TempAdvLetterLineRelBuf.FindSet then
            repeat
                if not AdvanceLetterLineRelation.Get(Type, DocType, DocNo, TempAdvLetterLineRelBuf."Doc Line No.",
                     TempAdvLetterLineRelBuf."Letter No.",
                     TempAdvLetterLineRelBuf."Letter Line No.")
                then begin
                    WriteChanges := true;
                    AdvanceLetterLineRelation.Init;
                    AdvanceLetterLineRelation.Type := Type;
                    AdvanceLetterLineRelation."Document No." := DocNo;
                    AdvanceLetterLineRelation."Document Line No." := TempAdvLetterLineRelBuf."Doc Line No.";
                    AdvanceLetterLineRelation."Letter No." := TempAdvLetterLineRelBuf."Letter No.";
                    AdvanceLetterLineRelation."Letter Line No." := TempAdvLetterLineRelBuf."Letter Line No.";
                    AdvanceLetterLineRelation.Amount := TempAdvLetterLineRelBuf.Amount + AdvanceLetterLineRelation."Deducted Amount";
                    AdvanceLetterLineRelation."Invoiced Amount" := TempAdvLetterLineRelBuf."Invoiced Amount" +
                      AdvanceLetterLineRelation."Deducted Amount";
                    AdvanceLetterLineRelation."Document Type" := DocType;
                    AdvanceLetterLineRelation.Insert;
                end else
                    if 0 <> TempAdvLetterLineRelBuf.Amount then begin
                        WriteChanges := true;
                        AdvanceLetterLineRelation.Amount := TempAdvLetterLineRelBuf.Amount + AdvanceLetterLineRelation."Deducted Amount";
                        AdvanceLetterLineRelation."Invoiced Amount" := TempAdvLetterLineRelBuf."Invoiced Amount" +
                          AdvanceLetterLineRelation."Deducted Amount";
                        AdvanceLetterLineRelation.Modify;
                    end;

                case Type of
                    Type::Sale:
                        SalesLine.Get(DocType, DocNo, AdvanceLetterLineRelation."Document Line No.");
                    Type::Purchase:
                        PurchLine.Get(DocType, DocNo, AdvanceLetterLineRelation."Document Line No.");
                end;
                AdvanceLetterLineRelation.Modify;

                if Type = Type::Sale then begin
                    SalesAdvanceLetterLine.Get(TempAdvLetterLineRelBuf."Letter No.", TempAdvLetterLineRelBuf."Letter Line No.");
                    if LinkingType = LinkingType::Amount then
                        SalesPostAdvances.UpdInvAmountToLineRelations(SalesAdvanceLetterLine);
                    SalesAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount");
                    if SalesAdvanceLetterLine."Document Linked Inv. Amount" > SalesAdvanceLetterLine."Amount Invoiced" then
                        Error(Text008Err, SalesAdvanceLetterLine."Letter No.", SalesAdvanceLetterLine."Line No.");
                    if SalesAdvanceLetterLine."Document Linked Amount" > SalesAdvanceLetterLine."Amount Including VAT" then
                        Error(Text009Err, SalesAdvanceLetterLine."Letter No.", SalesAdvanceLetterLine."Line No.");
                    SalesLine.Get(TempSalesHeader."Document Type", DocNo, TempAdvLetterLineRelBuf."Doc Line No.");
                    SalesPostAdvances.UpdateOrderLine(SalesLine, TempSalesHeader."Prices Including VAT", true);
                    SalesLine.Modify;
                end else begin
                    PurchAdvanceLetterLine.Get(TempAdvLetterLineRelBuf."Letter No.", TempAdvLetterLineRelBuf."Letter Line No.");
                    if LinkingType = LinkingType::Amount then
                        PurchPostAdvances.UpdInvAmountToLineRelations(PurchAdvanceLetterLine);
                    PurchAdvanceLetterLine.CalcFields("Document Linked Amount", "Document Linked Inv. Amount");
                    if PurchAdvanceLetterLine."Document Linked Inv. Amount" > PurchAdvanceLetterLine."Amount Invoiced" then
                        Error(Text008Err, PurchAdvanceLetterLine."Letter No.", PurchAdvanceLetterLine."Line No.");
                    if PurchAdvanceLetterLine."Document Linked Amount" > PurchAdvanceLetterLine."Amount Including VAT" then
                        Error(Text009Err, PurchAdvanceLetterLine."Letter No.", PurchAdvanceLetterLine."Line No.");
                    PurchLine.Get(TempPurchHeader."Document Type", DocNo, TempAdvLetterLineRelBuf."Doc Line No.");
                    PurchPostAdvances.UpdateOrderLine(PurchLine, TempPurchHeader."Prices Including VAT", true);
                    PurchLine.Modify;
                end;
            until TempAdvLetterLineRelBuf.Next = 0;
        TempAdvLetterLineRelBuf.Reset;
        if WriteChanges then
            case Type of
                Type::Sale:
                    SalesPostAdvances.SetAmtToDedOnSalesDoc(SalesHeader, true);
                Type::Purchase:
                    PurchPostAdvances.SetAmtToDedOnPurchDoc(PurchHeader, true);
            end;
        exit(WriteChanges);
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnAfterDeleteEvent', '', false, false)]
    local procedure CancelRelationsOnAfterDeleteEventSalesLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        with Rec do begin
            if not RunTrigger or IsTemporary then
                exit;

            if not ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) then
                exit;

            CancelAdvanceLetterRelations;
        end;
    end;

    [EventSubscriber(ObjectType::Report, 299, 'OnAfterDeleteSalesLine', '', false, false)]
    local procedure CancelRelationsOnAfterDeleteSalesLineOfInvoicedSalesOrders(var SalesLine: Record "Sales Line")
    begin
        with SalesLine do begin
            if not ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) then
                exit;

            CancelAdvanceLetterRelations;
        end;
    end;

    [EventSubscriber(ObjectType::Table, 39, 'OnAfterDeleteEvent', '', false, false)]
    local procedure CancelRelationsOnAfterDeleteEventPurchaseLine(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        with Rec do begin
            if not RunTrigger or IsTemporary then
                exit;

            if not ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) then
                exit;

            CancelAdvanceLetterRelations;
        end;
    end;

    [EventSubscriber(ObjectType::Report, 499, 'OnBeforePurchLineDelete', '', false, false)]
    local procedure CancelRelationsOnBeforePurchLineDeleteOfInvoicedPurchOrders(var PurchLine: Record "Purchase Line")
    begin
        with PurchLine do begin
            if not ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) then
                exit;

            CancelAdvanceLetterRelations;
        end;
    end;
}

