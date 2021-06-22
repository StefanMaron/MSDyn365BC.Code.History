codeunit 5807 "Item Charge Assgnt. (Sales)"
{
    Permissions = TableData "Sales Header" = r,
                  TableData "Sales Line" = r,
                  TableData "Sales Shipment Line" = r,
                  TableData "Item Charge Assignment (Sales)" = imd,
                  TableData "Return Receipt Line" = r;

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

    procedure InsertItemChargeAssgnt(ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; ApplToDocType: Option; ApplToDocNo2: Code[20]; ApplToDocLineNo2: Integer; ItemNo2: Code[20]; Description2: Text[100]; var NextLineNo: Integer)
    begin
        InsertItemChargeAssgntWithAssignValues(
          ItemChargeAssgntSales, ApplToDocType, ApplToDocNo2, ApplToDocLineNo2, ItemNo2, Description2, 0, 0, NextLineNo);
    end;

    procedure InsertItemChargeAssgntWithAssignValues(FromItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; ApplToDocType: Option; FromApplToDocNo: Code[20]; FromApplToDocLineNo: Integer; FromItemNo: Code[20]; FromDescription: Text[100]; QtyToAssign: Decimal; AmountToAssign: Decimal; var NextLineNo: Integer)
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        InsertItemChargeAssgntWithAssignValuesTo(
          FromItemChargeAssgntSales, ApplToDocType, FromApplToDocNo, FromApplToDocLineNo, FromItemNo, FromDescription,
          QtyToAssign, AmountToAssign, NextLineNo, ItemChargeAssgntSales);
    end;

    procedure InsertItemChargeAssgntWithAssignValuesTo(FromItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; ApplToDocType: Option; FromApplToDocNo: Code[20]; FromApplToDocLineNo: Integer; FromItemNo: Code[20]; FromDescription: Text[100]; QtyToAssign: Decimal; AmountToAssign: Decimal; var NextLineNo: Integer; var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    begin
        NextLineNo := NextLineNo + 10000;

        ItemChargeAssgntSales."Document No." := FromItemChargeAssgntSales."Document No.";
        ItemChargeAssgntSales."Document Type" := FromItemChargeAssgntSales."Document Type";
        ItemChargeAssgntSales."Document Line No." := FromItemChargeAssgntSales."Document Line No.";
        ItemChargeAssgntSales."Item Charge No." := FromItemChargeAssgntSales."Item Charge No.";
        ItemChargeAssgntSales."Line No." := NextLineNo;
        ItemChargeAssgntSales."Applies-to Doc. No." := FromApplToDocNo;
        ItemChargeAssgntSales."Applies-to Doc. Type" := ApplToDocType;
        ItemChargeAssgntSales."Applies-to Doc. Line No." := FromApplToDocLineNo;
        ItemChargeAssgntSales."Item No." := FromItemNo;
        ItemChargeAssgntSales.Description := FromDescription;
        ItemChargeAssgntSales."Unit Cost" := FromItemChargeAssgntSales."Unit Cost";
        if QtyToAssign <> 0 then begin
            ItemChargeAssgntSales."Amount to Assign" := AmountToAssign;
            ItemChargeAssgntSales.Validate("Qty. to Assign", QtyToAssign);
        end;
        OnBeforeInsertItemChargeAssgntWithAssignValues(ItemChargeAssgntSales, FromItemChargeAssgntSales);
        ItemChargeAssgntSales.Insert();
    end;

    procedure Summarize(var TempToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary; var ToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)")
    begin
        with TempToItemChargeAssignmentSales do begin
            SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
            if FindSet then
                repeat
                    if ("Item Charge No." <> ToItemChargeAssignmentSales."Item Charge No.") or
                       ("Applies-to Doc. No." <> ToItemChargeAssignmentSales."Applies-to Doc. No.") or
                       ("Applies-to Doc. Line No." <> ToItemChargeAssignmentSales."Applies-to Doc. Line No.")
                    then begin
                        if ToItemChargeAssignmentSales."Line No." <> 0 then
                            ToItemChargeAssignmentSales.Insert();
                        ToItemChargeAssignmentSales := TempToItemChargeAssignmentSales;
                        ToItemChargeAssignmentSales."Qty. to Assign" := 0;
                        ToItemChargeAssignmentSales."Amount to Assign" := 0;
                    end;
                    ToItemChargeAssignmentSales."Qty. to Assign" += "Qty. to Assign";
                    ToItemChargeAssignmentSales."Amount to Assign" += "Amount to Assign";
                until Next = 0;
            if ToItemChargeAssignmentSales."Line No." <> 0 then
                ToItemChargeAssignmentSales.Insert();
        end;
    end;

    procedure CreateDocChargeAssgn(LastItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; ShipmentNo: Code[20])
    var
        FromSalesLine: Record "Sales Line";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        NextLineNo: Integer;
    begin
        OnBeforeCreateDocChargeAssgn(LastItemChargeAssgntSales, FromSalesLine);

        with LastItemChargeAssgntSales do begin
            FromSalesLine.SetRange("Document Type", "Document Type");
            FromSalesLine.SetRange("Document No.", "Document No.");
            FromSalesLine.SetRange(Type, FromSalesLine.Type::Item);
            if FromSalesLine.Find('-') then begin
                NextLineNo := "Line No.";
                ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
                ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
                ItemChargeAssgntSales.SetRange("Document Line No.", "Document Line No.");
                ItemChargeAssgntSales.SetRange("Applies-to Doc. No.", "Document No.");
                repeat
                    if (FromSalesLine.Quantity <> 0) and
                       (FromSalesLine.Quantity <> FromSalesLine."Quantity Invoiced") and
                       (FromSalesLine."Job No." = '') and
                       ((ShipmentNo = '') or (FromSalesLine."Shipment No." = ShipmentNo)) and
                       FromSalesLine."Allow Item Charge Assignment"
                    then begin
                        ItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", FromSalesLine."Line No.");
                        if not ItemChargeAssgntSales.FindFirst then
                            InsertItemChargeAssgnt(
                              LastItemChargeAssgntSales, FromSalesLine."Document Type",
                              FromSalesLine."Document No.", FromSalesLine."Line No.",
                              FromSalesLine."No.", FromSalesLine.Description, NextLineNo);
                    end;
                until FromSalesLine.Next = 0;
            end;
        end;

        OnAfterCreateDocChargeAssgnt(LastItemChargeAssgntSales, ShipmentNo);
    end;

    procedure CreateShptChargeAssgnt(var FromSalesShptLine: Record "Sales Shipment Line"; ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    var
        ItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        Nextline: Integer;
    begin
        Nextline := ItemChargeAssgntSales."Line No.";
        ItemChargeAssgntSales2.SetRange("Document Type", ItemChargeAssgntSales."Document Type");
        ItemChargeAssgntSales2.SetRange("Document No.", ItemChargeAssgntSales."Document No.");
        ItemChargeAssgntSales2.SetRange("Document Line No.", ItemChargeAssgntSales."Document Line No.");
        ItemChargeAssgntSales2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntSales2."Applies-to Doc. Type"::Shipment);
        repeat
            FromSalesShptLine.TestField("Job No.", '');
            ItemChargeAssgntSales2.SetRange("Applies-to Doc. No.", FromSalesShptLine."Document No.");
            ItemChargeAssgntSales2.SetRange("Applies-to Doc. Line No.", FromSalesShptLine."Line No.");
            if not ItemChargeAssgntSales2.FindFirst then
                InsertItemChargeAssgnt(ItemChargeAssgntSales, ItemChargeAssgntSales2."Applies-to Doc. Type"::Shipment,
                  FromSalesShptLine."Document No.", FromSalesShptLine."Line No.",
                  FromSalesShptLine."No.", FromSalesShptLine.Description, Nextline);
        until FromSalesShptLine.Next = 0;
    end;

    procedure CreateRcptChargeAssgnt(var FromReturnRcptLine: Record "Return Receipt Line"; ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    var
        ItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)";
        Nextline: Integer;
    begin
        Nextline := ItemChargeAssgntSales."Line No.";
        ItemChargeAssgntSales2.SetRange("Document Type", ItemChargeAssgntSales."Document Type");
        ItemChargeAssgntSales2.SetRange("Document No.", ItemChargeAssgntSales."Document No.");
        ItemChargeAssgntSales2.SetRange("Document Line No.", ItemChargeAssgntSales."Document Line No.");
        ItemChargeAssgntSales2.SetRange(
          "Applies-to Doc. Type", ItemChargeAssgntSales2."Applies-to Doc. Type"::"Return Receipt");
        repeat
            FromReturnRcptLine.TestField("Job No.", '');
            ItemChargeAssgntSales2.SetRange("Applies-to Doc. No.", FromReturnRcptLine."Document No.");
            ItemChargeAssgntSales2.SetRange("Applies-to Doc. Line No.", FromReturnRcptLine."Line No.");
            if not ItemChargeAssgntSales2.FindFirst then
                InsertItemChargeAssgnt(ItemChargeAssgntSales, ItemChargeAssgntSales2."Applies-to Doc. Type"::"Return Receipt",
                  FromReturnRcptLine."Document No.", FromReturnRcptLine."Line No.",
                  FromReturnRcptLine."No.", FromReturnRcptLine.Description, Nextline);
        until FromReturnRcptLine.Next = 0;
    end;

    procedure SuggestAssignment(SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        Selection: Integer;
        SelectionTxt: Text;
        SuggestItemChargeMenuTxt: Text;
        SuggestItemChargeMessageTxt: Text;
    begin
        with SalesLine do begin
            TestField("Qty. to Invoice");
            ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
            ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
            ItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
        end;
        if ItemChargeAssgntSales.IsEmpty then
            exit;

        Selection := 1;
        SuggestItemChargeMenuTxt :=
          StrSubstNo('%1,%2,%3,%4', AssignEquallyMenuText, AssignByAmountMenuText, AssignByWeightMenuText, AssignByVolumeMenuText);
        if ItemChargeAssgntSales.Count > 1 then begin
            Selection := 2;
            SuggestItemChargeMessageTxt := SuggestItemChargeMsg;
            OnBeforeShowSuggestItemChargeAssignStrMenu(SalesLine, SuggestItemChargeMenuTxt, SuggestItemChargeMessageTxt, Selection);
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

        AssignItemCharges(SalesLine, TotalQtyToAssign, TotalAmtToAssign, SelectionTxt);
    end;

    procedure SuggestAssignment2(SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; Selection: Option Equally,"By Amount","By Weight","By Volume")
    begin
        // this function will be deprecated. Please use AssignItemCharges instead
        AssignItemCharges(SalesLine, TotalQtyToAssign, TotalAmtToAssign, Format(Selection))
    end;

    procedure AssignItemCharges(SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; SelectionTxt: Text)
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargesAssigned: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignItemCharges(SalesLine, TotalQtyToAssign, TotalAmtToAssign, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        if not Currency.Get(SalesHeader."Currency Code") then
            Currency.InitRoundingPrecision;

        ItemChargeAssgntSales.SetRange("Document Type", SalesLine."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesLine."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", SalesLine."Line No.");
        if ItemChargeAssgntSales.FindFirst then
            case SelectionTxt of
                AssignEquallyMenuText:
                    AssignEqually(ItemChargeAssgntSales, Currency, TotalQtyToAssign, TotalAmtToAssign);
                AssignByAmountMenuText:
                    AssignByAmount(ItemChargeAssgntSales, Currency, SalesHeader, TotalQtyToAssign, TotalAmtToAssign);
                AssignByWeightMenuText:
                    AssignByWeight(ItemChargeAssgntSales, Currency, TotalQtyToAssign);
                AssignByVolumeMenuText:
                    AssignByVolume(ItemChargeAssgntSales, Currency, TotalQtyToAssign);
                else begin
                        OnAssignItemCharges(
                          SelectionTxt, ItemChargeAssgntSales, Currency, SalesHeader, TotalQtyToAssign, TotalAmtToAssign, ItemChargesAssigned);
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

    local procedure AssignEqually(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        RemainingNumOfLines: Integer;
    begin
        repeat
            if not ItemChargeAssignmentSales.SalesLineInvoiced then begin
                TempItemChargeAssgntSales.Init();
                TempItemChargeAssgntSales := ItemChargeAssignmentSales;
                TempItemChargeAssgntSales.Insert();
            end;
        until ItemChargeAssignmentSales.Next = 0;

        if TempItemChargeAssgntSales.FindSet(true) then begin
            RemainingNumOfLines := TempItemChargeAssgntSales.Count();
            repeat
                ItemChargeAssignmentSales.Get(
                  TempItemChargeAssgntSales."Document Type",
                  TempItemChargeAssgntSales."Document No.",
                  TempItemChargeAssgntSales."Document Line No.",
                  TempItemChargeAssgntSales."Line No.");
                ItemChargeAssignmentSales."Qty. to Assign" :=
                  Round(TotalQtyToAssign / RemainingNumOfLines, UOMMgt.QtyRndPrecision);
                ItemChargeAssignmentSales."Amount to Assign" :=
                  Round(
                    ItemChargeAssignmentSales."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                    Currency."Amount Rounding Precision");
                TotalQtyToAssign -= ItemChargeAssignmentSales."Qty. to Assign";
                TotalAmtToAssign -= ItemChargeAssignmentSales."Amount to Assign";
                RemainingNumOfLines := RemainingNumOfLines - 1;
                OnAssignEquallyOnBeforeItemChargeAssignmentSalesModify(ItemChargeAssignmentSales);
                ItemChargeAssignmentSales.Modify();
            until TempItemChargeAssgntSales.Next = 0;
        end;
        TempItemChargeAssgntSales.DeleteAll();
    end;

    local procedure AssignByAmount(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; SalesHeader: Record "Sales Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal)
    var
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        CurrExchRate: Record "Currency Exchange Rate";
        ReturnRcptLine: Record "Return Receipt Line";
        CurrencyCode: Code[10];
        TotalAppliesToDocLineAmount: Decimal;
    begin
        repeat
            if not ItemChargeAssignmentSales.SalesLineInvoiced then begin
                TempItemChargeAssgntSales.Init();
                TempItemChargeAssgntSales := ItemChargeAssignmentSales;
                case ItemChargeAssignmentSales."Applies-to Doc. Type" of
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::Quote,
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::Order,
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::Invoice,
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::"Return Order",
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::"Credit Memo":
                        begin
                            SalesLine.Get(
                              ItemChargeAssignmentSales."Applies-to Doc. Type",
                              ItemChargeAssignmentSales."Applies-to Doc. No.",
                              ItemChargeAssignmentSales."Applies-to Doc. Line No.");
                            TempItemChargeAssgntSales."Applies-to Doc. Line Amount" :=
                              Abs(SalesLine."Line Amount");
                        end;
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::"Return Receipt":
                        begin
                            ReturnRcptLine.Get(
                              ItemChargeAssignmentSales."Applies-to Doc. No.",
                              ItemChargeAssignmentSales."Applies-to Doc. Line No.");
                            CurrencyCode := ReturnRcptLine.GetCurrencyCode;
                            if CurrencyCode = SalesHeader."Currency Code" then
                                TempItemChargeAssgntSales."Applies-to Doc. Line Amount" :=
                                  Abs(ReturnRcptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntSales."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    SalesHeader."Posting Date", CurrencyCode, SalesHeader."Currency Code",
                                    Abs(ReturnRcptLine."Item Charge Base Amount"));
                        end;
                    ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment:
                        begin
                            SalesShptLine.Get(
                              ItemChargeAssignmentSales."Applies-to Doc. No.",
                              ItemChargeAssignmentSales."Applies-to Doc. Line No.");
                            CurrencyCode := SalesShptLine.GetCurrencyCode;
                            if CurrencyCode = SalesHeader."Currency Code" then
                                TempItemChargeAssgntSales."Applies-to Doc. Line Amount" :=
                                  Abs(SalesShptLine."Item Charge Base Amount")
                            else
                                TempItemChargeAssgntSales."Applies-to Doc. Line Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    SalesHeader."Posting Date", CurrencyCode, SalesHeader."Currency Code",
                                    Abs(SalesShptLine."Item Charge Base Amount"));
                        end;
                end;
                if TempItemChargeAssgntSales."Applies-to Doc. Line Amount" <> 0 then
                    TempItemChargeAssgntSales.Insert
                else begin
                    ItemChargeAssignmentSales."Amount to Assign" := 0;
                    ItemChargeAssignmentSales."Qty. to Assign" := 0;
                    ItemChargeAssignmentSales.Modify();
                end;
                TotalAppliesToDocLineAmount += TempItemChargeAssgntSales."Applies-to Doc. Line Amount";
            end;
        until ItemChargeAssignmentSales.Next = 0;

        if TempItemChargeAssgntSales.FindSet(true) then
            repeat
                ItemChargeAssignmentSales.Get(
                  TempItemChargeAssgntSales."Document Type",
                  TempItemChargeAssgntSales."Document No.",
                  TempItemChargeAssgntSales."Document Line No.",
                  TempItemChargeAssgntSales."Line No.");
                if TotalQtyToAssign <> 0 then begin
                    ItemChargeAssignmentSales."Qty. to Assign" :=
                      Round(
                        TempItemChargeAssgntSales."Applies-to Doc. Line Amount" / TotalAppliesToDocLineAmount * TotalQtyToAssign,
                        UOMMgt.QtyRndPrecision);
                    ItemChargeAssignmentSales."Amount to Assign" :=
                      Round(
                        ItemChargeAssignmentSales."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                        Currency."Amount Rounding Precision");
                    TotalQtyToAssign -= ItemChargeAssignmentSales."Qty. to Assign";
                    TotalAmtToAssign -= ItemChargeAssignmentSales."Amount to Assign";
                    TotalAppliesToDocLineAmount -= TempItemChargeAssgntSales."Applies-to Doc. Line Amount";
                    OnAssignByAmountOnBeforeItemChargeAssignmentSalesModify(ItemChargeAssignmentSales);
                    ItemChargeAssignmentSales.Modify();
                end;
            until TempItemChargeAssgntSales.Next = 0;

        TempItemChargeAssgntSales.DeleteAll();
    end;

    local procedure AssignByWeight(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; TotalQtyToAssign: Decimal)
    var
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        LineArray: array[3] of Decimal;
        TotalGrossWeight: Decimal;
        QtyRemaining: Decimal;
        AmountRemaining: Decimal;
    begin
        repeat
            if not ItemChargeAssignmentSales.SalesLineInvoiced then begin
                TempItemChargeAssgntSales.Init();
                TempItemChargeAssgntSales := ItemChargeAssignmentSales;
                TempItemChargeAssgntSales.Insert();
                GetItemValues(TempItemChargeAssgntSales, LineArray);
                TotalGrossWeight := TotalGrossWeight + (LineArray[2] * LineArray[1]);
            end;
        until ItemChargeAssignmentSales.Next = 0;

        if TempItemChargeAssgntSales.FindSet(true) then
            repeat
                GetItemValues(TempItemChargeAssgntSales, LineArray);
                if TotalGrossWeight <> 0 then
                    TempItemChargeAssgntSales."Qty. to Assign" :=
                      (TotalQtyToAssign * LineArray[2] * LineArray[1]) / TotalGrossWeight + QtyRemaining
                else
                    TempItemChargeAssgntSales."Qty. to Assign" := 0;
                AssignSalesItemCharge(ItemChargeAssignmentSales, TempItemChargeAssgntSales, Currency, QtyRemaining, AmountRemaining);
            until TempItemChargeAssgntSales.Next = 0;
        TempItemChargeAssgntSales.DeleteAll();
    end;

    local procedure AssignByVolume(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; TotalQtyToAssign: Decimal)
    var
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        LineArray: array[3] of Decimal;
        TotalUnitVolume: Decimal;
        QtyRemaining: Decimal;
        AmountRemaining: Decimal;
    begin
        repeat
            if not ItemChargeAssignmentSales.SalesLineInvoiced then begin
                TempItemChargeAssgntSales.Init();
                TempItemChargeAssgntSales := ItemChargeAssignmentSales;
                TempItemChargeAssgntSales.Insert();
                GetItemValues(TempItemChargeAssgntSales, LineArray);
                TotalUnitVolume := TotalUnitVolume + (LineArray[3] * LineArray[1]);
            end;
        until ItemChargeAssignmentSales.Next = 0;

        if TempItemChargeAssgntSales.FindSet(true) then
            repeat
                GetItemValues(TempItemChargeAssgntSales, LineArray);
                if TotalUnitVolume <> 0 then
                    TempItemChargeAssgntSales."Qty. to Assign" :=
                      (TotalQtyToAssign * LineArray[3] * LineArray[1]) / TotalUnitVolume + QtyRemaining
                else
                    TempItemChargeAssgntSales."Qty. to Assign" := 0;
                AssignSalesItemCharge(ItemChargeAssignmentSales, TempItemChargeAssgntSales, Currency, QtyRemaining, AmountRemaining);
            until TempItemChargeAssgntSales.Next = 0;
        TempItemChargeAssgntSales.DeleteAll();
    end;

    local procedure AssignSalesItemCharge(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; ItemChargeAssignmentSales2: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; var QtyRemaining: Decimal; var AmountRemaining: Decimal)
    begin
        ItemChargeAssignmentSales.Get(
          ItemChargeAssignmentSales2."Document Type",
          ItemChargeAssignmentSales2."Document No.",
          ItemChargeAssignmentSales2."Document Line No.",
          ItemChargeAssignmentSales2."Line No.");
        ItemChargeAssignmentSales."Qty. to Assign" :=
          Round(ItemChargeAssignmentSales2."Qty. to Assign", UOMMgt.QtyRndPrecision);
        ItemChargeAssignmentSales."Amount to Assign" :=
          ItemChargeAssignmentSales."Qty. to Assign" * ItemChargeAssignmentSales."Unit Cost" + AmountRemaining;
        AmountRemaining := ItemChargeAssignmentSales."Amount to Assign" -
          Round(ItemChargeAssignmentSales."Amount to Assign", Currency."Amount Rounding Precision");
        QtyRemaining := ItemChargeAssignmentSales2."Qty. to Assign" - ItemChargeAssignmentSales."Qty. to Assign";
        ItemChargeAssignmentSales."Amount to Assign" :=
          Round(ItemChargeAssignmentSales."Amount to Assign", Currency."Amount Rounding Precision");
        ItemChargeAssignmentSales.Modify();
    end;

    procedure GetItemValues(TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; var DecimalArray: array[3] of Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        Clear(DecimalArray);
        with TempItemChargeAssgntSales do
            case "Applies-to Doc. Type" of
                "Applies-to Doc. Type"::Order,
                "Applies-to Doc. Type"::Invoice,
                "Applies-to Doc. Type"::"Return Order",
                "Applies-to Doc. Type"::"Credit Memo":
                    begin
                        SalesLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                        DecimalArray[1] := SalesLine.Quantity;
                        DecimalArray[2] := SalesLine."Gross Weight";
                        DecimalArray[3] := SalesLine."Unit Volume";
                    end;
                "Applies-to Doc. Type"::"Return Receipt":
                    begin
                        ReturnRcptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                        DecimalArray[1] := ReturnRcptLine.Quantity;
                        DecimalArray[2] := ReturnRcptLine."Gross Weight";
                        DecimalArray[3] := ReturnRcptLine."Unit Volume";
                    end;
                "Applies-to Doc. Type"::Shipment:
                    begin
                        SalesShptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                        DecimalArray[1] := SalesShptLine.Quantity;
                        DecimalArray[2] := SalesShptLine."Gross Weight";
                        DecimalArray[3] := SalesShptLine."Unit Volume";
                    end;
            end;
    end;

    procedure SuggestAssignmentFromLine(var FromItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)")
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        TotalAmountToAssign: Decimal;
        TotalQtyToAssign: Decimal;
        ItemChargeAssgntLineAmt: Decimal;
        ItemChargeAssgntLineQty: Decimal;
    begin
        with FromItemChargeAssignmentSales do begin
            SalesHeader.Get("Document Type", "Document No.");
            if not Currency.Get(SalesHeader."Currency Code") then
                Currency.InitRoundingPrecision;

            GetItemChargeAssgntLineAmounts(
              "Document Type", "Document No.", "Document Line No.",
              ItemChargeAssgntLineQty, ItemChargeAssgntLineAmt);

            if not ItemChargeAssignmentSales.Get("Document Type", "Document No.", "Document Line No.", "Line No.") then
                exit;

            ItemChargeAssignmentSales."Qty. to Assign" := "Qty. to Assign";
            ItemChargeAssignmentSales."Amount to Assign" := "Amount to Assign";
            ItemChargeAssignmentSales.Modify();

            ItemChargeAssignmentSales.SetRange("Document Type", "Document Type");
            ItemChargeAssignmentSales.SetRange("Document No.", "Document No.");
            ItemChargeAssignmentSales.SetRange("Document Line No.", "Document Line No.");
            ItemChargeAssignmentSales.CalcSums("Qty. to Assign", "Amount to Assign");
            TotalQtyToAssign := ItemChargeAssignmentSales."Qty. to Assign";
            TotalAmountToAssign := ItemChargeAssignmentSales."Amount to Assign";

            if TotalAmountToAssign = ItemChargeAssgntLineAmt then
                exit;

            if TotalQtyToAssign = ItemChargeAssgntLineQty then begin
                TotalAmountToAssign := ItemChargeAssgntLineAmt;
                ItemChargeAssignmentSales.FindSet;
                repeat
                    if not ItemChargeAssignmentSales.SalesLineInvoiced then begin
                        TempItemChargeAssgntSales := ItemChargeAssignmentSales;
                        TempItemChargeAssgntSales.Insert();
                    end;
                until ItemChargeAssignmentSales.Next = 0;

                if TempItemChargeAssgntSales.FindSet then begin
                    repeat
                        ItemChargeAssignmentSales.Get(
                          TempItemChargeAssgntSales."Document Type",
                          TempItemChargeAssgntSales."Document No.",
                          TempItemChargeAssgntSales."Document Line No.",
                          TempItemChargeAssgntSales."Line No.");
                        if TotalQtyToAssign <> 0 then begin
                            ItemChargeAssignmentSales."Amount to Assign" :=
                              Round(
                                ItemChargeAssignmentSales."Qty. to Assign" / TotalQtyToAssign * TotalAmountToAssign,
                                Currency."Amount Rounding Precision");
                            TotalQtyToAssign -= ItemChargeAssignmentSales."Qty. to Assign";
                            TotalAmountToAssign -= ItemChargeAssignmentSales."Amount to Assign";
                            ItemChargeAssignmentSales.Modify();
                        end;
                    until TempItemChargeAssgntSales.Next = 0;
                end;
            end;

            ItemChargeAssignmentSales.Get("Document Type", "Document No.", "Document Line No.", "Line No.");
        end;

        FromItemChargeAssignmentSales := ItemChargeAssignmentSales;
    end;

    local procedure GetItemChargeAssgntLineAmounts(DocumentType: Option; DocumentNo: Code[20]; DocumentLineNo: Integer; var ItemChargeAssgntLineQty: Decimal; var ItemChargeAssgntLineAmt: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        if SalesHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(SalesHeader."Currency Code");

        with SalesLine do begin
            Get(DocumentType, DocumentNo, DocumentLineNo);
            TestField(Type, Type::"Charge (Item)");
            TestField("No.");
            TestField(Quantity);

            if ("Inv. Discount Amount" = 0) and
               ("Line Discount Amount" = 0) and
               (not SalesHeader."Prices Including VAT")
            then
                ItemChargeAssgntLineAmt := "Line Amount"
            else
                if SalesHeader."Prices Including VAT" then
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
    local procedure OnAfterCreateDocChargeAssgnt(var LastItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var ShipmentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignItemCharges(var SalesLine: Record "Sales Line"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDocChargeAssgn(var LastItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemChargeAssgntWithAssignValues(var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; FromItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSuggestItemChargeAssignStrMenu(SalesLine: Record "Sales Line"; var SuggestItemChargeMenuTxt: Text; var SuggestItemChargeMessageTxt: Text; var Selection: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignItemCharges(SelectionTxt: Text; var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; Currency: Record Currency; SalesHeader: Record "Sales Header"; TotalQtyToAssign: Decimal; TotalAmtToAssign: Decimal; var ItemChargesAssigned: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignEquallyOnBeforeItemChargeAssignmentSalesModify(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssignByAmountOnBeforeItemChargeAssignmentSalesModify(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)")
    begin
    end;
}

