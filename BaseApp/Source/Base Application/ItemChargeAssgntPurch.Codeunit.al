codeunit 5805 "Item Charge Assgnt. (Purch.)"
{
    Permissions = TableData "Purchase Header" = r,
                  TableData "Purchase Line" = r,
                  TableData "Purch. Rcpt. Line" = r,
                  TableData "Item Charge Assignment (Purch)" = imd,
                  TableData "Return Shipment Line" = r;

    trigger OnRun()
    begin
    end;

    var
        SuggestItemChargeMsg: Label 'Select how to distribute the assigned item charge when the document has more than one line of type Item.';
        EquallyTok: Label 'Equally';
        ByAmountTok: Label 'By Amount';
        ByWeightTok: Label 'By Weight';
        ByVolumeTok: Label 'By Volume';
        ItemChargesNotAssignedErr: Label 'No item charges were assigned.';
        UOMMgt: Codeunit "Unit of Measure Management";

    procedure InsertItemChargeAssgnt(ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; ApplToDocType: Option; ApplToDocNo2: Code[20]; ApplToDocLineNo2: Integer; ItemNo2: Code[20]; Description2: Text[100]; var NextLineNo: Integer)
    begin
        InsertItemChargeAssgntWithAssignValues(
          ItemChargeAssgntPurch, ApplToDocType, ApplToDocNo2, ApplToDocLineNo2, ItemNo2, Description2, 0, 0, NextLineNo);
    end;

    procedure InsertItemChargeAssgntWithAssignValues(FromItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; ApplToDocType: Option; FromApplToDocNo: Code[20]; FromApplToDocLineNo: Integer; FromItemNo: Code[20]; FromDescription: Text[100]; QtyToAssign: Decimal; AmountToAssign: Decimal; var NextLineNo: Integer)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        InsertItemChargeAssgntWithAssignValuesTo(
          FromItemChargeAssgntPurch, ApplToDocType, FromApplToDocNo, FromApplToDocLineNo, FromItemNo, FromDescription,
          QtyToAssign, AmountToAssign, NextLineNo, ItemChargeAssgntPurch);
    end;

    procedure InsertItemChargeAssgntWithAssignValuesTo(FromItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; ApplToDocType: Option; FromApplToDocNo: Code[20]; FromApplToDocLineNo: Integer; FromItemNo: Code[20]; FromDescription: Text[100]; QtyToAssign: Decimal; AmountToAssign: Decimal; var NextLineNo: Integer; var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    begin
        NextLineNo := NextLineNo + 10000;

        ItemChargeAssgntPurch."Document No." := FromItemChargeAssgntPurch."Document No.";
        ItemChargeAssgntPurch."Document Type" := FromItemChargeAssgntPurch."Document Type";
        ItemChargeAssgntPurch."Document Line No." := FromItemChargeAssgntPurch."Document Line No.";
        ItemChargeAssgntPurch."Item Charge No." := FromItemChargeAssgntPurch."Item Charge No.";
        ItemChargeAssgntPurch."Line No." := NextLineNo;
        ItemChargeAssgntPurch."Applies-to Doc. No." := FromApplToDocNo;
        ItemChargeAssgntPurch."Applies-to Doc. Type" := ApplToDocType;
        ItemChargeAssgntPurch."Applies-to Doc. Line No." := FromApplToDocLineNo;
        ItemChargeAssgntPurch."Item No." := FromItemNo;
        ItemChargeAssgntPurch.Description := FromDescription;
        ItemChargeAssgntPurch."Unit Cost" := FromItemChargeAssgntPurch."Unit Cost";
        if QtyToAssign <> 0 then begin
            ItemChargeAssgntPurch."Amount to Assign" := AmountToAssign;
            ItemChargeAssgntPurch.Validate("Qty. to Assign", QtyToAssign);
        end;
        OnBeforeInsertItemChargeAssgntWithAssignValues(ItemChargeAssgntPurch, FromItemChargeAssgntPurch);
        ItemChargeAssgntPurch.Insert();
    end;

    procedure Summarize(var TempToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var ToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
        with TempToItemChargeAssignmentPurch do begin
            SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
            if FindSet then
                repeat
                    if ("Item Charge No." <> ToItemChargeAssignmentPurch."Item Charge No.") or
                       ("Applies-to Doc. No." <> ToItemChargeAssignmentPurch."Applies-to Doc. No.") or
                       ("Applies-to Doc. Line No." <> ToItemChargeAssignmentPurch."Applies-to Doc. Line No.")
                    then begin
                        if ToItemChargeAssignmentPurch."Line No." <> 0 then
                            ToItemChargeAssignmentPurch.Insert();
                        ToItemChargeAssignmentPurch := TempToItemChargeAssignmentPurch;
                        ToItemChargeAssignmentPurch."Qty. to Assign" := 0;
                        ToItemChargeAssignmentPurch."Amount to Assign" := 0;
                    end;
                    ToItemChargeAssignmentPurch."Qty. to Assign" += "Qty. to Assign";
                    ToItemChargeAssignmentPurch."Amount to Assign" += "Amount to Assign";
                until Next = 0;
            if ToItemChargeAssignmentPurch."Line No." <> 0 then
                ToItemChargeAssignmentPurch.Insert();
        end;
    end;

    procedure CreateDocChargeAssgnt(LastItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; ReceiptNo: Code[20])
    var
        FromPurchLine: Record "Purchase Line";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        NextLineNo: Integer;
    begin
        OnBeforeCreateDocChargeAssgn(LastItemChargeAssgntPurch, FromPurchLine);

        with LastItemChargeAssgntPurch do begin
            FromPurchLine.SetRange("Document Type", "Document Type");
            FromPurchLine.SetRange("Document No.", "Document No.");
            FromPurchLine.SetRange(Type, FromPurchLine.Type::Item);
            if FromPurchLine.Find('-') then begin
                NextLineNo := "Line No.";
                ItemChargeAssgntPurch.Reset();
                ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
                ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
                ItemChargeAssgntPurch.SetRange("Document Line No.", "Document Line No.");
                ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", "Document No.");
                repeat
                    if (FromPurchLine.Quantity <> 0) and
                       (FromPurchLine.Quantity <> FromPurchLine."Quantity Invoiced") and
                       (FromPurchLine."Work Center No." = '') and
                       ((ReceiptNo = '') or (FromPurchLine."Receipt No." = ReceiptNo)) and
                       FromPurchLine."Allow Item Charge Assignment"
                    then begin
                        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", FromPurchLine."Line No.");
                        if not ItemChargeAssgntPurch.FindFirst then
                            InsertItemChargeAssgnt(
                              LastItemChargeAssgntPurch, FromPurchLine."Document Type",
                              FromPurchLine."Document No.", FromPurchLine."Line No.",
                              FromPurchLine."No.", FromPurchLine.Description, NextLineNo);
                    end;
                until FromPurchLine.Next = 0;
            end;
        end;

        OnAfterCreateDocChargeAssgnt(LastItemChargeAssgntPurch, ReceiptNo);
    end;

    procedure CreateRcptChargeAssgnt(var FromPurchRcptLine: Record "Purch. Rcpt. Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        NextLine: Integer;
    begin
        FromPurchRcptLine.TestField("Work Center No.", '');
        NextLine := ItemChargeAssgntPurch."Line No.";
        ItemChargeAssgntPurch2.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch2.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch2.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntPurch2."Applies-to Doc. Type"::Receipt);
        repeat
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. No.", FromPurchRcptLine."Document No.");
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Line No.", FromPurchRcptLine."Line No.");
            if not ItemChargeAssgntPurch2.FindFirst then
                InsertItemChargeAssgnt(ItemChargeAssgntPurch, ItemChargeAssgntPurch2."Applies-to Doc. Type"::Receipt,
                  FromPurchRcptLine."Document No.", FromPurchRcptLine."Line No.",
                  FromPurchRcptLine."No.", FromPurchRcptLine.Description, NextLine);
        until FromPurchRcptLine.Next = 0;
    end;

    procedure CreateTransferRcptChargeAssgnt(var FromTransRcptLine: Record "Transfer Receipt Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        NextLine: Integer;
    begin
        NextLine := ItemChargeAssgntPurch."Line No.";
        ItemChargeAssgntPurch2.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch2.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch2.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Transfer Receipt");
        repeat
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. No.", FromTransRcptLine."Document No.");
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Line No.", FromTransRcptLine."Line No.");
            if not ItemChargeAssgntPurch2.FindFirst then
                InsertItemChargeAssgnt(ItemChargeAssgntPurch, ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Transfer Receipt",
                  FromTransRcptLine."Document No.", FromTransRcptLine."Line No.",
                  FromTransRcptLine."Item No.", FromTransRcptLine.Description, NextLine);
        until FromTransRcptLine.Next = 0;
    end;

    procedure CreateShptChargeAssgnt(var FromReturnShptLine: Record "Return Shipment Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        NextLine: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateShptChargeAssgnt(FromReturnShptLine, ItemChargeAssgntPurch, IsHandled);
        if not IsHandled then
            FromReturnShptLine.TestField("Job No.", '');
        NextLine := ItemChargeAssgntPurch."Line No.";
        ItemChargeAssgntPurch2.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch2.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch2.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Return Shipment");
        repeat
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. No.", FromReturnShptLine."Document No.");
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Line No.", FromReturnShptLine."Line No.");
            if not ItemChargeAssgntPurch2.FindFirst then
                InsertItemChargeAssgnt(ItemChargeAssgntPurch, ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Return Shipment",
                  FromReturnShptLine."Document No.", FromReturnShptLine."Line No.",
                  FromReturnShptLine."No.", FromReturnShptLine.Description, NextLine);
        until FromReturnShptLine.Next = 0;
    end;

    procedure CreateSalesShptChargeAssgnt(var FromSalesShptLine: Record "Sales Shipment Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        NextLine: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSalesShptChargeAssgnt(FromSalesShptLine, ItemChargeAssgntPurch, IsHandled);
        if not IsHandled then
            FromSalesShptLine.TestField("Job No.", '');
        NextLine := ItemChargeAssgntPurch."Line No.";
        ItemChargeAssgntPurch2.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch2.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch2.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Sales Shipment");
        repeat
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. No.", FromSalesShptLine."Document No.");
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Line No.", FromSalesShptLine."Line No.");
            if not ItemChargeAssgntPurch2.FindFirst then
                InsertItemChargeAssgnt(ItemChargeAssgntPurch, ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Sales Shipment",
                  FromSalesShptLine."Document No.", FromSalesShptLine."Line No.",
                  FromSalesShptLine."No.", FromSalesShptLine.Description, NextLine);
        until FromSalesShptLine.Next = 0;
    end;

    procedure CreateReturnRcptChargeAssgnt(var FromReturnRcptLine: Record "Return Receipt Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    var
        ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)";
        NextLine: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateReturnRcptChargeAssgnt(FromReturnRcptLine, ItemChargeAssgntPurch, IsHandled);
        if not IsHandled then
            FromReturnRcptLine.TestField("Job No.", '');
        NextLine := ItemChargeAssgntPurch."Line No.";
        ItemChargeAssgntPurch2.SetRange("Document Type", ItemChargeAssgntPurch."Document Type");
        ItemChargeAssgntPurch2.SetRange("Document No.", ItemChargeAssgntPurch."Document No.");
        ItemChargeAssgntPurch2.SetRange("Document Line No.", ItemChargeAssgntPurch."Document Line No.");
        ItemChargeAssgntPurch2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Return Receipt");
        repeat
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. No.", FromReturnRcptLine."Document No.");
            ItemChargeAssgntPurch2.SetRange("Applies-to Doc. Line No.", FromReturnRcptLine."Line No.");
            if not ItemChargeAssgntPurch2.FindFirst then
                InsertItemChargeAssgnt(ItemChargeAssgntPurch, ItemChargeAssgntPurch2."Applies-to Doc. Type"::"Return Receipt",
                  FromReturnRcptLine."Document No.", FromReturnRcptLine."Line No.",
                  FromReturnRcptLine."No.", FromReturnRcptLine.Description, NextLine);
        until FromReturnRcptLine.Next = 0;
    end;

    procedure SuggestAssgnt(PurchLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        Selection: Integer;
        SelectionTxt: Text;
        SuggestItemChargeMenuTxt: Text;
        SuggestItemChargeMessageTxt: Text;
    begin
        with PurchLine do begin
            TestField("Qty. to Invoice");
            ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
            ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
            ItemChargeAssgntPurch.SetRange("Document Line No.", "Line No.");
        end;
        if ItemChargeAssgntPurch.IsEmpty then
            exit;

        ItemChargeAssgntPurch.SetFilter("Applies-to Doc. Type", '<>%1', ItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt");
        OnSuggestAssgntOnAfterItemChargeAssgntPurchSetFilters(ItemChargeAssgntPurch);

        Selection := 1;
        SuggestItemChargeMenuTxt :=
          StrSubstNo('%1,%2,%3,%4', AssignEquallyMenuText, AssignByAmountMenuText, AssignByWeightMenuText, AssignByVolumeMenuText);
        if ItemChargeAssgntPurch.Count > 1 then begin
            Selection := 2;
            SuggestItemChargeMessageTxt := SuggestItemChargeMsg;
            OnBeforeShowSuggestItemChargeAssignStrMenu(PurchLine, SuggestItemChargeMenuTxt, SuggestItemChargeMessageTxt, Selection);
            if SuggestItemChargeMenuTxt = '' then
                exit;
            if StrLen(DelChr(SuggestItemChargeMenuTxt, '=', DelChr(SuggestItemChargeMenuTxt, '=', ','))) > 1 then
                Selection := StrMenu(SuggestItemChargeMenuTxt, Selection, SuggestItemChargeMessageTxt)
            else
                Selection := 1;
        end;
        if Selection = 0 then
            exit;

        SelectionTxt := SelectStr(Selection, SuggestItemChargeMenuTxt);
        AssignItemCharges(PurchLine, TotalQtyToAssign, TotalAmtToAssign, SelectionTxt);
    end;

    procedure SuggestAssgnt2(PurchLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; Selection: Option Equally,"By Amount","By Weight","By Volume")
    begin
        // this function will be deprecated. Please use AssignItemCharges instead.
        AssignItemCharges(PurchLine, TotalQtyToAssign, TotalAmtToAssign, Format(Selection));
    end;

    procedure AssignItemCharges(PurchLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; SelectionTxt: Text)
    var
        Currency: Record Currency;
        PurchHeader: Record "Purchase Header";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ItemChargesAssigned: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignItemCharges(PurchLine, TotalQtyToAssign, TotalAmtToAssign, IsHandled);
        if IsHandled then
            exit;

        PurchLine.TestField("Qty. to Invoice");
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");

        if not Currency.Get(PurchHeader."Currency Code") then
            Currency.InitRoundingPrecision;

        ItemChargeAssgntPurch.SetRange("Document Type", PurchLine."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", PurchLine."Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", PurchLine."Line No.");
        if ItemChargeAssgntPurch.FindFirst then
            case SelectionTxt of
                AssignEquallyMenuText:
                    AssignEqually(ItemChargeAssgntPurch, Currency, TotalQtyToAssign, TotalAmtToAssign);
                AssignByAmountMenuText:
                    AssignByAmount(ItemChargeAssgntPurch, Currency, PurchHeader, TotalQtyToAssign, TotalAmtToAssign);
                AssignByWeightMenuText:
                    AssignByWeight(ItemChargeAssgntPurch, Currency, TotalQtyToAssign);
                AssignByVolumeMenuText:
                    AssignByVolume(ItemChargeAssgntPurch, Currency, TotalQtyToAssign);
                else begin
                        OnAssignItemCharges(
                          SelectionTxt, ItemChargeAssgntPurch, Currency, PurchHeader, TotalQtyToAssign, TotalAmtToAssign, ItemChargesAssigned);
                        if not ItemChargesAssigned then
                            Error(ItemChargesNotAssignedErr);
                    end;
            end;
    end;

    procedure AssignEquallyMenuText(): Text
    begin
        exit(EquallyTok)
    end;

    procedure AssignByAmountMenuText(): Text
    begin
        exit(ByAmountTok)
    end;

    procedure AssignByWeightMenuText(): Text
    begin
        exit(ByWeightTok)
    end;

    procedure AssignByVolumeMenuText(): Text
    begin
        exit(ByVolumeTok)
    end;

    local procedure AssignEqually(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        RemainingNumOfLines: Integer;
    begin
        repeat
            if not ItemChargeAssgntPurch.PurchLineInvoiced then begin
                TempItemChargeAssgntPurch := ItemChargeAssgntPurch;
                TempItemChargeAssgntPurch.Insert();
            end;
        until ItemChargeAssgntPurch.Next = 0;

        if TempItemChargeAssgntPurch.FindSet(true) then begin
            RemainingNumOfLines := TempItemChargeAssgntPurch.Count();
            repeat
                ItemChargeAssgntPurch.Get(
                  TempItemChargeAssgntPurch."Document Type",
                  TempItemChargeAssgntPurch."Document No.",
                  TempItemChargeAssgntPurch."Document Line No.",
                  TempItemChargeAssgntPurch."Line No.");
                ItemChargeAssgntPurch."Qty. to Assign" := Round(TotalQtyToAssign / RemainingNumOfLines, UOMMgt.QtyRndPrecision);
                ItemChargeAssgntPurch."Amount to Assign" :=
                  Round(
                    ItemChargeAssgntPurch."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                    Currency."Amount Rounding Precision");
                TotalQtyToAssign -= ItemChargeAssgntPurch."Qty. to Assign";
                TotalAmtToAssign -= ItemChargeAssgntPurch."Amount to Assign";
                RemainingNumOfLines := RemainingNumOfLines - 1;
                OnAssignEquallyOnBeforeItemChargeAssignmentPurchModify(ItemChargeAssgntPurch);
                ItemChargeAssgntPurch.Modify();
            until TempItemChargeAssgntPurch.Next = 0;
        end;
        TempItemChargeAssgntPurch.DeleteAll();
    end;

    local procedure AssignByAmount(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; PurchHeader: Record "Purchase Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        CurrExchRate: Record "Currency Exchange Rate";
        ReturnRcptLine: Record "Return Receipt Line";
        ReturnShptLine: Record "Return Shipment Line";
        SalesShptLine: Record "Sales Shipment Line";
        CurrencyCode: Code[10];
        TotalAppliesToDocLineAmount: Decimal;
    begin
        repeat
            if not ItemChargeAssgntPurch.PurchLineInvoiced then begin
                TempItemChargeAssgntPurch := ItemChargeAssgntPurch;
                case ItemChargeAssgntPurch."Applies-to Doc. Type" of
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::Quote,
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::Order,
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::Invoice,
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Order",
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::"Credit Memo":
                        begin
                            PurchLine.Get(
                              ItemChargeAssgntPurch."Applies-to Doc. Type",
                              ItemChargeAssgntPurch."Applies-to Doc. No.",
                              ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                              Abs(PurchLine."Line Amount");
                        end;
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt:
                        begin
                            PurchRcptLine.Get(
                              ItemChargeAssgntPurch."Applies-to Doc. No.",
                              ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            CurrencyCode := PurchRcptLine.GetCurrencyCodeFromHeader;
                            if CurrencyCode = PurchHeader."Currency Code" then
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  Abs(PurchRcptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    PurchHeader."Posting Date", CurrencyCode, PurchHeader."Currency Code",
                                    Abs(PurchRcptLine."Item Charge Base Amount"));
                        end;
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment":
                        begin
                            ReturnShptLine.Get(
                              ItemChargeAssgntPurch."Applies-to Doc. No.",
                              ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            CurrencyCode := ReturnShptLine.GetCurrencyCode;
                            if CurrencyCode = PurchHeader."Currency Code" then
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  Abs(ReturnShptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    PurchHeader."Posting Date", CurrencyCode, PurchHeader."Currency Code",
                                    Abs(ReturnShptLine."Item Charge Base Amount"));
                        end;
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::"Sales Shipment":
                        begin
                            SalesShptLine.Get(
                              ItemChargeAssgntPurch."Applies-to Doc. No.",
                              ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            CurrencyCode := SalesShptLine.GetCurrencyCode;
                            if CurrencyCode = PurchHeader."Currency Code" then
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  Abs(SalesShptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    PurchHeader."Posting Date", CurrencyCode, PurchHeader."Currency Code",
                                    Abs(SalesShptLine."Item Charge Base Amount"));
                        end;
                    ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Receipt":
                        begin
                            ReturnRcptLine.Get(
                              ItemChargeAssgntPurch."Applies-to Doc. No.",
                              ItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            CurrencyCode := ReturnRcptLine.GetCurrencyCode;
                            if CurrencyCode = PurchHeader."Currency Code" then
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  Abs(ReturnRcptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    PurchHeader."Posting Date", CurrencyCode, PurchHeader."Currency Code",
                                    Abs(ReturnRcptLine."Item Charge Base Amount"));
                        end;
                end;
                if TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" <> 0 then
                    TempItemChargeAssgntPurch.Insert
                else begin
                    ItemChargeAssgntPurch."Amount to Assign" := 0;
                    ItemChargeAssgntPurch."Qty. to Assign" := 0;
                    ItemChargeAssgntPurch.Modify();
                end;
                TotalAppliesToDocLineAmount += TempItemChargeAssgntPurch."Applies-to Doc. Line Amount";
            end;
        until ItemChargeAssgntPurch.Next = 0;

        if TempItemChargeAssgntPurch.FindSet(true) then
            repeat
                ItemChargeAssgntPurch.Get(
                  TempItemChargeAssgntPurch."Document Type",
                  TempItemChargeAssgntPurch."Document No.",
                  TempItemChargeAssgntPurch."Document Line No.",
                  TempItemChargeAssgntPurch."Line No.");
                if TotalQtyToAssign <> 0 then begin
                    ItemChargeAssgntPurch."Qty. to Assign" :=
                      Round(
                        TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" / TotalAppliesToDocLineAmount * TotalQtyToAssign,
                        UOMMgt.QtyRndPrecision);
                    ItemChargeAssgntPurch."Amount to Assign" :=
                      Round(
                        ItemChargeAssgntPurch."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                        Currency."Amount Rounding Precision");
                    TotalQtyToAssign -= ItemChargeAssgntPurch."Qty. to Assign";
                    TotalAmtToAssign -= ItemChargeAssgntPurch."Amount to Assign";
                    TotalAppliesToDocLineAmount -= TempItemChargeAssgntPurch."Applies-to Doc. Line Amount";
                    OnAssignByAmountOnBeforeItemChargeAssignmentPurchModify(ItemChargeAssgntPurch);
                    ItemChargeAssgntPurch.Modify();
                end;
            until TempItemChargeAssgntPurch.Next = 0;
        TempItemChargeAssgntPurch.DeleteAll();
    end;

    local procedure AssignByWeight(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; TotalQtyToAssign: Decimal)
    var
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        LineAray: array[3] of Decimal;
        TotalGrossWeight: Decimal;
        QtyRemainder: Decimal;
        AmountRemainder: Decimal;
    begin
        repeat
            if not ItemChargeAssgntPurch.PurchLineInvoiced then begin
                TempItemChargeAssgntPurch.Init();
                TempItemChargeAssgntPurch := ItemChargeAssgntPurch;
                TempItemChargeAssgntPurch.Insert();
                GetItemValues(TempItemChargeAssgntPurch, LineAray);
                TotalGrossWeight := TotalGrossWeight + (LineAray[2] * LineAray[1]);
            end;
        until ItemChargeAssgntPurch.Next = 0;

        if TempItemChargeAssgntPurch.FindSet(true) then
            repeat
                GetItemValues(TempItemChargeAssgntPurch, LineAray);
                if TotalGrossWeight <> 0 then
                    TempItemChargeAssgntPurch."Qty. to Assign" :=
                      (TotalQtyToAssign * LineAray[2] * LineAray[1]) / TotalGrossWeight + QtyRemainder
                else
                    TempItemChargeAssgntPurch."Qty. to Assign" := 0;
                AssignPurchItemCharge(ItemChargeAssgntPurch, TempItemChargeAssgntPurch, Currency, QtyRemainder, AmountRemainder);
            until TempItemChargeAssgntPurch.Next = 0;
        TempItemChargeAssgntPurch.DeleteAll();
    end;

    local procedure AssignByVolume(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; TotalQtyToAssign: Decimal)
    var
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        LineAray: array[3] of Decimal;
        TotalUnitVolume: Decimal;
        QtyRemainder: Decimal;
        AmountRemainder: Decimal;
    begin
        repeat
            if not ItemChargeAssgntPurch.PurchLineInvoiced then begin
                TempItemChargeAssgntPurch.Init();
                TempItemChargeAssgntPurch := ItemChargeAssgntPurch;
                TempItemChargeAssgntPurch.Insert();
                GetItemValues(TempItemChargeAssgntPurch, LineAray);
                TotalUnitVolume := TotalUnitVolume + (LineAray[3] * LineAray[1]);
            end;
        until ItemChargeAssgntPurch.Next = 0;

        if TempItemChargeAssgntPurch.FindSet(true) then
            repeat
                GetItemValues(TempItemChargeAssgntPurch, LineAray);
                if TotalUnitVolume <> 0 then
                    TempItemChargeAssgntPurch."Qty. to Assign" :=
                      (TotalQtyToAssign * LineAray[3] * LineAray[1]) / TotalUnitVolume + QtyRemainder
                else
                    TempItemChargeAssgntPurch."Qty. to Assign" := 0;
                AssignPurchItemCharge(ItemChargeAssgntPurch, TempItemChargeAssgntPurch, Currency, QtyRemainder, AmountRemainder);
            until TempItemChargeAssgntPurch.Next = 0;
        TempItemChargeAssgntPurch.DeleteAll();
    end;

    local procedure AssignPurchItemCharge(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; ItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; var QtyRemainder: Decimal; var AmountRemainder: Decimal)
    begin
        ItemChargeAssgntPurch.Get(
          ItemChargeAssgntPurch2."Document Type",
          ItemChargeAssgntPurch2."Document No.",
          ItemChargeAssgntPurch2."Document Line No.",
          ItemChargeAssgntPurch2."Line No.");
        ItemChargeAssgntPurch."Qty. to Assign" := Round(ItemChargeAssgntPurch2."Qty. to Assign", UOMMgt.QtyRndPrecision);
        ItemChargeAssgntPurch."Amount to Assign" :=
          ItemChargeAssgntPurch."Qty. to Assign" * ItemChargeAssgntPurch."Unit Cost" + AmountRemainder;
        AmountRemainder := ItemChargeAssgntPurch."Amount to Assign" -
          Round(ItemChargeAssgntPurch."Amount to Assign", Currency."Amount Rounding Precision");
        QtyRemainder := ItemChargeAssgntPurch2."Qty. to Assign" - ItemChargeAssgntPurch."Qty. to Assign";
        ItemChargeAssgntPurch."Amount to Assign" :=
          Round(ItemChargeAssgntPurch."Amount to Assign", Currency."Amount Rounding Precision");
        ItemChargeAssgntPurch.Modify();
    end;

    procedure GetItemValues(TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary; var DecimalArray: array[3] of Decimal)
    var
        PurchLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShptLine: Record "Return Shipment Line";
        TransferRcptLine: Record "Transfer Receipt Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        Clear(DecimalArray);
        with TempItemChargeAssgntPurch do
            case "Applies-to Doc. Type" of
                "Applies-to Doc. Type"::Order,
                "Applies-to Doc. Type"::Invoice,
                "Applies-to Doc. Type"::"Return Order",
                "Applies-to Doc. Type"::"Credit Memo":
                    begin
                        PurchLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                        DecimalArray[1] := PurchLine.Quantity;
                        DecimalArray[2] := PurchLine."Gross Weight";
                        DecimalArray[3] := PurchLine."Unit Volume";
                    end;
                "Applies-to Doc. Type"::Receipt:
                    begin
                        PurchRcptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                        DecimalArray[1] := PurchRcptLine.Quantity;
                        DecimalArray[2] := PurchRcptLine."Gross Weight";
                        DecimalArray[3] := PurchRcptLine."Unit Volume";
                    end;
                "Applies-to Doc. Type"::"Return Receipt":
                    begin
                        ReturnRcptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                        DecimalArray[1] := ReturnRcptLine.Quantity;
                        DecimalArray[2] := ReturnRcptLine."Gross Weight";
                        DecimalArray[3] := ReturnRcptLine."Unit Volume";
                    end;
                "Applies-to Doc. Type"::"Return Shipment":
                    begin
                        ReturnShptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                        DecimalArray[1] := ReturnShptLine.Quantity;
                        DecimalArray[2] := ReturnShptLine."Gross Weight";
                        DecimalArray[3] := ReturnShptLine."Unit Volume";
                    end;
                "Applies-to Doc. Type"::"Transfer Receipt":
                    begin
                        TransferRcptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                        DecimalArray[1] := TransferRcptLine.Quantity;
                        DecimalArray[2] := TransferRcptLine."Gross Weight";
                        DecimalArray[3] := TransferRcptLine."Unit Volume";
                    end;
                "Applies-to Doc. Type"::"Sales Shipment":
                    begin
                        SalesShptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                        DecimalArray[1] := SalesShptLine.Quantity;
                        DecimalArray[2] := SalesShptLine."Gross Weight";
                        DecimalArray[3] := SalesShptLine."Unit Volume";
                    end;
            end;
    end;

    procedure SuggestAssgntFromLine(var FromItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    var
        Currency: Record Currency;
        PurchHeader: Record "Purchase Header";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        TotalAmountToAssign: Decimal;
        TotalQtyToAssign: Decimal;
        ItemChargeAssgntLineAmt: Decimal;
        ItemChargeAssgntLineQty: Decimal;
    begin
        with FromItemChargeAssignmentPurch do begin
            PurchHeader.Get("Document Type", "Document No.");
            if not Currency.Get(PurchHeader."Currency Code") then
                Currency.InitRoundingPrecision;

            GetItemChargeAssgntLineAmounts(
              "Document Type", "Document No.", "Document Line No.",
              ItemChargeAssgntLineQty, ItemChargeAssgntLineAmt);

            if not ItemChargeAssignmentPurch.Get("Document Type", "Document No.", "Document Line No.", "Line No.") then
                exit;

            ItemChargeAssignmentPurch."Qty. to Assign" := "Qty. to Assign";
            ItemChargeAssignmentPurch."Amount to Assign" := "Amount to Assign";
            ItemChargeAssignmentPurch.Modify();

            ItemChargeAssignmentPurch.SetRange("Document Type", "Document Type");
            ItemChargeAssignmentPurch.SetRange("Document No.", "Document No.");
            ItemChargeAssignmentPurch.SetRange("Document Line No.", "Document Line No.");
            ItemChargeAssignmentPurch.CalcSums("Qty. to Assign", "Amount to Assign");
            TotalQtyToAssign := ItemChargeAssignmentPurch."Qty. to Assign";
            TotalAmountToAssign := ItemChargeAssignmentPurch."Amount to Assign";

            if TotalAmountToAssign = ItemChargeAssgntLineAmt then
                exit;

            if TotalQtyToAssign = ItemChargeAssgntLineQty then begin
                TotalAmountToAssign := ItemChargeAssgntLineAmt;
                ItemChargeAssignmentPurch.FindSet;
                repeat
                    if not ItemChargeAssignmentPurch.PurchLineInvoiced then begin
                        TempItemChargeAssgntPurch := ItemChargeAssignmentPurch;
                        TempItemChargeAssgntPurch.Insert();
                    end;
                until ItemChargeAssignmentPurch.Next = 0;

                if TempItemChargeAssgntPurch.FindSet then begin
                    repeat
                        ItemChargeAssignmentPurch.Get(
                          TempItemChargeAssgntPurch."Document Type",
                          TempItemChargeAssgntPurch."Document No.",
                          TempItemChargeAssgntPurch."Document Line No.",
                          TempItemChargeAssgntPurch."Line No.");
                        if TotalQtyToAssign <> 0 then begin
                            ItemChargeAssignmentPurch."Amount to Assign" :=
                              Round(
                                ItemChargeAssignmentPurch."Qty. to Assign" / TotalQtyToAssign * TotalAmountToAssign,
                                Currency."Amount Rounding Precision");
                            TotalQtyToAssign -= ItemChargeAssignmentPurch."Qty. to Assign";
                            TotalAmountToAssign -= ItemChargeAssignmentPurch."Amount to Assign";
                            ItemChargeAssignmentPurch.Modify();
                        end;
                    until TempItemChargeAssgntPurch.Next = 0;
                end;
            end;

            ItemChargeAssignmentPurch.Get("Document Type", "Document No.", "Document Line No.", "Line No.");
        end;

        FromItemChargeAssignmentPurch := ItemChargeAssignmentPurch;
    end;

    local procedure GetItemChargeAssgntLineAmounts(DocumentType: Option; DocumentNo: Code[20]; DocumentLineNo: Integer; var ItemChargeAssgntLineQty: Decimal; var ItemChargeAssgntLineAmt: Decimal)
    var
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        Currency: Record Currency;
    begin
        PurchHeader.Get(DocumentType, DocumentNo);
        if not Currency.Get(PurchHeader."Currency Code") then
            Currency.InitRoundingPrecision;

        with PurchLine do begin
            Get(DocumentType, DocumentNo, DocumentLineNo);
            TestField(Type, Type::"Charge (Item)");
            TestField("No.");
            TestField(Quantity);

            if ("Inv. Discount Amount" = 0) and
               ("Line Discount Amount" = 0) and
               (not PurchHeader."Prices Including VAT")
            then
                ItemChargeAssgntLineAmt := "Line Amount"
            else
                if PurchHeader."Prices Including VAT" then
                    ItemChargeAssgntLineAmt :=
                      Round(("Line Amount" - "Inv. Discount Amount") / (1 + "VAT %" / 100),
                        Currency."Amount Rounding Precision")
                else
                    ItemChargeAssgntLineAmt := "Line Amount" - "Inv. Discount Amount";

            ItemChargeAssgntLineAmt :=
              Round(
                ItemChargeAssgntLineAmt * ("Qty. to Invoice" / Quantity),
                Currency."Amount Rounding Precision");
            ItemChargeAssgntLineQty := "Qty. to Invoice";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDocChargeAssgnt(var LastItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var ReceiptNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignItemCharges(var PurchaseLine: Record "Purchase Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDocChargeAssgn(var LastItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var FromPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateShptChargeAssgnt(var FromReturnShptLine: Record "Return Shipment Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesShptChargeAssgnt(var FromSalesShptLine: Record "Sales Shipment Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReturnRcptChargeAssgnt(var FromReturnRcptLine: Record "Return Receipt Line"; ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemChargeAssgntWithAssignValues(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; FromItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSuggestItemChargeAssignStrMenu(PurchLine: Record "Purchase Line"; var SuggestItemChargeMenuTxt: Text; var SuggestItemChargeMessageTxt: Text; var Selection: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignItemCharges(SelectionTxt: Text; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; Currency: Record Currency; PurchaseHeader: Record "Purchase Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var ItemChargesAssigned: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignEquallyOnBeforeItemChargeAssignmentPurchModify(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByAmountOnBeforeItemChargeAssignmentPurchModify(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSuggestAssgntOnAfterItemChargeAssgntPurchSetFilters(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;
}

